defmodule Role.Svr do
  use GenServer
  use Common

  defstruct role_id: nil, last_save_time: nil, status: 0, last_msg_time: nil

  @status_init 0
  @status_online 1
  @status_offline 2

  @save_interval 5
  @loop_interval 1000

  ## =====API====
  # def start(role_id) do
  #   DynamicSupervisor.start_child(
  #     Role.Sup,
  #     {__MODULE__, role_id}
  #   )
  # end

  def pid(role_id) do
    :global.whereis_name(name(role_id))
  end

  # 获取在线玩家pid
  def role_pids(role_ids) do
    Enum.reduce(role_ids, [], fn role_id, role_pids ->
      role_pid = pid(role_id)

      if is_pid(role_pid) do
        [role_pid | role_pids]
      else
        role_pids
      end
    end)
  end

  # 判断玩家在线
  def alive?(role_id) do
    pid(role_id)
    |> is_pid()
  end

  # 在角色进程执行模块回调函数
  def manifold_do_callback_fun(role_ids, mod_fun, args \\ []) do
    role_pids(role_ids)
    |> Manifold.send({:callback_fun, mod_fun, args})
  end

  # 在角色进程执行模块回调函数
  def execute_mod_fun(role_id_or_ids, mod_fun) do
    execute_mod_fun(role_id_or_ids, mod_fun, [])
  end

  def execute_mod_fun(role_id, mod_fun, args) when is_integer(role_id) do
    execute_mod_fun([role_id], mod_fun, args)
  end

  def execute_mod_fun(role_ids, mod_fun, args) when is_list(role_ids) do
    for role_pid <- role_pids(role_ids) do
      Process.send(role_pid, {:callback_fun, mod_fun, args}, [:nosuspend])
    end
  end

  def exit(role_id) do
    cast(role_id, :exit)
  end

  def client_msg(role_id, msg) do
    cast(role_id, {:client_msg, msg})
  end

  def reconnect(role_id) do
    cast(role_id, :reconnect)
  end

  def offline(role_id) do
    cast(role_id, :offline)
  end

  def role_status_change(role_id, event) do
    cast(role_id, {:role_status_change, event})
  end

  def get_data(role_id, mod) do
    call(role_id, {:apply, mod, :get_data, []})
  end

  def get_all_data(role_id) do
    call(role_id, :get_all_data)
  end

  def execute(role_id, mod_fun, args) do
    call(role_id, {:execute, mod_fun, args})
  end

  def role_id() do
    Process.get(:role_id)
  end

  def sid() do
    Process.get(:sid)
  end

  def child_spec(role_id) do
    %{
      id: "Role_#{role_id}",
      start: {__MODULE__, :start_link, [role_id]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  def start_link(role_id) do
    GenServer.start_link(__MODULE__, role_id, name: via(role_id))
  end

  ## ===CALLBACK====
  @impl true
  def init(role_id) do
    Logger.debug("role.svr [#{role_id}]  start")
    Process.put(:role_id, role_id)
    Role.load_data()
    now = Util.unixtime()
    status = @status_init
    Process.send(self(), :init, [:nosuspend])
    {:ok, ~M{%Role.Svr role_id,status,last_save_time: now, last_msg_time: now}}
  end

  @impl true
  def handle_info(:init, ~M{%Role.Svr role_id} = state) do
    Process.put(:sid, Role.Misc.sid(role_id))
    hook(:init)
    Process.send_after(self(), :secondloop, @loop_interval)
    :pg.join(__MODULE__, self())
    status = @status_online
    {:noreply, ~M{%Role.Svr state|status}}
  end

  def handle_info(:secondloop, state) do
    now = Util.longunixtime()
    now_sec = round(now / 1000)
    interval = (now_sec + 1) * 1000 - now
    Process.send_after(self(), :secondloop, interval)
    hook(:secondloop, [now_sec])

    state =
      state
      |> check_save(now_sec)
      |> check_down(now_sec)

    {:noreply, state}
  end

  def handle_info(:safe_stop, state) do
    try do
      Role.save_all()
      {:stop, :normal, state}
    rescue
      err ->
        Logger.warning("safe save data error: #{inspect(err)}, retry later..")
        Process.send_after(self(), :safe_stop, 1000)
        {:noreply, state}
    end
  end

  def handle_info({:callback_fun, mod_fun, args}, state) do
    try do
      mod = Function.info(mod_fun)[:module]
      mod_fun.(mod.get_data(), args)
      {:noreply, state}
    rescue
      err ->
        Logger.warning(
          "#{inspect(err)},  args: #{inspect(args)} \n    Stacktrace: #{inspect(__STACKTRACE__)}"
        )

        {:noreply, state}
    end
  end

  def handle_info(msg, state) do
    Logger.warn("unhandle msg: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:client_msg, data}, state) when is_binary(data) do
    with {:ok, msg} <- PB.decode(data) do
      mod = msg |> Map.get(:__struct__) |> PB.mod()

      try do
        mod.h(msg)
      catch
        x when is_integer(x) ->
          Role.Misc.sd_err(x)

        x when is_bitstring(x) ->
          Role.Misc.sd_err(0, x)

        x ->
          Role.Misc.sd_err(0, inspect(x))
      end
    else
      err ->
        Logger.warning("client msg decode error, #{inspect(err)}")
    end

    last_msg_time = Util.unixtime()
    {:noreply, ~M{%Role.Svr state | last_msg_time}}
  end

  def handle_cast(:reconnect, ~M{role_id} = state) do
    Process.put(:sid, Role.Misc.sid(role_id))
    status = @status_online
    {:noreply, ~M{state|status}}
  end

  def handle_cast(:exit, state) do
    Logger.debug("exit role svr #{state.role_id} ")
    hook(:on_terminate)
    Process.send(self(), :safe_stop, [:nosuspend])
    {:noreply, state}
  end

  def handle_cast(:offline, state) do
    Logger.debug("role offline")
    hook(:on_offline)
    status = @status_offline
    {:noreply, ~M{%Role.Svr state|status}}
  end

  def handle_cast({:kicked_from_room, f_role_id}, state) do
    Role.Mod.Room.kicked_from_room(f_role_id)
    {:noreply, state}
  end

  def handle_cast({:role_status_change, event}, state) do
    for mod <- PB.modules() do
      try do
        if function_exported?(mod, :role_status_change, 3) do
          old_status = Role.Misc.get_role_status()
          apply(mod, :role_status_change, [mod.get_data(), old_status, event])
        end

        true
      catch
        kind, reason ->
          Logger.error(
            "#{mod} [role_status_change] event: [#{inspect(event)}], error !! #{inspect({kind, reason})} , #{inspect(__STACKTRACE__)} "
          )

          false
      end
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:apply, mod, f, args}, _from, state) do
    reply = :erlang.apply(mod, f, args)
    {:reply, reply, state}
  end

  def handle_call(:get_all_data, _from, state) do
    reply =
      for mod <- PB.modules() do
        {mod, mod.get_data() |> Map.from_struct()}
      end

    {:reply, reply, state}
  end

  def handle_call({:execute, mod_fun, args}, _from, state) do
    try do
      mod = Function.info(mod_fun)[:module]
      reply = mod_fun.(mod.get_data(), args)
      {:reply, reply, state}
    catch
      {:error, err} ->
        {:reply, {:error, err}, state}

      err ->
        {:reply, {:error, err}, state}
    end
  end

  @impl true
  def terminate(_reason, _state) do
    Role.save_all()
    :ok
  end

  @impl true
  def code_change(old_vsn, state, extra) do
    for mod <- extra, mod != __MODULE__ do
      apply(mod, :code_change, [old_vsn])
    end

    {:ok, state}
  end

  defp hook(f, args \\ []) do
    for mod <- PB.modules() do
      try do
        apply(mod, f, args)
      catch
        kind, reason ->
          Logger.error(
            "#{mod} [#{f}] error !! #{inspect({kind, reason})} , #{inspect(__STACKTRACE__)} "
          )

          false
      end
    end
  end

  defp check_save(~M{%Role.Svr last_save_time} = state, now) do
    if now - last_save_time >= @save_interval do
      hook(:save)
      ~M{state | last_save_time: now }
    else
      state
    end
  end

  defp check_down(~M{%Role.Svr last_msg_time,status} = state, now) do
    timeout = now - last_msg_time

    cond do
      # status == @status_init && timeout >= 5 ->
      #   Process.send(self(), :exit, [:nosuspend])
      status == @status_offline && timeout >= 5 ->
        cast(self(), :exit)

      true ->
        :ignore
    end

    state
  end

  def name(role_id) do
    :"Role_#{role_id}"
  end

  def via(role_id) do
    {:global, name(role_id)}
    # {:via, Horde.Registry, {Matrix.RoleRegistry, role_id}}
  end

  def cast(role_id, msg) when is_integer(role_id) do
    role_id
    |> via()
    |> GenServer.cast(msg)
  end

  def cast(pid, msg) when is_pid(pid) do
    pid |> GenServer.cast(msg)
  end

  def call(role_id, msg) when is_integer(role_id) do
    with role_pid when is_pid(role_pid) <- pid(role_id) do
      call(role_pid, msg)
    else
      _ ->
        {:error, :role_not_online}
    end
  end

  def call(pid, msg) when is_pid(pid) do
    pid |> GenServer.call(msg)
  end
end

defmodule Mail do
  use GenServer
  use Memoize
  use Common
  @dump_interval 1000

  defmodule Schema do
    defstruct id: nil,
              oid: 0,
              body: "",
              args: [],
              attachs: [],
              create_time: 0,
              expire_time: 0,
              status: 0
  end

  defstruct mails: nil, max_mail_id: 0, is_dirty: false

  # 发送全服系统邮件
  @spec send_global_mail(neg_integer(), list(), neg_integer()) :: :ok
  def send_global_mail(oid, args, expire_time) when oid > 0 do
    # TODO need set body,attachs and expire_time
    GenServer.call(via_tuple(), {:send_global_mail, ~M{%Schema oid,args,expire_time}})
  end

  # 发送全服自定义邮件
  @spec send_global_mail(binary(), list(), list(), neg_integer()) :: :ok
  def send_global_mail(body, args, attachs, expire_time) do
    GenServer.call(via_tuple(), {:send_global_mail, ~M{%Schema body,args,attachs,expire_time}})
  end

  # 拉取 mail_id > last_mail_id 的全服邮件
  @spec fetch_mails(neg_integer()) :: :ok
  defmemo fetch_mails(last_mail_id) do
    GenServer.call(via_tuple(), {:fetch_mails, last_mail_id})
  end

  def fetch_mails2(last_mail_id) do
    GenServer.call(via_tuple(), {:fetch_mails, last_mail_id})
  end

  def start_link(args) do
    case GenServer.start_link(__MODULE__, args, name: via_tuple()) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  @impl true
  def init(_args) do
    Process.flag(:trap_exit, true)
    Process.send_after(self(), :init_mail, 1_000)
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_cast(_, %__MODULE__{mails: nil} = state) do
    Logger.warn("#{__MODULE__} mail need init first!")
    {:noreply, state}
  end

  @impl true
  def handle_call(_msg, _from, %__MODULE__{mails: nil} = state) do
    Logger.warn("#{__MODULE__} mail need init first!")
    {:reply, nil, state}
  end

  def handle_call({:send_global_mail, %Schema{} = mail}, _, ~M{%Mail max_mail_id,mails} = state) do
    max_mail_id = max_mail_id + 1
    mails = [~M{mail|id: max_mail_id} | mails]
    Mail.Manager.clear_cache(__MODULE__, :fetch_mails, :_)
    {:reply, :ok, ~M{state|mails,max_mail_id,is_dirty: true}}
  end

  def handle_call({:fetch_mails, last_mail_id}, _, ~M{%Mail max_mail_id,mails} = state) do
    if max_mail_id > last_mail_id do
      undeal_mails =
        Enum.reduce_while(mails, [], fn x, acc ->
          if x.id > last_mail_id do
            {:cont, [x | acc]}
          else
            {:halt, acc}
          end
        end)

      {:reply, undeal_mails, state}
    else
      {:reply, [], state}
    end
  end

  @impl true
  def handle_info(:init_mail, state) do
    with %__MODULE__{} = state <- load() do
      Logger.info("#{__MODULE__} init mail success!")
      Process.send_after(self(), :dump_mail, dump_interval())
      {:noreply, state}
    else
      {:error, error} ->
        Process.send_after(self(), :init_mail, 1_000)
        Logger.debug(inspect(error))
        {:noreply, state}
    end
  end

  def handle_info(:dump_mail, %__MODULE__{is_dirty: false} = state) do
    Process.send_after(self(), :dump_mail, dump_interval())
    {:noreply, state}
  end

  def handle_info(:dump_mail, %__MODULE__{is_dirty: true} = state) do
    IO.inspect("hh2")

    with %__MODULE__{is_dirty: false} = state <- dump(state) do
      Logger.info("#{__MODULE__} dump mail success!")
      Process.send_after(self(), :dump_mail, dump_interval())
      {:noreply, state}
    else
      {:error, _error} ->
        Process.send_after(self(), :dump_mail, dump_interval())
        {:noreply, state}
    end
  end

  # look for details: https://hexdocs.pm/horde/Horde.Registry.html#register/3
  def handle_info(
        {:EXIT, _registry_pid,
         {:name_conflict, {_name, _value}, _registry_name, _winning_pid} = err},
        state
      ) do
    Logger.info(inspect(err))
    Process.exit(self(), :kill)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    IO.inspect("#{__MODULE__} stop")
    dump(state)
    :ok
  end

  def via_tuple(), do: {:via, Horde.Registry, {Matrix.MailRegistry, __MODULE__}}

  defp key() do
    __MODULE__
  end

  defp load() do
    try do
      temp = Redis.get(key())

      if is_nil(temp) do
        mails = []
        %__MODULE__{mails: mails}
      else
        mails = :erlang.binary_to_term(temp)
        mail = hd(mails)
        %__MODULE__{mails: mails, max_mail_id: mail.id}
      end
    catch
      error ->
        {:error, error}
    end
  end

  defp dump(%__MODULE__{mails: nil} = state), do: state
  defp dump(%__MODULE__{is_dirty: false} = state), do: state

  defp dump(%__MODULE__{mails: mails} = state) do
    IO.inspect("h")

    try do
      val = :erlang.term_to_binary(mails)
      "OK" = Redis.set(key(), val)
      put_in(state.is_dirty, false)
    catch
      error ->
        Logger.warn("#{__MODULE__} dump failed,reason: #{inspect(error)}")
        {:error, error}
    end
  end

  defp dump_interval() do
    @dump_interval + Util.rand(0, 1000)
  end
end

defmodule Mail.Global do
  use GenServer
  use Memoize
  use Common

  defstruct mails: nil, max_mail_id: 0, is_dirty: false

  def db_key() do
    __MODULE__
  end

  # 发送全服系统邮件
  @spec send_mail(neg_integer(), list(), neg_integer()) :: :ok
  def send_mail(cfg_id, args, expire_time) when cfg_id > 0 do
    # TODO need set body,attachs and expire_time
    GenServer.call(via_tuple(), {:send_mail, ~M{%Mail cfg_id,args,expire_time}})
  end

  # 发送全服自定义邮件
  @spec send_mail(binary(), list(), list(), neg_integer()) :: :ok
  def send_mail(body, args, attachs, expire_time) do
    GenServer.call(via_tuple(), {:send_mail, ~M{%Mail body,args,attachs,expire_time}})
  end

  # 拉取 mail_id > last_mail_id 的全服邮件 asc
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

  def handle_call({:send_mail, %Mail{} = mail}, _, ~M{%__MODULE__ max_mail_id,mails} = state) do
    max_mail_id = max_mail_id + 1
    new_mail = ~M{mail|id: max_mail_id}
    save_mail(new_mail)
    mails = [new_mail | mails]
    Mail.Manager.clear_cache(__MODULE__, :fetch_mails, :_)
    {:reply, :ok, ~M{state|mails,max_mail_id,is_dirty: true}}
  end

  def handle_call({:fetch_mails, last_mail_id}, _, ~M{%__MODULE__ max_mail_id,mails} = state) do
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
    with %__MODULE__{} = state <- load_mails() do
      Logger.info("#{__MODULE__} init mail success!")
      {:noreply, state}
    else
      {:error, error} ->
        Process.send_after(self(), :init_mail, 1_000)
        Logger.debug(inspect(error))
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
  def terminate(_reason, _state) do
    IO.inspect("#{__MODULE__} stop")
    :ok
  end

  def via_tuple(), do: {:via, Horde.Registry, {Matrix.MailRegistry, __MODULE__}}

  # desc
  defp load_mails() do
    try do
      mails =
        Redis.lrange(db_key(), -1000, -1)
        |> Enum.reduce([], fn x, acc -> [Poison.decode!(x, as: %Mail{}) | acc] end)

      last_mail = List.first(mails, %Mail{id: 0})
      %__MODULE__{mails: mails, max_mail_id: last_mail.id}
    catch
      error ->
        {:error, error}
    end
  end

  defp save_mail(%Mail{} = mail) do
    Redis.rpush(db_key(), Map.from_struct(mail))
  end
end

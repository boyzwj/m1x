defmodule Redis do
  use GenServer
  use Common
  defstruct conns: {}

  @redis_blocks Application.get_env(:m1x, :redis_blocks)
  @db_worker_num Application.get_env(:m1x, :db_worker_num)
  @type score :: integer() | float()
  @type array :: [any()]
  @type opt :: [:withscores]
  ###       API          ###
  def hset(key, field, value) do
    select_call("HSET", [key, field, value])
  end

  def hset_array(_key, []), do: 0

  def hset_array(key, array) do
    select_call("HSET", [key | array])
  end

  def hget(key, field) do
    select_call("HGET", [key, field])
  end

  def hgetall(key) do
    select_call("HGETALL", [key])
  end

  def set(key, value) do
    select_call("SET", [key, value])
  end

  def get(key) do
    select_call("GET", [key])
  end

  def incr(key) do
    select_call("INCR", [key])
  end

  def clearall() do
    select_call("FLUSHALL", [])
  end

  def bf_add(filter, key) do
    select_call("BF.ADD", [filter, key])
  end

  def bf_exists?(filter, key) do
    select_call("BF.EXISTS", [filter, key])
  end

  @doc """
  add member into redis sorted set

  ## Examples

      iex> Redis.zadd("rank:role_level",1,"Mar")
      1

      iex> Redis.zadd("rank:role_level",[2.1,"June",4.0,"May"])
      2
  """
  @spec zadd(binary() | atom(), score(), binary()) :: term()
  def zadd(key, score, member) do
    zadd(key, [score, member])
  end

  @spec zadd(binary(), array()) :: term()
  def zadd(key, array) do
    select_call("ZADD", [key | array])
  end

  @doc """
  get the range members from redis sorted set, ordered from highest to lowest.

  ## Examples
      # list all members
      iex> Redis.zrange("rank:role_level",0,-1)
      [...]


      # list last three members
      iex> Redis.zrange("rank:role_level",-3,-1)
      [...]

      # list members with score
      iex> Redis.zrange("rank:role_level",0,-1,[:withscores])
      [...]
  """
  @spec zrange(binary() | atom(), score(), score(), opt()) :: list()
  def zrange(key, small, big, opt \\ []) do
    select_call("ZRANGE", [key, small, big | opt])
  end

  @spec zrevrange(binary() | atom(), score(), score(), opt()) :: list()
  def zrevrange(key, small, big, opt \\ []) do
    select_call("ZREVRANGE", [key, small, big | opt])
  end

  @doc """
  get the member's rank in sorted set, ordered from smallest to biggest

  ## Examples

      iex> Redis.zrank("rank:role_level","Mar")
      integer()

  """
  @spec zrank(binary() | atom(), binary()) :: integer()
  def zrank(key, member) do
    select_call("ZRANK", [key, member])
  end

  @spec zrevrank(binary() | atom(), binary()) :: integer()
  def zrevrank(key, member) do
    select_call("ZREVRANK", [key, member])
  end

  @doc """
  get the member's rank score in sorted set
  """
  @spec zscore(binary() | atom(), binary()) :: integer()
  def zscore(key, member) do
    select_call("ZSCORE", [key, member])
  end

  def child_spec(worker_id) do
    # worker_id = Keyword.fetch!(opts, :worker_id)

    %{
      id: "#{__MODULE__}_#{worker_id}",
      start: {__MODULE__, :start_link, [worker_id]},
      shutdown: 10_000,
      restart: :transient,
      type: :worker
    }
  end

  def start_link(worker_id) do
    # Logger.debug("start redis #{worker_id}")
    GenServer.start_link(__MODULE__, [], name: via(worker_id))
  end

  @impl true
  def init(_args) do
    Process.flag(:trap_exit, true)
    interval = Util.rand(1, 500)
    Process.send_after(self(), :connect_all, interval)
    {:ok, %Redis{}}
  end

  @impl true
  def handle_info(:connect_all, state) do
    conns =
      for {host, port} <- @redis_blocks do
        {:ok, conn} = Redix.start_link(host: host, port: port)
        conn
      end
      |> List.to_tuple()

    {:noreply, ~M{%Redis state| conns}}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.debug("#{__MODULE__} terminate,reason: #{inspect(reason)}")
    :ok
  end

  @impl true

  def handle_call({:cmd, cmd, args}, _from, state) do
    reply = do_handle(state, cmd, args)
    {:reply, reply, state}
  end

  defp worker_by_key(key) do
    worker_id = :erlang.phash2(key, @db_worker_num) + 1
    via(worker_id)
  end

  defp via(worker_id) do
    {:via, Horde.Registry, {Matrix.DBRegistry, worker_id}}
  end

  defp select_call(cmd, []) do
    worker_by_key(0)
    |> GenServer.call({:cmd, cmd, []})
  end

  defp select_call(cmd, [key | _] = args) do
    worker_by_key(key)
    |> GenServer.call({:cmd, cmd, args})
  end

  defp do_handle(~M{conns} = _state, "FLUSHALL", []) do
    Tuple.to_list(conns)
    |> Enum.each(&Redis.Cmd.clear(&1))
  end

  defp do_handle(~M{conns} = _state, cmd, []) do
    index = Util.rand(0, tuple_size(conns) - 1)
    conn = elem(conns, index)
    Redis.Cmd.handle(conn, cmd, [])
  end

  defp do_handle(~M{conns} = _state, cmd, [key | _] = args) do
    index = :erlang.phash2(key, tuple_size(conns))
    conn = elem(conns, index)
    Redis.Cmd.handle(conn, cmd, args)
  end
end

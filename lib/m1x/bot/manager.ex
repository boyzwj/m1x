defmodule Bot.Manager do
  use GenServer
  use Common

  @robot_type_room 1
  @robot_type_fakeman 2
  @robot_type_npc 3

  @robot_max_id 1_000_000
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true

  def init(_args) do
    state = %{}

    Agent.start(fn ->
      :ets.new(Bot, [
        :public,
        :named_table,
        :set,
        {:keypos, 1},
        {:write_concurrency, true},
        {:read_concurrency, true}
      ])
    end)

    Process.send_after(self(), :init_bot, 1000)
    {:ok, state}
  end

  @impl true
  def handle_info(:init_bot, state) do
    init_bot()
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("unhandle info : #{msg}")
    {:noreply, state}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  @spec get_info(any) :: any
  def get_info(id) do
    with [{_, info}] <- :ets.lookup(Bot, id) do
      info
    else
      _ ->
        nil
    end
  end

  @spec is_robot_id(any) :: boolean
  def is_robot_id(role_id) do
    role_id <= @robot_max_id
  end

  defp init_bot() do
    for robot_type <- [@robot_type_room, @robot_type_fakeman, @robot_type_npc] do
      for base_id <- Data.RobotInfoManage.ids() do
        ~M{first_name,last_name1,last_name2} = Data.RobotInfoManage.get(base_id)
        id = make_bot_id(base_id, robot_type)
        role_name = "#{last_name1}#{last_name2} #{first_name}"

        info = %Pbm.Common.RoleInfo{
          role_id: id,
          robot: 1,
          rank: 1,
          level: 30,
          robot_type: robot_type,
          role_name: role_name
        }

        :ets.insert(Bot, {id, info})
      end
    end
  end

  defp make_bot_id(base_id, robot_type), do: base_id * 10 + robot_type

  def random_bot_by_type(type, num) do
    Data.RobotInfoManage.ids()
    |> Util.shuffle()
    |> Enum.slice(0..num)
    |> Enum.map(&make_bot_id(&1, type))
  end
end

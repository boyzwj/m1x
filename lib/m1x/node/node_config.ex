defmodule NodeConfig do
  use Common

  def services() do
    with [node_type, node_id] <-
           "#{node()}"
           |> String.split("@")
           |> List.first()
           |> String.split("_") do
      block_id = String.to_integer(node_id)
      Node.Misc.set_block_id(block_id)
      Node.Misc.set_node_type(node_type)
      services(node_type, block_id)
    else
      _ ->
        block_id = 1
        node_type = "develop"
        Node.Misc.set_block_id(block_id)
        Node.Misc.set_node_type(node_type)
        services(node_type, block_id)
    end
  end

  def services("game", _block_id) do
    topologies = Application.get_env(:m1x, :topologies)

    [
      {Cluster.Supervisor, [topologies, [name: Matrix.ClusterSupervisor]]},
      {Horde.Registry, [name: Matrix.GlobalRegistry, keys: :unique, members: :auto]},
      {
        Horde.DynamicSupervisor,
        [
          name: Matrix.DistributedSupervisor,
          shutdown: 1000,
          strategy: :one_for_one,
          members: :auto
        ]
      },
      {Horde.DynamicSupervisor,
       [name: Matrix.RankSupervisor, strategy: :one_for_one, members: :auto]},
      {Horde.DynamicSupervisor,
       [name: Matrix.MailSupervisor, strategy: :one_for_one, members: :auto]},
      {Global.Sup, []},
      {Dba.Mnesia.Sup, []},
      {Rank.Sup, []},
      {Bot.Sup, []},
      {Mail.Manager, []},
      {Role.Sup, []},
      {Lobby.Sup, []},
      {Dc.Sup, []},
      {Team.Sup, []}
    ]
  end

  def services("gate", _block_id) do
    topologies = Application.get_env(:m1x, :topologies)

    [
      {Cluster.Supervisor, [topologies, [name: Matrix.ClusterSupervisor]]},
      {Horde.Registry, [name: Matrix.GlobalRegistry, keys: :unique, members: :auto]},
      {GateWay.ListenerSup, []}
    ]
  end

  def services("robot", _block_id) do
    [Robot.Sup, Robot.Manager]
  end

  def services("dsa", _block_id) do
    [{Dsa.Sup, []}]
  end

  def services("develop", _block_id) do
    [
      {Horde.Registry, [name: Matrix.GlobalRegistry, keys: :unique, members: :auto]},
      {
        Horde.DynamicSupervisor,
        [
          name: Matrix.DistributedSupervisor,
          shutdown: 1000,
          strategy: :one_for_one,
          members: :auto
        ]
      },
      {Horde.DynamicSupervisor,
       [name: Matrix.RankSupervisor, strategy: :one_for_one, members: :auto]},
      {Rank.Sup, []},
      {Horde.DynamicSupervisor,
       [name: Matrix.MailSupervisor, strategy: :one_for_one, members: :auto]},
      {Mail.Manager, []},
      {Role.Sup, []},
      {Lobby.Sup, []},
      {GateWay.ListenerSup, []},
      {Dc.Sup, []},
      {Bot.Sup, []},
      {Team.Sup, []},
      {Global.Sup, []},
      {Dba.Mnesia.Sup, []}
    ]
  end

  def services(node_type, _) do
    Logger.warning("unknow node type #{inspect(node_type)}")
    []
  end
end

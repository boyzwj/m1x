defmodule Mnesia.Service.Session do
  use Memento.Table,
    attributes: [:id, :role_id]

  # index: [:role_id]

  # type: :ordered_set,
  # autoincrement: true
end

defmodule Mnesia.Storage.RoleData do
  use Memento.Table,
    attributes: [:id, :mod, :data]

end




defmodule Dba.Mnesia.Def do
  def stores() do
    [Mnesia.Storage.RoleData]
  end

  def services do
    [Mnesia.Service.Session]
  end

  def tables() do
    # (stores() |> Enum.map(&{&1, :rocksdb_copies})) ++
    (stores() |> Enum.map(&{&1, :disc_copies})) ++
      (services() |> Enum.map(&{&1, :ram_copies}))
  end
end

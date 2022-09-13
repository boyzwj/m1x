defmodule Tool.Benchmark do
  def test() do
    Benchee.run(%{
      "mnesia1" => fn ->
        Dba.Mnesia.Api.dirty_read(Mnesia.Storage.RoleData, 1001)
      end,
      "mnesia2" => fn ->
        Dba.Mnesia.Api.read(Mnesia.Storage.RoleData, 1001)
      end
    })
  end
end

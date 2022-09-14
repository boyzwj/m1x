defmodule Tool.Benchmark do
  def test() do
    data = %{id: 1001, mod: Role.Mod.Battle, data: "fuck"}

    Benchee.run(%{
      "write" => fn ->
        Dba.Mnesia.Api.write(data)
      end,
      "dirty_write" => fn ->
        Dba.Mnesia.Api.dirty_write(data)
      end
    })
  end
end

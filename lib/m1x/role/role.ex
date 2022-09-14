defmodule Role do
  use Common
  import Role.Misc

  @doc """
  上线加载游戏所有数据
  """
  def load_data() do
    for mod <- PB.modules() do
      mod.load() |> mod.set_data()
    end

    :ok
  end

  @doc """
  下线保存角色所有数据
  """
  def save_all() do
    array =
      PB.modules()
      |> Enum.reduce([], fn mod, acc ->
        if function_exported?(mod, :dirty?, 0) && mod.dirty?() do
          data = mod.get_data() |> Map.from_struct() |> Map.delete(:__meta__) |> Jason.encode!()
          [mod, data | acc]
        else
          acc
        end
      end)

    Redis.hset_array(dbkey(), array)
  end
end

defmodule Role do
  use Common
  import Role.Misc

  @doc """
  上线加载游戏所有数据
  """
  def load_data() do
    dbkey()
    |> Redis.hgetall()
    |> do_load()
  end

  defp do_load([]), do: :ok

  defp do_load([k, v | tail]) do
    mod = String.to_atom(k)

    if Enum.member?(PB.modules(), mod) do
      data = v && Poison.decode!(v, as: mod.__struct__)
      mod.set_data(data)
    end

    do_load(tail)
  end

  @doc """
  下线保存角色所有数据
  """
  def save_all() do
    array =
      PB.modules()
      |> Enum.reduce([], fn mod, acc ->
        if function_exported?(mod, :dirty?, 0) && mod.dirty?() do
          data = mod.get_data() |> Map.from_struct() |> Jason.encode!()
          [mod, data | acc]
        else
          acc
        end
      end)

    Redis.hset_array(dbkey(), array)
  end

  @bf_role_name "bloomfilter:rolename"

  @doc """
  判断名称是否全服唯一
  """
  @spec exists_name?(binary()) :: boolean()
  def exists_name?(name) do
    Redis.bf_exists?(@bf_role_name, name) == 1
  end

  @doc """
  标记角色名称已被使用
  """
  @spec mark_name(binary()) :: boolean()
  def mark_name(name) do
    Redis.bf_add(@bf_role_name, name)
  end
end

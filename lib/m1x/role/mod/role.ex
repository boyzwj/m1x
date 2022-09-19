defmodule Role.Mod.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "role" do
    field(:role_id, :integer, default: nil)
    field(:account, :string, default: "")
    field(:role_name, :string, default: "")
    field(:level, :integer, default: 1)
    field(:gender, :integer, default: 1)
    field(:head_id, :integer, default: 1)
    field(:avatar_id, :integer, default: 1)
    field(:rank, :integer, default: 0)
    field(:create_time, :integer, default: 0)
    field(:elo, :integer, default: 1000)
    field(:status, :integer, default: 0)
  end

  def changeset(params), do: %__MODULE__{} |> changeset(params)

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :role_id,
      :account,
      :role_name,
      :level,
      :gender,
      :head_id,
      :avatar_id,
      :rank,
      :create_time,
      :elo,
      :status
    ])
    |> validate_required([
      :role_id,
      :account,
      :role_name,
      :level,
      :gender,
      :head_id,
      :avatar_id,
      :rank,
      :create_time,
      :elo,
      :status
    ])
  end

  use Role.Mod
  use Memoize

  defp on_init(~M{%M status} = state) do
    set_role_status(status)
    state
  end

  def on_before_save(~M{%M status: last_status} = state) do
    status = get_role_status()

    # Logger.debug(mod: __MODULE__, fun: :on_before_save, status: status, last_status: last_status)

    if last_status != status do
      set_dirty(true)
      ~M{state|status}
    else
      state
    end
  end

  def h(state, ~M{%Pbm.Role.Info2S }) do
    with ~M{%M } = data <- state do
      role_info = to_common(data)
      ~M{%Pbm.Role.Info2C role_info} |> sd()
    else
      _ ->
        :ignore
    end
  end

  def h(_state, ~M{%Pbm.Role.OtherInfo2S requests}) do
    infos =
      for ~M{role_id,timestamp} <- requests do
        {cachetime, role_info} = role_info(role_id)

        if timestamp < cachetime do
          %Pbm.Role.InfoReply{role_id: role_id, timestamp: cachetime, role_info: role_info}
        else
          %Pbm.Role.InfoReply{role_id: role_id, timestamp: timestamp}
        end
      end

    ~M{%Pbm.Role.OtherInfo2C  infos} |> sd()
    :ok
  end

  defp on_after_save(false), do: false

  defp on_after_save(true) do
    Role.Manager.clear_cache(__MODULE__, :role_info, [role_id()])
    true
  end

  defmemo role_info(role_id), expires_in: 86_400_000 do
    cachetime = Util.unixtime()

    role_info =
      if Bot.Manager.is_robot_id(role_id) do
        Bot.Manager.get_info(role_id)
      else
        data = load(role_id)
        data && to_common(data)
      end

    {cachetime, role_info}
  end

  def common_data() do
    get_data() |> to_common()
  end

  defp to_common(data) do
    data = Map.from_struct(data)
    data = %Pbm.Common.RoleInfo{}.__struct__ |> struct(data)
    ~M{data | role_id()}
  end
end

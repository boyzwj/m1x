defmodule Role.Mod.Friend do
  defstruct role_id: nil, friend_ids: []
  use Role.Mod

  def h(~M{%M } = state, ~M{%Pbm.Friend.Info2S }) do
    # TODO friend_ids
    friend_ids = get_friend_ids()

    friends =
      for role_id <- friend_ids do
        {_, ~M{%Pbm.Common.RoleInfo role_name,gender,head_id,avatar_id,level,rank}} =
          Role.Mod.Role.role_info(role_id)

        ~M{%Pbm.Friend.FriendInfo role_id,role_name,gender,head_id,avatar_id,level,rank}
      end

    ~M{%Pbm.Friend.Info2C friends} |> sd()
    {:ok, state}
  end

  def get_friend_ids() do
    for pid <- :pg.get_members(Role.Svr) do
      Role.Svr.get_data(pid, Role.Mod.Role)
      |> Map.get(:role_id)
    end
  end
end

defmodule M1xWeb.Matchingpool do
  use M1xWeb, :live_view
  use Common
  alias Phoenix.LiveView.Socket

  defmodule AddRole do
    use Ecto.Schema
    import Ecto.Changeset

    schema "add_role" do
      field :mode, :integer
      field :team_id, :integer
      field :role_ids, {:array, :integer}
      field :avg_elo, :integer
      field :warm, :boolean
    end

    def changeset(struct, %{} = params) when map_size(params) == 0 do
      changeset(struct, Map.put(params, "role_ids", ""))
    end

    def changeset(struct, ~m{role_ids} = params) do
      role_ids = role_ids |> String.split("\n")
      params = ~m{params|role_ids}

      struct
      |> cast(params, [:mode, :team_id, :role_ids, :avg_elo, :warm])
      |> validate_required([:mode, :team_id, :role_ids, :avg_elo, :warm])
      |> validate_number(:mode, greater_than: 0)
      |> validate_number(:team_id, greater_than: 0)
      |> validate_number(:avg_elo, greater_than: 0)
      |> validate_elo()
    end

    def validate_elo(changeset) do
      with ~M{avg_elo} <- changeset.changes,
           true <-
             Team.Matcher.Pool.get_base_id_by_elo(avg_elo) != nil ||
               {:error, "avg_elo not in range"} do
        changeset
      else
        {:error, msg} ->
          add_error(changeset, :avg_elo, msg)

        _ ->
          changeset
      end
    end
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(2000, self(), :tick)
    end

    game_modes = Data.GameModeManage.ids()

    socket
    |> assign(:pool_infos, [])
    |> assign(:game_modes, game_modes)
    |> assign(:active_mode, game_modes |> hd)
    |> assign(:role_add_modal, false)
    |> assign(:changeset, AddRole.changeset(%AddRole{}, %{}))
    |> then(&{:ok, &1})
  end

  def handle_params(%{"game_mode" => game_mode}, _uri, socket) do
    socket
    |> assign(:active_mode, String.to_integer(game_mode))
    |> assign_pool_infos()
    |> assign_group_infos()
    |> then(&{:noreply, &1})
  end

  def handle_params(%{}, _uri, socket) do
    socket
    |> assign_pool_infos()
    |> assign_group_infos
    |> then(&{:noreply, &1})
  end

  def handle_event("close_modal", _p, %Socket{assigns: %{active_mode: active_mode}} = socket) do
    {:noreply, socket |> push_redirect(to: "/matchingpool?game_mode=#{active_mode}")}
  end

  def handle_event(
        "show_role_modal",
        _params,
        %Socket{assigns: %{role_add_modal: role_add_modal}} = socket
      ) do
    socket
    |> assign(:role_add_modal, !role_add_modal)
    |> then(&{:noreply, &1})
  end

  def handle_event("add_role", %{"add_role" => params}, socket) do
    changeset =
      %AddRole{}
      |> AddRole.changeset(params)
      |> Map.put(:action, :insert)

    with %Ecto.Changeset{errors: [], changes: changes} <- changeset,
         ~M{avg_elo,role_ids,team_id,warm,mode} <- changes do
      Team.Matcher.Svr.join(mode, [team_id, role_ids, avg_elo, warm])

      socket
      |> put_flash(:info, "添加成功")
      |> assign(:role_add_modal, false)
      |> then(&{:noreply, &1})
    else
      %Ecto.Changeset{errors: errors} ->
        socket
        |> put_flash(:error, inspect(errors))
        |> then(&{:noreply, &1})
    end
  end

  def handle_event("validate", %{"add_role" => params}, socket) do
    ~m{role_ids} = params

    changeset =
      %AddRole{}
      |> AddRole.changeset(params)
      |> Map.put(:action, :insert)

    ~M{errors,changes} = changeset

    changeset =
      if errors[:role_ids] == nil do
        changes = ~M{changes|role_ids}
        ~M{changeset|changes}
      else
        changeset
      end

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    # Logger.debug("fuckoff")
    socket
    |> assign_pool_infos()
    |> assign_group_infos()
    |> then(&{:noreply, &1})
  end

  def assign_pool_infos(%Socket{assigns: %{active_mode: active_mode}} = socket) do
    pool_infos =
      Team.Matcher.Svr.get_pool_infos(active_mode, [])
      |> Enum.map(fn %Team.Matcher.Pool{team_list: team_list} = pool ->
        team_list =
          for {_, _, team_id} <- Discord.SortedSet.to_list(team_list) do
            team_id
          end
          |> Jason.encode!()

        ~M{pool|team_list}
      end)

    socket |> assign(:pool_infos, pool_infos)
  end

  def assign_group_infos(%Socket{assigns: %{active_mode: active_mode}} = socket) do
    group_infos =
      Team.Matcher.Svr.get_group_infos(active_mode, [])
      |> Enum.map(fn %Team.Matcher.Group{side1: side1, side2: side2, all_role_ids: all_role_ids} =
                       group ->
        side1 =
          Enum.map(side1, & &1.team_id)
          |> Jason.encode!()

        side2 =
          Enum.map(side2, & &1.team_id)
          |> Jason.encode!()

        all_role_ids = all_role_ids |> Jason.encode!()
        ~M{group|side1,side2,all_role_ids}
      end)

    socket |> assign(:group_infos, group_infos)
  end
end

## <div class="field">
## <%= label f, :role_ids, "Size (MB)" %>
## <%= textarea f, :role_ids %>
## <%= error_tag f, :role_ids %>
## </div>
# %{"avg_elo" => "0","mode" => "1001","role_ids" => "","team_id" => "1","warm" => "true"}

defmodule Mnesia.Service.Session do
  use Memento.Table,
    attributes: [:id, :role_id]

  # index: [:role_id]

  # type: :ordered_set,
  # autoincrement: true
end

defmodule Mnesia.Storage.Account do
  use Memento.Table,
    attributes: [:token, :role_id]
end

defmodule Mnesia.Storage.Global do
  use Memento.Table,
    attributes: [:key, :value]

  # def init_datas() do
  #   [%__MODULE__{key: :battle_id, value: 100_000_000}, %__MODULE__{key: :role_id, value: 0}]
  # end
end

defmodule Mnesia.Storage.Rank do
  use Memento.Table,
    attributes: [:key, :set, :indexs]
end

defmodule Mnesia.Storage.GlobalMail do
  use Memento.Table,
    attributes: [:id, :mail],
    type: :ordered_set
end

defmodule Mnesia.Storage.PersonalMail do
  use Memento.Table,
    attributes: [:role_id, :mails],
    type: :ordered_set
end

defmodule Mnesia.Storage.Mail do
  use Memento.Table,
    attributes: [:key, :role_id, :mail],
    index: [:role_id]
end

defmodule Dba.Mnesia.Def do
  def stores() do
    [
      Mnesia.Storage.Account,
      Mnesia.Storage.Global,
      Mnesia.Storage.Rank,
      Mnesia.Storage.GlobalMail,
      Mnesia.Storage.PersonalMail,
      Mnesia.Storage.Mail
    ]
  end

  @spec services :: [Mnesia.Service.Session, ...]
  def services do
    [Mnesia.Service.Session]
  end

  def role_tables() do
    for mod <- PB.modules() do
      {mod, [:id, :data, :last_changed], :disc_copies}
    end
  end

  def tables() do
    (stores() |> Enum.map(&{&1, :disc_copies})) ++
      (services() |> Enum.map(&{&1, :ram_copies}))
  end
end

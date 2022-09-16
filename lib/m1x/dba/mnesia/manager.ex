defmodule Dba.Mnesia.Manager do
  require Logger
  alias Memento.Table

  def create_database(_store_list) do
    Logger.info("Creating database...")
    Memento.stop()
    Memento.Schema.create([node()])
    Memento.start()
    :mnesia_monitor.set_env(:dump_log_write_threshold, 50000)
    :mnesia_monitor.set_env(:dc_dump_limit, 40)
    :mnesia_eleveldb.register()
    create_tables()
  end

  defp create_tables() do
    Logger.info("Creating tables...", ansi_color: :yellow)

    for {tab, attributes, type} <- Dba.Mnesia.Def.role_tables() do
      with {:atomic, :ok} <- :mnesia.create_table(tab, [{type, [node()]}, attributes: attributes]) do
        Logger.info("Table [#{inspect(tab)}] create ok ..", ansi_color: :yellow)

        if function_exported?(tab, :init_datas, 0) do
          Logger.info("insert init datas to #{tab}")
          tab.init_datas() |> Enum.each(&Dba.Mnesia.Api.dirty_write(&1))
        end
      else
        {:aborted, {:already_exists, _}} ->
          Logger.info("Load exist table [#{inspect(tab)}] ", ansi_color: :yellow)

        error ->
          Logger.error("Table init error #{inspect(error)}")
      end
    end

    for {tab, type} <- Dba.Mnesia.Def.tables() do
      with :ok <- Table.create(tab, [{type, [node()]}]) do
        Logger.info("Table [#{inspect(tab)}] create ok ..", ansi_color: :yellow)

        if function_exported?(tab, :init_datas, 0) do
          Logger.info("insert init datas to #{tab}")
          tab.init_datas() |> Enum.each(&Dba.Mnesia.Api.dirty_write(&1))
        end
      else
        {:error, {:already_exists, _}} ->
          Logger.info("Load exist table [#{inspect(tab)}] ", ansi_color: :yellow)
          check_update_table(tab)

        {:error, reason} ->
          Logger.error("Table init error #{inspect(reason)}")
      end

      tab
    end
    |> Table.wait()
  end

  def copy_database(store_list) do
    Memento.start()
    :mnesia_monitor.set_env(:dump_log_write_threshold, 50000)
    :mnesia_monitor.set_env(:dc_dump_limit, 40)
    :mnesia_eleveldb.register()
    {:ok, _} = Memento.add_nodes(store_list)
    Table.set_storage_type(:schema, node(), :disc_copies)
    copy_tables()
  end

  defp copy_tables() do
    Logger.info("Copying tables...", ansi_color: :yellow)

    for {tab, _attributes, type} <- Dba.Mnesia.Def.role_tables() do
      :mnesia.add_table_copy(tab, node(), type)
      Logger.info("copy table [#{inspect(tab)}] ", ansi_color: :yellow)
    end

    for {tab, type} <- Dba.Mnesia.Def.tables() do
      with :ok <- Table.create_copy(tab, node(), type) do
        Logger.info("copy table [#{inspect(tab)}] finish", ansi_color: :yellow)
      else
        {:error, {:already_exists, _, _}} ->
          Logger.info("check update exist table [#{inspect(tab)}] ", ansi_color: :yellow)
          check_update_table(tab)

        {:error, {:no_exists, {^tab, _}}} ->
          :ok = Table.create(tab, [{type, [node() | Node.list()]}])
          Logger.info("create new table [#{inspect(tab)}] ", ansi_color: :yellow)

        {:error, reason} ->
          Logger.error("Table init error #{inspect(reason)}")
      end

      tab
    end
    |> Table.wait()
  end

  defp check_update_table(tab) do
    old = Table.info(tab, :attributes)
    new = tab.__info__.attributes

    if old != new do
      Table.wait([tab], 5000)

      Logger.info("Table [#{inspect(tab)}] column changed, updating ...",
        ansi_color: :yellow
      )

      :mnesia.transform_table(
        tab,
        fn data ->
          [tab | values] = Tuple.to_list(data)
          values = old |> Enum.zip(values)

          struct(tab, values)
          |> Memento.Query.Data.dump()
        end,
        new
      )
    end
  end
end

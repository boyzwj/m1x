defmodule Dba.Mnesia.Api do
  def dirty_read(tab, key) do
    case :mnesia.dirty_read(tab, key) do
      [t] -> Memento.Query.Data.load(t)
      [] -> nil
    end
  end

  def read(tab, key) do
    Memento.transaction!(fn -> Memento.Query.read(tab, key) end)
  end
end

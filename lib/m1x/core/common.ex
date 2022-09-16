defmodule Common do
  defmacro __using__(_) do
    quote do
      import ShorterMaps
      require Logger

      # role status
      @role_status_idle 0
      @role_status_matching 1
      @role_status_matched 2
      @role_status_battle 3
    end
  end
end

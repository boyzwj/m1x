defmodule Role.Mod.Chat do
  defstruct role_id: nil,channels: %{}, last_chat_time: nil
  use Role.Mod

  def h(~M{%M } = state, ~M{%Pbm.Chat.Chat2S channel,content}) do
    %Pbm.Chat.Chat2C{
      role_id: role_id(),
      content: content,
      channel: channel,
      time: Util.unixtime()
    }
    |> broad_cast_all()

    last_chat_time = Util.unixtime()
    {:ok, ~M{state| last_chat_time}}
  end
end

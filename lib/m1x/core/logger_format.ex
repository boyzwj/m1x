defmodule LoggerFormat do
  def format(level, message, {date, {h, m, s, ms}}, []) do
    date = date |> Tuple.to_list() |> Enum.join("-")
    time = "#{h}:#{m}:#{s}.#{ms}"
    "### [#{date} #{time}] [#{level}] \n  * #{message}\n\n"
  end

  def format(level, message, {date, {h, m, s, ms}}, metadata) do
    date = date |> Tuple.to_list() |> Enum.join("-")
    time = "#{h}:#{m}:#{s}.#{ms}"
    {m, f, arity} = metadata[:mfa]
    mfa = "#{Module.concat(m, f)}/#{arity}"
    metadata_content = "#{metadata[:file]}:#{metadata[:line]}: #{mfa}"
    "### [#{date} #{time}] #{metadata_content}[#{level}] \n  * #{message}\n\n"
  rescue
    _ -> "could not format: #{inspect(%{level: level, message: message, metadata: metadata})}"
  end
end

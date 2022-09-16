defmodule Node.Misc do
  def set_block_id(block_id) do
    FastGlobal.put(:block_id, block_id)
  end

  def block_id() do
    FastGlobal.get(:block_id)
  end

  def set_node_type(node_type) do
    FastGlobal.put(:node_type, node_type)
  end

  def node_type() do
    FastGlobal.get(:node_type)
  end
end

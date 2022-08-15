defmodule Data.ItemType do
	## SOURCE:"xls\D道具类型对应表.xlsx" SHEET:"Sheet1"

	def ids() do
		[]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data


	def get(_), do: nil
end
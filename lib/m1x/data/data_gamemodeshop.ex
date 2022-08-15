defmodule Data.GameModeShop do
	## SOURCE:"xls\M模式商店表.xlsx" SHEET:"Sheet1"

	def ids() do
		[]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data


	def get(_), do: nil
end
defmodule Data.Treasure do
	## SOURCE:"xls\B宝箱表.xlsx" SHEET:"宝箱表"

	def ids() do
		[]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data


	def get(_), do: nil
end
defmodule Data.SkinFeature do
	## SOURCE:"xls\P皮肤特性表.xlsx" SHEET:"Sheet1"

	def ids() do
		[]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data


	def get(_), do: nil
end
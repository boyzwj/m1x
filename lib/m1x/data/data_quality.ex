defmodule Data.Quality do
	## SOURCE:"xls\P品质对应表.xlsx" SHEET:"Quality"

	def ids() do
		[]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data


	def get(_), do: nil
end
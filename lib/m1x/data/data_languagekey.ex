defmodule Data.LanguageKey do
	## SOURCE:"xls\D多语言Key表.xlsx" SHEET:"sheet1"

	def ids() do
		[]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data


	def get(_), do: nil
end
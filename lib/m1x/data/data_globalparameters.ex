defmodule Data.GlobalParameters do
	## SOURCE:"xls\Q全局参数表.xlsx" SHEET:"Sheet1"

	def ids() do
		[1, 2, 3, 4, 5]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(1) do
		%{
			id: 1,
			value: 900
		}
	end

	def get(2) do
		%{
			id: 2,
			value: 1
		}
	end

	def get(3) do
		%{
			id: 3,
			value: 5
		}
	end

	def get(4) do
		%{
			id: 4,
			value: 15
		}
	end

	def get(5) do
		%{
			id: 5,
			value: 30
		}
	end

	def get(_), do: nil
end
defmodule Data.Character do
	## SOURCE:"xls\J角色表.xlsx" SHEET:"Sheet1"

	def ids() do
		[100010001, 100020001]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(100010001) do
		%{
			id: 100010001,
			base_class: 10001
		}
	end

	def get(100020001) do
		%{
			id: 100020001,
			base_class: 10002
		}
	end

	def get(_), do: nil
end
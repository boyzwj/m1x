defmodule Data.GameModeConfig do
	## SOURCE:"xls\M模式规则配置表.xlsx" SHEET:"Sheet1"

	def ids() do
		[3001, 1001, 1002]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(3001) do
		%{
			id: 3001
		}
	end

	def get(1001) do
		%{
			id: 1001
		}
	end

	def get(1002) do
		%{
			id: 1002
		}
	end

	def get(_), do: nil
end
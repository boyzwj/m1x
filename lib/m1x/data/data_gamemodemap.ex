defmodule Data.GameModeMap do
	## SOURCE:"xls\M模式地图表.xlsx" SHEET:"Sheet1"

	def ids() do
		[30011001, 10011002, 10021002]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(30011001) do
		%{
			id: 30011001,
			mode_id: 3001
		}
	end

	def get(10011002) do
		%{
			id: 10011002,
			mode_id: 1001
		}
	end

	def get(10021002) do
		%{
			id: 10021002,
			mode_id: 1002
		}
	end

	def get(_), do: nil
end
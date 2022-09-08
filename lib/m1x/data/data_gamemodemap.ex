defmodule Data.GameModeMap do
	## SOURCE:"xls\M模式地图表.xlsx" SHEET:"Sheet1"

	def ids() do
		[10021070, 10051071]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(10021070) do
		%{
			id: 10021070,
			mode_id: 1002
		}
	end

	def get(10051071) do
		%{
			id: 10051071,
			mode_id: 1005
		}
	end

	def get(_), do: nil
end
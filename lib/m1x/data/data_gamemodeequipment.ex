defmodule Data.GameModeEquipment do
	## SOURCE:"xls\M模式装备表.xlsx" SHEET:"Sheet1"

	def ids() do
		[1002, 1005]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(1002) do
		%{
			id: 1002
		}
	end

	def get(1005) do
		%{
			id: 1005
		}
	end

	def get(_), do: nil
end
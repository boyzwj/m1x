defmodule Data.GameModeEquipment do
	## SOURCE:"xls\M模式装备表.xlsx" SHEET:"Sheet1"

	def ids() do
		[1001, 1002, 1003, 1004]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

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

	def get(1003) do
		%{
			id: 1003
		}
	end

	def get(1004) do
		%{
			id: 1004
		}
	end

	def get(_), do: nil
end
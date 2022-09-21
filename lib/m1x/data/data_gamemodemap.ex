defmodule Data.GameModeMap do
	## SOURCE:"xls\M模式地图表.xlsx" SHEET:"Sheet1"

	def ids() do
		[10021070, 10021071, 10021072, 10021073, 10021074, 10051071, 10051072, 10051073, 10051074, 10051075]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(10021070) do
		%{
			id: 10021070,
			mode_id: 1002,
			weight: 100
		}
	end

	def get(10021071) do
		%{
			id: 10021071,
			mode_id: 1002,
			weight: 0
		}
	end

	def get(10021072) do
		%{
			id: 10021072,
			mode_id: 1002,
			weight: 0
		}
	end

	def get(10021073) do
		%{
			id: 10021073,
			mode_id: 1002,
			weight: 0
		}
	end

	def get(10021074) do
		%{
			id: 10021074,
			mode_id: 1002,
			weight: 0
		}
	end

	def get(10051071) do
		%{
			id: 10051071,
			mode_id: 1005,
			weight: 100
		}
	end

	def get(10051072) do
		%{
			id: 10051072,
			mode_id: 1005,
			weight: 0
		}
	end

	def get(10051073) do
		%{
			id: 10051073,
			mode_id: 1005,
			weight: 0
		}
	end

	def get(10051074) do
		%{
			id: 10051074,
			mode_id: 1005,
			weight: 0
		}
	end

	def get(10051075) do
		%{
			id: 10051075,
			mode_id: 1005,
			weight: 0
		}
	end

	def get(_), do: nil
end
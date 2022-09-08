defmodule Data.MintQuality do
	## SOURCE:"xls\J角色铸造概率表.xlsx" SHEET:"Sheet1"

	def ids() do
		[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(1) do
		%{
			id: 1
		}
	end

	def get(2) do
		%{
			id: 2
		}
	end

	def get(3) do
		%{
			id: 3
		}
	end

	def get(4) do
		%{
			id: 4
		}
	end

	def get(5) do
		%{
			id: 5
		}
	end

	def get(6) do
		%{
			id: 6
		}
	end

	def get(7) do
		%{
			id: 7
		}
	end

	def get(8) do
		%{
			id: 8
		}
	end

	def get(9) do
		%{
			id: 9
		}
	end

	def get(10) do
		%{
			id: 10
		}
	end

	def get(_), do: nil
end
defmodule Data.CharacterAttribute do
	## SOURCE:"xls\J角色属性模板.xlsx" SHEET:"Sheet1"

	def ids() do
		[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30]
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

	def get(11) do
		%{
			id: 11
		}
	end

	def get(12) do
		%{
			id: 12
		}
	end

	def get(13) do
		%{
			id: 13
		}
	end

	def get(14) do
		%{
			id: 14
		}
	end

	def get(15) do
		%{
			id: 15
		}
	end

	def get(16) do
		%{
			id: 16
		}
	end

	def get(17) do
		%{
			id: 17
		}
	end

	def get(18) do
		%{
			id: 18
		}
	end

	def get(19) do
		%{
			id: 19
		}
	end

	def get(20) do
		%{
			id: 20
		}
	end

	def get(21) do
		%{
			id: 21
		}
	end

	def get(22) do
		%{
			id: 22
		}
	end

	def get(23) do
		%{
			id: 23
		}
	end

	def get(24) do
		%{
			id: 24
		}
	end

	def get(25) do
		%{
			id: 25
		}
	end

	def get(26) do
		%{
			id: 26
		}
	end

	def get(27) do
		%{
			id: 27
		}
	end

	def get(28) do
		%{
			id: 28
		}
	end

	def get(29) do
		%{
			id: 29
		}
	end

	def get(30) do
		%{
			id: 30
		}
	end

	def get(_), do: nil
end
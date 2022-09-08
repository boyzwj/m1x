defmodule Data.LevelUp do
	## SOURCE:"xls\J角色等级数据表.xlsx" SHEET:"Sheet1"

	def ids() do
		[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60]
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

	def get(31) do
		%{
			id: 31
		}
	end

	def get(32) do
		%{
			id: 32
		}
	end

	def get(33) do
		%{
			id: 33
		}
	end

	def get(34) do
		%{
			id: 34
		}
	end

	def get(35) do
		%{
			id: 35
		}
	end

	def get(36) do
		%{
			id: 36
		}
	end

	def get(37) do
		%{
			id: 37
		}
	end

	def get(38) do
		%{
			id: 38
		}
	end

	def get(39) do
		%{
			id: 39
		}
	end

	def get(40) do
		%{
			id: 40
		}
	end

	def get(41) do
		%{
			id: 41
		}
	end

	def get(42) do
		%{
			id: 42
		}
	end

	def get(43) do
		%{
			id: 43
		}
	end

	def get(44) do
		%{
			id: 44
		}
	end

	def get(45) do
		%{
			id: 45
		}
	end

	def get(46) do
		%{
			id: 46
		}
	end

	def get(47) do
		%{
			id: 47
		}
	end

	def get(48) do
		%{
			id: 48
		}
	end

	def get(49) do
		%{
			id: 49
		}
	end

	def get(50) do
		%{
			id: 50
		}
	end

	def get(51) do
		%{
			id: 51
		}
	end

	def get(52) do
		%{
			id: 52
		}
	end

	def get(53) do
		%{
			id: 53
		}
	end

	def get(54) do
		%{
			id: 54
		}
	end

	def get(55) do
		%{
			id: 55
		}
	end

	def get(56) do
		%{
			id: 56
		}
	end

	def get(57) do
		%{
			id: 57
		}
	end

	def get(58) do
		%{
			id: 58
		}
	end

	def get(59) do
		%{
			id: 59
		}
	end

	def get(60) do
		%{
			id: 60
		}
	end

	def get(_), do: nil
end
defmodule Data.MatchPool do
	## SOURCE:"xls\P排位赛ELO匹配池.xlsx" SHEET:"MatchPool"

	def ids() do
		[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(1) do
		%{
			id: 1,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 1009
		}
	end

	def get(2) do
		%{
			id: 2,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 1001
		}
	end

	def get(3) do
		%{
			id: 3,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 1001
		}
	end

	def get(4) do
		%{
			id: 4,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 1004
		}
	end

	def get(5) do
		%{
			id: 5,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 1004
		}
	end

	def get(6) do
		%{
			id: 6,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 1005
		}
	end

	def get(7) do
		%{
			id: 7,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 1005
		}
	end

	def get(8) do
		%{
			id: 8,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 1006
		}
	end

	def get(9) do
		%{
			id: 9,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 0
		}
	end

	def get(10) do
		%{
			id: 10,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 0
		}
	end

	def get(11) do
		%{
			id: 11,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 0
		}
	end

	def get(12) do
		%{
			id: 12,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 0
		}
	end

	def get(13) do
		%{
			id: 13,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 0
		}
	end

	def get(14) do
		%{
			id: 14,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 0
		}
	end

	def get(15) do
		%{
			id: 15,
			timeup: 3,
			across: 1,
			across_frequency: 2,
			blend_time: 8,
			multiplayer_bot: 10,
			single_bot: 15,
			ai_id: 0
		}
	end

	def get(_), do: nil
end
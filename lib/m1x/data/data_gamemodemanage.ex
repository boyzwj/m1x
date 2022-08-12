defmodule Data.GameModeManage do
	## SOURCE:"xls\M模式表.xlsx" SHEET:"Sheet1"

	def ids() do
		[1001, 1002, 1003, 1004, 3001]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(1001) do
		%{
			id: 1001,
			unlock_level: 1,
			max_players: 10,
			max_camp_players: 5,
			map_list: [],
			map_weights: [1,1,1,1],
			room_win_score: [4,7,9],
			room_round_time: [120,180],
			room_begin_players: 1
		}
	end

	def get(1002) do
		%{
			id: 1002,
			unlock_level: 1,
			max_players: 10,
			max_camp_players: 5,
			map_list: [],
			map_weights: [1,2,3,4],
			room_win_score: [50100],
			room_round_time: [600,1200],
			room_begin_players: 1
		}
	end

	def get(1003) do
		%{
			id: 1003,
			unlock_level: 5,
			max_players: 10,
			max_camp_players: 5,
			map_list: [],
			map_weights: [1,2,3,4],
			room_win_score: [0],
			room_round_time: [600,1200],
			room_begin_players: 1
		}
	end

	def get(1004) do
		%{
			id: 1004,
			unlock_level: 5,
			max_players: 10,
			max_camp_players: 5,
			map_list: [],
			map_weights: [1,2,3,4],
			room_win_score: [50100],
			room_round_time: [600,1200],
			room_begin_players: 1
		}
	end

	def get(3001) do
		%{
			id: 3001,
			unlock_level: 1,
			max_players: 10,
			max_camp_players: 5,
			map_list: [],
			map_weights: [1,1,1,1],
			room_win_score: [4,7,9],
			room_round_time: [120,180],
			room_begin_players: 1
		}
	end

	def get(_), do: nil
end
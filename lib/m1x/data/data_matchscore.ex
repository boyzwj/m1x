defmodule Data.MatchScore do
	## SOURCE:"xls\P排位赛ELO分数.xlsx" SHEET:"ELO"

	def ids() do
		[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(1) do
		%{
			id: 1,
			elo_pot: 1,
			elo_min: 1000,
			elo_max: 1099,
			coefficient_f: 36,
			coefficient_s: 1.25,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [3,7500],
			cumulative_failure: [5,2,5000]
		}
	end

	def get(2) do
		%{
			id: 2,
			elo_pot: 1,
			elo_min: 1100,
			elo_max: 1199,
			coefficient_f: 36,
			coefficient_s: 1.25,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [3,7500],
			cumulative_failure: [5,2,5000]
		}
	end

	def get(3) do
		%{
			id: 3,
			elo_pot: 1,
			elo_min: 1200,
			elo_max: 1299,
			coefficient_f: 36,
			coefficient_s: 1.25,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [3,7500],
			cumulative_failure: [5,2,5000]
		}
	end

	def get(4) do
		%{
			id: 4,
			elo_pot: 2,
			elo_min: 1300,
			elo_max: 1399,
			coefficient_f: 36,
			coefficient_s: 0.93,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [4,7500],
			cumulative_failure: [5,3,5000]
		}
	end

	def get(5) do
		%{
			id: 5,
			elo_pot: 2,
			elo_min: 1400,
			elo_max: 1499,
			coefficient_f: 36,
			coefficient_s: 0.93,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [4,7500],
			cumulative_failure: [5,3,5000]
		}
	end

	def get(6) do
		%{
			id: 6,
			elo_pot: 2,
			elo_min: 1500,
			elo_max: 1599,
			coefficient_f: 36,
			coefficient_s: 0.93,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [4,7500],
			cumulative_failure: [5,3,5000]
		}
	end

	def get(7) do
		%{
			id: 7,
			elo_pot: 3,
			elo_min: 1600,
			elo_max: 1674,
			coefficient_f: 36,
			coefficient_s: 0.69,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [4,7500],
			cumulative_failure: [5,3,5000]
		}
	end

	def get(8) do
		%{
			id: 8,
			elo_pot: 3,
			elo_min: 1675,
			elo_max: 1749,
			coefficient_f: 36,
			coefficient_s: 0.69,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [4,7500],
			cumulative_failure: [5,3,5000]
		}
	end

	def get(9) do
		%{
			id: 9,
			elo_pot: 4,
			elo_min: 1750,
			elo_max: 1824,
			coefficient_f: 36,
			coefficient_s: 0.69,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [4,7500],
			cumulative_failure: [5,3,5000]
		}
	end

	def get(10) do
		%{
			id: 10,
			elo_pot: 4,
			elo_min: 1825,
			elo_max: 1899,
			coefficient_f: 36,
			coefficient_s: 0.69,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [4,7500],
			cumulative_failure: [5,3,5000]
		}
	end

	def get(11) do
		%{
			id: 11,
			elo_pot: 5,
			elo_min: 1900,
			elo_max: 1959,
			coefficient_f: 36,
			coefficient_s: 0.45,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [5,5000],
			cumulative_failure: [10,6,2500]
		}
	end

	def get(12) do
		%{
			id: 12,
			elo_pot: 5,
			elo_min: 1960,
			elo_max: 2019,
			coefficient_f: 36,
			coefficient_s: 0.45,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [5,5000],
			cumulative_failure: [10,6,2500]
		}
	end

	def get(13) do
		%{
			id: 13,
			elo_pot: 5,
			elo_min: 2020,
			elo_max: 2079,
			coefficient_f: 36,
			coefficient_s: 0.45,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [5,5000],
			cumulative_failure: [10,6,2500]
		}
	end

	def get(14) do
		%{
			id: 14,
			elo_pot: 6,
			elo_min: 2080,
			elo_max: 2139,
			coefficient_f: 36,
			coefficient_s: 0.45,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [5,5000],
			cumulative_failure: [10,6,2500]
		}
	end

	def get(15) do
		%{
			id: 15,
			elo_pot: 6,
			elo_min: 2140,
			elo_max: 2199,
			coefficient_f: 36,
			coefficient_s: 0.45,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [5,5000],
			cumulative_failure: [10,6,2500]
		}
	end

	def get(16) do
		%{
			id: 16,
			elo_pot: 6,
			elo_min: 2200,
			elo_max: 2249,
			coefficient_f: 36,
			coefficient_s: 0.375,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [5,5000],
			cumulative_failure: [10,7,2500]
		}
	end

	def get(17) do
		%{
			id: 17,
			elo_pot: 7,
			elo_min: 2250,
			elo_max: 2299,
			coefficient_f: 36,
			coefficient_s: 0.375,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [5,5000],
			cumulative_failure: [10,7,2500]
		}
	end

	def get(18) do
		%{
			id: 18,
			elo_pot: 7,
			elo_min: 2300,
			elo_max: 2349,
			coefficient_f: 36,
			coefficient_s: 0.375,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [5,5000],
			cumulative_failure: [10,7,2500]
		}
	end

	def get(19) do
		%{
			id: 19,
			elo_pot: 7,
			elo_min: 2350,
			elo_max: 2399,
			coefficient_f: 36,
			coefficient_s: 0.375,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [5,5000],
			cumulative_failure: [10,7,2500]
		}
	end

	def get(20) do
		%{
			id: 20,
			elo_pot: 8,
			elo_min: 2400,
			elo_max: 2449,
			coefficient_f: 36,
			coefficient_s: 0.375,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [5,5000],
			cumulative_failure: [10,7,2500]
		}
	end

	def get(21) do
		%{
			id: 21,
			elo_pot: 8,
			elo_min: 2450,
			elo_max: 2494,
			coefficient_f: 36,
			coefficient_s: 0.34,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(22) do
		%{
			id: 22,
			elo_pot: 8,
			elo_min: 2495,
			elo_max: 2539,
			coefficient_f: 36,
			coefficient_s: 0.34,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(23) do
		%{
			id: 23,
			elo_pot: 9,
			elo_min: 2540,
			elo_max: 2584,
			coefficient_f: 36,
			coefficient_s: 0.34,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(24) do
		%{
			id: 24,
			elo_pot: 9,
			elo_min: 2585,
			elo_max: 2629,
			coefficient_f: 36,
			coefficient_s: 0.34,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(25) do
		%{
			id: 25,
			elo_pot: 10,
			elo_min: 2630,
			elo_max: 2674,
			coefficient_f: 36,
			coefficient_s: 0.34,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(26) do
		%{
			id: 26,
			elo_pot: 10,
			elo_min: 2675,
			elo_max: 2714,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(27) do
		%{
			id: 27,
			elo_pot: 10,
			elo_min: 2715,
			elo_max: 2754,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(28) do
		%{
			id: 28,
			elo_pot: 11,
			elo_min: 2755,
			elo_max: 2794,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(29) do
		%{
			id: 29,
			elo_pot: 11,
			elo_min: 2795,
			elo_max: 2834,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(30) do
		%{
			id: 30,
			elo_pot: 11,
			elo_min: 2835,
			elo_max: 2874,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(31) do
		%{
			id: 31,
			elo_pot: 12,
			elo_min: 2875,
			elo_max: 2914,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(32) do
		%{
			id: 32,
			elo_pot: 12,
			elo_min: 2915,
			elo_max: 2954,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(33) do
		%{
			id: 33,
			elo_pot: 13,
			elo_min: 2955,
			elo_max: 2994,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(34) do
		%{
			id: 34,
			elo_pot: 13,
			elo_min: 2995,
			elo_max: 3034,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(35) do
		%{
			id: 35,
			elo_pot: 13,
			elo_min: 3035,
			elo_max: 3074,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(36) do
		%{
			id: 36,
			elo_pot: 14,
			elo_min: 3075,
			elo_max: 3114,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(37) do
		%{
			id: 37,
			elo_pot: 14,
			elo_min: 3115,
			elo_max: 3154,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(38) do
		%{
			id: 38,
			elo_pot: 14,
			elo_min: 3155,
			elo_max: 3194,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(39) do
		%{
			id: 39,
			elo_pot: 14,
			elo_min: 3195,
			elo_max: 3234,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(40) do
		%{
			id: 40,
			elo_pot: 14,
			elo_min: 3235,
			elo_max: 3274,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(41) do
		%{
			id: 41,
			elo_pot: 15,
			elo_min: 3275,
			elo_max: 3314,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(42) do
		%{
			id: 42,
			elo_pot: 15,
			elo_min: 3315,
			elo_max: 3354,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(43) do
		%{
			id: 43,
			elo_pot: 15,
			elo_min: 3355,
			elo_max: 3394,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(44) do
		%{
			id: 44,
			elo_pot: 15,
			elo_min: 3395,
			elo_max: 3434,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(45) do
		%{
			id: 45,
			elo_pot: 15,
			elo_min: 3435,
			elo_max: 3474,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(46) do
		%{
			id: 46,
			elo_pot: 15,
			elo_min: 3475,
			elo_max: 3514,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(47) do
		%{
			id: 47,
			elo_pot: 15,
			elo_min: 3415,
			elo_max: 9999999,
			coefficient_f: 36,
			coefficient_s: 0.3,
			coefficient_r: 2,
			coefficient_t: 1200,
			coefficient_a: 1,
			continuous_failure: [0,0],
			cumulative_failure: [0,0,0]
		}
	end

	def get(_), do: nil
end
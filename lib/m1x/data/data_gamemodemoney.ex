defmodule Data.GameModeMoney do
	## SOURCE:"xls\M模式经济配置表.xlsx" SHEET:"BattleMoneyMatchEventConfig"

	def ids() do
		[3001, 1001, 1002]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(3001) do
		%{
			id: 3001,
			weapon_type1: [10020101,10030101],
			weapon_type2: [10040101,10050101],
			weapon_type3: [10060101,10070101]
		}
	end

	def get(1001) do
		%{
			id: 1001,
			weapon_type1: [10020101,10030101],
			weapon_type2: [10040101,10050101],
			weapon_type3: [10060101,10070101]
		}
	end

	def get(1002) do
		%{
			id: 1002,
			weapon_type1: [10020101,10030101],
			weapon_type2: [10040101,10050101],
			weapon_type3: [10060101,10070101]
		}
	end

	def get(_), do: nil
end
defmodule Data.CharacterPassiveSkill do
	## SOURCE:"xls\J角色被动技能表.xlsx" SHEET:"Sheet1"

	def ids() do
		[10001, 10002, 10003, 10004]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(10001) do
		%{
			id: 10001
		}
	end

	def get(10002) do
		%{
			id: 10002
		}
	end

	def get(10003) do
		%{
			id: 10003
		}
	end

	def get(10004) do
		%{
			id: 10004
		}
	end

	def get(_), do: nil
end
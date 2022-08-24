defmodule Data.RobotManage do
	## SOURCE:"xls\J机器人配置表.xlsx" SHEET:"sheet1"

	def ids() do
		[100201]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(100201) do
		%{
			id: 100201
		}
	end

	def get(_), do: nil
end
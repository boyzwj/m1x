defmodule Data.RobotWeaponManage do
	## SOURCE:"xls\J机器人武器配置表.xlsx" SHEET:"Sheet1"

	def ids() do
		[10011, 10021, 10031, 10041, 10051, 10061, 10071, 10081, 10091, 10101, 10111, 10121, 10131, 10141, 10151, 10161, 10171, 10181, 10191, 20011, 10012, 10022, 10032, 10042, 10052, 10062, 10072, 10082, 10092, 10102, 10112, 10122, 10132, 10142, 10152, 10162, 10172, 10182, 10192, 20012, 10013, 10023, 10033, 10043, 10053, 10063, 10073, 10083, 10093, 10103, 10113, 10123, 10133, 10143, 10153, 10163, 10173, 10183, 10193, 20013]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(10011) do
		%{
			id: 10011
		}
	end

	def get(10021) do
		%{
			id: 10021
		}
	end

	def get(10031) do
		%{
			id: 10031
		}
	end

	def get(10041) do
		%{
			id: 10041
		}
	end

	def get(10051) do
		%{
			id: 10051
		}
	end

	def get(10061) do
		%{
			id: 10061
		}
	end

	def get(10071) do
		%{
			id: 10071
		}
	end

	def get(10081) do
		%{
			id: 10081
		}
	end

	def get(10091) do
		%{
			id: 10091
		}
	end

	def get(10101) do
		%{
			id: 10101
		}
	end

	def get(10111) do
		%{
			id: 10111
		}
	end

	def get(10121) do
		%{
			id: 10121
		}
	end

	def get(10131) do
		%{
			id: 10131
		}
	end

	def get(10141) do
		%{
			id: 10141
		}
	end

	def get(10151) do
		%{
			id: 10151
		}
	end

	def get(10161) do
		%{
			id: 10161
		}
	end

	def get(10171) do
		%{
			id: 10171
		}
	end

	def get(10181) do
		%{
			id: 10181
		}
	end

	def get(10191) do
		%{
			id: 10191
		}
	end

	def get(20011) do
		%{
			id: 20011
		}
	end

	def get(10012) do
		%{
			id: 10012
		}
	end

	def get(10022) do
		%{
			id: 10022
		}
	end

	def get(10032) do
		%{
			id: 10032
		}
	end

	def get(10042) do
		%{
			id: 10042
		}
	end

	def get(10052) do
		%{
			id: 10052
		}
	end

	def get(10062) do
		%{
			id: 10062
		}
	end

	def get(10072) do
		%{
			id: 10072
		}
	end

	def get(10082) do
		%{
			id: 10082
		}
	end

	def get(10092) do
		%{
			id: 10092
		}
	end

	def get(10102) do
		%{
			id: 10102
		}
	end

	def get(10112) do
		%{
			id: 10112
		}
	end

	def get(10122) do
		%{
			id: 10122
		}
	end

	def get(10132) do
		%{
			id: 10132
		}
	end

	def get(10142) do
		%{
			id: 10142
		}
	end

	def get(10152) do
		%{
			id: 10152
		}
	end

	def get(10162) do
		%{
			id: 10162
		}
	end

	def get(10172) do
		%{
			id: 10172
		}
	end

	def get(10182) do
		%{
			id: 10182
		}
	end

	def get(10192) do
		%{
			id: 10192
		}
	end

	def get(20012) do
		%{
			id: 20012
		}
	end

	def get(10013) do
		%{
			id: 10013
		}
	end

	def get(10023) do
		%{
			id: 10023
		}
	end

	def get(10033) do
		%{
			id: 10033
		}
	end

	def get(10043) do
		%{
			id: 10043
		}
	end

	def get(10053) do
		%{
			id: 10053
		}
	end

	def get(10063) do
		%{
			id: 10063
		}
	end

	def get(10073) do
		%{
			id: 10073
		}
	end

	def get(10083) do
		%{
			id: 10083
		}
	end

	def get(10093) do
		%{
			id: 10093
		}
	end

	def get(10103) do
		%{
			id: 10103
		}
	end

	def get(10113) do
		%{
			id: 10113
		}
	end

	def get(10123) do
		%{
			id: 10123
		}
	end

	def get(10133) do
		%{
			id: 10133
		}
	end

	def get(10143) do
		%{
			id: 10143
		}
	end

	def get(10153) do
		%{
			id: 10153
		}
	end

	def get(10163) do
		%{
			id: 10163
		}
	end

	def get(10173) do
		%{
			id: 10173
		}
	end

	def get(10183) do
		%{
			id: 10183
		}
	end

	def get(10193) do
		%{
			id: 10193
		}
	end

	def get(20013) do
		%{
			id: 20013
		}
	end

	def get(_), do: nil
end
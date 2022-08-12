defmodule Data.PseudoRandom do
	## SOURCE:"xls\W伪随机概率表.xlsx" SHEET:"sheet1"

	def ids() do
		[0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800, 3900, 4000, 4100, 4200, 4300, 4400, 4500, 4600, 4700, 4800, 4900, 5000, 5100, 5200, 5300, 5400, 5500, 5600, 5700, 5800, 5900, 6000, 6100, 6200, 6300, 6400, 6500, 6600, 6700, 6800, 6900, 7000, 7100, 7200, 7300, 7400, 7500, 7600, 7700, 7800, 7900, 8000, 8100, 8200, 8300, 8400, 8500, 8600, 8700, 8800, 8900, 9000, 9100, 9200, 9300, 9400, 9500, 9600, 9700, 9800, 9900, 10000]
	end

	def all(), do: for id <- ids(), do: get(id)

	def query(q), do: for data <- all(), q.(data), do: data

	def get(0) do
		%{
			probability: 0,
			increment: 0
		}
	end

	def get(100) do
		%{
			probability: 100,
			increment: 2
		}
	end

	def get(200) do
		%{
			probability: 200,
			increment: 6
		}
	end

	def get(300) do
		%{
			probability: 300,
			increment: 14
		}
	end

	def get(400) do
		%{
			probability: 400,
			increment: 24
		}
	end

	def get(500) do
		%{
			probability: 500,
			increment: 38
		}
	end

	def get(600) do
		%{
			probability: 600,
			increment: 54
		}
	end

	def get(700) do
		%{
			probability: 700,
			increment: 74
		}
	end

	def get(800) do
		%{
			probability: 800,
			increment: 96
		}
	end

	def get(900) do
		%{
			probability: 900,
			increment: 120
		}
	end

	def get(1000) do
		%{
			probability: 1000,
			increment: 148
		}
	end

	def get(1100) do
		%{
			probability: 1100,
			increment: 177
		}
	end

	def get(1200) do
		%{
			probability: 1200,
			increment: 210
		}
	end

	def get(1300) do
		%{
			probability: 1300,
			increment: 245
		}
	end

	def get(1400) do
		%{
			probability: 1400,
			increment: 282
		}
	end

	def get(1500) do
		%{
			probability: 1500,
			increment: 322
		}
	end

	def get(1600) do
		%{
			probability: 1600,
			increment: 365
		}
	end

	def get(1700) do
		%{
			probability: 1700,
			increment: 409
		}
	end

	def get(1800) do
		%{
			probability: 1800,
			increment: 456
		}
	end

	def get(1900) do
		%{
			probability: 1900,
			increment: 505
		}
	end

	def get(2000) do
		%{
			probability: 2000,
			increment: 557
		}
	end

	def get(2100) do
		%{
			probability: 2100,
			increment: 611
		}
	end

	def get(2200) do
		%{
			probability: 2200,
			increment: 667
		}
	end

	def get(2300) do
		%{
			probability: 2300,
			increment: 725
		}
	end

	def get(2400) do
		%{
			probability: 2400,
			increment: 785
		}
	end

	def get(2500) do
		%{
			probability: 2500,
			increment: 848
		}
	end

	def get(2600) do
		%{
			probability: 2600,
			increment: 911
		}
	end

	def get(2700) do
		%{
			probability: 2700,
			increment: 979
		}
	end

	def get(2800) do
		%{
			probability: 2800,
			increment: 1047
		}
	end

	def get(2900) do
		%{
			probability: 2900,
			increment: 1116
		}
	end

	def get(3000) do
		%{
			probability: 3000,
			increment: 1190
		}
	end

	def get(3100) do
		%{
			probability: 3100,
			increment: 1463
		}
	end

	def get(3200) do
		%{
			probability: 3200,
			increment: 1463
		}
	end

	def get(3300) do
		%{
			probability: 3300,
			increment: 1463
		}
	end

	def get(3400) do
		%{
			probability: 3400,
			increment: 1463
		}
	end

	def get(3500) do
		%{
			probability: 3500,
			increment: 1463
		}
	end

	def get(3600) do
		%{
			probability: 3600,
			increment: 1813
		}
	end

	def get(3700) do
		%{
			probability: 3700,
			increment: 1813
		}
	end

	def get(3800) do
		%{
			probability: 3800,
			increment: 1813
		}
	end

	def get(3900) do
		%{
			probability: 3900,
			increment: 1813
		}
	end

	def get(4000) do
		%{
			probability: 4000,
			increment: 1813
		}
	end

	def get(4100) do
		%{
			probability: 4100,
			increment: 2187
		}
	end

	def get(4200) do
		%{
			probability: 4200,
			increment: 2187
		}
	end

	def get(4300) do
		%{
			probability: 4300,
			increment: 2187
		}
	end

	def get(4400) do
		%{
			probability: 4400,
			increment: 2187
		}
	end

	def get(4500) do
		%{
			probability: 4500,
			increment: 2187
		}
	end

	def get(4600) do
		%{
			probability: 4600,
			increment: 2570
		}
	end

	def get(4700) do
		%{
			probability: 4700,
			increment: 2570
		}
	end

	def get(4800) do
		%{
			probability: 4800,
			increment: 2570
		}
	end

	def get(4900) do
		%{
			probability: 4900,
			increment: 2570
		}
	end

	def get(5000) do
		%{
			probability: 5000,
			increment: 2570
		}
	end

	def get(5100) do
		%{
			probability: 5100,
			increment: 2951
		}
	end

	def get(5200) do
		%{
			probability: 5200,
			increment: 2951
		}
	end

	def get(5300) do
		%{
			probability: 5300,
			increment: 2951
		}
	end

	def get(5400) do
		%{
			probability: 5400,
			increment: 2951
		}
	end

	def get(5500) do
		%{
			probability: 5500,
			increment: 2951
		}
	end

	def get(5600) do
		%{
			probability: 5600,
			increment: 3332
		}
	end

	def get(5700) do
		%{
			probability: 5700,
			increment: 3332
		}
	end

	def get(5800) do
		%{
			probability: 5800,
			increment: 3332
		}
	end

	def get(5900) do
		%{
			probability: 5900,
			increment: 3332
		}
	end

	def get(6000) do
		%{
			probability: 6000,
			increment: 3332
		}
	end

	def get(6100) do
		%{
			probability: 6100,
			increment: 3811
		}
	end

	def get(6200) do
		%{
			probability: 6200,
			increment: 3811
		}
	end

	def get(6300) do
		%{
			probability: 6300,
			increment: 3811
		}
	end

	def get(6400) do
		%{
			probability: 6400,
			increment: 3811
		}
	end

	def get(6500) do
		%{
			probability: 6500,
			increment: 3811
		}
	end

	def get(6600) do
		%{
			probability: 6600,
			increment: 4245
		}
	end

	def get(6700) do
		%{
			probability: 6700,
			increment: 4245
		}
	end

	def get(6800) do
		%{
			probability: 6800,
			increment: 4245
		}
	end

	def get(6900) do
		%{
			probability: 6900,
			increment: 4245
		}
	end

	def get(7000) do
		%{
			probability: 7000,
			increment: 4245
		}
	end

	def get(7100) do
		%{
			probability: 7100,
			increment: 4613
		}
	end

	def get(7200) do
		%{
			probability: 7200,
			increment: 4613
		}
	end

	def get(7300) do
		%{
			probability: 7300,
			increment: 4613
		}
	end

	def get(7400) do
		%{
			probability: 7400,
			increment: 4613
		}
	end

	def get(7500) do
		%{
			probability: 7500,
			increment: 4613
		}
	end

	def get(7600) do
		%{
			probability: 7600,
			increment: 5028
		}
	end

	def get(7700) do
		%{
			probability: 7700,
			increment: 5028
		}
	end

	def get(7800) do
		%{
			probability: 7800,
			increment: 5028
		}
	end

	def get(7900) do
		%{
			probability: 7900,
			increment: 5028
		}
	end

	def get(8000) do
		%{
			probability: 8000,
			increment: 5028
		}
	end

	def get(8100) do
		%{
			probability: 8100,
			increment: 5791
		}
	end

	def get(8200) do
		%{
			probability: 8200,
			increment: 5791
		}
	end

	def get(8300) do
		%{
			probability: 8300,
			increment: 5791
		}
	end

	def get(8400) do
		%{
			probability: 8400,
			increment: 5791
		}
	end

	def get(8500) do
		%{
			probability: 8500,
			increment: 5791
		}
	end

	def get(8600) do
		%{
			probability: 8600,
			increment: 6707
		}
	end

	def get(8700) do
		%{
			probability: 8700,
			increment: 6707
		}
	end

	def get(8800) do
		%{
			probability: 8800,
			increment: 6707
		}
	end

	def get(8900) do
		%{
			probability: 8900,
			increment: 6707
		}
	end

	def get(9000) do
		%{
			probability: 9000,
			increment: 6707
		}
	end

	def get(9100) do
		%{
			probability: 9100,
			increment: 7704
		}
	end

	def get(9200) do
		%{
			probability: 9200,
			increment: 7704
		}
	end

	def get(9300) do
		%{
			probability: 9300,
			increment: 7704
		}
	end

	def get(9400) do
		%{
			probability: 9400,
			increment: 7704
		}
	end

	def get(9500) do
		%{
			probability: 9500,
			increment: 7704
		}
	end

	def get(9600) do
		%{
			probability: 9600,
			increment: 7704
		}
	end

	def get(9700) do
		%{
			probability: 9700,
			increment: 7704
		}
	end

	def get(9800) do
		%{
			probability: 9800,
			increment: 7704
		}
	end

	def get(9900) do
		%{
			probability: 9900,
			increment: 7704
		}
	end

	def get(10000) do
		%{
			probability: 10000,
			increment: 7704
		}
	end

	def get(_), do: nil
end
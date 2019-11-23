library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity spi_slave is
	Port(
		clk: in std_logic;
		rst: in std_logic;
		sck: in std_logic;
		mosi: in std_logic;
		csn: in std_logic;
		data_out: out std_logic_vector(7 downto 0);
		valid: out std_logic
	);
end spi_slave;

architecture Behavioral of spi_slave is
	type SPI_STATE is (SPI_IDLE, SPI_DATA, SPI_STOP);
	signal state: SPI_STATE := SPI_IDLE;
	signal data: std_logic_vector(7 downto 0) := "00000000";
	signal bit_cnt: natural range 0 to 7 := 0;
	signal sck_d: std_logic;
	signal sck_i: std_logic;
	signal csn_d: std_logic; 
	signal csn_i: std_logic; 
begin
	
	process(clk) begin
		if(rising_edge(clk)) then
			sck_i <= sck;
			csn_i <= csn;
			if(rst = '1') then
				state <= SPI_IDLE;
			else
				valid <= '0';
				case(state) is
					when SPI_IDLE => 
						bit_cnt <= 0;
						data <= "00000000";
						if(csn_i = '0' and csn_d = '1') then
							state <= SPI_DATA;
						end if;
					when SPI_DATA => if(sck_i = '1' and sck_d = '0') then
						data <= data(6 downto 0) & mosi;
						bit_cnt <= bit_cnt + 1;
						if(bit_cnt = 7) then
							state <= SPI_STOP;
						end if;
					end if;
					when SPI_STOP => if(csn_i = '1' and csn_d = '0') then
							data_out <= data;
							valid <= '1';
							state <= SPI_IDLE;
						end if;
				end case;
				sck_d <= sck_i;
				csn_d <= csn_i;

			end if;
		end if;
	end process;

end Behavioral;

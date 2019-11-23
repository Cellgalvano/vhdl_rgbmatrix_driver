library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_rx is
	Port(
		clk: in std_logic;
		rst: in std_logic;
		din: in std_logic;
		data_out: out std_logic_vector(7 downto 0);
		valid: out std_logic
	);
end uart_rx;

architecture Behavioral of uart_rx is
	constant SYSTEM_CLOCK : natural := 50_000_000;
	constant UART_FULL_ETU : natural := (SYSTEM_CLOCK/115200);
	constant UART_HALF_ETU : natural := ((SYSTEM_CLOCK/115200)/2);
	type UART_STATE is (UART_START, UART_DATA, UART_STOP);
	signal data : std_logic_vector(7 downto 0) := "00000000";
	signal state : UART_STATE := UART_START;
	signal bit_cnt : natural range 0 to 7 := 0;
	signal etu_cnt : natural range 0 to 1023 := 0;
	signal etu_full : std_logic;
	signal etu_half : std_logic;
begin
	etu_full <= '1' when etu_cnt = UART_FULL_ETU else '0';
	etu_half <= '1' when etu_cnt = UART_HALF_ETU else '0';
	data_out <= data;
	process(clk) begin
		if(rising_edge(clk)) then
			if(rst = '1') then
				state <= UART_START;
			else
				valid <= '0';
				etu_cnt <= etu_cnt + 1;
				case(state) is
					when UART_START => if(din = '0') then
						if(etu_half = '1') then
							etu_cnt <= 0;
							bit_cnt <= 0;
							data <= "00000000";
							state <= UART_DATA;
						end if;
					else
						etu_cnt <= 0;
					end if;
					when UART_DATA => if(etu_full = '1') then
						etu_cnt <= 0;
						data <= din & data(7 downto 1);
						bit_cnt <= bit_cnt + 1;
						if(bit_cnt = 7) then
							state <= UART_STOP;
						end if;
					end if;
					when UART_STOP => if(etu_full = '1') then
						etu_cnt <= 0;
						valid <= '1';
						state <= UART_START;
					end if;
				end case;
			end if;
		end if;
	end process;

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rgbmatrix.all;

entity bufferconv is
	Port(
		clk: in std_logic;
		rst: in std_logic;
		panel_addr: in std_logic_vector(PANEL_ADDR_WIDTH-1 downto 0);
		panel_data: out std_logic_vector(47 downto 0);
		panel_ren: in std_logic;
		panel_valid: out std_logic;
		fb_addr: out std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);
		fb_data: in std_logic_vector(7 downto 0);
		fb_ren: out std_logic;
		fb_valid: in std_logic
	);
end bufferconv;

architecture Behavioral of bufferconv is
	type STATE_TYPE is (INIT, READ_BYTE0, READ_BYTE1, READ_BYTE2, READ_BYTE3, READ_BYTE4, READ_BYTE5, DATA_READY);
	signal state: STATE_TYPE := INIT;
	signal mem_addr: std_logic_vector(MEM_ADDR_WIDTH-1 downto 0) := (others => '0');
begin
	fb_addr <= mem_addr;
	process(clk) begin
		if(rising_edge(clk)) then
			if rst = '1' then
				fb_ren <= '0';
				panel_valid <= '0';
				state <= INIT;
			else
				case state is
					when INIT => 
						panel_valid <= '0';
						fb_ren <= '0';
							if(panel_ren = '1') then
							--mem_addr <= panel_addr(8 downto 0) & "000";
							mem_addr <= std_logic_vector(unsigned("000" & panel_addr) + unsigned("000" & panel_addr) + unsigned("000" & panel_addr) + unsigned("000" & panel_addr) + unsigned("000" & panel_addr) + unsigned("000" & panel_addr));
							fb_ren <= '1';
							state <= READ_BYTE0;
						end if;
					when READ_BYTE0 =>
						fb_ren <= '1';
						if fb_valid = '1' then
							panel_data(47 downto 40) <= fb_data;
							fb_ren <= '0';
							mem_addr <= std_logic_vector(unsigned(mem_addr) + 1);
							state <= READ_BYTE1;
						end if;
					when READ_BYTE1 =>
						fb_ren <= '1';
						if fb_valid = '1' then
							panel_data(39 downto 32) <= fb_data;
							fb_ren <= '0';
							mem_addr <= std_logic_vector(unsigned(mem_addr) + 1);
							state <= READ_BYTE2;
						end if;
					when READ_BYTE2 =>
						fb_ren <= '1';
						if fb_valid = '1' then
							panel_data(31 downto 24) <= fb_data;
							fb_ren <= '0';
							mem_addr <= std_logic_vector(unsigned(mem_addr) + 1);
							state <= READ_BYTE3;
						end if;
					when READ_BYTE3 =>
					fb_ren <= '1';
						if fb_valid = '1' then
							panel_data(23 downto 16) <= fb_data;
							fb_ren <= '0';
							mem_addr <= std_logic_vector(unsigned(mem_addr) + 1);
							state <= READ_BYTE4;
						end if;
					when READ_BYTE4 =>
						fb_ren <= '1';
						if fb_valid = '1' then
							panel_data(15 downto 8) <= fb_data;
							fb_ren <= '0';
							mem_addr <= std_logic_vector(unsigned(mem_addr) + 1);
							state <= READ_BYTE5;
						end if;
					when READ_BYTE5 =>
						fb_ren <= '1';
						if fb_valid = '1' then
							panel_data(7 downto 0) <= fb_data;
							fb_ren <= '0';
							state <= DATA_READY;
						end if;
					when DATA_READY =>
						panel_valid <= '1';
						state <= INIT;
				end case;
			end if;
		end if;
	end process;

end Behavioral;

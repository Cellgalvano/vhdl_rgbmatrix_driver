library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rgbmatrix.all;

entity ledctrl is
	port(
		clk: in  std_logic;
		rst: in  std_logic;
		-- LED Panel IO
		clk_out: out std_logic;
		rgb1: out std_logic_vector(2 downto 0);
		rgb2: out std_logic_vector(2 downto 0);
		led_addr: out std_logic_vector(PANEL_HEIGHT_ADDR_WIDTH-1 downto 0);
		lat: out std_logic;
		oe: out std_logic;
		-- Memory IO
		addr: out std_logic_vector(PANEL_ADDR_WIDTH-1 downto 0);
		data: in  std_logic_vector(47 downto 0);
		data_valid: in std_logic;
		read_en: out std_logic
	);
end ledctrl;

architecture Behavioral of ledctrl is
	type STATE_TYPE is (INIT, READ_DATA, WAIT_FOR_DATA_VALID, SHIFT_PIXEL, INCR_RAM_ADDR, LATCH, OE_WAIT, INCR_LED_ADDR);
	signal state: STATE_TYPE := INIT;
	type LUT_TYPE is array (0 to 255) of unsigned(7 downto 0);
	signal gamma: LUT_TYPE := ("00000000","00000000","00000000","00000000","00000000","00000000","00000001","00000001","00000001","00000001","00000001","00000001","00000001","00000001","00000001","00000010","00000010","00000010","00000010","00000010","00000010","00000010","00000010","00000010","00000011","00000011","00000011","00000011","00000011","00000011","00000011","00000011","00000100","00000100","00000100","00000100","00000100","00000100","00000101","00000101","00000101","00000101","00000101","00000110","00000110","00000110","00000110","00000110","00000111","00000111","00000111","00000111","00001000","00001000","00001000","00001000","00001001","00001001","00001001","00001010","00001010","00001010","00001010","00001011","00001011","00001011","00001100","00001100","00001100","00001101","00001101","00001101","00001110","00001110","00001111","00001111","00001111","00010000","00010000","00010001","00010001","00010001","00010010","00010010","00010011","00010011","00010100","00010100","00010101","00010101","00010110","00010110","00010111","00010111","00011000","00011000","00011001","00011001","00011010","00011010","00011011","00011100","00011100","00011101","00011101","00011110","00011111","00011111","00100000","00100000","00100001","00100010","00100010","00100011","00100100","00100101","00100101","00100110","00100111","00100111","00101000","00101001","00101010","00101011","00101011","00101100","00101101","00101110","00101111","00101111","00110000","00110001","00110010","00110011","00110100","00110101","00110110","00110110","00110111","00111000","00111001","00111010","00111011","00111100","00111101","00111110","00111111","01000000","01000001","01000010","01000011","01000100","01000110","01000111","01001000","01001001","01001010","01001011","01001100","01001101","01001111","01010000","01010001","01010010","01010011","01010101","01010110","01010111","01011000","01011010","01011011","01011100","01011110","01011111","01100000","01100010","01100011","01100100","01100110","01100111","01101001","01101010","01101100","01101101","01101110","01110000","01110001","01110011","01110100","01110110","01111000","01111001","01111011","01111100","01111110","10000000","10000001","10000011","10000100","10000110","10001000","10001010","10001011","10001101","10001111","10010001","10010010","10010100","10010110","10011000","10011010","10011011","10011101","10011111","10100001","10100011","10100101","10100111","10101001","10101011","10101101","10101111","10110001","10110011","10110101","10110111","10111001","10111011","10111101","10111111","11000001","11000100","11000110","11001000","11001010","11001100","11001111","11010001","11010011","11010110","11011000","11011010","11011100","11011111","11100001","11100100","11100110","11101000","11101011","11101101","11110000","11110010","11110101","11110111","11111010","11111100");
	signal col_count: unsigned(PANEL_COL_WIDTH_LOG downto 0);
	signal led_addr_int: std_logic_vector(PANEL_HEIGHT_ADDR_WIDTH-1 downto 0);
	signal ram_addr_int: std_logic_vector(PANEL_ADDR_WIDTH-1 downto 0);
	signal r1, g1, b1, r2, g2, b2: std_logic;
	signal upper, lower : std_logic_vector(23 downto 0);
	signal upper_r, upper_g, upper_b : std_logic_vector(7 downto 0);
	signal lower_r, lower_g, lower_b : std_logic_vector(7 downto 0);
	signal bam_cnt: natural range 0 to 7;
	signal oe_cnt: std_logic_vector(9 downto 0);
	signal oe_max: std_logic_vector(9 downto 0);
	
begin

	led_addr <= led_addr_int;
	addr <= ram_addr_int;
	rgb1 <= b1 & g1 & r1;
	rgb2 <= b2 & g2 & r2;
	
	upper <= data(47 downto 24);
	lower <= data(23 downto 0);
	
	-- blockram gamma correction based on a LUT by adafruit
	process(clk) begin
		if rising_edge(clk) then
			upper_r <= std_logic_vector(gamma(to_integer(unsigned(upper(23 downto 16)))));
			upper_g <= std_logic_vector(gamma(to_integer(unsigned(upper(15 downto 8)))));
			upper_b <= std_logic_vector(gamma(to_integer(unsigned(upper(7 downto 0)))));
			lower_r <= std_logic_vector(gamma(to_integer(unsigned(lower(23 downto 16)))));
			lower_g <= std_logic_vector(gamma(to_integer(unsigned(lower(15 downto 8)))));
			lower_b <= std_logic_vector(gamma(to_integer(unsigned(lower(7 downto 0)))));
		end if;
	end process;
	
	-- main logic / fsm
	process(clk) begin
		if(rising_edge(clk)) then
			if(rst = '1') then
				state <= INIT;
				led_addr_int <= (others => '0');
				ram_addr_int <= (others => '0');
				oe_cnt <= (others => '0');
				oe <= '1';
			else
				clk_out <= '0';
				lat <= '0';
				oe <= '1';
				case state is
					when INIT =>
						col_count <= (others => '0');
						bam_cnt <= 0;
						state <= READ_DATA;
					when READ_DATA =>
						read_en <= '1';
						state <= WAIT_FOR_DATA_VALID;
					when WAIT_FOR_DATA_VALID =>
						if data_valid = '1' then
							read_en <= '0';
							state <= SHIFT_PIXEL;
						end if;
					when SHIFT_PIXEL =>
						r1 <= upper_r(bam_cnt);
						g1 <= upper_g(bam_cnt);
						b1 <= upper_b(bam_cnt);
						r2 <= lower_r(bam_cnt);
						g2 <= lower_g(bam_cnt);
						b2 <= lower_b(bam_cnt);
						clk_out <= '1';
						if(col_count < DISPLAY_WIDTH) then
							state <= INCR_RAM_ADDR;
						else
							state <= LATCH;
						end if;
					when INCR_RAM_ADDR =>
						ram_addr_int <= std_logic_vector(unsigned(ram_addr_int) + 1);
						col_count <= col_count + 1;
						state <= READ_DATA;
					when LATCH =>
						lat <= '1';
						col_count <= (others => '0');
						case bam_cnt is
							when 0 => oe_max <= "0000000100";
							when 1 => oe_max <= "0000001100";
							when 2 => oe_max <= "0000011100";
							when 3 => oe_max <= "0000111100";
							when 4 => oe_max <= "0001111100";
							when 5 => oe_max <= "0011111100";
							when 6 => oe_max <= "0111111100";
							when 7 => oe_max <= "1111111100";
						end case;
						state <= OE_WAIT;
					when OE_WAIT =>
						oe <= '0';
						if oe_cnt = oe_max then
							oe_cnt <= (others => '0');
							bam_cnt <= bam_cnt + 1;
							if bam_cnt = 7 then
								state <= INCR_LED_ADDR;
							else
								ram_addr_int <= std_logic_vector(unsigned(ram_addr_int) - DISPLAY_WIDTH);
								state <= READ_DATA;
							end if;
						else
							oe_cnt <= std_logic_vector(unsigned(oe_cnt) + 1);
						end if;
					when INCR_LED_ADDR =>
						led_addr_int <= std_logic_vector(unsigned(led_addr_int) + 1);
						state <= READ_DATA;
					when others => null;
				end case;

			end if;	
		end if;
		
	end process;
end Behavioral;

library ieee;
use ieee.std_logic_1164.all;
use work.rgbmatrix.all;

entity top_level is
	port(
		clk_12mhz: in std_logic;
		user_btn: in std_logic;
		uart_rxd: in std_logic;
		ain: out std_logic_vector(6 downto 0);
		gpio: out std_logic_vector(6 downto 0);
		pmod: in std_logic_vector(7 downto 3);
		led_out: out std_logic_vector(7 downto 0) := "00000000"
	);
end top_level;

architecture str of top_level is
	-- Reset signals
	signal rst: std_logic;
	signal clk_50mhz: std_logic;
	signal clk_100mhz: std_logic;

	-- Memory signals
	signal panel_addr: std_logic_vector(PANEL_ADDR_WIDTH-1 downto 0);
	signal panel_data: std_logic_vector(47 downto 0);
	signal panel_ren: std_logic;
	signal panel_valid: std_logic;
	signal fb_addr: std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);
	signal fb_data: std_logic_vector(7 downto 0);
	signal fb_ren: std_logic; 
	signal fb_valid: std_logic;
	
	-- Flags
	signal uart_valid: std_logic;
	signal uart_data: std_logic_vector(7 downto 0); 
	signal spi_valid: std_logic;
	signal spi_data: std_logic_vector(7 downto 0);
	signal input_data: std_logic_vector(7 downto 0);
	signal input_valid: std_logic;
begin
	
	rst <= not user_btn;

	clockpll_inst: entity work.clockpll port map(
		areset => '0',
		inclk0 => clk_12mhz,
		c0	 => clk_50mhz,
		c1	 => clk_100mhz
	);
	
	-- LED panel controller
	U_LEDCTRL : entity work.ledctrl port map(
		rst => rst,
		clk => clk_50mhz,
		-- Connection to LED panel
		clk_out => gpio(3),
		rgb1(0) => ain(0),
		rgb1(1) => ain(1),
		rgb1(2) => ain(2),
		rgb2(0) => ain(3),
		rgb2(1) => ain(4),
		rgb2(2) => ain(5),
		led_addr(0) => ain(6),
		led_addr(1) => gpio(0),
		led_addr(2) => gpio(1),
		led_addr(3) => gpio(2),
		--led_addr(4) => gpio(6),
		lat => gpio(4),
		oe  => gpio(5),
		-- Connection with framebuffer
		addr => panel_addr,
		data => panel_data,
		data_valid => panel_valid,
		read_en => panel_ren
	);
	
	U_BUFFERCONV: entity work.bufferconv port map(
		clk => clk_50mhz,
		rst => rst,
		panel_addr => panel_addr,
		panel_data => panel_data,
		panel_ren => panel_ren,
		panel_valid => panel_valid,
		fb_addr => fb_addr,
		fb_data => fb_data,
		fb_ren => fb_ren,
		fb_valid => fb_valid
	);
	
	U_FB: entity work.framebuffer port map(
		clk => clk_50mhz,
		rst => rst,
		data_in => input_data,
		data_out => fb_data,
		addr => fb_addr,
		wen => input_valid,
		ren => fb_ren,
		valid => fb_valid,
		sync => pmod(7)
	);
	
	URX: entity work.uart_rx port map(
		clk => clk_50mhz, 
		rst => rst, 
		din => uart_rxd, 
		data_out => uart_data, 
		valid => uart_valid
	);
	
	SPIS: entity work.spi_slave port map(
		clk => clk_50mhz, 
		rst => rst, 
		sck => pmod(4),
		mosi => pmod(5),
		csn => pmod(6),
		data_out => spi_data, 
		valid => spi_valid
	);
	
	process(pmod(3)) begin
		if pmod(3) = '1' then
			input_data <= uart_data;
			input_valid <= uart_valid;
		else
			input_data <= spi_data;
			input_valid <= spi_valid;
		end if;
	end process;
	
end str;

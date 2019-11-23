library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rgbmatrix.all;

entity framebuffer is
    Port(
        clk: in std_logic;
		  rst: in std_logic;
        data_in: in std_logic_vector(7 downto 0);
        data_out: out std_logic_vector(7 downto 0);
		  addr: in std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);
        wen: in std_logic;
        ren: in std_logic;
        valid: out std_logic := '0';
		  sync: in std_logic := '0'
    );
end framebuffer;

architecture Behavioral of framebuffer is
    signal WCnt: unsigned(MEM_ADDR_WIDTH-1 downto 0) := (others => '0');
    type RAM is array(0 to NUM_SUBPIXELS-1) of unsigned(7 downto 0);
    signal memory1: RAM;
	 signal memory2: RAM;
	 signal ren_d: std_logic;
    signal wen_d: std_logic;
	 signal sync_i: std_logic;
	 signal sync_d: std_logic;
	 signal swap: std_logic := '0';
begin
	process(clk) begin
		if(rising_edge(clk)) then
			sync_i <= sync;
			if rst = '1' then
				WCnt <= (others => '0');
				valid <= '0';
			else
				if (sync_i = '1' and not sync_d = '1') then
					WCnt <= (others => '0');
				end if;
				if (wen = '1' and not wen_d = '1') then
					if swap = '0' then
						memory1(to_integer(WCnt)) <= unsigned(data_in);
					else
						memory2(to_integer(WCnt)) <= unsigned(data_in);
					end if;
					WCnt <= WCnt + 1;
					if WCnt = NUM_SUBPIXELS-1 then
						WCnt <= (others => '0');
						swap <= not swap;
					end if;
				end if;
				if (ren = '1' and not ren_d = '1') then
					if swap = '1' then
						data_out <= std_logic_vector(memory1(to_integer(signed(addr))));
					else
						data_out <= std_logic_vector(memory2(to_integer(signed(addr))));
					end if;
					valid <= '1';
				else
					valid <= '0';
				end if;
				ren_d <= ren;
				wen_d <= wen;
				sync_d <= sync_i;
			end if;
		end if;
	end process;
end Behavioral;

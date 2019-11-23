library ieee;
use ieee.math_real.log2;
use ieee.math_real.ceil;

package rgbmatrix is
    
    -- User configurable constants
    constant DISPLAY_HEIGHT: integer := 32;
    constant DISPLAY_WIDTH: integer := 32;
    
    -- Derived constants
	 constant NUM_PIXELS: positive := DISPLAY_HEIGHT*DISPLAY_WIDTH; -- For32x32: 1024
    constant NUM_SUBPIXELS: positive := DISPLAY_HEIGHT*DISPLAY_WIDTH*3; -- For32x32: 3072
	 
	 constant MEM_ADDR_WIDTH: positive := positive(ceil(log2(real(NUM_SUBPIXELS)))); -- For32x32: 12
    constant PANEL_ADDR_WIDTH: positive := positive(log2(real(NUM_PIXELS/2))); -- For32x32: 9
	 constant PANEL_COL_WIDTH_LOG: positive := positive(log2(real(DISPLAY_WIDTH))); -- For32x32: 5
	 constant PANEL_HEIGHT_ADDR_WIDTH: positive := positive(log2(real(DISPLAY_HEIGHT/2))); -- For32x32: 4
    
end rgbmatrix;
--   __   __     __  __     __         __
--  /\ "-.\ \   /\ \/\ \   /\ \       /\ \
--  \ \ \-.  \  \ \ \_\ \  \ \ \____  \ \ \____
--   \ \_\\"\_\  \ \_____\  \ \_____\  \ \_____\
--    \/_/ \/_/   \/_____/   \/_____/   \/_____/
--   ______     ______       __     ______     ______     ______
--  /\  __ \   /\  == \     /\ \   /\  ___\   /\  ___\   /\__  _\
--  \ \ \/\ \  \ \  __<    _\_\ \  \ \  __\   \ \ \____  \/_/\ \/
--   \ \_____\  \ \_____\ /\_____\  \ \_____\  \ \_____\    \ \_\
--    \/_____/   \/_____/ \/_____/   \/_____/   \/_____/     \/_/
--
-- https://joshbassett.info
-- https://twitter.com/nullobject
-- https://github.com/nullobject
--
-- Copyright (c) 2020 Josh Bassett
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config.all;
use work.math.all;
use work.types.all;

package common is
  constant CPU_ADDR_WIDTH : natural := 16;

  -- IOCTL
  constant IOCTL_ADDR_WIDTH : natural := 20;

  -- SDRAM
  constant SDRAM_ADDR_WIDTH      : natural := 13;
  constant SDRAM_DATA_WIDTH      : natural := 16;
  constant SDRAM_BANK_WIDTH      : natural := 2;
  constant SDRAM_COL_WIDTH       : natural := 9;
  constant SDRAM_ROW_WIDTH       : natural := 13;
  constant SDRAM_CTRL_ADDR_WIDTH : natural := 23; -- 8Mx32-bit
  constant SDRAM_CTRL_DATA_WIDTH : natural := 32;

  -- work RAM
  constant WORK_RAM_ADDR_WIDTH : natural := 12; -- 4kB

  -- program ROMs
  constant PROG_ROM_1_ADDR_WIDTH : natural := 16;
  constant PROG_ROM_1_DATA_WIDTH : natural := 8;
  constant PROG_ROM_2_ADDR_WIDTH : natural := 16;
  constant PROG_ROM_2_DATA_WIDTH : natural := 8;

  -- tile ROMs
  constant SPRITE_ROM_ADDR_WIDTH : natural := 16;
  constant SPRITE_ROM_DATA_WIDTH : natural := 32;
  constant CHAR_ROM_ADDR_WIDTH   : natural := 13;
  constant CHAR_ROM_DATA_WIDTH   : natural := 32;
  constant FG_ROM_ADDR_WIDTH     : natural := 16;
  constant FG_ROM_DATA_WIDTH     : natural := 32;
  constant BG_ROM_ADDR_WIDTH     : natural := 16;
  constant BG_ROM_DATA_WIDTH     : natural := 32;

  -- sound ROMs
  constant SOUND_ROM_1_ADDR_WIDTH : natural := 15;
  constant SOUND_ROM_1_DATA_WIDTH : natural := 8;
  constant SOUND_ROM_2_ADDR_WIDTH : natural := 15;
  constant SOUND_ROM_2_DATA_WIDTH : natural := 8;

  -- ROM sizes/offsets
  --
  -- When MiSTer loads a core, ROM data is downloaded from the HPS and streamed
  -- directly into the SDRAM. These offset values contain the address of each
  -- ROM segment in the IOCTL data stream.
  --
  -- If the ordering of the ROMs in the MRA file changes, then these offset
  -- values must also be changed.
  constant PROG_ROM_1_OFFSET  : natural := 16#00000#;
  constant PROG_ROM_1_SIZE    : natural := 16#0C000#; -- 48kB
  constant PROG_ROM_2_OFFSET  : natural := 16#0C000#;
  constant PROG_ROM_2_SIZE    : natural := 16#10000#; -- 64kB
  constant SOUND_ROM_1_OFFSET : natural := 16#1C000#;
  constant SOUND_ROM_1_SIZE   : natural := 16#08000#; -- 32kB
  constant CHAR_ROM_OFFSET    : natural := 16#24000#;
  constant CHAR_ROM_SIZE      : natural := 16#08000#; -- 32kB
  constant SPRITE_ROM_OFFSET  : natural := 16#2C000#;
  constant SPRITE_ROM_SIZE    : natural := 16#40000#; -- 256kB
  constant FG_ROM_OFFSET      : natural := 16#6C000#;
  constant FG_ROM_SIZE        : natural := 16#40000#; -- 256kB
  constant BG_ROM_OFFSET      : natural := 16#AC000#;
  constant BG_ROM_SIZE        : natural := 16#40000#; -- 256kB
  constant SOUND_ROM_2_OFFSET : natural := 16#EC000#;
  constant SOUND_ROM_2_SIZE   : natural := 16#08000#; -- 32kB

  -- VRAM
  constant CHAR_RAM_CPU_ADDR_WIDTH    : natural := 11; -- 2kB
  constant CHAR_RAM_GPU_ADDR_WIDTH    : natural := 10;
  constant CHAR_RAM_GPU_DATA_WIDTH    : natural := 16;
  constant SCROLL_RAM_CPU_ADDR_WIDTH  : natural := 10; -- 1kB
  constant SCROLL_RAM_GPU_ADDR_WIDTH  : natural := 9;
  constant SCROLL_RAM_GPU_DATA_WIDTH  : natural := 16;
  constant SPRITE_RAM_CPU_ADDR_WIDTH  : natural := 11; -- 2kB
  constant SPRITE_RAM_GPU_ADDR_WIDTH  : natural := 8;
  constant SPRITE_RAM_GPU_DATA_WIDTH  : natural := 64;
  constant PALETTE_RAM_CPU_ADDR_WIDTH : natural := 11; -- 2kB
  constant PALETTE_RAM_GPU_ADDR_WIDTH : natural := 10;
  constant PALETTE_RAM_GPU_DATA_WIDTH : natural := 16;

  -- sound RAM
  constant SOUND_RAM_ADDR_WIDTH : natural := 11;

  -- line buffer
  constant LINE_BUFFER_ADDR_WIDTH : natural := 8;
  constant LINE_BUFFER_DATA_WIDTH : natural := 8;

  -- frame buffer
  constant FRAME_BUFFER_ADDR_WIDTH : natural := 16;
  constant FRAME_BUFFER_DATA_WIDTH : natural := 10;

  -- determines the game config for the given index
  function select_game_config (index : natural) return game_config_t;

  -- determines whether an address is within a given range
  function addr_in_range (addr : unsigned(CPU_ADDR_WIDTH-1 downto 0); addr_range : addr_range_t) return boolean;

  -- calculates the sprite size (8x8, 16x16, 32x32, 64x64)
  function sprite_size_in_pixels (size : unsigned(1 downto 0)) return natural;

  -- decodes a tile from a 16-bit vector
  function decode_tile (config : tile_config_t; data : std_logic_vector(15 downto 0)) return tile_t;

  -- decodes a sprite from a 64-bit vector
  function decode_sprite (config : sprite_config_t; data : std_logic_vector(63 downto 0)) return sprite_t;

  -- selects a pixel from a tile row at the given offset
  function select_pixel (row : row_t; offset : unsigned(2 downto 0)) return pixel_t;

  -- determines the graphics layer to be rendered
  function mux_layers (
    sprite_priority : priority_t;
    sprite_data     : byte_t;
    char_data       : byte_t;
    fg_data         : byte_t;
    bg_data         : byte_t
  ) return layer_t;
end package common;

package body common is
  function select_game_config (index : natural) return game_config_t is
  begin
    case index is
      when 2      => return SILKWORM_GAME_CONFIG;
      when 1      => return GEMINI_GAME_CONFIG;
      when others => return RYGAR_GAME_CONFIG;
    end case;
  end select_game_config;

  function addr_in_range (addr : unsigned(CPU_ADDR_WIDTH-1 downto 0); addr_range : addr_range_t) return boolean is
  begin
    if addr >= addr_range.min and addr <= addr_range.max then
      return true;
    else
      return false;
    end if;
  end addr_in_range;

  function sprite_size_in_pixels (size : unsigned(1 downto 0)) return natural is
  begin
    case size is
      when "00" => return 8;
      when "01" => return 16;
      when "10" => return 32;
      when "11" => return 64;
    end case;
  end sprite_size_in_pixels;

  function decode_tile (config : tile_config_t; data : std_logic_vector(15 downto 0)) return tile_t is
    variable hi_code : std_logic_vector(2 downto 0);
    variable lo_code : byte_t;
  begin
    hi_code := mask_bits(data, config.hi_code_msb, config.hi_code_lsb, 3);
    lo_code := mask_bits(data, config.lo_code_msb, config.lo_code_lsb, 8);

    return (
      code  => unsigned(hi_code & lo_code),
      color => mask_bits(data, config.color_msb, config.color_lsb, 4)
    );
  end decode_tile;

  function decode_sprite (config : sprite_config_t; data : std_logic_vector(63 downto 0)) return sprite_t is
    variable mask     : std_logic_vector(12 downto 0);
    variable hi_code  : std_logic_vector(4 downto 0);
    variable lo_code  : byte_t;
    variable lo_pos_x : byte_t;
    variable lo_pos_y : byte_t;
    variable priority : std_logic_vector(1 downto 0);
    variable size     : unsigned(1 downto 0);
  begin
    size     := unsigned(mask_bits(data, config.size_msb, config.size_lsb, 2));
    priority := mask_bits(data, config.priority_msb, config.priority_lsb, 2);
    hi_code  := mask_bits(data, config.hi_code_msb, config.hi_code_lsb, 5);
    lo_code  := mask_bits(data, config.lo_code_msb, config.lo_code_lsb, 8);
    lo_pos_x := mask_bits(data, config.lo_pos_x_msb, config.lo_pos_x_lsb, 8);
    lo_pos_y := mask_bits(data, config.lo_pos_y_msb, config.lo_pos_y_lsb, 8);

    -- Depending on the sprite size, the lower bits of the code should be masked off.
    --
    -- For example:
    --
    -- * 16x16 sprites should have the lower two bits masked off.
    -- * 32x32 sprites should have the lower four bits masked off.
    -- * 64x64 sprites should have the lower six bits masked off.
    mask := not std_logic_vector(shift_left(to_unsigned(1, 13), to_integer(size*2))-1);

    return (
      code     => unsigned((hi_code & lo_code) and mask),
      color    => mask_bits(data, config.color_msb, config.color_lsb, 4),
      enable   => data(config.enable_bit),
      flip_x   => data(config.flip_x_bit),
      flip_y   => data(config.flip_y_bit),
      pos      => (unsigned(data(config.hi_pos_x_bit) & lo_pos_x), unsigned(data(config.hi_pos_y_bit) & lo_pos_y)),
      priority => priority,
      size     => to_unsigned(sprite_size_in_pixels(size), 7)
    );
  end decode_sprite;

  function select_pixel (row : row_t; offset : unsigned(2 downto 0)) return pixel_t is
  begin
    case offset is
      when "000" => return row(31 downto 28);
      when "001" => return row(27 downto 24);
      when "010" => return row(23 downto 20);
      when "011" => return row(19 downto 16);
      when "100" => return row(15 downto 12);
      when "101" => return row(11 downto 8);
      when "110" => return row(7 downto 4);
      when "111" => return row(3 downto 0);
    end case;
  end select_pixel;

  -- This function determines which graphics layer should be rendered, based on
  -- the sprite priority and graphics layer data.
  --
  -- This differs from the original arcade hardware, which uses a priority
  -- encoder and some other logic gates to choose the correct layer to render.
  --
  -- A giant conditional is more verbose, but it's easier to understand how it
  -- works.
  function mux_layers (
    sprite_priority : priority_t;
    sprite_data     : byte_t;
    char_data       : byte_t;
    fg_data         : byte_t;
    bg_data         : byte_t
  ) return layer_t is
  begin
    case sprite_priority is
      -- sprites have the highest priority
      when "00" =>
        if sprite_data(3 downto 0) /= "0000" then
          return SPRITE_LAYER;
        elsif char_data(3 downto 0) /= "0000" then
          return CHAR_LAYER;
        elsif fg_data(3 downto 0) /= "0000" then
          return FG_LAYER;
        elsif bg_data(3 downto 0) /= "0000" then
          return BG_LAYER;
        else
          return FILL_LAYER;
        end if;

      -- sprites are obscured by the character layer
      when "01" =>
        if char_data(3 downto 0) /= "0000" then
          return CHAR_LAYER;
        elsif sprite_data(3 downto 0) /= "0000" then
          return SPRITE_LAYER;
        elsif fg_data(3 downto 0) /= "0000" then
          return FG_LAYER;
        elsif bg_data(3 downto 0) /= "0000" then
          return BG_LAYER;
        else
          return FILL_LAYER;
        end if;

      -- sprites are obscured by the character and foreground layers
      when "10" =>
        if char_data(3 downto 0) /= "0000" then
          return CHAR_LAYER;
        elsif fg_data(3 downto 0) /= "0000" then
          return FG_LAYER;
        elsif sprite_data(3 downto 0) /= "0000" then
          return SPRITE_LAYER;
        elsif bg_data(3 downto 0) /= "0000" then
          return BG_LAYER;
        else
          return FILL_LAYER;
        end if;

      -- sprites are obscured by the character, foreground, and background layers
      when "11" =>
        if char_data(3 downto 0) /= "0000" then
          return CHAR_LAYER;
        elsif fg_data(3 downto 0) /= "0000" then
          return FG_LAYER;
        elsif bg_data(3 downto 0) /= "0000" then
          return BG_LAYER;
        elsif sprite_data(3 downto 0) /= "0000" then
          return SPRITE_LAYER;
        else
          return FILL_LAYER;
        end if;
    end case;
  end mux_layers;
end package body common;

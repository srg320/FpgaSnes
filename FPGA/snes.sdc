set_time_format -unit ns -decimal_places 3
derive_pll_clocks -create_base_clocks
derive_clock_uncertainty 

create_generated_clock -name {cpuclk} -source [get_nets {pll|altpll_component|auto_generated|wire_pll1_clk[0]}] -divide_by 6 [get_registers {SNES:SNES|SCPU:CPU|INT_CLK}]
create_generated_clock -name {cpudotclk} -source [get_nets {pll|altpll_component|auto_generated|wire_pll1_clk[0]}] -divide_by 4 [get_registers {SNES:SNES|SCPU:CPU|DOT_CLK}]
create_generated_clock -name {ppudotclk} -source [get_nets {pll|altpll_component|auto_generated|wire_pll1_clk[0]}] -divide_by 4 [get_registers {SNES:SNES|SPPU:PPU|DOT_CLK}]
create_generated_clock -name {ppuioclk} -source [get_nets {pll|altpll_component|auto_generated|wire_pll1_clk[0]}] -divide_by 2 [get_registers {SNES:SNES|SPPU:PPU|IO_CLK}]
create_generated_clock -name {smpclk} -source [get_nets {apupll|altpll_component|auto_generated|wire_pll1_clk[0]}] -divide_by 6 [get_registers {SNES:SNES|DSP:DSP|INT_CLK}]

derive_clock_uncertainty 

set_clock_groups -exclusive -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0] cpuclk cpudotclk ppudotclk ppuioclk}]
set_clock_groups -exclusive -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]
set_clock_groups -exclusive -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[2]}]
set_clock_groups -exclusive -group [get_clocks {apupll|altpll_component|auto_generated|pll1|clk[0] smpclk }]

set_clock_groups -exclusive -group [get_clocks {SMAP|cx4pll|altpll_component|auto_generated|pll1|clk[0]}]
set_clock_groups -exclusive -group [get_clocks {SMAP|dspnpll|altpll_component|auto_generated|pll1|clk[0]}]

set_false_path -from [get_registers {mcu:MCU|CTRL[*]}] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|DATA_OUT[*] }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|DBG_DAT_OUT[*] }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|DBG_REG[*] }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|DBG_SEL[*] }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|REG_WR }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|LOADER_ADDR[*] }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|LOADER_WR }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|MAP_BSRAM_MASK[*] }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|MAP_CTRL[*] }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|MAP_ROM_MASK[*]}] -to [get_registers *]
set_false_path -from [get_registers {SNES:SNES|SMP_BRK }] -to [get_registers *]
set_false_path -from [get_registers {SNES:SNES|APU_DBG_REG[*]}] -to [get_registers *]
set_false_path -from [get_registers {SNES:SNES|APU_ENABLE }] -to [get_registers *]

set_false_path -from [get_registers *] -to [get_ports LCD_R[*]]
set_false_path -from [get_registers *] -to [get_ports LCD_G[*]]
set_false_path -from [get_registers *] -to [get_ports LCD_B[*]]
set_false_path -from [get_registers *] -to [get_ports {LCD_DCLK LCD_DE LCD_HS LCD_VS LCD_DISP}]

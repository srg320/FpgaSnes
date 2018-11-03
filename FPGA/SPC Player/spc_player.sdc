set_time_format -unit ns -decimal_places 3
derive_pll_clocks -create_base_clocks
derive_clock_uncertainty 

create_generated_clock -name {smpclk} -source [get_nets {apupll|altpll_component|auto_generated|wire_pll1_clk[0]}] -divide_by 6 [get_registers {SNES:SNES|DSP:DSP|INT_CLK}]

derive_clock_uncertainty 

set_clock_groups -exclusive -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]
set_clock_groups -exclusive -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]
set_clock_groups -exclusive -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[2]}]
set_clock_groups -exclusive -group [get_clocks {apupll|altpll_component|auto_generated|pll1|clk[0] smpclk }]

set_false_path -from [get_registers {mcu:MCU|CTRL[*]}] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|DBG_DAT_OUT[*] }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|DBG_REG[*] }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|DBG_SEL[*] }] -to [get_registers *]
set_false_path -from [get_registers {mcu:MCU|REG_WR }] -to [get_registers *]


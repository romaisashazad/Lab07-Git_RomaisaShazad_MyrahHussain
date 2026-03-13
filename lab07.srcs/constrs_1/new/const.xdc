# ================================================================
# Basys 3 XDC for top_rf_alu
# Port names: clk, rst_btn, sw_phys[3:0], led_phys[15:0], seg[6:0], an[3:0]
# ================================================================

# Voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# ----------------------------------------------------------------
# Clock - 100 MHz
# ----------------------------------------------------------------
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# ----------------------------------------------------------------
# Reset button - BTNR right button (T17), active high
# ----------------------------------------------------------------
set_property PACKAGE_PIN T17 [get_ports rst_btn]
set_property IOSTANDARD LVCMOS33 [get_ports rst_btn]

# ----------------------------------------------------------------
# Step button - BTNC center button (U18)
# Press to advance FSM one state when sw_phys[3]=1
# ----------------------------------------------------------------
set_property PACKAGE_PIN U18 [get_ports btn_step]
set_property IOSTANDARD LVCMOS33 [get_ports btn_step]

# ----------------------------------------------------------------
# Slide switches SW0-SW3 -> sw_phys[0]-sw_phys[3]
#   sw_phys[3] = demo FSM enable (SW3, leftmost of the four)
# ----------------------------------------------------------------
set_property PACKAGE_PIN V17 [get_ports {sw_phys[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_phys[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw_phys[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_phys[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw_phys[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_phys[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw_phys[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_phys[3]}]

# ----------------------------------------------------------------
# LEDs LD0-LD15 -> led_phys[0]-led_phys[15]
#   led_phys[3:0]  = FSM state
#   led_phys[4]    = ALU Zero flag
#   led_phys[15:5] = alu_result[10:0]
# ----------------------------------------------------------------
set_property PACKAGE_PIN U16 [get_ports {led_phys[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[0]}]
set_property PACKAGE_PIN E19 [get_ports {led_phys[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[1]}]
set_property PACKAGE_PIN U19 [get_ports {led_phys[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[2]}]
set_property PACKAGE_PIN V19 [get_ports {led_phys[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[3]}]
set_property PACKAGE_PIN W18 [get_ports {led_phys[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[4]}]
set_property PACKAGE_PIN U15 [get_ports {led_phys[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[5]}]
set_property PACKAGE_PIN U14 [get_ports {led_phys[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[6]}]
set_property PACKAGE_PIN V14 [get_ports {led_phys[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[7]}]
set_property PACKAGE_PIN V13 [get_ports {led_phys[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[8]}]
set_property PACKAGE_PIN V3  [get_ports {led_phys[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[9]}]
set_property PACKAGE_PIN W3  [get_ports {led_phys[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[10]}]
set_property PACKAGE_PIN U3  [get_ports {led_phys[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[11]}]
set_property PACKAGE_PIN P3  [get_ports {led_phys[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[12]}]
set_property PACKAGE_PIN N3  [get_ports {led_phys[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[13]}]
set_property PACKAGE_PIN P1  [get_ports {led_phys[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[14]}]
set_property PACKAGE_PIN L1  [get_ports {led_phys[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_phys[15]}]

# ----------------------------------------------------------------
# 7-Segment cathodes seg[6:0]  (active low)
#   seg[0]=a  seg[1]=b  seg[2]=c  seg[3]=d
#   seg[4]=e  seg[5]=f  seg[6]=g
# ----------------------------------------------------------------
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

# ----------------------------------------------------------------
# 7-Segment anodes an[3:0]  (active low)
#   an[0]=rightmost digit   an[3]=leftmost digit
# ----------------------------------------------------------------
set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]
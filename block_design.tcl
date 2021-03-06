source $board_path/config/ports.tcl

# Add PS and AXI Interconnect
set board_preset $board_path/config/board_preset.tcl
source $sdk_path/fpga/lib/starting_point.tcl

# Add ADCs and DACs
source $sdk_path/fpga/lib/redp_adc_dac.tcl
set adc_dac_name adc_dac
add_redp_adc_dac $adc_dac_name

# Add processor system reset synchronous to adc clock
set adc_clk $adc_dac_name/adc_clk
set rst_adc_clk_name proc_sys_reset_adc_clk

cell xilinx.com:ip:proc_sys_reset:5.0 $rst_adc_clk_name {} {
  ext_reset_in $ps_name/FCLK_RESET0_N
  slowest_sync_clk $adc_clk
}

# Add config and status registers
source $sdk_path/fpga/lib/ctl_sts.tcl
add_ctl_sts $adc_clk $rst_adc_clk_name/peripheral_aresetn

# Add boxcar filter
set filter_name boxcar_filter
cell koheron:user:boxcar_filter:1.0 $filter_name { DATA_WIDTH 14 } {
    clk $adc_clk
    din adc_dac/adc1
    dout adc_dac/dac2
}

# Connect LEDs
connect_port_pin led_o [get_slice_pin [ctl_pin led] 7 0]

# Connect DAC to config and ADC to status
# for {set i 0} {$i < [get_parameter n_adc]} {incr i} {
#   connect_pins [ctl_pin dac$i] adc_dac/dac[expr $i+1]
#   connect_pins [sts_pin adc$i] adc_dac/adc[expr $i+1]
# }
connect_pins [sts_pin adc0] adc_dac/adc1
connect_pins [sts_pin adc1] adc_dac/adc2

# Loop ADC2 back to DAC1 to compare filtered and unfiltered
connect_pins adc_dac/adc2 adc_dac/dac1

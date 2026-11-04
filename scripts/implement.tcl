# Direct, single-process flow avoids the TD prompt executable's run.bat launcher.
import_device ph1_35p.db -package PH1P35MDG324 -speed 3
open_project basic_sc520.al -single_run
elaborate -top design_top_wrapper
read_adc ../user_source/constraints_source/pin.adc
read_ip_adc -ip ddr2 -file ../user_source/hdl_source/ph1p35_ddr/ddr2/src/adc/ddr2.adc
read_sdc basic_sc520.sdc
read_sdc -ip ddr2 ../user_source/hdl_source/ph1p35_ddr/ddr2/src/sdc/ddr2.sdc
read_sdc -ip w128_d512_fifo ../user_source/ip_source/w128_d512_fifo/w128_d512_fifo.tcl
optimize_rtl
report_area -file basic_sc520_rtl.area
optimize_gate -packarea basic_sc520_gate.area
legalize_phy_inst
export_db basic_sc520_gate.db
set v23_place_start [clock milliseconds]
place
puts "V23_PLACE_MS [expr {[clock milliseconds]-$v23_place_start}]"
report_area -io_info -file basic_sc520_phy.area
export_db basic_sc520_place.db
set v23_area_file [open basic_sc520_phy.area r]
set v23_area [read $v23_area_file]
close $v23_area_file
if {![regexp -line {^\s*#slice\*?\s+([0-9]+)} $v23_area -> v23_slice]} {error "No placed slice count"}
if {![regexp -line {^\s*#eram20k\s+([0-9]+)} $v23_area -> v23_eram]} {error "No placed ERAM count"}
puts "V23_PREFLIGHT slice=$v23_slice eram=$v23_eram"
if {$v23_slice>21000 || $v23_eram>108} {error "Resource preflight failed before routing"}
set v23_route_start [clock milliseconds]
route
puts "V23_ROUTE_MS [expr {[clock milliseconds]-$v23_route_start}]"
update_timing -mode final
report_timing_status -file basic_sc520_phy.ts
report_timing_summary -file basic_sc520_pr.timing
report_timing_exception -file basic_sc520_exception.timing
report_timing_ignored -file basic_sc520_ignored.timing
report_clock_utilization -file basic_sc520_clock_utilization.txt
export_db basic_sc520_pr.db
bitgen -bit basic_sc520.bit -bin basic_sc520.bin -compress
puts "BASIC_BUILD_FINISHED"

exit

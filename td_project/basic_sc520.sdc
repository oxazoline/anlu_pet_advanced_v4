create_clock -name {sys_clk_50m} -period 20.000 -waveform {0.000 10.000} [get_ports {I_sys_clk}]
create_clock -name {mipi_rx_ck_pad} -period 2.415 -waveform {0.000 1.208} [get_nets {IO_rx_clk_pad_p}]

derive_clocks

rename_clock -name {pll_clk_100m} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[0]}]
rename_clock -name {pll_clk_24m} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[1]}]
rename_clock -name {HDMI_PIXEL_CLK} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[4]}]
rename_clock -name {HDMI_SERIAL_CLK} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[5]}]

rename_clock -name {MIPI_RX_BYTE_CLK} [get_clocks {u_mipi_dphy_rx_ph1p_mipiio_wrapper/u_ph1p_mipiio_rx_wrapper/u_PH1P_LOGIC_DPHY_MIPI_RX.o_fabric_div4_8_clk}]


set_clock_groups -asynchronous \
    -group [get_clocks {mipi_rx_ck_pad MIPI_RX_BYTE_CLK}] \
    -group [get_clocks {sys_clk_50m pll_clk_100m pll_clk_24m HDMI_PIXEL_CLK HDMI_SERIAL_CLK}] \
    -group [get_clocks {u_ph1p35_324_ddr_wrapper/u_ddr2/ddr_clk u_ph1p35_324_ddr_wrapper/u_ddr2/usr_clk}]

# Registered status bits cross into two-flop synchronizers. Only the first
# receiving stage is excluded; second-stage and downstream timing stay checked.
set_false_path -to [get_regs {*fault_sync1*}]
set_false_path -to [get_regs {*u_display_startup/camera_meta*}]
set_false_path -to [get_regs {*u_display_startup/ddr_meta*}]
# Diagnostic CDC first stages only; Gray source counters are registered.
set_false_path -to [get_regs {*u_diag_*/run_meta*}]
set_false_path -to [get_regs {*u_diag_*/boot_meta*}]
set_false_path -to [get_regs {*u_diag_*/count_meta*}]
set_false_path -to [get_regs {*u_video_out/fifo_reset_meta*}]
set_false_path -to [get_regs {*u_video_in/fifo_reset_meta*}]
set_false_path -to [get_regs {*u_uicfgcs520/bus_error_meta*}]
set_false_path -to [get_regs {*error_addr_meta*}]
set_false_path -to [get_regs {*readback_meta*}]

ext_expression_preview u_expression_preview(
        .I_src_clk(S_csi_rx_clk),.I_dst_clk(S_hdmi_pixel_clk),.I_rst_n(S_rst_n),
        .I_write(patch_write),.I_write_address(patch_address),.I_pixel(patch_pixel),
        .I_commit(patch_commit),.I_patch_id(patch_id),.I_vs(S_hdmi_out_vsync),
        .I_read_address(preview_address),.O_gray(preview_gray),.O_valid(preview_valid),.O_patch_id(preview_id)
    );
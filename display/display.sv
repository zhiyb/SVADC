module display #(parameter AN, DN, BASE, SWAP,
`ifdef MODEL_TECH
	W = 16, H = 4
`else
	W = 800, H = 480
`endif
) (
	input logic clkSYS, clkSmpl, n_reset,
	input logic [9:0] smpl_data,

	// Display buffer swap
	output logic swap,
	input logic stat,

	// System interface
	arbiter_if sys
);

arbiter_if #(AN, DN, 2) mem ();
assign sys.addr = mem.addr;
assign sys.data = mem.data;
assign sys.req = mem.req;
assign sys.wr = 1'b1;
assign mem.ack = sys.ack;
assign mem.valid = 1'b0;
assign mem.mem = 0;

arbiter_if #(AN, DN, 2) arb[4] ();
arbiter_sync_pri #(AN, DN, 2) arb0 (clkSYS, n_reset, mem, 2'h0, arb);

assign arb[0].req = 1'b0;

logic smpl_start, smpl_done;
disp_samples #(AN, DN, BASE, SWAP, W, H) smpl0 (clkSYS, clkSmpl, n_reset,
	smpl_start, smpl_done, ~stat, arb[1], smpl_data);

logic test_start, test_done;
disp_test_lines #(AN, DN, BASE, SWAP, W, H) test0 (clkSYS, n_reset,
	test_start, test_done, ~stat, arb[2]);

logic bg_start, bg_done;
disp_background #(AN, DN, BASE, SWAP, W, H) bg0 (clkSYS, n_reset,
	bg_start, bg_done, ~stat, arb[3]);

logic swap_start, swap_done;
disp_swap swap0 (clkSYS, n_reset, swap_start, swap_done, stat, swap);

enum int unsigned {Swap, Background, Test, Samples} state;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		state <= Swap;
	else if (state == Swap) begin
		if (swap_done)
			state <= Background;
	end else if (state == Background) begin
		if (bg_done)
`ifndef MODEL_TECH
			state <= Test;
	end else if (state == Test) begin
		if (test_done)
`endif
			state <= Samples;
	end else if (state == Samples) begin
		if (smpl_done)
			state <= Swap;
	end else
		state <= Swap;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset) begin
		bg_start <= 1'b0;
		test_start <= 1'b0;
		smpl_start <= 1'b0;
	end else begin
		bg_start <= state == Swap && swap_done;
`ifdef MODEL_TECH
		smpl_start <= state == Background && bg_done;
`else
		test_start <= state == Background && bg_done;
		smpl_start <= state == Test && test_done;
`endif
	end

assign swap_start = state == Samples && smpl_done;

endmodule

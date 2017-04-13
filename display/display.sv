module display #(parameter AN, DN, BASE, SWAP,
`ifdef MODEL_TECH
	W = 16, H = 2
`else
	W = 800, H = 480
`endif
) (
	input logic clkSYS, clkSmpl, n_reset,
	input logic [9:0] in_data,

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

logic bg_start, bg_done;
disp_background #(AN, DN, BASE, SWAP, W, H) disp0 (clkSYS, n_reset, bg_start, bg_done, ~stat, arb[0]);

assign arb[1].req = 1'b0;
assign arb[2].req = 1'b0;

logic test_start, test_done;
disp_test_lines #(AN, DN, BASE, SWAP, W, H) disp3 (clkSYS, n_reset, test_start, test_done, ~stat, arb[3]);

logic swap_start, swap_done;
disp_swap swap0 (clkSYS, n_reset, swap_start, swap_done, stat, swap);

enum int unsigned {Swap, Background, Test} state;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		state <= Swap;
	else if (state == Swap) begin
		if (swap_done)
			state <= Background;
	end else if (state == Background) begin
		if (bg_done)
			state <= Test;
	end else if (state == Test) begin
		if (test_done)
			state <= Swap;
	end else
		state <= Swap;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset) begin
		bg_start <= 1'b0;
		test_start <= 1'b0;
	end else begin
		bg_start <= state == Swap && swap_done;
		test_start <= state == Background && bg_done;
	end

assign swap_start = state == Test && test_done;

endmodule

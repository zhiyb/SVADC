module display #(parameter AN, DN, BASE, SWAP, FFT,
`ifdef MODEL_TECH
	W = 64, H = 4
`else
	W = 800, H = 480
`endif
) (
	input logic clkSYS, clkSmpl, n_reset,

	// Data samples and FFT
	input logic [9:0] smpl,
	input logic fft_avail,
	output logic fft_shift,
	input logic [9:0] fft,

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

logic fft_start, fft_done;
disp_samples_sparse #(AN, DN, BASE, SWAP, FFT, W, H) fft0 (
	clkSYS, clkSmpl, n_reset,
	fft_start, fft_done, ~stat, arb[0], fft_avail, fft_shift, fft);

logic smpl_start, smpl_done;
disp_samples #(AN, DN, BASE, SWAP, W, H) smpl0 (clkSYS, clkSmpl, n_reset,
	smpl_start, smpl_done, ~stat, arb[1], smpl);

logic test_start, test_done;
disp_test_lines #(AN, DN, BASE, SWAP, W, H) test0 (clkSYS, n_reset,
	test_start, test_done, ~stat, arb[2]);

logic bg_start, bg_done;
disp_background #(AN, DN, BASE, SWAP, W, H) bg0 (clkSYS, n_reset,
	bg_start, bg_done, ~stat, arb[3]);

logic swap_start, swap_done;
disp_swap swap0 (clkSYS, n_reset, swap_start, swap_done, stat, swap);

enum int unsigned {Swap, Background, Test, Samples, FFTDisp} state;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		state <= Swap;
	else if (state == Swap) begin
		if (swap_done)
			state <= Background;
	end else if (state == Background) begin
		if (bg_done)
`ifndef MODEL_TECH
`ifdef TEST
			state <= Test;
	end else if (state == Test) begin
		if (test_done)
`endif
			state <= Samples;
	end else if (state == Samples) begin
		if (smpl_done)
`endif
			state <= FFTDisp;
	end else if (state == FFTDisp) begin
		if (fft_done)
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
`ifdef TEST
		test_start <= state == Background && bg_done;
		smpl_start <= state == Test && test_done;
`else
		smpl_start <= state == Background && bg_done;
`endif
`ifdef MODEL_TECH
		fft_start <= state == Background && bg_done;
`else
		fft_start <= state == Samples && smpl_done;
`endif
	end

assign swap_start = state == FFTDisp && fft_done;

endmodule

module display #(parameter AN, DN, FFTN, BASE, SWAP, FFT,
`ifdef MODEL_TECH
	W = 64, H = 4
`else
	W = 800, H = 480
`endif
) (
	input logic clkSYS, clkRAW, clkSmpl, n_reset,

	// Data samples and FFT
	input logic [9:0] raw, smpl,
	input logic fft_valid,
	output logic fft_req,
	input logic [FFTN - 1:0] fft,

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
disp_samples_sparse #(AN, DN, FFTN, BASE, SWAP, FFT, W, H) fft0 (
	clkSYS, clkSmpl, n_reset,
	fft_start, fft_done, ~stat, arb[0], fft_valid, fft_req, fft);

logic smpl_start, smpl_done;
disp_samples #(AN, DN, BASE, SWAP, W, H, 16'h07e0) smpl0 (clkSYS, clkSmpl,
	n_reset, smpl_start, smpl_done, ~stat, arb[1], smpl);

logic raw_start, raw_done;
disp_samples #(AN, DN, BASE, SWAP, W, H, 16'hf800) smpl1 (clkSYS, clkRAW,
	n_reset, raw_start, raw_done, ~stat, arb[2], raw);

logic bg_start, bg_done;
disp_background #(AN, DN, BASE, SWAP, W, H) bg0 (clkSYS, n_reset,
	bg_start, bg_done, ~stat, arb[3]);

logic swap_start, swap_done;
disp_swap swap0 (clkSYS, n_reset, swap_start, swap_done, stat, swap);

enum int unsigned {Swap, Background, Raw, Samples, FFTDisp} state;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		state <= Swap;
	else if (state == Swap) begin
		if (swap_done)
			state <= Background;
	end else if (state == Background) begin
		if (bg_done)
			state <= Raw;
	end else if (state == Raw) begin
		if (raw_done)
			state <= Samples;
	end else if (state == Samples) begin
		if (smpl_done)
			state <= FFTDisp;
	end else if (state == FFTDisp) begin
		if (fft_done)
			state <= Swap;
	end else
		state <= Swap;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset) begin
		bg_start <= 1'b0;
		smpl_start <= 1'b0;
	end else begin
		bg_start <= state == Swap && swap_done;
		raw_start <= state == Background && bg_done;
		smpl_start <= state == Raw && raw_done;
		fft_start <= state == Samples && smpl_done;
	end

assign swap_start = state == FFTDisp && fft_done;

endmodule

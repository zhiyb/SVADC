module fft #(parameter SN, RN, FRAC, SIZE, DIV) (
	input logic clk, n_reset,
	input logic [SN - 1:0] smpl,

	output logic valid,
	input logic start,
	output logic [RN - 1:0] fft_data
);

logic req, uactive, uvalid;
logic [RN - 1:0] in[2], out[2];
fft_dit2 #(SIZE * 2, RN, FRAC) fft0 (clk, n_reset,
	in, req, uactive, uvalid, out);

// Rectangular window
assign in = '{{{RN - FRAC{~smpl[SN - 1]}}, smpl[SN - 2 -: FRAC]}, 0};

always_ff @(posedge clk)
	fft_data <= (out[0][RN - 1] ? -out[0] : out[0]) +
		(out[1][RN - 1] ? -out[1] : out[1]);

enum int unsigned {Idle, Waiting, Inactive, Active} state;
always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		state <= Idle;
	else if (state == Idle) begin
		if (start)
			state <= Waiting;
	end else if (state == Waiting) begin
		if (~uactive)
			state <= Inactive;
	end else if (state == Inactive) begin
		if (uactive)
			state <= Active;
	end else if (state == Active) begin
		if (~uactive)
			state <= Idle;
	end

always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		valid <= 1'b0;
	else
		valid <= state == Active && uvalid;

endmodule

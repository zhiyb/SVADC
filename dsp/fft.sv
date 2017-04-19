module fft #(parameter SN, RN, FRAC, SIZE) (
	input logic clk, n_reset,
	input logic [SN - 1:0] smpl[2],

	output logic valid,
	input logic request,
	output logic [RN - 1:0] fft_data
);

logic req, uactive, uvalid;
logic [RN - 1:0] in[2], out[2];
fft_dit2 #(SIZE, RN, FRAC) fft0 (clk, n_reset,
	in, req, uactive, uvalid, out);

// Rectangular window
assign in[0] = {{RN - FRAC{smpl[0][SN - 1]}}, smpl[0][SN - 2 -: FRAC]};
assign in[1] = {{RN - FRAC{smpl[1][SN - 1]}}, smpl[1][SN - 2 -: FRAC]};

always_ff @(posedge clk)
	fft_data <= (out[0][RN - 1] ? -out[0] : out[0]) +
		(out[1][RN - 1] ? -out[1] : out[1]);

enum int unsigned {Waiting, Inactive, Active} state;
always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		state <= Waiting;
	else if (~request)
		state <= Waiting;
	else if (state == Waiting) begin
		if (~uactive)
			state <= Inactive;
	end else if (state == Inactive) begin
		if (uactive)
			state <= Active;
	end else if (state == Active) begin
		if (~uactive)
			state <= Waiting;
	end

always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		valid <= 1'b0;
	else
		valid <= state == Active && uvalid;

endmodule

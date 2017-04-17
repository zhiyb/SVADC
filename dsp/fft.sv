module fft #(parameter SN, RN, FRAC, SIZE, DIV) (
	input logic clk, n_reset,
	input logic [SN - 1:0] smpl,

	output logic valid,
	input logic start,
	output logic [RN - 1:0] fft_data
);

logic [RN - 1:0] w[SIZE * 2];
generate
case (SIZE * 2)
8:	assign w = '{
`include "fft_data/window_bh_8.sv"
	};
16:	assign w = '{
`include "fft_data/window_bh_16.sv"
	};
32:	assign w = '{
`include "fft_data/window_bh_32.sv"
	};
64:	assign w = '{
`include "fft_data/window_bh_64.sv"
	};
128:	assign w = '{
`include "fft_data/window_bh_128.sv"
	};
256:	assign w = '{
`include "fft_data/window_bh_256.sv"
	};
512:	assign w = '{
`include "fft_data/window_bh_512.sv"
	};
1024:	assign w = '{
`include "fft_data/window_bh_1024.sv"
	};
2048:	assign w = '{
`include "fft_data/window_bh_2048.sv"
	};
endcase
endgenerate

logic req, uactive, uvalid;
logic [RN - 1:0] in[SIZE * 2][2], out[2];
fft_dit2 #(SIZE * 2, RN, FRAC) fft0 (clk, n_reset, in, req, uactive, uvalid, out);

logic [RN - 1:0] data[SIZE * 2];
always_ff @(posedge clk)
begin
	data[0] <= {{RN - FRAC{~smpl[SN - 1]}}, smpl[SN - 2 -: FRAC]};
	for (int i = 1; i != SIZE * 2; i++)
		data[i] <= data[i - 1];
end

always_ff @(posedge clk)
	if (~req)
		for (int i = 0; i != SIZE * 2; i++)
			// Rectangular window
			in[i] = '{data[i], 0};
			// Blackman-Harris window
			//in[i] = '{signed'((int'(signed'(data[i])) * int'(signed'(w[i]))) >>> FRAC), 0};

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

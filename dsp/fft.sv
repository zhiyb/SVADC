module fft #(parameter SN, RN, FRAC, SIZE, DIV) (
	input logic clk,
	input logic [SN - 1:0] smpl,

	input logic shift,
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
endcase
endgenerate

logic [RN - 1:0] in[SIZE * 2][2], out[SIZE * 2][2];
fft_dit2 #(SIZE * 2, RN, FRAC) fft0 (clk, n_reset, in, out);

logic [RN - 1:0] data[SIZE * 2];
always_ff @(posedge clk)
begin
	data[0] <= (smpl - {1'b1, {SN - 1{1'b0}}}) >> FRAC;
	for (int i = 1; i != SIZE * 2; i++)
		data[i] <= data[i - 1];
end

always_comb
	for (int i = 0; i != SIZE * 2; i++)
		in[i] = '{(signed'(data[i]) * signed'(w[i])) >> FRAC, 0};

logic [RN - 1:0] data_latch[SIZE][2];
always_ff @(posedge clk)
	if (shift)
		for (int i = 1; i != SIZE; i++)
			data_latch[i - 1] <= data_latch[i];
	else
		for (int i = 0; i != SIZE; i++) begin
			data_latch[i][0] <=
				out[i][0][RN - 1] ? -out[i][0] : out[i][0];
			data_latch[i][1] <=
				out[i][1][RN - 1] ? -out[i][1] : out[i][1];
		end

always_ff @(posedge clk)
begin
	fft_data <= data_latch[0][0] + data_latch[0][1];
end

endmodule

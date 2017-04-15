// Size of DFF unit, result number of bits, fraction bits
module fft_dit2 #(parameter SIZE, RN, FRAC) (
	input logic clk, n_reset,
	input logic [RN - 1:0] in[SIZE][2],
	output logic [RN - 1:0] out[SIZE][2]
);

logic [RN - 1:0] e[SIZE / 2][2], o[SIZE / 2][2];

genvar i;
generate
if (SIZE > 2) begin
	logic [RN - 1:0] x[2][SIZE / 2][2];
	fft_dit2 #(SIZE / 2, RN, FRAC) u0 (clk, n_reset, x[0], e);
	fft_dit2 #(SIZE / 2, RN, FRAC) u1 (clk, n_reset, x[1], o);

	for (i = 0; i != SIZE / 2; i++) begin: asgn
		assign x[0][i] = in[i * 2];
		assign x[1][i] = in[i * 2 + 1];
	end
end else begin
	always_ff @(posedge clk)
	begin
		e[0] <= in[0];
		o[0] <= in[1];
	end
end
endgenerate

logic [RN - 1:0] exp[SIZE / 2][2];
generate
case (SIZE / 2)
1:	assign exp = '{
`include "fft_data/exp1.sv"
	};
2:	assign exp = '{
`include "fft_data/exp2.sv"
	};
4:	assign exp = '{
`include "fft_data/exp4.sv"
	};
8:	assign exp = '{
`include "fft_data/exp8.sv"
	};
16:	assign exp = '{
`include "fft_data/exp16.sv"
	};
32:	assign exp = '{
`include "fft_data/exp32.sv"
	};
endcase

for (i = 0; i != SIZE / 2; i++) begin: mult
	logic [RN - 1:0] w[2];
	assign w[0] = signed'((int'(signed'(o[i][0])) * int'(signed'(exp[i][0])) -
		int'(signed'(o[i][1])) * int'(signed'(exp[i][1]))) >>> FRAC);
	assign w[1] = signed'((int'(signed'(o[i][0])) * int'(signed'(exp[i][1])) +
		int'(signed'(o[i][1])) * int'(signed'(exp[i][0]))) >>> FRAC);

	always_ff @(posedge clk)
	begin
		out[i][0] <= e[i][0] + w[0];
		out[i][1] <= e[i][1] + w[1];
		out[i + SIZE / 2][0] <= e[i][0] - w[0];
		out[i + SIZE / 2][1] <= e[i][1] - w[1];
	end
end
endgenerate

endmodule

// Size of DFF unit, result number of bits, fraction bits
module fft_dit2 #(parameter SIZE, RN, FRAC) (
	input logic clk, n_reset,
	input logic [RN - 1:0] in[SIZE][2],
	output logic done,
	output logic [RN - 1:0] out[2]
);

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
64:	assign exp = '{
`include "fft_data/exp64.sv"
	};
endcase
endgenerate

logic [RN - 1:0] x[2][SIZE / 2][2];
genvar i;
generate
for (i = 0; i != SIZE / 2; i++) begin: mult
	assign x[0][i] = in[i * 2];
	assign x[1][i] = in[i * 2 + 1];
end
endgenerate

logic [$clog2(SIZE) - 1:0] sel;
always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		sel <= -$clog2(SIZE / 2);
	else
		sel <= sel + 1;

always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		done <= 1'b0;
	else
		done <= sel == 0;

logic section;
logic [RN - 1:0] e[2], o[2], w[2];
generate
if (SIZE > 2) begin
	logic [$clog2(SIZE) - 2:0] select;
	assign {section, select} = sel;

	fft_dit2 #(SIZE / 2, RN, FRAC) u0 (clk, n_reset, x[0], , e);
	fft_dit2 #(SIZE / 2, RN, FRAC) u1 (clk, n_reset, x[1], , o);

	assign w[0] = signed'((int'(signed'(o[0])) * int'(signed'(exp[select][0])) -
		int'(signed'(o[1])) * int'(signed'(exp[select][1]))) >>> FRAC);
	assign w[1] = signed'((int'(signed'(o[0])) * int'(signed'(exp[select][1])) +
		int'(signed'(o[1])) * int'(signed'(exp[select][0]))) >>> FRAC);
end else begin
	assign section = sel;
	assign e = x[0][0];
	assign o = x[1][0];
	assign w[0] = signed'((int'(signed'(o[0])) * int'(signed'(exp[0][0])) -
		int'(signed'(o[1])) * int'(signed'(exp[0][1]))) >>> FRAC);
	assign w[1] = signed'((int'(signed'(o[0])) * int'(signed'(exp[0][1])) +
		int'(signed'(o[1])) * int'(signed'(exp[0][0]))) >>> FRAC);
end
endgenerate

always_ff @(posedge clk)
	if (~section)
		out <= '{e[0] + w[0], e[1] + w[1]};
	else
		out <= '{e[0] - w[0], e[1] - w[1]};

endmodule

// Size of DFF unit, result number of bits, fraction bits
module fft_dit2 #(parameter SIZE, RN, FRAC) (
	input logic clk, n_reset,
	input logic [RN - 1:0] in[SIZE][2],
	output logic done,
	output logic [RN - 1:0] out[SIZE][2]
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

genvar i;
generate
if (SIZE > 4) begin
	logic swap, udone;
	logic [RN - 1:0] ui[SIZE / 2][2], uo[SIZE / 2][2];
	fft_dit2 #(SIZE / 2, RN, FRAC) u0 (clk, n_reset, ui, udone, uo);

	always_ff @(posedge clk, negedge n_reset)
		if (~n_reset)
			swap <= 1'b0;
		else if (udone)
			swap <= ~swap;

	for (i = 0; i != SIZE / 2; i++) begin: mult
		assign ui[i] = swap ? in[i * 2 + 1] : in[i * 2];

		logic [RN - 1:0] w[2];
		assign w[0] = signed'((int'(signed'(uo[i][0])) * int'(signed'(exp[i][0])) -
			int'(signed'(uo[i][1])) * int'(signed'(exp[i][1]))) >>> FRAC);
		assign w[1] = signed'((int'(signed'(uo[i][0])) * int'(signed'(exp[i][1])) +
			int'(signed'(uo[i][1])) * int'(signed'(exp[i][0]))) >>> FRAC);

		always_ff @(posedge clk)
		begin
			if (udone) begin
				if (swap) begin
					out[i][0] <= out[i][0] + w[0];
					out[i][1] <= out[i][1] + w[1];
					out[i + SIZE / 2][0] <= out[i][0] - w[0];
					out[i + SIZE / 2][1] <= out[i][1] - w[1];
				end else begin
					out[i][0] <= uo[i][0];
					out[i][1] <= uo[i][1];
					out[i + SIZE / 2][0] <= uo[i][0];
					out[i + SIZE / 2][1] <= uo[i][1];
				end
			end
		end
	end

	always_ff @(posedge clk, negedge n_reset)
		if (~n_reset)
			done <= 1'b0;
		else
			done <= udone && swap;
end else if (SIZE > 2) begin
	logic udone;
	logic [RN - 1:0] x[2][SIZE / 2][2];
	logic [RN - 1:0] e[SIZE / 2][2], o[SIZE / 2][2];
	fft_dit2 #(SIZE / 2, RN, FRAC) u0 (clk, n_reset, x[0], udone, e);
	fft_dit2 #(SIZE / 2, RN, FRAC) u1 (clk, n_reset, x[1], , o);

	for (i = 0; i != SIZE / 2; i++) begin: mult
		assign x[0][i] = in[i * 2];
		assign x[1][i] = in[i * 2 + 1];

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

	logic unit_done;
	always_ff @(posedge clk, negedge n_reset)
		if (~n_reset) begin
			unit_done <= 1'b0;
			done <= 1'b0;
		end else begin
			unit_done <= udone;
			done <= unit_done;
		end
end else begin
	logic [RN - 1:0] e[SIZE / 2][2], o[SIZE / 2][2];
	assign e[0] = in[0];
	assign o[0] = in[1];

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

	always_ff @(posedge clk, negedge n_reset)
		if (~n_reset)
			done <= 1'b0;
		else
			done <= ~done;
end
endgenerate

endmodule

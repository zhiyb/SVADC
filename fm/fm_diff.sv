module fm_diff #(parameter N) (
	input logic clk, n_reset,
	input logic signed [N - 1:0] d[2],
	output logic signed [N - 1:0] q[2]
);

localparam taps = 9;
logic signed [9:0] coeff[taps] = '{
`include "data/diffcoeff.sv"
};

logic signed [N - 1:0] hm[taps][2], z[2][taps + 1][2];
localparam shift = 9;
genvar i;
generate
for (i = 0; i < taps; i++) begin: tap
	assign hm[i][0] = (int'(coeff[i]) * int'(d[0])) >>> shift;
	assign hm[i][1] = (int'(coeff[i]) * int'(d[1])) >>> shift;

	always_ff @(posedge clk, negedge n_reset)
		if (~n_reset) begin
			z[0][i + 1][0] <= 0;
			z[0][i + 1][1] <= 0;
			z[1][i + 1][0] <= 0;
			z[1][i + 1][1] <= 0;
		end else begin
			z[0][i + 1][0] <= z[0][i][0] + hm[i][0];
			z[0][i + 1][1] <= z[0][i][1] + hm[i][1];
			z[1][i + 1][0] <= z[1][i][0] + hm[taps - 1 - i][0];
			z[1][i + 1][1] <= z[1][i][1] + hm[taps - 1 - i][1];
		end
end
endgenerate

assign z[0][0][0] = 0;
assign z[0][0][1] = 0;
always_ff @(posedge clk, negedge n_reset)
	if (~n_reset) begin
		z[1][0][0] <= 0;
		z[1][0][1] <= 0;
	end else begin
		z[1][0][0] <= -z[0][taps][0];
		z[1][0][1] <= -z[0][taps][1];
	end

assign q = z[1][taps];

endmodule

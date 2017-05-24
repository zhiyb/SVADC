module fm_demod #(parameter N) (
	input logic clk, n_reset,
	input logic signed [N - 1:0] d[2],
	output logic signed [N - 1:0] q
);

logic signed [N - 1:0] diff[2];
fm_diff #(10) (clk, n_reset, d, diff);

logic signed [N - 1:0] conj[2];
always_ff @(posedge clk, negedge n_reset)
	if (~n_reset) begin
		conj[0] <= 0;
		conj[1] <= 0;
	end else begin
		conj[0] <= d[0];
		conj[1] <= -d[1];
	end

assign q = diff[0];

endmodule

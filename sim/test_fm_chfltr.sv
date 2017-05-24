`timescale 1 ps / 1 ps

module test_fm_chfltr;

logic n_reset;
initial
begin
	n_reset = 0;
	#20ns n_reset = 1;
end

logic clk;
initial
begin
	clk = 1'b0;
	forever #10ns clk = ~clk;
end

logic clkout;
logic signed [8:0] d[2], q[2];
fm_chfltr #(.N(9)) fm0 (.*);

always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		d[0] <= 0;
	else
		d[0] <= d[0] + 1;

assign d[1] = ~d[0];

endmodule

module fm #(parameter N) (
	input logic clk, n_reset,
	input logic signed [N - 1:0] d,
	output logic clkFM,
	output logic signed [N - 1:0] q[2]
);

logic signed [N - 1:0] mix[2], ch[2], demod;
fm_mixer #(10) mix0 (clk, n_reset, d, mix);
fm_chfltr #(10) (clk, n_reset, mix, clkFM, ch);
fm_demod #(10) (clkFM, n_reset, ch, demod);

assign q = demod;

endmodule

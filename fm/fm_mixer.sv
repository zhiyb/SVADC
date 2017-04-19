module fm_mixer #(parameter N) (
	input logic clk, n_reset,

	input logic [N - 1:0] in,
	output logic [N - 1:0] out[2]
);

logic [9:0] addr;
logic [N * 2 - 1:0] rom;
rom_fm_exp rom0 (addr, clk, rom);

always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		addr <= 0;
	else if (addr == 799)
		addr <= 0;
	else
		addr <= addr + 1;

logic signed [N - 1:0] data;
assign data = {~in[N - 1], in[N - 2:0]};

logic signed [N - 1:0] exp[2];
assign {exp[1], exp[0]} = rom;

always_ff @(posedge clk)
begin
	out[0] <= signed'((int'(data) * int'(exp[0])) >>> (N - 1));
	out[1] <= signed'((int'(data) * int'(exp[1])) >>> (N - 1));
end

endmodule

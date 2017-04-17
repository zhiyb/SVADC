module wavegen_sin #(parameter N = 4, SN = 5) (
	input logic clk, n_reset,
	output logic pwm
);

logic [SN - 1:0] addr;
logic [N - 1:0] rom;
rom_sin_4_5 rom0 (addr, clk, rom);

logic [N - 1:0] cnt;
always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		cnt <= 0;
	else
		cnt <= cnt + 1;

always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		addr <= 0;
	else if (cnt == {{N - 2{1'b1}}, 2'b01})
		addr <= addr + 1;

logic match, reload;
always_ff @(posedge clk)
begin
	match <= cnt == rom;
	reload <= cnt == 0;
end

always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		pwm <= 1'b0;
	else if (match)
		pwm <= 1'b0;
	else if (reload)
		pwm <= 1'b1;

endmodule

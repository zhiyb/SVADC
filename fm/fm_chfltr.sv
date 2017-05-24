module fm_chfltr #(parameter N) (
	input logic clk, n_reset,
	input logic signed [N - 1:0] d[2],
	output logic clkout,
	output logic signed [N - 1:0] q[2]	// 0: real, 1: imaginary
);

logic [7:0] cnt;
always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		cnt <= 0;
	else if (cnt == 0)
		cnt <= 199;
	else
		cnt <= cnt - 1;

always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		clkout <= 0;
	else if (cnt == 0)
		clkout <= 1;
	else if (cnt == 100)
		clkout <= 0;

logic [1:0] update;
always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		update <= 0;
	else
		update <= {update[0], cnt == 0};

logic [7:0] addr;
logic signed [8:0] rom[6];
assign addr = cnt;
rom_fm_chfltr_1 rom1 (addr, clk, rom[0]);
rom_fm_chfltr_2 rom2 (addr, clk, rom[1]);
rom_fm_chfltr_3 rom3 (addr, clk, rom[2]);
rom_fm_chfltr_4 rom4 (addr, clk, rom[3]);
rom_fm_chfltr_5 rom5 (addr, clk, rom[4]);
rom_fm_chfltr_6 rom6 (addr, clk, rom[5]);

logic signed [N - 1:0] um[6][2];
logic signed [16:0] acc[6][2];
logic signed [N - 1:0] out[7][2];

localparam shift = 3;
genvar i;
generate
for (i = 0; i < 6; i++) begin: tap
	assign um[i][0] = (int'(rom[i]) * int'(d[0])) >>> (N - 1);
	assign um[i][1] = (int'(rom[i]) * int'(d[1])) >>> (N - 1);

	// Accumulator
	always_ff @(posedge clk, negedge n_reset)
		if (~n_reset) begin
			acc[i][0] <= 0;
			acc[i][1] <= 0;
		end else if (update[1]) begin
			acc[i][0] <= int'(um[i][0]);
			acc[i][1] <= int'(um[i][1]);
		end else begin
			acc[i][0] <= int'(um[i][0]) + acc[i][0];
			acc[i][1] <= int'(um[i][1]) + acc[i][1];
		end

	// Output chain
	always_ff @(posedge clk, negedge n_reset)
		if (~n_reset) begin
			out[i + 1][0] <= 0;
			out[i + 1][1] <= 0;
		end else if (update[1]) begin
			out[i + 1][0] <= out[i][0] + (acc[i][0] >> shift);
			out[i + 1][1] <= out[i][1] + (acc[i][1] >> shift);
		end
end
endgenerate

assign out[0][0] = 0;
assign out[0][1] = 0;
assign q[0] = int'(out[6][0]);
assign q[1] = int'(out[6][1]);

endmodule

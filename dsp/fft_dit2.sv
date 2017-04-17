// Size of DFF unit, result number of bits, fraction bits
module fft_dit2 #(parameter SIZE, RN, FRAC) (
	input logic clk, n_reset,
	input logic [RN - 1:0] in[2],
	output logic req, active, valid,
	output logic [RN - 1:0] out[2]
);

localparam RAM_AN = 10, RAM_DN = 32;
localparam ROM_AN = 9, ROM_DN = 14;

logic [ROM_AN - 1:0] eaddr;
logic [ROM_DN - 1:0] rom;
rom_exp rom0 (eaddr, clk, rom);

logic [RN - 1:0] exp[2];
assign exp = '{{{RN - ROM_DN / 2{rom[ROM_DN / 2 - 1]}}, rom[0 +: ROM_DN / 2]},
	{{RN - ROM_DN / 2{rom[ROM_DN - 1]}}, rom[ROM_DN / 2 +: ROM_DN / 2]}};

localparam SIZEN = $clog2(SIZE / 2);

logic delay;
logic [SIZEN - 1:0] sel;
always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		sel <= 0;
	else if (~delay)
		sel <= sel + 1;

logic next;
assign next = sel == {SIZEN{1'b1}};

logic reload;
always_ff @(posedge clk)
	if (~reload && next)
		delay <= 1'b1;
	else
		delay <= 1'b0;

assign req = reload && ~delay;

logic dir;
logic [SIZEN - 1:0] mask;
always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		{mask, reload} <= {SIZEN + 1{1'b1}};
	else if (reload && dir && next)
		{mask, reload} <= 0;
	else if (next)
		{mask, reload} <= {1'b1, mask};

always_ff @(posedge clk, negedge n_reset)
	if (~n_reset)
		dir <= 1'b0;
	else if (next)
		dir <= (~reload && mask[0]) ? 1'b0 : ~dir;

logic [SIZEN - 1:0] rev;
genvar i;
generate
for (i = 0; i != SIZEN; i++)  begin: reverse
	assign rev[i] = sel[SIZEN - 1 - i];
end
endgenerate

logic [SIZEN:0] rdaddr[2], wraddr[2];
assign rdaddr[0] = sel;
assign rdaddr[1] = sel | (SIZE / 2);

always_ff @(posedge clk)
begin
	wraddr[0] <= sel << 1;
	wraddr[1] <= (sel << 1) | 1;
end

struct {
	logic [RN - 1:0] d[2], q[2], w[2], o[2];
} sec[2];

struct {
	logic [RAM_AN - 1:0] addr[2];
	logic [RAM_DN - 1:0] d[2], q[2];
	logic wren[2];
} ram[2];

logic dir_latch;
always_ff @(posedge clk)
	if (reload)
		dir_latch <= 1'b0;
	else
		dir_latch <= dir;

assign eaddr = (rev & mask) << (ROM_AN - SIZEN);

generate
for (i = 0; i != 2; i++) begin: asgn
	ram_fft ram0 (ram[i].addr[0], ram[i].addr[1], clk,
		ram[i].d[0], ram[i].d[1], ram[i].wren[0], ram[i].wren[1],
		ram[i].q[0], ram[i].q[1]);

	assign ram[i].addr[0] = (~reload && ram[i].wren[0]) ? wraddr[0] : rdaddr[0];
	assign ram[i].addr[1] = (~reload && ram[i].wren[1]) ? wraddr[1] : rdaddr[1];
	assign sec[i].d = '{ram[dir_latch].q[i][0 +: RN], ram[dir_latch].q[i][RN +: RN]};

	assign sec[i].w = exp;
	assign sec[i].o[0] = signed'((int'(signed'(sec[i].d[0])) * int'(signed'(sec[i].w[0])) -
		int'(signed'(sec[i].d[1])) * int'(signed'(sec[i].w[1]))) >>> FRAC);
	assign sec[i].o[1] = signed'((int'(signed'(sec[i].d[0])) * int'(signed'(sec[i].w[1])) +
		int'(signed'(sec[i].d[1])) * int'(signed'(sec[i].w[0]))) >>> FRAC);
end
endgenerate

assign sec[0].q[0] = sec[0].d[0] + sec[1].o[0];
assign sec[0].q[1] = sec[0].d[1] + sec[1].o[1];
assign sec[1].q[0] = sec[0].d[0] - sec[1].o[0];
assign sec[1].q[1] = sec[0].d[1] - sec[1].o[1];

logic [RAM_DN - 1:0] ram_out_d[2];
assign ram_out_d[0] = {{RAM_DN - RN * 2{1'bx}}, sec[0].q[1], sec[0].q[0]};
assign ram_out_d[1] = {{RAM_DN - RN * 2{1'bx}}, sec[1].q[1], sec[1].q[0]};

always_comb
begin
	ram[0].d = ram_out_d;
	ram[0].wren = '{dir_latch, dir_latch};
	if (reload) begin
		ram[0].d[0] = {{RAM_DN - RN * 2{1'bx}}, in[1], in[0]};
		ram[0].d[1] = ram[0].d[0];
		ram[0].wren = '{~dir, dir};
	end
	ram[1].d = ram[0].d;
	ram[1].wren = '{~ram[0].wren[0], ~ram[0].wren[1]};
end

logic [RAM_DN - 1:0] ram_out[2];
logic [RAM_AN - 1:0] ram_out_addr[2];
logic ram_out_wren;
ram_fft ram1 (ram_out_addr[0], ram_out_addr[1], clk, ram_out_d[0], ram_out_d[1],
	ram_out_wren, ram_out_wren, ram_out[0], ram_out[1]);

assign ram_out_wren = ~active;

logic [2:0] swap;
logic delay_latch;
always_ff @(posedge clk)
begin
	swap <= {swap[1:0], dir};
	delay_latch <= delay;
	active <= reload;
	ram_out_addr <= rdaddr;
	valid <= active && ~delay_latch;
end

assign out = '{ram_out[swap[1]][0 +: RN], ram_out[swap[1]][RN +: RN]};

endmodule

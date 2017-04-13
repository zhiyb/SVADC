module disp_test_lines #(parameter AN, DN, BASE, SWAP, W, H) (
	input logic clkSYS, n_reset,
	input logic start,
	output logic done,

	// Rendering buffer select
	input logic stat,

	// System interface
	arbiter_if arb
);

enum int unsigned {Idle, Active} state;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		state <= Idle;
	else if (state == Idle) begin
		if (start)
			state <= Active;
	end else if (state == Active) begin
		if (done)
			state <= Idle;
	end

logic [3:0] addr;
logic [9:0] x[2];
logic [8:0] y[2];
logic [15:0] clr;
rom_test rom0 (addr, clkSYS, {x[0], y[0], x[1], y[1], clr});

logic [9:0] line_out[2];
logic line_start, line_done, line_next, line_valid;
draw_line #(10) draw0 (clkSYS, n_reset, line_start, line_done,
	'{'{x[0], {1'b0, y[0]}}, '{x[1], {1'b0, y[1]}}},
	line_out, line_next, line_valid);

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		arb.req <= 1'b0;
	else
		arb.req <= ~arb.ack && line_valid;

assign line_next = arb.ack;

logic line_start_latch;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset) begin
		done <= 1'b0;
		line_start_latch <= 1'b0;
		addr <= 0;
	end else if (line_done) begin
		done <= addr == 4'hf;
		line_start_latch <= addr != 4'hf;
		addr <= addr + 1;
	end else if (start) begin
		done <= 1'b0;
		line_start_latch <= 1'b1;
		addr <= 0;
	end else begin
		done <= 1'b0;
		line_start_latch <= 1'b0;
	end

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		line_start <= 1'b0;
	else
		line_start <= line_start_latch;

always_ff @(posedge clkSYS)
	arb.addr <= (stat ? SWAP : BASE) | (line_out[1][8:0] * W + line_out[0]);

assign arb.data = clr;
assign arb.wr = 1'b1;

endmodule

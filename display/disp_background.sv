module disp_background #(parameter AN, DN, BASE, SWAP, W, H) (
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
	end else
		state <= Idle;

logic [$clog2(W * H) - 1:0] addrcnt;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		addrcnt <= 0;
	else if (state == Idle)
		addrcnt <= 0;
	else if (arb.ack)
		addrcnt <= addrcnt + 1;

assign arb.addr = (stat ? SWAP : BASE) | addrcnt;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		done <= 1'b0;
	else
		done <= arb.ack && addrcnt == W * H - 1;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		arb.req <= 1'b0;
	else if (arb.ack || done)
		arb.req <= 1'b0;
	else
		arb.req <= state == Active;

assign arb.data = 0;
assign arb.wr = 1'b1;

endmodule

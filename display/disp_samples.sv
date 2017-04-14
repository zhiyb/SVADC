module disp_samples #(parameter AN, DN, BASE, SWAP, W, H) (
	input logic clkSYS, clkSmpl, n_reset,
	input logic start,
	output logic done,

	// Rendering buffer select
	input logic stat,

	// System interface
	arbiter_if arb,

	// Sample data input
	input logic [9:0] smpl_data
);

logic aclr, rdreq, wrreq;
logic rdempty, rdfull, wrempty, wrfull;
logic [9:0] fifo;
fifo_samples fifo0 (aclr, smpl_data,
	clkSYS, ~rdempty && rdreq, clkSmpl, ~wrfull && wrreq,
	fifo, rdempty, rdfull, wrempty, wrfull);

always_ff @(posedge clkSmpl, negedge n_reset)
	if (~n_reset)
		wrreq <= 1'b0;
	else if (wrempty)
		wrreq <= 1'b1;
	else if (wrfull)
		wrreq <= 1'b0;

enum int unsigned {Idle, Smpl, Draw} state;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		state <= Idle;
	else if (state == Idle) begin
		if (start)
			state <= Smpl;
	end else if (state == Smpl) begin
		if (rdfull)
			state <= Draw;
	end else if (state == Draw) begin
		if (done)
			state <= Idle;
	end

logic [$clog2(W) - 1:0] x;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		x <= 0;
	else if (state != Draw)
		x <= 0;
	else if (arb.ack)
		x <= x + 1;

logic [2:0] req;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		req <= 0;
	else if (arb.ack)
		req <= 0;
	else
		req <= {req[1:0], state == Draw ? 1'b1 : 1'b0};

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		arb.req <= 1'b0;
	else if (arb.ack)
		arb.req <= 1'b0;
	else
		arb.req <= req[1];

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		rdreq <= 1'b0;
	else if (state == Smpl && rdfull)
		rdreq <= 1'b1;
	else
		rdreq <= arb.ack;

always_ff @(posedge clkSYS)
	done <= arb.ack && x == W - 1;

assign aclr = ~n_reset || done;

logic [$clog2(H) - 1:0] y;
always_ff @(posedge clkSYS)
	y <= (H - 1) - fifo * H / 1024;

always_ff @(posedge clkSYS)
	arb.addr <= (stat ? SWAP : BASE) | (y * W + x);

always_ff @(posedge clkSYS)
	arb.data <= {fifo[9:5], fifo[5:0], ~fifo[9:5]};

//assign arb.data = 16'h667f;
assign arb.wr = 1'b1;

endmodule

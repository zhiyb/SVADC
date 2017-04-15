module disp_samples_sparse #(parameter AN, DN, BASE, SWAP, SIZE, W, H) (
	input logic clkSYS, clkSmpl, n_reset,
	input logic start,
	output logic done,

	// Rendering buffer select
	input logic stat,

	// System interface
	arbiter_if arb,

	// Sample data input
	input logic smpl_avail,
	output logic smpl_req,
	input logic [9:0] smpl
);

logic aclr, rdreq, wrreq;
logic rdempty, rdfull, wrempty, wrfull;
logic [9:0] fifo;
fifo_samples_sparse fifo0 (aclr, smpl,
	clkSYS, ~rdempty && rdreq, clkSmpl, ~wrfull && wrreq,
	fifo, rdempty, rdfull, wrempty, wrfull);

always_ff @(posedge clkSmpl, negedge n_reset)
	if (~n_reset)
		smpl_req <= 1'b0;
	else if (wrempty && smpl_avail)
		smpl_req <= 1'b1;
	else if (wrfull)
		smpl_req <= 1'b0;

always_ff @(posedge clkSmpl)
	wrreq <= smpl_req;

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

logic first;
always_ff @(posedge clkSYS)
	first <= state == Smpl && rdfull;

logic [$clog2(W) - 1:0] x[2];
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		x[1] <= 0;
	else if (state == Idle)
		x[1] <= 0;
	else if (rdreq && ~first)
		x[1] <= x[1] + (W - 1) / (SIZE - 1);

logic [$clog2(H) - 1:0] y[2];
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		y[1] <= 0;
	else
		y[1] <= fifo[9] ? H - 1 : (H - 1) - fifo * H / 512;

always_ff @(posedge clkSYS)
	if (rdreq)
		x[0] <= x[1];

logic rdreq_latch;
always_ff @(posedge clkSYS)
	rdreq_latch <= rdreq;

always_ff @(posedge clkSYS)
	if (rdreq_latch)
		y[0] <= y[1];

logic [9:0] pos[2];
logic line_start, line_done, line_next, line_valid;
draw_line #(10) draw0 (clkSYS, n_reset, line_start, line_done,
	'{'{x[0], {1'b0, y[0]}}, '{x[1], {1'b0, y[1]}}},
	pos, line_next, line_valid);

logic last;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		last <= 1'b0;
	else if (state == Idle)
		last <= 1'b0;
	else if (rdempty)
		last <= 1'b1;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		rdreq <= 1'b0;
	else if ((state == Smpl && rdfull) || first)
		rdreq <= 1'b1;
	else
		rdreq <= line_done && ~last;

logic line_start_latch;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset) begin
		line_start_latch <= 1'b0;
		line_start <= 1'b0;
	end else begin
		line_start_latch <= rdreq && ~first;
		line_start <= line_start_latch;
	end

logic req;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset) begin
		req <= 1'b0;
		arb.req <= 1'b0;
	end else if (arb.ack) begin
		req <= 1'b0;
		arb.req <= 1'b0;
	end else begin
		req <= line_valid;
		arb.req <= req;
	end

assign line_next = arb.ack;

always_ff @(posedge clkSYS)
	done <= line_done && last;

assign aclr = ~n_reset;

always_ff @(posedge clkSYS)
begin
	arb.addr <= (stat ? SWAP : BASE) | pos[1] * W + pos[0];
	arb.data <= {~pos[1][8:4], 6'h3f, pos[1][8:4]};
end

assign arb.wr = 1'b1;

endmodule

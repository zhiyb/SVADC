module draw_line #(parameter N) (
	input logic clkSYS, n_reset,
	input logic start,
	output logic done,

	// Coordinates, x: 0, y: 1
	input logic [N - 1:0] in[2][2],
	output logic [N - 1:0] out[2],
	input logic next,
	output logic valid
);

logic [6:0] start_latch;
always_ff @(posedge clkSYS)
	start_latch <= {start_latch[5:0], start};

`define x 0
`define y 1

//	\7|3/
//	6\|/2
//	--o-- x
//	4/|\0
//	/5|1\
//	  y
logic [2:0] octant;
logic [N - 1:0] first[2], last[2], pos[2], pos_next[2];
logic [N:0] absdiff[2], diff[2], d, d_init, d_next;
logic last_point;
always_ff @(posedge clkSYS)
begin
	octant[2] <= in[1][`x] < in[0][`x];
	octant[1] <= in[1][`y] < in[0][`y];
	octant[0] <= absdiff[`x] < absdiff[`y];

	absdiff[`x] <= octant[2] ? in[0][`x] - in[1][`x] : in[1][`x] - in[0][`x];
	absdiff[`y] <= octant[1] ? in[0][`y] - in[1][`y] : in[1][`y] - in[0][`y];

	diff[`x] <= last[`x] - first[`x];
	diff[`y] <= last[`y] - first[`y];
	d_init <= {diff[`y], 1'b0} - {diff[`x][N - 1], diff[`x]};
	d_next <= d + {diff[`y], 1'b0} - (~d[N] ? {diff[`x], 1'b0} : 0);

	case (octant)
	0:	first <= '{in[0][`x], in[0][`y]};
	1:	first <= '{in[0][`y], in[0][`x]};
	2:	first <= '{in[0][`x], -in[0][`y]};
	3:	first <= '{-in[0][`y], in[0][`x]};
	4:	first <= '{-in[0][`x], in[0][`y]};
	5:	first <= '{in[0][`y], -in[0][`x]};
	6:	first <= '{-in[0][`x], -in[0][`y]};
	7:	first <= '{-in[0][`y], -in[0][`x]};
	endcase
	case (octant)
	0:	last <= '{in[1][`x], in[1][`y]};
	1:	last <= '{in[1][`y], in[1][`x]};
	2:	last <= '{in[1][`x], -in[1][`y]};
	3:	last <= '{-in[1][`y], in[1][`x]};
	4:	last <= '{-in[1][`x], in[1][`y]};
	5:	last <= '{in[1][`y], -in[1][`x]};
	6:	last <= '{-in[1][`x], -in[1][`y]};
	7:	last <= '{-in[1][`y], -in[1][`x]};
	endcase
	case (octant)
	0:	out <= '{pos[`x], pos[`y]};
	1:	out <= '{pos[`y], pos[`x]};
	2:	out <= '{pos[`x], -pos[`y]};
	3:	out <= '{pos[`y], -pos[`x]};
	4:	out <= '{-pos[`x], pos[`y]};
	5:	out <= '{-pos[`y], pos[`x]};
	6:	out <= '{-pos[`x], -pos[`y]};
	7:	out <= '{-pos[`y], -pos[`x]};
	endcase

	last_point <= pos[`x] == last[`x];
	pos_next <= '{pos[`x] + 1, pos[`y] + 1};
end

localparam latency = 5;

logic active;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		active <= 1'b0;
	else if (start_latch[latency])
		active <= 1'b1;
	else if (active)
		active <= ~(last_point && next);

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		valid <= 1'b0;
	else
		valid <= active && ~next;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		done <= 1'b0;
	else
		done <= last_point && next;

always_ff @(posedge clkSYS)
	if (start_latch[latency]) begin
		d <= d_init;
		pos <= first;
	end else if (active && next) begin
		if (~d[N])
			pos[`y] <= pos_next[`y];
		d <= d_next;
		pos[`x] <= pos_next[`x];
	end

endmodule

module disp_swap (
	input logic clkSYS, n_reset,
	input logic start,
	output logic done,

	input logic stat,
	output logic swap
);

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		swap <= 1'b0;
	else if (start)
		swap <= ~stat;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		done <= 1'b0;
	else if (start)
		done <= 1'b0;
	else
		done <= swap == stat;

endmodule

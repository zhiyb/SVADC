// For ADC chip ADC10080
module adc #(parameter BASE) (
	input logic clkSYS, clkADC, n_reset,
	output logic [9:0] adc_data,

	// Display buffer swap
	output logic swap,
	input logic stat,

	// System interface
	input logic [15:0] mem,
	input logic valid,

	// Request interface
	output logic [23:0] addr,
	output logic [15:0] data,
	output logic req, wr,
	input logic ack,

	// ADC IO
	output logic ADC_CLK,
	input logic [9:0] ADC_D
);

assign ADC_CLK = clkADC;

always_ff @(posedge clkADC)
	adc_data <= ADC_D;

logic [9:0] x;

logic aclr, rdreq, wrreq;
logic rdfull, wrempty, wrfull;
logic [9:0] fifo;
adc_fifo fifo0 (aclr, adc_data, clkSYS, rdreq, clkADC, wrreq && ~wrfull, fifo, rdfull, wrempty, wrfull);

always_ff @(posedge clkADC, negedge n_reset)
	if (~n_reset)
		wrreq <= 1'b0;
	else if (wrfull)
		wrreq <= 1'b0;
	else if (wrempty)
		wrreq <= 1'b1;

enum int unsigned {ADCWait, DispClr, Disp, DispWait} state;

logic clrdone;
logic [23:0] addrcnt;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset) begin
		addrcnt <= 0;
		clrdone <= 1'b0;
	end else if (state != DispClr) begin
		addrcnt <= 0;
		clrdone <= 1'b0;
	end else if (ack) begin
		addrcnt <= addrcnt + 1;
`ifdef MODEL_TECH
		clrdone <= addrcnt == 100 - 1;
`else
		clrdone <= addrcnt == 800 * 480 - 1;
`endif
	end

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		data <= 0;
	else if (state == DispClr)
		data <= {adc_data[9:7], 2'b0, adc_data[6:3], 2'b0, adc_data[2:0], 2'b0};

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		req <= 1'b0;
	else if (state == DispClr)
		req <= ~clrdone && ~ack;
	else
		req <= 1'b0;

assign addr = BASE + (swap ? 24'h000000 : 24'h080000) + addrcnt;
assign wr = 1'b1;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		state <= ADCWait;
	else if (state == ADCWait) begin
		if (rdfull)
			state <= DispClr;
	end else if (state == DispClr) begin
		if (clrdone)
			state <= Disp;
	end else if (state == Disp) begin
		state <= DispWait;
	end else if (state == DispWait) begin
		if (stat == swap)
			state <= ADCWait;
	end

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		aclr <= 1'b0;
	else
		aclr <= state == DispWait;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		swap <= 0;
	else if (state == Disp)
		swap <= ~swap;

endmodule

// For ADC chip ADC10080
module adc #(parameter BASE,
`ifdef MODEL_TECH
	W = 16, H = 2
`else
	W = 800, H = 480
`endif
) (
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

logic [9:0] rdaddr, wraddr;
logic [9:0] ram_data, ram;
logic wren, rden, wrfull, rdfull;
adc_ram ram0 (ram_data, rdaddr, clkSYS, wraddr, clkADC, wren, ram);

assign ram_data = (H - 1) - adc_data * H / 1024;

logic rdfull_latch;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset) begin
		rdfull_latch <= 1'b0;
		rdfull <= 1'b0;
	end else if (rden) begin
		rdfull_latch <= 1'b0;
		rdfull <= 1'b0;
	end else begin
		rdfull_latch <= wrfull;
		rdfull <= rdfull_latch;
	end

always_ff @(posedge clkADC, negedge n_reset)
	if (~n_reset)
		wraddr <= 10'h0;
	else if (wren)
		wraddr <= wraddr + 10'h1;
	else if (rden)
		wraddr <= 10'h0;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		rdaddr <= 10'h0;
	else if (rden) begin
		if (rdaddr == W - 1)
			rdaddr <= 10'h0;
		else
			rdaddr <= rdaddr + 10'h1;
	end else if (rdfull)
		rdaddr <= 10'h0;

logic adcen;
always_ff @(posedge clkADC, negedge n_reset)
	if (~n_reset)
		wrfull <= 1'b0;
	else if (wraddr == W - 1 && wren)
		wrfull <= 1'b1;
	else if (~adcen)
		wrfull <= 1'b0;

logic wrreq, aclr;
always_ff @(posedge clkADC, negedge n_reset)
	if (~n_reset)
		wrreq <= 1'b0;
	else if (wrfull)
		wrreq <= 1'b0;
	else if (adcen)
		wrreq <= 1'b1;
	else
		wrreq <= 1'b0;

assign wren = wrreq && ~wrfull;

enum int unsigned {ADCWait, DispClr, Disp, DispWait} state;

logic dispdone;
logic [23:0] addrcnt;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset) begin
		addrcnt <= 0;
		dispdone <= 1'b0;
	end else if ((state != DispClr && state != Disp) || dispdone) begin
		addrcnt <= 0;
		dispdone <= 1'b0;
	end else if (ack) begin
		addrcnt <= addrcnt + 1;
		dispdone <= addrcnt == W * H - 1;
	end

logic [8:0] rdrow;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		rdrow <= 9'h0;
	else if (ack && rdaddr == W - 1)
		rdrow <= rdrow + 1;
	else if (rdfull)
		rdrow <= 9'h0;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		data <= 0;
	else if (state == DispClr)
		data <= 0;
	else if (state == Disp)
		data <= ram[8:0] == rdrow ? 16'h667f : {2'b0, rdrow[8:6], 3'b0, rdrow[5:3], 2'b0, rdrow[2:0]};
		//data <= ram[9:1] == rdrow ? 16'h667f : 16'h0;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		req <= 1'b0;
	else if (state == DispClr || state == Disp)
		req <= ~rdfull && ~dispdone && ~ack && ~rden;
	else
		req <= 1'b0;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		rden <= 1'b0;
	else if ((state == DispClr && dispdone) || (state == Disp && ack))
		rden <= 1'b1;
	else
		rden <= 1'b0;

assign addr = BASE + (swap ? 24'h000000 : 24'h080000) + addrcnt;
assign wr = 1'b1;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		state <= DispWait;
	else if (state == ADCWait) begin
		if (rdfull)
			state <= Disp;//Clr;
	end else if (state == DispClr) begin
		if (dispdone)
			state <= Disp;
	end else if (state == Disp) begin
		if (dispdone)
			state <= DispWait;
	end else if (state == DispWait) begin
		if (stat == swap)
			state <= ADCWait;
	end

logic [1:0] adcen_latch;
always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		adcen_latch[0] <= 1'b0;
	else if (state == ADCWait)
		adcen_latch[0] <= 1'b1;
	else
		adcen_latch[0] <= 1'b0;

always_ff @(posedge clkADC, negedge n_reset)
	if (~n_reset) begin
		adcen_latch[1] <= 1'b0;
		adcen <= 1'b0;
	end else begin
		{adcen, adcen_latch[1]} <= adcen_latch;
	end

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		aclr <= 1'b0;
	else
		aclr <= state == DispWait;

always_ff @(posedge clkSYS, negedge n_reset)
	if (~n_reset)
		swap <= 0;
	else if (state == Disp && dispdone)
		swap <= ~swap;

endmodule

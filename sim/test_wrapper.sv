`timescale 1 ps / 1 ps

module test_wrapper;

logic CLOCK_50;
logic [1:0] KEY;
logic [3:0] SW;
logic [7:0] LED;

logic [12:0] DRAM_ADDR;
logic [1:0] DRAM_BA, DRAM_DQM;
logic DRAM_CKE, DRAM_CLK;
logic DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N;
wire [15:0] DRAM_DQ;

wire I2C_SCLK, I2C_SDAT;

logic G_SENSOR_CS_N;
logic G_SENSOR_INT;

logic ADC_CS_N, ADC_SADDR, ADC_SCLK;
logic ADC_SDAT;

wire [33:0] GPIO_0;
logic [1:0] GPIO_0_IN;
wire [33:0] GPIO_1;
logic [1:0] GPIO_1_IN;
wire [12:0] GPIO_2;
logic [2:0] GPIO_2_IN;

wrapper w0 (.*);

initial
begin
	KEY = 2'b00;
	#100ns KEY = 2'b11;
end

initial
begin
	CLOCK_50 = 1'b0;
	forever #10ns CLOCK_50 = ~CLOCK_50;
end

logic [15:0] cnt;
assign DRAM_DQ = cnt;
//assign {GPIO_1[32], GPIO_1[30], GPIO_1[31], GPIO_1[29], GPIO_1[33],
//	GPIO_1[27], GPIO_1[25], GPIO_1[19], GPIO_1[23], GPIO_1[21]} = cnt[9:0];
//assign {GPIO_1[21], GPIO_1[23], GPIO_1[19], GPIO_1[25], GPIO_1[27],
//	GPIO_1[33], GPIO_1[29], GPIO_1[31], GPIO_1[30], GPIO_1[32]} = cnt[9:0];
//assign {GPIO_1[32], GPIO_1[30], GPIO_1[31], GPIO_1[29], GPIO_1[33],
//	GPIO_1[27], GPIO_1[25], GPIO_1[19], GPIO_1[23], GPIO_1[21]} = 10'h0;
assign {GPIO_1[32], GPIO_1[30], GPIO_1[31], GPIO_1[29], GPIO_1[33],
	GPIO_1[27], GPIO_1[25], GPIO_1[19], GPIO_1[23], GPIO_1[21]} =
	$rtoi(($sin(4.0 * $acos(0.0) * $itor(cnt[8:0]) / 512.0)
		+ 1.0) * (2.0 ** 9.0));

assign SW = 4'hf;

always_ff @(posedge DRAM_CLK, negedge KEY[0])
	if (~KEY[0])
		cnt <= 16'h0;
	else
		cnt <= cnt + 1;

endmodule

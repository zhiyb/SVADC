module wrapper (
	input logic CLOCK_50,
	input logic [1:0] KEY,
	input logic [3:0] SW,
	output logic [7:0] LED,
	
	output logic [12:0] DRAM_ADDR,
	output logic [1:0] DRAM_BA, DRAM_DQM,
	output logic DRAM_CKE, DRAM_CLK,
	output logic DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N,
	inout wire [15:0] DRAM_DQ,
	
	inout wire I2C_SCLK, I2C_SDAT,
	
	output logic G_SENSOR_CS_N,
	input logic G_SENSOR_INT,
	
	output logic ADC_CS_N, ADC_SADDR, ADC_SCLK,
	input logic ADC_SDAT,
	
	inout wire [33:0] GPIO_0,
	input logic [1:0] GPIO_0_IN,
	inout wire [33:0] GPIO_1,
	input logic [1:0] GPIO_1_IN,
	inout wire [12:0] GPIO_2,
	input logic [2:0] GPIO_2_IN
);

// Clocks
logic clk36M, clk80M, clk50M, clk90M, clk240M, clk360M;
assign clk50M = CLOCK_50;
pll pll0 (.inclk0(clk50M), .locked(),
	.c0(clk80M), .c1(clk36M), .c2(clk90M), .c3(clk360M), .c4(clk240M));

logic clkSYS, clkSDRAM, clkTFT, clkADC;
//assign clkSYS = clk300M;
assign clkSDRAM = clk90M;
assign clkTFT = clk36M;
assign clkADC = clk80M;

// Reset control
logic n_reset;
logic n_reset_ext, n_reset_mem;

always_ff @(posedge clk50M)
begin
	n_reset_ext <= KEY[0];
	n_reset <= n_reset_ext & n_reset_mem;
end

// System interface clock switch for debugging
`ifdef MODEL_TECH
logic [1:0] clk;
assign clk = 0;
assign clkSYS = clk240M;
`else
logic [1:0] clk;
logic [25:0] cnt;
always_ff @(posedge clk50M)
	if (cnt == 0) begin
		cnt <= 50000000;
		clk <= KEY[1] ? clk : clk + 1;
	end else
		cnt <= cnt - 1;

logic sys[4];
assign sys[0] = clk240M;
assign sys[1] = clk90M;
assign sys[2] = clk240M;
assign sys[3] = clk360M;
assign clkSYS = sys[clk];
`endif

// Memory interface and arbiter
localparam AN = 24, DN = 16, BURST = 8;

logic [1:0] mem_id;
arbiter_if #(AN, DN, 2) mem ();
arbiter_if #(AN, DN, 2) arb[4] ();
arbiter_sync_pri #(AN, DN, 2) arb0 (clkSYS, n_reset, mem, mem_id, arb);

assign arb[0].req = 0;
`define tft arb[2]
`define disp arb[3]

// SDRAM
logic [1:0] sdram_level;
logic sdram_empty, sdram_full;
sdram #(.AN(AN), .DN(DN), .BURST(BURST)) sdram0
	(clkSYS, clkSDRAM, n_reset_ext, n_reset_mem,
	mem.mem, mem_id, mem.valid,
	mem.addr, mem.data, mem.id, mem.req, mem.wr, mem.ack,
	DRAM_DQ, DRAM_ADDR, DRAM_BA, DRAM_DQM,
	DRAM_CLK, DRAM_CKE, DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N,
	sdram_empty, sdram_full, sdram_level);

// TFT
localparam tft_base = 24'hf00000, tft_swap = 24'hf80000;
logic [5:0] tft_level;
logic tft_empty, tft_full, disp_swap, disp_stat;
`ifdef MODEL_TECH
tft #(AN, DN, BURST, tft_base, tft_swap,
	10, '{1, 1, 60, 1}, 10, '{1, 1, 3, 1}) tft0
`else
tft #(AN, DN, BURST, tft_base, tft_swap,
	10, '{1, 43, 799, 15}, 10, '{1, 21, 479, 6}) tft0
`endif
	(.clkSYS(clkSYS), .clkTFT(clkTFT), .n_reset(n_reset),
	.swap(disp_swap), .stat(disp_stat),
	.mem_data(`tft.mem), .mem_valid(`tft.valid),
	.req_addr(`tft.addr), .req_ack(`tft.ack), .req(`tft.req),
	.disp(GPIO_0[26]), .de(GPIO_0[29]), .dclk(GPIO_0[25]),
	.vsync(GPIO_0[28]), .hsync(GPIO_0[27]),
	.out({GPIO_0[7:0], GPIO_0[15:8], GPIO_0[23:16]}),
	.level(tft_level), .empty(tft_empty), .full(tft_full));

assign `tft.data = 'x;
assign `tft.wr = 0;

logic tft_pwm;
assign GPIO_0[24] = tft_pwm;
assign tft_pwm = n_reset;

// Amplifier
logic amp_sd;
logic [3:0] amp_d;
assign GPIO_1[28] = amp_sd;
assign {GPIO_1[22], GPIO_1[20], GPIO_1[26], GPIO_1[24]} = amp_d;

assign amp_sd = 1'b0;
assign amp_d = SW;

// ADC
localparam ADCN = 10;
logic [ADCN - 1:0] adc_data;
adc #(10) adc0 (clkADC, n_reset, adc_data, GPIO_1[18],
	{GPIO_1[32], GPIO_1[30], GPIO_1[31], GPIO_1[29], GPIO_1[33],
	GPIO_1[27], GPIO_1[25], GPIO_1[19], GPIO_1[23], GPIO_1[21]});

logic signed [ADCN - 1:0] adc_sdata;
assign adc_sdata = {~adc_data[ADCN - 1], adc_data[ADCN - 2:0]};

logic sw;
always_ff @(posedge clkADC)
	sw <= ~SW[0];

// FM receiver
logic clkFM;
logic signed [ADCN - 1:0] fm[2];
fm #(ADCN) fm0 (clkADC, n_reset, adc_sdata, clkFM, fm);

// Sample display
logic clkSmpl[2];
assign clkSmpl[0] = clkADC;
assign clkSmpl[1] = clkFM;

logic signed [ADCN - 1:0] smpl[2][2];
assign smpl[0][0] = adc_sdata;
assign smpl[1] = fm;

logic [ADCN - 1:0] waveform[2];
always_ff @(posedge clkSmpl[0])
	waveform[0] <= {~smpl[0][0][ADCN - 1], smpl[0][0][ADCN - 2:0]};
always_ff @(posedge clkSmpl[1])
	waveform[1] <= {~smpl[1][0][ADCN - 1], smpl[1][0][ADCN - 2:0]};

// FFT
localparam FFTN = 18, FFT_SIZE = 512;
logic fft_start, fft_valid;
logic [FFTN - 1:0] fft_data;
`ifdef MODEL_TECH
fft #(ADCN, FFTN, 5, FFT_SIZE) fft0 (clkSmpl[1], n_reset,
	smpl[1], fft_valid, fft_start, fft_data);
`else
fft #(ADCN, FFTN, 5, FFT_SIZE) fft0 (clkSmpl[1], n_reset,
	smpl[1], fft_valid, fft_start, fft_data);
`endif

// Waveform display
display #(AN, DN, FFTN, tft_base, tft_swap,
	FFT_SIZE > 800 ? 800 : FFT_SIZE) disp0 (clkSYS, clkSmpl[0], clkSmpl[1],
	n_reset, waveform[0], waveform[1], fft_valid, fft_start, fft_data,
	disp_swap, disp_stat, `disp);

// Waveform generator
wavegen_sin #(4, 5) wave0 (clk80M, n_reset, GPIO_1[0]);

// Debugging LEDs
assign LED[7:0] = {clk, adc_data[9:4]};

endmodule

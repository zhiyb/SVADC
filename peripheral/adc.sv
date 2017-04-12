module adc #(parameter N = 10) (
	input logic clkADC, n_reset,
	output logic [N - 1:0] adc_data,

	// ADC IO
	output logic ADC_CLK,
	input logic [N - 1:0] ADC_D
);

assign ADC_CLK = clkADC;

always_ff @(posedge clkADC)
	adc_data <= ADC_D;

endmodule

module play_song(
	// Inputs
	clk,
	pause,
	stop,

	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	FPGA_I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	FPGA_I2C_SCLK
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				clk, pause, stop;

input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				FPGA_I2C_SDAT;

// Outputs
output				AUD_XCK;
output				AUD_DACDAT;

output				FPGA_I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
wire				read_audio_in;

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;

wire [31:0] current_sample;

reg [31:0] sample;
reg [15:0] count = 16'd0;

always @(posedge CLOCK_8)
begin
	if (~stop)
	begin
		if (~pause)
		begin
			if (audio_out_allowed)
				count <= count + 1;
				
			if (count == 16'd65535)
				count <= 16'd0;
		end
	end
	
	else if (stop) count <= 16'd0;
end

reg CLOCK_8 = 1'd0;
reg [2:0] count2 = 3'd0;

always @(posedge clk)
begin
	count2<=count2+1;
	
	if (count2 == 3'd2)
	begin
		count2 <= 3'd0;
		CLOCK_8 <= CLOCK_8 ? 0:1;
	end
	
end

audio_in get_sample(.address(count),
						  .clock(CLOCK_8),
						  .data(),
						  .wren(1'b0),
						  .q(current_sample));

always @(posedge CLOCK_8)
begin
	if (audio_out_allowed)
	begin
		sample <= current_sample;
	end
end

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

assign left_channel_audio_out	= sample;
assign right_channel_audio_out	= sample;
assign write_audio_out			= audio_out_allowed;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50					(CLOCK_8),
	.reset						(stop),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),


	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)

);

avconf #(.USE_MIC_INPUT(1)) avc (
	.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
	.CLOCK_50					(CLOCK_8),
	.reset						(stop)
);

endmodule


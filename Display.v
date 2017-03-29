// VGA display module, written by Daniel

module Display
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,  		//	VGA Blue[9:0]
		LEDR
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output [17:0] LEDR;
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire [7:0] allowed;
	wire [2:0] out_colour;
	wire [7:0] out_x;
	wire [6:0] out_y;
	

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y), 
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	// datapath d0(...);
	datapath d0(
	.clk3(CLOCK_50),
	.clk1(KEY[1]),
    .resetn(resetn),
    //input ld_x, ld_y, ld_colour,
    .data_in(SW[9:0]),
	.out_colour(colour),
    .out_x(x),
	.out_y(y)
	);
    // Instansiate FSM control
    // control c0(...);
    control c0(
	.clk(CLOCK_50),
	.resetn(resetn),
	.x(x),
	.y(y),
	.colour(colour),
	.ld_alu_out_colour(out_colour),
    .ld_alu_out_x(out_x),
	.ld_alu_out_y(out_y)
	);
	assign LEDR[6:0] = out_y[6:0];
	assign LEDR[17:10] = out_x[7:0];

	

	
	
endmodule

module datapath(
	input clk3,
	input clk1,
	input resetn,
   //input ld_x, ld_y, ld_colour,
   input [9:0] data_in,
	output reg[2:0]  out_colour,
   output reg[7:0]  out_x,
	output reg[6:0]  out_y
   );
    
   // output of the alu//////////////////////
   //assign out_x 	 	= 7'b0000000;
	//assign out_y 	 	= 6'b000000;
	//assign out_colour 	= 3'b000;
   	
	// Register x  is set with respective input logic
	reg [7:0] x_counter; 
	initial x_counter = 0;
	reg [7:0] y_counter; 
	initial y_counter = 0;


   always@(posedge clk3) begin
		if (clk1 == 1)
			x_counter = 0;
		if(!resetn) begin
			out_x 		<= 8'b00000000;
		end
		else begin
			case(data_in[1:0])
				2'b00: begin
					if (x_counter < 32) begin
						out_x <= 8'b00000111 + (x_counter[7:4]);
						x_counter = x_counter + 1;
					end
				end
				2'b01: begin
					if (x_counter < 32) begin
						out_x <= 8'b00001111 + (x_counter[7:4]);
						x_counter = x_counter + 1;
					end
				end
				2'b10: begin
					if (x_counter < 32) begin
						out_x <= 8'b00011001 + (x_counter[7:4]);
						x_counter = x_counter + 1;
					end
				end
				2'b11: begin
					if (x_counter < 32) begin
						out_x <= 8'b00100001 + (x_counter[7:4]);
						x_counter = x_counter + 1;
					end
				end
			endcase 
			//out_x <= 8'b00000111 + (x_counter[6:3]);
			//x_counter = x_counter + 1;
		end
	end
	
	
	
   // Register y and colour are set with respective input logic
   always@(posedge clk3) begin
		if(!resetn) begin
			out_y 		<= 7'b0000000;
			out_colour 	<= 3'b000;
		end
		else begin
			if (x_counter < 32) begin
				out_y <= 7'b0000111 + (x_counter[2:0]);
			end	
			
//			out_y 		<= {4'b0111, data_in[5:3]};
			out_colour 	<= data_in[9:7];
		end
	end
endmodule

module control(
	input clk,
   input resetn,
   input [7:0] x,
	input [6:0] y,
	input [2:0] colour,
	output reg[2:0]  ld_alu_out_colour,
   output reg[7:0]  ld_alu_out_x,
	output reg[6:0]  ld_alu_out_y
    );

    // Output logic aka all of our datapath control signals
	// By default make all our signals 0
	/////////////////////////////////////////////
	//assign ld_alu_out_x = 2'b0;
	//assign ld_alu_out_y = 2'b0;
	//assign ld_alu_out_colour = 2'b0;
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
			begin
				ld_alu_out_x <= 8'b00000000;
				ld_alu_out_y <= 7'b0000000;
				ld_alu_out_colour <= 3'b000;
			end
        else
            begin
				ld_alu_out_x <= {1'b0,x};
				ld_alu_out_y <= y;
				ld_alu_out_colour <= colour;
			end
    end // state_FFS
endmodule
module Project(CLOCK_50, SW, KEY, LEDR, HEX0, HEX1, LEDG);

    input [9:0] SW;
	 output [6:0] LEDG;
    input [3:0] KEY;
    input CLOCK_50;
	 output [6:0] HEX0;
	 output [6:0] HEX1;	 
    output [17:0] LEDR;
	 
	 wire adjusted_clock;
	 
	 speed_module clock_controller(
		.CLOCK_50(CLOCK_50),
		.LEDG(adjusted_clock));
	 
	core memory_game (.fast_clock(CLOCK_50),
							.clock(adjusted_clock),
							.button_1(KEY[0]),
							.button_2(KEY[1]),
							.button_3(KEY[2]),
							.button_4(KEY[3]),
							.led_1(LEDG[0]),
							.led_2(LEDG[2]),
							.led_3(LEDG[4]),
							.led_4(LEDG[6]),
							.led_5(LEDR[0]),
							.h0(HEX0[6:0]),
							.h1(HEX1[6:0]));
endmodule


// The core memory game logic, written by Neeilan
module core(fast_clock, clock, button_1, button_2, button_3, button_4, led_1, led_2, led_3, led_4, led_5, h0, h1);
	
	input fast_clock;
	input clock;
	input button_1, button_2, button_3, button_4;
	output reg led_1, led_2, led_3, led_4,  led_5;
	output [6:0] h0, h1;
	
	// We want to know if the user is pressing any button
	wire [3:0] user_input = {!button_4, !button_3, !button_2, !button_1};
	wire button_pressed = ((user_input & 4'b1111) > 0 ? 1 : 0);

	// State logic
	parameter START 		= 8'b00000000;
	parameter GENERATE_SEQ 		= 8'b00000001;
	parameter SHOW_SEQ 		= 8'b00000011;
	parameter AWAIT_INPUT		= 8'b00000010;
	parameter RECEIVE_INPUT 	= 8'b00000110;
	parameter CHECK_INPUT		= 8'b00000111;
	parameter DELAY 		= 8'b00000101;
	parameter INCREMENT_LEVEL 	= 8'b00000100;

	reg [7:0] current_state 	= START;
	
	reg [31:0] sequence;
	reg [31:0] currentSequence;
	reg [31:0] userEnteredSequence; 

	initial sequence 		= 32'b11_10_11_01_01_11_10_01_00_01_00_11_01_00_01_11_10;	
	initial currentSequence 	= 32'b00000000000000000000000000000000;
	initial userEnteredSequence 	= 32'b00000000000000000000000000000000;
	
	// The 2 bit number currently being displayed
	reg display_msb;
	reg display_lsb;
	wire [1:0] activeLightNumber = { display_msb, display_lsb };
	

	// Counters
	
		// Number of times user has pressed a button
	reg [5:0] numberOfUserInputs;		
	initial numberOfUserInputs = 0;
	
		// The index of the 2 bit number being displayed now
	reg [3:0] _display_ct; 
	initial _display_ct = 4'b0000;

	reg [7:0] score;
	initial score = 0;
	
	reg [7:0] level;
	initial level = 0;				
	
	
	// 7-segment display for score and inputs
	
	hex_display hd0(.IN(score[3:0]), .OUT(h0));
	hex_display hd1(.IN(numberOfUserInputs[3:0]), .OUT(h1));

	
	always @(posedge clock)
	begin
			case (current_state)
				START: begin
//					level = 8;
					current_state = GENERATE_SEQ;
				end
				
				GENERATE_SEQ: begin
					current_state = SHOW_SEQ;
				end 
				

				SHOW_SEQ: begin
					if (_display_ct >= level)
						current_state = RECEIVE_INPUT;
					else
						current_state = SHOW_SEQ;
				end


				RECEIVE_INPUT: begin
				current_state = (numberOfUserInputs >= level) ? CHECK_INPUT : RECEIVE_INPUT;
				end

				CHECK_INPUT: begin
						if (currentSequence[15:0] == userEnteredSequence [15:0]) begin
							current_state = INCREMENT_LEVEL;
						end
						else
							current_state = START;
				end

				INCREMENT_LEVEL: begin
					if (button_pressed == 1) begin
						score = score + 1;
						current_state = START;
					end
				end
				
				default: begin
				end
				
		endcase
	end
	
	// GENERATE AND SHOW_SEQ logic
	always @(posedge clock)
	begin
		if (current_state === GENERATE_SEQ)
			_display_ct = 8'b00000000;
			
		if (current_state === SHOW_SEQ && _display_ct < level * 2) begin
			display_lsb = sequence[_display_ct * 2 ];
			display_msb = sequence[_display_ct* 2 + 1];
			currentSequence[_display_ct * 2] = sequence[_display_ct * 2];
			currentSequence[_display_ct* 2 + 1] = sequence[_display_ct* 2 + 1];
			_display_ct = _display_ct + 1;
		end
	end
	

	// RECEIVE_INPUT AND INCREMENT LEVEL logic
	always @(posedge clock)
	begin
		if (current_state === RECEIVE_INPUT && button_pressed == 1)
		begin
			if (user_input == 4'b0001) begin
					userEnteredSequence[numberOfUserInputs * 2] = 0;
					userEnteredSequence[numberOfUserInputs* 2 + 1] = 0;
				end
			if (user_input == 4'b0010) begin
					userEnteredSequence[numberOfUserInputs * 2] = 1;
					userEnteredSequence[numberOfUserInputs* 2 + 1] = 0;
				end
			if (user_input == 4'b0100) begin
					userEnteredSequence[numberOfUserInputs * 2] = 0;
					userEnteredSequence[numberOfUserInputs* 2 + 1] = 1;
				end
			if (user_input == 4'b1000) begin
					userEnteredSequence[numberOfUserInputs * 2] = 1;
					userEnteredSequence[numberOfUserInputs* 2 + 1] = 1;
				end
			numberOfUserInputs = numberOfUserInputs + 1;
		end
		
		if (current_state === INCREMENT_LEVEL || current_state == GENERATE_SEQ) begin
				numberOfUserInputs = 0;
				userEnteredSequence = 32'b000000000000000000000000000000000;
			end			
	end
		
	
	// get buttons to light up led_1, led_2, led_3, led_4
	always @(posedge clock)
	begin
		led_1 = 0;
		led_2 = 0;
		led_3 = 0;
		led_4 = 0;
		
		if (current_state === RECEIVE_INPUT && button_pressed == 1)
			begin
				if (user_input == 4'b0001)
					led_1 = 1;
				if (user_input == 4'b0010)
					led_2 = 1;
				if (user_input == 4'b0100)
					led_3 = 1;
				if (user_input == 4'b1000)
					led_4 = 1;	
			end
			
		else if (current_state === INCREMENT_LEVEL)
			begin
				led_1 = 1;
				led_2 = 1;
				led_3 = 1;
				led_4 = 1;
			end
		
		else if (current_state === SHOW_SEQ)
			begin
				if (activeLightNumber == 2'b00)
					led_1 = 1;
				if (activeLightNumber == 2'b01)
					led_2 = 1;
				if (activeLightNumber == 2'b10)
					led_3 = 1;
				if (activeLightNumber == 2'b11) 
					led_4 = 1;	
			end		
	end		
	
	
	// state indicators
	always @(posedge clock) begin
	 led_5 = (current_state === RECEIVE_INPUT);
	end
		
endmodule






module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000; //0
			4'b0001: OUT = 7'b1111001; //1
			4'b0010: OUT = 7'b0100100; //2
			4'b0011: OUT = 7'b0110000; //3
			4'b0100: OUT = 7'b0011001; //4
			4'b0101: OUT = 7'b0010010; //5
			4'b0110: OUT = 7'b0000010; //6
			4'b0111: OUT = 7'b1111000; //7
			4'b1000: OUT = 7'b0000000; //8
			4'b1001: OUT = 7'b0011000; //9
			4'b1010: OUT = 7'b1000000; //A or 10
			4'b1011: OUT = 7'b1111001; //B or 11
			4'b1100: OUT = 7'b0100100; //C or 12
			4'b1101: OUT = 7'b0110000; //D or 13
			4'b1110: OUT = 7'b0011001; //E or 14
			4'b1111: OUT = 7'b0010010; //F or 15
			
			default: OUT = 7'b1000000;
		endcase
	end
endmodule


// A module to slow down the 50MHz clock
// Written by Mathun

module speed_module(CLOCK_50, LEDG);
    input CLOCK_50;
    output [0:0] LEDG;

    /* registers */
    reg [25:0] counter;
    reg state;
    
    /* assign */
    assign LEDG[0] = state;
    
	/* state change */
    always @ (posedge CLOCK_50) begin
        counter <= counter + 1;
        state <= counter[25]; // refresh every 1 second as default.
    end
endmodule
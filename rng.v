// 5-bit random number generator
// Written by Ryan
module rng(clk, rst_n, data);
  input  clk, rst_n;

  output [4:0] data;

  wire feedback = data[4] ^ data[1];

  reg [4:0] _data;

  always @(posedge clk or negedge rst_n)
  begin
  if (~rst_n) 
    _data <= 4'hf;
  else
    _data <= {data[3:0], feedback};
  end
  assign data = _data;
endmodule
module pcounter(input clk, input enable, input jump, input out_enable,
  input [ADDRESS_WIDTH-1 : 0] bus_in,
  output [ADDRESS_WIDTH-1 : 0] bus_out);

  parameter ADDRESS_WIDTH = 4;
  reg [ADDRESS_WIDTH-1 : 0] counter = 0;

  assign bus_out = (out_enable) ? counter : {ADDRESS_WIDTH{1'b0}};

  always @(posedge clk)
    if (enable)
      counter <= counter + 1;
    else if (jump)
      counter <= bus_in;
endmodule

module alu(input clk, input alu_enable, input rega_enable,
  input regb_enable, input rega_write_enable,
  input regb_write_enable, input sub_enable,
  input [WIDTH-1 : 0] bus_in, output [WIDTH-1 : 0] bus_out,
  output carry);

  parameter WIDTH = 8;
  reg [WIDTH-1 : 0] reg_a;
  reg [WIDTH-1 : 0] reg_b;
  wire [WIDTH-1 : 0] b_in;
  wire [WIDTH-1 : 0] add_sum;

  assign b_in = sub_enable ? ~(reg_b) : reg_b;
  assign bus_out = (alu_enable) ? add_sum :
                   (rega_enable) ? reg_a :
                   (regb_enable) ? reg_b : {WIDTH{1'b0}};

  adderN #(.WIDTH(WIDTH)) add(reg_a, b_in, sub_enable, add_sum, carry);

  always @(posedge clk)
    if (rega_write_enable)
      reg_a <= bus_in;
    else if (regb_write_enable)
      reg_b <= bus_in;
endmodule

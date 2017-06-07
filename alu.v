module alu(input clk, input alu_enable, input rega_enable,
  input regb_enable, input rega_write_enable,
  input regb_write_enable, input sub_enable,
  input [WIDTH-1 : 0] bus_in, output [WIDTH-1 : 0] bus_out,
  output carry_out);

  parameter WIDTH = 8;
  reg [WIDTH-1 : 0] reg_a;
  reg [WIDTH-1 : 0] reg_b;
  wire [WIDTH-1 : 0] sum;
  wire [WIDTH-1 : 0] carry;
  wire [WIDTH-1 : 0] b_in;

  initial begin
    reg_a = 0;
    reg_b = 0;
  end

  assign b_in = sub_enable ? ~(reg_b) : reg_b;
  assign bus_out = (alu_enable) ? sum :
                   (rega_enable) ? reg_a :
                   (regb_enable) ? reg_b : {WIDTH{1'b1}};
  assign carry_out = carry[WIDTH-1];

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin
      if (i == 0) begin
        assign sum[i] = (reg_a[i] ^ b_in[i]) ^ sub_enable;
        assign carry[i] = ((reg_a[i] ^ b_in[i]) & sub_enable) | (reg_a[i] & b_in[i]);
      end else begin
        assign sum[i] = (reg_a[i] ^ b_in[i]) ^ carry[i-1];
        assign carry[i] = ((reg_a[i] ^ b_in[i]) & carry[i-1]) | (reg_a[i] & b_in[i]);
      end
    end
  endgenerate

  always @(posedge clk) begin
    if (rega_write_enable) begin
      reg_a <= bus_in;
    end else if (regb_write_enable) begin
      reg_b <= bus_in;
    end
  end
endmodule

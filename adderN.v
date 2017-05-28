module adderN(input [WIDTH-1 : 0] a, input [WIDTH-1 : 0] b,
  input carry_in, output [WIDTH-1 : 0] sum, output carry_out);

  parameter WIDTH = 8;
  wire [WIDTH : 0] carry;
  wire [WIDTH-1 : 0] adder_sum;
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin
      adder add(a[i], b[i], carry[i],
                adder_sum[i], carry[i+1]);
    end
  endgenerate
  assign carry[0] = carry_in;
  assign sum = adder_sum;
  assign carry_out = carry[WIDTH]; 
endmodule  

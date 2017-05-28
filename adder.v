module adder(input a, input b, input carry_in, output sum,
  output carry_out);

  wire sum_ab;
  wire and_carry_sum;
  wire and_ab;
  assign sum_ab = a ^ b;
  assign and_ab = a & b;
  assign sum = sum_ab ^ carry_in;
  assign and_carry_sum = carry_in & sum_ab;
  assign carry_out = and_carry_sum | and_ab;
endmodule

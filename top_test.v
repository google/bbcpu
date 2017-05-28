module top_test;

  reg clk = 0;
  wire d1, d2, d3, d4, d5;
  always #2 clk = !clk;
  initial
    # 100 $finish;

  top t(clk, d1, d2, d3, d4, d5);

  initial begin
    $dumpfile("top.vcd");
    $dumpvars;
  end
endmodule

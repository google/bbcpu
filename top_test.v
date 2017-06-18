`include "top.v"

module top_test;

  reg clk = 0;
  wire d1, d2, d3, d4, d5, uart_tx;
  always #2 clk = !clk;
  initial
    # 1500 $finish;

  top t(clk, d1, d2, d3, d4, d5, uart_tx);

  initial begin
    $dumpfile("top_test.vcd");
    $dumpvars;
  end
endmodule

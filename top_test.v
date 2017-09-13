`include "top.v"

module top_test;

  reg clk = 0;
  wire uart_tx;
  always #2 clk = !clk;
  initial
    # 1500 $finish;

  top t(clk, uart_tx);

  initial begin
    $dumpfile("top_test.vcd");
    $dumpvars;
  end
endmodule

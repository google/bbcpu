`include "cpu.v"

module top(input clk, output uart_tx_line);
  cpu node(clk, uart_tx_line);
endmodule

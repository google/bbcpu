`include "cpu.v"

module top(input clk, output d1, output d2, output d3, output d4,
  output d5);

  localparam LED_COUNT = 5;
  wire [LED_COUNT-1 : 0] leds;

  assign {d5, d4, d3, d2, d1} = leds;

  cpu #(.LED_COUNT(LED_COUNT)) node(clk, leds);
endmodule

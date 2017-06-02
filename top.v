`include "cpu.v"

module top(input clk, output d1, output d2, output d3, output d4,
  output d5);

  localparam clk_divider = 120000;
  localparam LED_COUNT = 5;
  reg [23:0] divider = 0;
  reg out_val = 0;
  wire output_clk;
  wire [LED_COUNT-1 : 0] leds; 

  assign output_clk = out_val;
  assign {d5, d4, d3, d2, d1} = leds;

  always @(posedge clk) begin
    if (divider == clk_divider) begin
      divider <= 0;
      out_val <= !out_val;
    end else
      divider <= divider + 1;
  end

  cpu #(.LED_COUNT(LED_COUNT)) node(output_clk, leds);
endmodule

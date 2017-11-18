/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`define IVERILOG_SIM
`include "top.v"

module top_test;

  localparam WIDTH = 8;
  localparam UART_WIDTH = $clog2(WIDTH);
  localparam OUTPUT_CNT = 12;

  reg clk = 1;
  reg uart_clk = 0;
  reg receiving = 0;
  reg display = 0;
  reg [UART_WIDTH-1 : 0] serial_cnt = 0;
  reg [WIDTH-1 : 0] serial_data;
  reg [WIDTH-1 : 0] expected_output [OUTPUT_CNT-1 : 0];
  wire uart_tx;

  reg [WIDTH-1 : 0] i, j, k, l;
  initial begin
    j = 1;
    k = 1;
    l = 0;
    for (i = 0; i < OUTPUT_CNT; i = i + 1) begin
      expected_output[i] = k;
      l = k;
      k = k + j;
      j = l;
    end
    i = 0;
  end

  always #2 clk = !clk;
  always #4 uart_clk = !uart_clk;

  top t(
    .clk(clk),
    .uart_tx_line(uart_tx));

  initial begin
    $dumpfile("top_test.vcd");
    $dumpvars;
  end

  always @ (posedge uart_clk) begin
    if (receiving) begin

      if (serial_cnt == WIDTH - 1 ) begin
        receiving <= 0;
        display <= 1;
      end

      serial_data[serial_cnt] <= uart_tx;
      serial_cnt <= serial_cnt + 1;

    end else if (display) begin

      if (i >= OUTPUT_CNT) begin
        $display("Test passed, computed results match the expected output!\n");
        $finish;
      end

      if (serial_data != expected_output[i]) begin
        $display("Test failed!\n");
        $display("Serial output:%d doesn't match expected_output[%d]:%d\n",
          serial_data, i, expected_output[i]);
        $finish;
      end

      i <= i + 1;
      display <= 0;

    end else begin

      if (uart_tx == 0) begin
        receiving <= 1;
      end

    end
  end

endmodule

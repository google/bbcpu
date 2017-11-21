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
`define TEST_PROG "prog_mul.list"
`include "top.v"

module top_test_mul;

  localparam WIDTH = 8;
  localparam UART_WIDTH = $clog2(WIDTH);
  localparam MUL_WIDTH = WIDTH / 2;

  reg clk = 1;
  reg uart_clk = 0;
  reg receiving = 0;
  reg display = 0;
  reg [UART_WIDTH-1 : 0] serial_cnt = 0;
  reg [WIDTH-1 : 0] serial_data;
  wire uart_tx;

  reg [WIDTH-1 : 0] in_args = 2;
  reg [WIDTH-1 : 0] expected_output = 0;

  always #2 clk = !clk;
  always #4 uart_clk = !uart_clk;

  top t(
    .clk(clk),
    .uart_tx_line(uart_tx));

  always @ (posedge uart_clk) begin
    if (receiving) begin

      if (serial_cnt == WIDTH - 1) begin
        receiving <= 0;
        display <= 1;
      end

      serial_data[serial_cnt] <= uart_tx;
      serial_cnt <= serial_cnt + 1;

    end else if (display) begin

      if (in_args == 0) begin
        $display("Multiply4x4 test passed!\n");
        $finish;
      end

      if (serial_data != expected_output) begin
        $display("Multiply4x4 test failed!\n");
        $display("Serial output:%d doesn't match expected_output:%d\n",
          serial_data, expected_output);
        $finish;
      end

      in_args <= in_args + 1;
      expected_output <= in_args[WIDTH-1 : MUL_WIDTH] * in_args[MUL_WIDTH-1 : 0];
      display <= 0;

    end else begin

      if (uart_tx == 0) begin
        receiving <= 1;
      end

    end
  end

endmodule

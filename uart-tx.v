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

module uarttx(
  input rst,
  input clk,
  input tx_start,
  input [7 : 0] tx_byte,
  output tx, output tx_ready);

  localparam STATE_IDLE       = 0;
  localparam STATE_START_BYTE = 1;
  localparam STATE_BYTE_1     = 2;
  localparam STATE_BYTE_2     = 3;
  localparam STATE_BYTE_3     = 4;
  localparam STATE_BYTE_4     = 5;
  localparam STATE_BYTE_5     = 6;
  localparam STATE_BYTE_6     = 7;
  localparam STATE_BYTE_7     = 8;
  localparam STATE_BYTE_8     = 9;
  localparam STATE_STOP_BYTE1 = 10;
  localparam STATE_STOP_BYTE2 = 11;
  localparam STATE_FINISH     = 12;
  localparam STATE_WIDTH = $clog2(STATE_FINISH);

  parameter CLK_SPEED = 12000000; //Hz
`ifdef IVERILOG_SIM
  parameter BAUD_RATE = CLK_SPEED / 2;
`else
  parameter BAUD_RATE = 19200;
`endif
  localparam BAUD_COUNT = CLK_SPEED / BAUD_RATE;
  localparam BAUD_REG_SIZE = $clog2(BAUD_COUNT);
  reg [BAUD_REG_SIZE-1 : 0] baud_counter;
  reg [STATE_WIDTH-1 : 0] tx_state;
  reg tx_val;
  reg [7 : 0] value;

  assign tx_ready = (tx_state != STATE_IDLE) || (tx_start) ? 0 : 1;
  assign tx = (tx_state == STATE_IDLE) ? 1 : tx_val;

  always @(posedge clk) begin
    if (rst) begin
      tx_state <= 0;
      tx_val <= 0;
      baud_counter <= 0;
      value <= 0;
    end else begin
      if (baud_counter == BAUD_COUNT) begin
        baud_counter <= 0;
      end else if (tx_state != STATE_IDLE) begin
        baud_counter <= baud_counter + 1;
      end

      case (tx_state)
        STATE_IDLE: begin
          if (tx_start) begin
            tx_state <= STATE_START_BYTE;
            tx_val <= 1;
            value <= tx_byte;
          end
        end
        STATE_START_BYTE: begin
          if (baud_counter == 0) begin
            tx_val <= 0;
            tx_state <= STATE_BYTE_1;
          end
        end
        STATE_BYTE_1: begin
          if (baud_counter == 0) begin
            tx_val <= value[0];
            tx_state <= STATE_BYTE_2;
          end
        end
        STATE_BYTE_2: begin
          if (baud_counter == 0) begin
            tx_val <= value[1];
            tx_state <= STATE_BYTE_3;
          end
        end
        STATE_BYTE_3: begin
          if (baud_counter == 0) begin
            tx_val <= value[2];
            tx_state <= STATE_BYTE_4;
          end
        end
        STATE_BYTE_4: begin
          if (baud_counter == 0) begin
            tx_val <= value[3];
            tx_state <= STATE_BYTE_5;
          end
        end
        STATE_BYTE_5: begin
          if (baud_counter == 0) begin
            tx_val <= value[4];
            tx_state <= STATE_BYTE_6;
          end
        end
        STATE_BYTE_6: begin
          if (baud_counter == 0) begin
            tx_val <= value[5];
            tx_state <= STATE_BYTE_7;
          end
        end
        STATE_BYTE_7: begin
          if (baud_counter == 0) begin
            tx_val <= value[6];
            tx_state <= STATE_BYTE_8;
          end
        end
        STATE_BYTE_8: begin
          if (baud_counter == 0) begin
            tx_val <= value[7];
            tx_state <= STATE_STOP_BYTE1;
          end
        end
        STATE_STOP_BYTE1: begin
          if (baud_counter == 0) begin
            tx_val <= 1;
            tx_state <= STATE_STOP_BYTE2;
          end
        end
        STATE_STOP_BYTE2: begin
          if (baud_counter == 0) begin
            tx_val <= 1;
            tx_state <= STATE_FINISH;
          end
        end
        STATE_FINISH : begin
          tx_state <= STATE_IDLE;
        end
        default: begin
          tx_state <= STATE_IDLE;
        end
      endcase
    end
  end
endmodule

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

module pcounter(
  input rst,
  input clk,
  input enable,
  input jump,
  input out_enable,
  input [ADDRESS_WIDTH-1 : 0] bus_in,
  output [ADDRESS_WIDTH-1 : 0] bus_out);

  parameter ADDRESS_WIDTH = 4;
  reg [ADDRESS_WIDTH-1 : 0] counter;

  assign bus_out = (out_enable) ? counter : 0;

  always @(posedge clk) begin
    if (rst) begin
      counter <= 0;
    end else begin
      if (enable) begin
        counter <= counter + 1;
      end else if (jump) begin
        counter <= bus_in;
      end
    end
  end
endmodule

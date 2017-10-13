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

module fadder(
  input [WIDTH-1 : 0] a,
  input [WIDTH - 1 : 0] b,
  input sub_enable,
  input carry_in,
  output [WIDTH - 1 : 0] res,
  output carry_out);

  parameter WIDTH = 8;
  wire [WIDTH - 1 : 0] carry;
  wire [WIDTH - 1 : 0] b_in;

  assign carry_out = carry[WIDTH-1];
  assign b_in = sub_enable ? ~(b) : b;

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin
      if (i == 0) begin
        assign res[i] = (a[i] ^ b_in[i]) ^ carry_in;
        assign carry[i] = ((a[i] ^ b_in[i]) & carry_in) | (a[i] & b_in[i]);
      end else begin
        assign res[i] = (a[i] ^ b_in[i]) ^ carry[i-1];
        assign carry[i] = ((a[i] ^ b_in[i]) & carry[i-1]) | (a[i] & b_in[i]);
      end
    end
  endgenerate

endmodule

/*
 * Copyright 2017 Emilian Peev
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

module alu(input rst, input clk, input alu_enable, input rega_enable,
  input regb_enable, input rega_write_enable,
  input regb_write_enable, input sub_enable,
  input [WIDTH-1 : 0] bus_in, output [WIDTH-1 : 0] bus_out,
  output carry_out);

  parameter WIDTH = 8;
  reg [WIDTH-1 : 0] reg_a;
  reg [WIDTH-1 : 0] reg_b;
  reg [WIDTH: 0] result;
  wire [WIDTH-1 : 0] sum;
  wire [WIDTH-1 : 0] carry;
  wire [WIDTH-1 : 0] b_in;

  assign b_in = sub_enable ? ~(reg_b) : reg_b;
  assign bus_out = (alu_enable) ? result[WIDTH-1:0] :
                   (rega_enable) ? reg_a :
                   (regb_enable) ? reg_b : {WIDTH{1'b1}};
  assign carry_out = result[WIDTH];

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin
      if (i == 0) begin
        assign sum[i] = (reg_a[i] ^ b_in[i]) ^ sub_enable;
        assign carry[i] = ((reg_a[i] ^ b_in[i]) & sub_enable) | (reg_a[i] & b_in[i]);
      end else begin
        assign sum[i] = (reg_a[i] ^ b_in[i]) ^ carry[i-1];
        assign carry[i] = ((reg_a[i] ^ b_in[i]) & carry[i-1]) | (reg_a[i] & b_in[i]);
      end
    end
  endgenerate

  always @(posedge clk) begin
    if (rst) begin
      result <= 0;
      reg_a <= 0;
      reg_b <= 0;
    end else begin
      result <= {carry[WIDTH-1], sum};
      if (rega_write_enable) begin
        reg_a <= bus_in;
      end else if (regb_write_enable) begin
        reg_b <= bus_in;
      end
    end
  end
endmodule

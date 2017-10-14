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

`include "mul4x4.v"

module alu(
  input rst,
  input clk,
  input alu_enable,
  input rega_enable,
  input regb_enable,
  input rega_write_enable,
  input regb_write_enable,
  input mul_enable,
  input sub_enable,
  input shift_enable,
  input [2 : 0] shift_pos,
  input [WIDTH-1 : 0] bus_in,
  output [WIDTH-1 : 0] bus_out,
  output carry_out);

  parameter WIDTH = 8;

  reg [WIDTH-1 : 0] reg_a;
  reg [WIDTH-1 : 0] reg_b;
  reg [WIDTH: 0] result;

  wire [WIDTH-1 : 0] adder_res;
  wire adder_carry;

  wire [7 : 0] shift_res;
  wire shift_carry;

  wire [7: 0] mul_res;

  assign bus_out = (alu_enable) ? result[WIDTH-1:0] :
                   (rega_enable) ? reg_a :
                   (regb_enable) ? reg_b : {WIDTH{1'b1}};
  assign carry_out = result[WIDTH];

  fadder #(.WIDTH(WIDTH)) fadder(
    .a(reg_a),
    .b(reg_b),
    .sub_enable(sub_enable),
    .carry_in(sub_enable),
    .res(adder_res),
    .carry_out(adder_carry));

  shl8 left_shift(
    .a(reg_a),
    .shift(shift_pos),
    .res(shift_res),
    .carry(shift_carry));

  mul4x4 multiply(reg_a[3:0], reg_a[7:4], mul_res);

  always @(posedge clk) begin
    if (rst) begin
      result <= 0;
      reg_a <= 0;
      reg_b <= 0;
    end else begin
      if (mul_enable) begin
        result <= {1'b0, mul_res};
      end else if (shift_enable) begin
        result <= {shift_carry, shift_res};
      end else begin
        result <= {adder_carry, adder_res};
      end
      if (rega_write_enable) begin
        reg_a <= bus_in;
      end else if (regb_write_enable) begin
        reg_b <= bus_in;
      end
    end
  end
endmodule

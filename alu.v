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
  input [WIDTH-1 : 0] a,
  input [WIDTH-1 : 0] b,
  input mul_enable,
  input sub_enable,
  input shift_enable,
  input [2 : 0] shift_pos,
  output [WIDTH-1 : 0] result,
  output carry_out);

  parameter WIDTH = 8;

  wire [WIDTH-1 : 0] adder_res;
  wire adder_carry;

  wire [7 : 0] shift_res;
  wire shift_carry;

  wire [7: 0] mul_res;

  assign result = (mul_enable) ? mul_res :
                  (shift_enable) ? shift_res :
                  (adder_res);
  assign carry_out = (shift_enable) ? shift_carry :
                     adder_carry;

  fadder #(.WIDTH(WIDTH)) ripple_adder(
    .a(a),
    .b(b),
    .sub_enable(sub_enable),
    .carry_in(sub_enable),
    .res(adder_res),
    .carry_out(adder_carry));

  shl8 left_shift(
    .a(a),
    .shift(shift_pos),
    .res(shift_res),
    .carry(shift_carry));

  mul4x4 multiply(a[3:0], a[7:4], mul_res);

endmodule

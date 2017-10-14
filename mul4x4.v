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

`include "fadder.v"
`include "shl8.v"

module mul4x4(
  input [3 : 0] a,
  input [3 : 0] b,
  output [7 : 0] res);

  wire [2 : 0] shift_carry, sum_carry;
  wire [7 : 0] a0, a1, a2, a3, sum0, sum1, sum2;

  assign a0 = {4'b0, b[0] ? a : {3'b0}};

  shl8 shifta1(
    .a({4'b0, b[1] ? a : {3'b0}}),
    .shift(3'b001),
    .res(a1),
    .carry(shift_carry[0]));

  shl8 shifta2(
    .a({4'b0, b[2] ? a : {3'b0}}),
    .shift(3'b010),
    .res(a2),
    .carry(shift_carry[1]));

  shl8 shifta3(
    .a({4'b0, b[3] ? a : {3'b0}}),
    .shift(3'b011),
    .res(a3),
    .carry(shift_carry[2]));

  fadder #(.WIDTH(8)) adder1(
    .a(a0),
    .b(a1),
    .sub_enable(1'b0),
    .carry_in(1'b0),
    .res(sum0),
    .carry_out(sum_carry[0]));

  fadder #(.WIDTH(8)) adder2(
    .a(sum0),
    .b(a2),
    .sub_enable(1'b0),
    .carry_in(1'b0),
    .res(sum1),
    .carry_out(sum_carry[1]));

  fadder #(.WIDTH(8)) adder3(
    .a(sum1),
    .b(a3),
    .sub_enable(1'b0),
    .carry_in(1'b0),
    .res(sum2),
    .carry_out(sum_carry[2]));

  assign res = sum2;
endmodule

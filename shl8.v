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

module shl8(input [7 : 0] a, input [2 : 0] shift, output [7 : 0] res, output carry);
  assign {carry, res} = (shift == 3'b000) ? {1'b0, a} :
                        (shift == 3'b001) ? {a[7 : 0], {1'b0}}:
                        (shift == 3'b010) ? {a[6 : 0], {2'b0}}:
                        (shift == 3'b011) ? {a[5 : 0], {3'b0}}:
                        (shift == 3'b100) ? {a[4 : 0], {4'b0}}:
                        (shift == 3'b101) ? {a[3 : 0], {5'b0}}:
                        (shift == 3'b110) ? {a[2 : 0], {6'b0}}:
                        {a[1 : 0], {7'b0}};
endmodule

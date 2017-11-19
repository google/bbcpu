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

module ram(
  input clk,
  input enable,
  input write_enable,
  input [WIDTH-1 : 0] addr,
  input [WIDTH-1 : 0] data_in,
  output [WIDTH-1 : 0] data_out);

  parameter ADDRESS_WIDTH = 4;
  parameter WIDTH = 8;
  parameter MEMORY_SIZE = 1 << ADDRESS_WIDTH;
  reg [WIDTH-1 : 0] mem [0 : MEMORY_SIZE-1];

  initial begin
`ifdef IVERILOG_SIM
    $readmemb(`TEST_PROG, mem);
`else
    $readmemb("prog_fib.list", mem);
`endif
  end

  assign data_out = (enable) ? mem[addr] : {WIDTH{1'b0}};

  always @(posedge clk) begin
    if (write_enable) begin
      mem[addr] <= data_in;
    end
  end
endmodule

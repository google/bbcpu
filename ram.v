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

module ram(input rst, input clk, input enable, input addr_enable,
  input write_enable, input [WIDTH-1 : 0] bus_in,
  output [WIDTH-1 : 0] bus_out);

  parameter ADDRESS_WIDTH = 4;
  parameter WIDTH = 8;
  parameter MEMORY_SIZE = 1 << ADDRESS_WIDTH;
  reg [WIDTH-1 : 0] mem [0 : MEMORY_SIZE-1];
  reg [ADDRESS_WIDTH-1 : 0] addr_reg;

  initial begin
    $readmemb("prog.list", mem);
  end

  assign bus_out = (enable) ? mem[addr_reg] : {WIDTH{1'b0}};

  always @(posedge clk) begin
    if (rst) begin
      addr_reg <= 0;
    end else begin
      if (write_enable) begin
        mem[addr_reg] <= bus_in;
      end else if (addr_enable) begin
        addr_reg <= bus_in[ADDRESS_WIDTH-1 : 0];
      end
    end
  end
endmodule

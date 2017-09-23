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

`include "alu.v"
`include "pcounter.v"
`include "ram.v"
`include "uart-tx.v"

module cpu(input clk, output uart_tx_wire);
  localparam INSTR_SIZE = 4;
  localparam WIDTH = 8;
  localparam ADDRESS_WIDTH = WIDTH - INSTR_SIZE;

  localparam NOP = 4'b0000; //No operation.
  localparam LDA = 4'b0001; //Load register A from memory.
  localparam ADD = 4'b0010; //Add specified memory pointer to register A.
                            //Store the result in register A.
  localparam SUB = 4'b0011; //Subtract specified memory from register A.
                            //Store the result in register A.
  localparam STA = 4'b0100; //Store register A to memory.
  localparam OUT = 4'b0101; //Send register A to UART port. The instruction
                            //will block until the transfer completes.
  localparam JMP = 4'b0110; //Jump at some code location
  localparam LDI = 4'b0111; //Load 4'bit immediate value in register A.
  localparam JC  = 4'b1000; //Jump if carry flag is set.
  localparam HLT = 4'b1111; //Halt CPU control clock;

  //Control signals
  localparam j   = 0;  //Program counter jump
  localparam co  = 1;  //Program counter output enable
  localparam ce  = 2;  //Program counter enable
  localparam oi  = 3;  //Display/UART tx
  localparam bi  = 4;  //Register B write enable
  localparam su  = 5;  //Subtract enable
  localparam eo  = 6;  //ALU enable
  localparam ao  = 7;  //Register A read enable
  localparam ai  = 8;  //Register A write enable
  localparam io  = 9;  //Instruction register read enable
  localparam ro  = 10; //RAM out
  localparam ri  = 11; //RAM in
  localparam mi  = 12; //Address in
  localparam SIG_COUNT = mi + 1;

  localparam STAGE_T0 = 0;
  localparam STAGE_T1 = 1;
  localparam STAGE_T2 = 2;
  localparam STAGE_T3 = 3;
  localparam STAGE_T4 = 4;
  localparam STAGE_T5 = 5;
  localparam STAGE_T6 = 6;
  localparam STAGE_COUNT = STAGE_T6 + 1;
  localparam STAGE_WIDTH = $clog2(STAGE_COUNT);

  localparam rst_size = 5;
  localparam rst_max = (1 << 5) - 1;

  reg [rst_size : 0] rst_cnt = 0;
  reg rstn = 0;
  reg [WIDTH-1 : 0] ir;               //Instruction register.
  reg [SIG_COUNT-1 : 0] ctrl_reg;     //Holds control signal status.
  reg [STAGE_WIDTH-1 : 0] stage_reg;  //Keeps track of the current execution stage.
  reg carry_status;
  wire [ADDRESS_WIDTH-1 : 0] pc_in;   //Program counter I/O
  wire [ADDRESS_WIDTH-1 : 0] pc_out;  //
  wire [WIDTH-1 : 0] alu_in;          //ALU I/O
  wire [WIDTH-1 : 0] alu_out;         //
  wire [WIDTH-1 : 0] mem_in;          //RAM I/O
  wire [WIDTH-1 : 0] mem_out;         //
  wire alu_carry;                     //Carry signal
  wire tx_idle;                       //UART TX idle signal

  //CPU modules
  pcounter #(.ADDRESS_WIDTH(ADDRESS_WIDTH)) pc(.rst(!rstn), .clk(clk),
    .enable(ctrl_reg[ce]), .jump(ctrl_reg[j]),
    .out_enable(ctrl_reg[co]), .bus_in(pc_in), .bus_out(pc_out));

  //Register B output enable functionality is not used at the moment
  alu #(.WIDTH(WIDTH)) alu(.rst(!rstn), .clk(clk), .alu_enable(ctrl_reg[eo]),
    .rega_enable(ctrl_reg[ao]), .regb_enable(1'b0),
    .rega_write_enable(ctrl_reg[ai]), .regb_write_enable(ctrl_reg[bi]),
    .sub_enable(ctrl_reg[su]), .bus_in(alu_in), .bus_out(alu_out),
    .carry_out(alu_carry));

  ram #(.WIDTH(WIDTH),.ADDRESS_WIDTH(ADDRESS_WIDTH)) memory(.rst(!rstn), .clk(clk),
    .enable(ctrl_reg[ro]), .addr_enable(ctrl_reg[mi]),
    .write_enable(ctrl_reg[ri]), .bus_in(mem_in), .bus_out(mem_out));

  uarttx uart(.rst(!rstn), .clk(clk), .tx_start(ctrl_reg[oi]), .tx_byte(alu_out),
    .tx(uart_tx_wire), .tx_ready(tx_idle));

  //Data transfer paths
  assign pc_in = (ctrl_reg[j] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] : 0;
  assign alu_in = ((ctrl_reg[ai] || ctrl_reg[bi]) && ctrl_reg[ro]) ? mem_out :
                  (ctrl_reg[ai] && ctrl_reg[eo]) ? alu_out :
                  (ctrl_reg[ai] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] : 0;
  assign mem_in = (ctrl_reg[mi] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] :
                  (ctrl_reg[mi] && ctrl_reg[co]) ? pc_out :
                  (ctrl_reg[ri] && ctrl_reg[ao]) ? alu_out : 0;

  always @(posedge clk) begin
    if (rst_cnt != rst_max) begin
      rst_cnt <= rst_cnt + 1;
    end else begin
      rstn <= 1;
    end
  end

  always @(posedge clk) begin
    if (rstn) begin
      case (stage_reg)
        STAGE_T0: begin
          ctrl_reg <= (1 << mi) | (1 << co);
          stage_reg <= STAGE_T1;
        end
        STAGE_T1: begin
          ctrl_reg <= 1 << ro;
          stage_reg <= STAGE_T2;
        end
        STAGE_T2: begin
          ctrl_reg <= 1 << ce;
          ir <= mem_out;
          stage_reg <= STAGE_T3;
        end
        STAGE_T3: begin
          case (ir[WIDTH-1 : ADDRESS_WIDTH])
            LDA: begin
              ctrl_reg <= (1 << mi) | (1 << io);
              stage_reg <= STAGE_T4;
            end
            STA: begin
              ctrl_reg <= (1 << mi) | (1 << io);
              stage_reg <= STAGE_T4;
            end
            ADD: begin
                 ctrl_reg <= (1 << mi) | (1 << io);
                 stage_reg <= STAGE_T4;
            end
            SUB: begin
              ctrl_reg <= (1 << mi) | (1 << io);
              stage_reg <= STAGE_T4;
            end
            OUT: begin
              ctrl_reg <= (1 << ao) | (1 << oi);
              stage_reg <= STAGE_T4;
            end
            JMP: begin
              ctrl_reg <= (1 << j) | (1 << io);
              stage_reg <= STAGE_T0;
            end
            JC:  begin
              if (carry_status) begin
                ctrl_reg <= (1 << j) | (1 << io);
              end else begin
                ctrl_reg <= 0;
              end
              stage_reg <= STAGE_T0;
            end
            LDI: begin
              ctrl_reg <= (1 << io) | (1 << ai);
              stage_reg <= STAGE_T0;
            end
            NOP: begin
              ctrl_reg <= 0;
              stage_reg <= STAGE_T0;
            end
            HLT: begin
              ctrl_reg <= 0;
              stage_reg <= STAGE_COUNT;
            end
            default: begin
              stage_reg <= STAGE_COUNT;
            end
          endcase
        end
        STAGE_T4: begin
          case (ir[WIDTH-1 : ADDRESS_WIDTH])
            LDA: begin
              ctrl_reg <= (1 << ro) | (1 << ai);
              stage_reg <= STAGE_T0;
            end
            STA: begin
              ctrl_reg <= (1 << ri) | (1 << ao);
              stage_reg <= STAGE_T0;
            end
            ADD: begin
              ctrl_reg <= (1 << ro) | (1 << bi);
              stage_reg <= STAGE_T5;
            end
            SUB: begin
              ctrl_reg <= (1 << ro) | (1 << bi) | (1 << su);
              stage_reg <= STAGE_T5;
            end
            OUT: begin
              ctrl_reg <= 0;
              if (tx_idle) begin
                stage_reg <= STAGE_T0;
              end else begin
                stage_reg <= STAGE_T4;
              end
            end
            default: begin
              stage_reg <= STAGE_COUNT;
            end
          endcase
        end
        STAGE_T5: begin
          case (ir[WIDTH-1 : ADDRESS_WIDTH])
            ADD: begin
              ctrl_reg <= 0;
              carry_status <= alu_carry;
              stage_reg <= STAGE_T6;
            end
            SUB: begin
              ctrl_reg <= 0;
              stage_reg <= STAGE_T6;
            end
            default: begin
              stage_reg <= STAGE_COUNT;
            end
          endcase
        end
        default: begin
          stage_reg <= STAGE_COUNT;
        end
      STAGE_T6: begin
          case (ir[WIDTH-1 : ADDRESS_WIDTH])
            ADD: begin
              ctrl_reg <= (1 << ai) | (1 << eo);
              stage_reg <= STAGE_T0;
            end
            SUB: begin
              ctrl_reg <= (1 << ai) | (1 << eo) | (1 << su);
              stage_reg <= STAGE_T0;
            end
            default: begin
              stage_reg <= STAGE_COUNT;
            end
          endcase
      end
      endcase
    end else begin
      ir <= 0;
      carry_status <= 0;
      ctrl_reg <= 0;
      stage_reg <= STAGE_T0;
    end
  end
endmodule

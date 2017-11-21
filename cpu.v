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

`include "alu.v"
`include "pcounter.v"
`include "ram.v"
`include "uart-tx.v"

module cpu(
  input clk,
  output uart_tx_wire);
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
  localparam SHLA= 4'b1001; //Logical shift left of register A.
  localparam MULA= 4'b1010; //Unsigned multiplcation between two nibbles in register A.
                            //Result is stored again in register A.
  localparam HLT = 4'b1111; //Halt CPU control clock;

  //Control signals
  localparam j   = 0;  //Program counter jump
  localparam co  = 1;  //Program counter output enable
  localparam ce  = 2;  //Program counter enable
  localparam oi  = 3;  //Display/UART tx
  localparam su  = 4;  //Subtract enable
  localparam ao  = 5;  //Register A read enable
  localparam io  = 6;  //Instruction register read enable
  localparam ro  = 7;  //RAM out
  localparam ri  = 8;  //RAM in
  localparam mi  = 9;  //Address in
  localparam she = 10; //Shift enable
  localparam mul = 11; //Multiply enable
  localparam SIG_COUNT = mul + 1;

  localparam STAGE_T0 = 0;
  localparam STAGE_T1 = 1;
  localparam STAGE_T2 = 2;
  localparam STAGE_T3 = 3;
  localparam STAGE_T4 = 4;
  localparam STAGE_COUNT = STAGE_T4 + 1;
  localparam STAGE_WIDTH = $clog2(STAGE_COUNT);

  localparam rst_size = 5;
  localparam rst_max = (1 << 5) - 1;

  reg [rst_size : 0] rst_cnt = 0;
  reg rstn = 0;
  reg [WIDTH-1 : 0] ir;               //Instruction register.
  reg [SIG_COUNT-1 : 0] ctrl_reg;     //Holds control signal status.
  reg [STAGE_WIDTH-1 : 0] stage_reg;  //Keeps track of the current execution stage.
  reg [WIDTH-1 : 0] reg_a;            //A CPU register
  reg [WIDTH-1 : 0] reg_b;            //B CPU register
  reg carry_status;
  wire [WIDTH-1 : 0] alu_out;         //ALU I/O
  wire alu_carry;                     //
  wire [ADDRESS_WIDTH-1 : 0] pc_in;   //Program counter I/O
  wire [ADDRESS_WIDTH-1 : 0] pc_out;  //
  wire [WIDTH-1 : 0] mem_in;          //RAM I/O
  wire [WIDTH-1 : 0] mem_out;         //
  wire [WIDTH-1 : 0] mem_addr;        //
  wire tx_idle;                       //UART TX idle signal

  //CPU modules
  pcounter #(.ADDRESS_WIDTH(ADDRESS_WIDTH)) pc(
    .rst(!rstn),
    .clk(clk),
    .enable(ctrl_reg[ce]),
    .jump(ctrl_reg[j]),
    .out_enable(ctrl_reg[co]),
    .bus_in(pc_in),
    .bus_out(pc_out));

  alu #(.WIDTH(WIDTH)) alu(
    .a(reg_a),
    .b(reg_b),
    .mul_enable(ctrl_reg[mul]),
    .sub_enable(ctrl_reg[su]),
    .shift_enable(ctrl_reg[she]),
    .shift_pos(ir[2 : 0]),
    .result(alu_out),
    .carry_out(alu_carry));

  ram #(.WIDTH(WIDTH),.ADDRESS_WIDTH(ADDRESS_WIDTH)) memory(
    .clk(clk),
    .enable(ctrl_reg[ro]),
    .write_enable(ctrl_reg[ri]),
    .addr(mem_addr),
    .data_in(mem_in),
    .data_out(mem_out));

  uarttx uart(
    .rst(!rstn),
    .clk(clk),
    .tx_start(ctrl_reg[oi]),
    .tx_byte(reg_a),
    .tx(uart_tx_wire),
    .tx_ready(tx_idle));

  //Data transfer paths
  assign pc_in = (ctrl_reg[j] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] : 0;
  assign mem_addr = (ctrl_reg[mi] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] :
                    (ctrl_reg[mi] && ctrl_reg[co]) ? pc_out : 0;
  assign mem_in = (ctrl_reg[ri] && ctrl_reg[ao]) ? reg_a : 0;

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
          ctrl_reg <= (1 << ro) | (1 << mi) | (1 << co);
          stage_reg <= STAGE_T1;
        end
        STAGE_T1: begin
          ctrl_reg <= 1 << ce;
          ir <= mem_out;
          stage_reg <= STAGE_T2;
        end
        STAGE_T2: begin
          case (ir[WIDTH-1 : ADDRESS_WIDTH])
            MULA: begin
              ctrl_reg <= (1 << mul);
              stage_reg <= STAGE_T3;
            end
            SHLA: begin
              ctrl_reg <= (1 << she);
              stage_reg <= STAGE_T3;
            end
            LDA: begin
              ctrl_reg <= (1 << ro) | (1 << mi) | (1 << io);
              stage_reg <= STAGE_T3;
            end
            STA: begin
              ctrl_reg <= (1 << ri) | (1 << ao) | (1 << mi) | (1 << io);
              stage_reg <= STAGE_T0;
            end
            ADD: begin
              ctrl_reg <= (1 << ro) | (1 << mi) | (1 << io);
              stage_reg <= STAGE_T3;
            end
            SUB: begin
              ctrl_reg <= (1 << ro) | (1 << mi) | (1 << io);
              stage_reg <= STAGE_T3;
            end
            OUT: begin
              ctrl_reg <= 1 << oi;
              stage_reg <= STAGE_T3;
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
              ctrl_reg <= 0;
              reg_a <= {4'b0, ir[3 : 0]};
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
        STAGE_T3: begin
          case (ir[WIDTH-1 : ADDRESS_WIDTH])
            MULA: begin
              reg_a <= alu_out;
              carry_status <= alu_carry;
              stage_reg <= STAGE_T0;
            end
            SHLA: begin
              reg_a <= alu_out;
              carry_status <= alu_carry;
              stage_reg <= STAGE_T0;
            end
            LDA: begin
              reg_a <= mem_out;
              stage_reg <= STAGE_T0;
            end
            ADD: begin
              ctrl_reg <= 0;
              reg_b <= mem_out;
              stage_reg <= STAGE_T4;
            end
            SUB: begin
              ctrl_reg <= 1 << su;
              reg_b <= mem_out;
              stage_reg <= STAGE_T4;
            end
            OUT: begin
              ctrl_reg <= 0;
              if (tx_idle) begin
                stage_reg <= STAGE_T0;
              end else begin
                stage_reg <= STAGE_T3;
              end
            end
            default: begin
              stage_reg <= STAGE_COUNT;
            end
          endcase
        end
        STAGE_T4: begin
          case (ir[WIDTH-1 : ADDRESS_WIDTH])
            ADD: begin
              reg_a <= alu_out;
              carry_status <= alu_carry;
              stage_reg <= STAGE_T0;
            end
            SUB: begin
              reg_a <= alu_out;
              stage_reg <= STAGE_T0;
            end
            default: begin
              stage_reg <= STAGE_COUNT;
            end
          endcase
        end
        default: begin
          stage_reg <= STAGE_COUNT;
        end
      endcase
    end else begin
      ir <= 0;
      carry_status <= 0;
      ctrl_reg <= 0;
      reg_a <= 0;
      reg_b <= 0;
      stage_reg <= STAGE_T0;
    end
  end
endmodule

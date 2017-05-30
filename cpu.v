`include "adder.v"
`include "adderN.v"
`include "alu.v"
`include "pcounter.v"
`include "ram.v"

module cpu(input clk, output [LED_COUNT-1 : 0] leds);

  parameter LED_COUNT = 5;
  localparam INSTR_SIZE = 4;
  localparam WIDTH = 8;
  localparam ADDRESS_WIDTH = WIDTH - INSTR_SIZE;

  //TODO: Load externally
  localparam LDA = 4'b0001; //Load register A from memory instruction code.
  localparam ADD = 4'b0010; //Add specified memory pointer to register A.
                            //Store the result in register A.
  localparam JMP = 4'b1100; //Jump at some code location
  localparam LDI = 4'b0111; //Load 4'bit immediate value in register A.
  localparam OUT = 4'b1110; //Output contents of register A to output device.
  localparam HLT = 4'b1111; //Halt CPU control clock;

  //Control signals
  //ce - Program counter enable
  //j  - Program counter jump
  //co - Program counter output enable
  //oi - Display/leds input
  //bi - Register B write enable
  //su - Subtract enable
  //eo - ALU enable
  //ao - Register A read enable
  //ai - Register A write enable
  //ii - Insruction register write enable
  //io - Instruction register read enable
  //ro - RAM out
  //ri - RAM in
  //mi - Address in
  //hlt- Halt
  localparam j   = 0;
  localparam co  = 1;
  localparam ce  = 2;
  localparam oi  = 3;
  localparam bi  = 4;
  localparam su  = 5;
  localparam eo  = 6;
  localparam ao  = 7;
  localparam ai  = 8;
  localparam ii  = 9;
  localparam io  = 10;
  localparam ro  = 11;
  localparam ri  = 12;
  localparam mi  = 13;
  localparam hlt = 14;
  localparam SIG_COUNT = hlt+1;

  localparam STAGE_INIT = 0;
  localparam STAGE_T1 = 1;
  localparam STAGE_T2 = 2;
  localparam STAGE_T3 = 3;
  localparam STAGE_T4 = 4;
  localparam STAGE_T5 = 5;
  localparam STAGE_COUNT = STAGE_T5 + 1;
  localparam STAGE_WIDTH = 3;             //log2(STAGE_COUNT);
  reg [WIDTH-1 : 0] ir = 0;               //Instruction register.
  reg [SIG_COUNT-1 : 0] ctrl_reg = 0;     //Holds control signal status.
  reg [STAGE_WIDTH-1 : 0] stage_reg = 0;  //Keeps track of the current
                                          //execution stage.
  reg [STAGE_WIDTH-1 : 0] next_stage = 0; //Keeps the next stage
  reg [LED_COUNT-1 : 0] out_reg = 0;      //Output LED register.
  wire [ADDRESS_WIDTH-1 : 0] pc_in;       //Program counter I/O
  wire [ADDRESS_WIDTH-1 : 0] pc_out;      //
  wire [WIDTH-1 : 0] alu_in;              //ALU I/O
  wire [WIDTH-1 : 0] alu_out;             //
  wire [WIDTH-1 : 0] mem_in;              //RAM I/O
  wire [WIDTH-1 : 0] mem_out;             //
  wire alu_carry;                         //Not used currently
  wire control_clk;                       //Control clock that can be halted

  //CPU modules
  pcounter #(.ADDRESS_WIDTH(ADDRESS_WIDTH)) pc(.clk(clk),
    .enable(ctrl_reg[ce]), .jump(ctrl_reg[j]),
    .out_enable(ctrl_reg[co]), .bus_in(pc_in), .bus_out(pc_out));

  //Register B output enable functionality is not used at the moment
  alu #(.WIDTH(WIDTH)) alu(.clk(clk), .alu_enable(ctrl_reg[eo]),
    .rega_enable(ctrl_reg[ao]), .regb_enable(1'b0),
    .rega_write_enable(ctrl_reg[ai]), .regb_write_enable(ctrl_reg[bi]),
    .sub_enable(ctrl_reg[su]), .bus_in(alu_in), .bus_out(alu_out),
    .carry(alu_carry));

  ram #(.WIDTH(WIDTH),.ADDRESS_WIDTH(ADDRESS_WIDTH)) memory(.clk(clk),
    .enable(ctrl_reg[ro]), .addr_enable(ctrl_reg[mi]),
    .write_enable(ctrl_reg[ri]), .bus_in(mem_in), .bus_out(mem_out));

  //Setup data paths
  assign leds = out_reg;
  assign pc_in = (ctrl_reg[j] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] : 0;
  assign alu_in = ((ctrl_reg[ai] || ctrl_reg[bi]) && ctrl_reg[ro]) ? mem_out :
                  (ctrl_reg[ai] && ctrl_reg[eo]) ? alu_out :
                  (ctrl_reg[ai] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] : 0;
  assign mem_in = (ctrl_reg[mi] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] :
                  (ctrl_reg[mi] && ctrl_reg[co]) ? pc_out : 0;
  assign control_clk = (!ctrl_reg[hlt]) ? clk : 0;

  //Control logic
  always @(negedge control_clk) begin
    stage_reg <= next_stage;
  end

  always @(*)
    if (ctrl_reg[ii] && ctrl_reg[ro])
      ir = mem_out;
    else if (ctrl_reg[oi] && ctrl_reg[ao])
      out_reg = alu_out[LED_COUNT-1 : 0];

  always @(*) begin
    ctrl_reg = 0;
    case (stage_reg)
      STAGE_INIT: begin
        next_stage = STAGE_T1;
        end
      STAGE_T1: begin
        ctrl_reg[mi] = 1;
        ctrl_reg[co] = 1;
        next_stage = STAGE_T2;
        end
      STAGE_T2: begin
        ctrl_reg[ro] = 1;
        ctrl_reg[ii] = 1;
        ctrl_reg[ce] = 1;
        next_stage = STAGE_T3;
        end
      STAGE_T3: begin
        case (ir[WIDTH-1 : ADDRESS_WIDTH])
          LDA: begin
               ctrl_reg[mi] = 1;
               ctrl_reg[io] = 1;
               next_stage = STAGE_T4;
               end
          ADD: begin
               ctrl_reg[mi] = 1;
               ctrl_reg[io] = 1;
               next_stage = STAGE_T4;
               end
          OUT: begin
               ctrl_reg[ao] = 1;
               ctrl_reg[oi] = 1;
               next_stage = STAGE_T1;
               end
          JMP: begin
               ctrl_reg[j] = 1;
               ctrl_reg[io] = 1;
               next_stage = STAGE_T1;
               end
          LDI: begin
               ctrl_reg[io] = 1;
               ctrl_reg[ai] = 1;
               next_stage = STAGE_T1;
               end
          HLT: begin
               ctrl_reg[hlt] = 1;
               end
        endcase
      end
      STAGE_T4: begin
        case (ir[WIDTH-1 : ADDRESS_WIDTH])
          LDA: begin
               ctrl_reg[ro] = 1;
               ctrl_reg[ai] = 1;
               next_stage = STAGE_T1;
               end
          ADD: begin
               ctrl_reg[ro] = 1;
               ctrl_reg[bi] = 1;
               next_stage = STAGE_T5;
               end
        endcase
      end
      STAGE_T5: begin
        case (ir[WIDTH-1 : ADDRESS_WIDTH])
          ADD: begin
               ctrl_reg[ai] = 1;
               ctrl_reg[eo] = 1;
               next_stage = STAGE_T1;
               end
        endcase
      end
    endcase
  end
endmodule

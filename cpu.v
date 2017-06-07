`include "alu.v"
`include "pcounter.v"
`include "ram.v"

module cpu(input clk, output [LED_COUNT-1 : 0] leds);

  parameter LED_COUNT = 5;
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
  localparam OUT = 4'b0101; //Output contents of register A to output device.
  localparam JMP = 4'b0110; //Jump at some code location
  localparam LDI = 4'b0111; //Load 4'bit immediate value in register A.
  localparam JC  = 4'b1000; //Jump if carry flag is set.
  localparam HLT = 4'b1111; //Halt CPU control clock;

  //Control signals
  localparam j   = 0;  //Program counter jump
  localparam co  = 1;  //Program counter output enable
  localparam ce  = 2;  //Program counter enable
  localparam oi  = 3;  //Display/leds input
  localparam bi  = 4;  //Register B write enable
  localparam su  = 5;  //Subtract enable
  localparam eo  = 6;  //ALU enable
  localparam ao  = 7;  //Register A read enable
  localparam ai  = 8;  //Register A write enable
  localparam ii  = 9;  //Insruction register write enable
  localparam io  = 10; //Instruction register read enable
  localparam ro  = 11; //RAM out
  localparam ri  = 12; //RAM in
  localparam mi  = 13; //Address in
  localparam SIG_COUNT = mi+1;

  localparam STAGE_T1 = 0;
  localparam STAGE_T2 = 1;
  localparam STAGE_T3 = 2;
  localparam STAGE_T4 = 3;
  localparam STAGE_T5 = 4;
  localparam STAGE_COUNT = STAGE_T5 + 1;
  localparam STAGE_WIDTH = $clog2(STAGE_COUNT);
  reg [WIDTH-1 : 0] ir;               //Instruction register.
  reg [SIG_COUNT-1 : 0] ctrl_reg;     //Holds control signal status.
  reg [STAGE_WIDTH-1 : 0] stage_reg;  //Keeps track of the current
                                      //execution stage.
  reg [STAGE_WIDTH-1 : 0] next_stage; //Keeps the next stage
  reg [LED_COUNT-1 : 0] out_reg;      //Output LED register.
  reg carry_status;
  wire [ADDRESS_WIDTH-1 : 0] pc_in;   //Program counter I/O
  wire [ADDRESS_WIDTH-1 : 0] pc_out;  //
  wire [WIDTH-1 : 0] alu_in;          //ALU I/O
  wire [WIDTH-1 : 0] alu_out;         //
  wire [WIDTH-1 : 0] mem_in;          //RAM I/O
  wire [WIDTH-1 : 0] mem_out;         //
  wire alu_carry;                     //Carry signal

  initial begin
    ir = 0;
    ctrl_reg = 0;
    stage_reg = 0;
    next_stage = 0;
    out_reg = 0;
    carry_status = 0;
  end

  //CPU modules
  pcounter #(.ADDRESS_WIDTH(ADDRESS_WIDTH)) pc(.clk(clk),
    .enable(ctrl_reg[ce]), .jump(ctrl_reg[j]),
    .out_enable(ctrl_reg[co]), .bus_in(pc_in), .bus_out(pc_out));

  //Register B output enable functionality is not used at the moment
  alu #(.WIDTH(WIDTH)) alu(.clk(clk), .alu_enable(ctrl_reg[eo]),
    .rega_enable(ctrl_reg[ao]), .regb_enable(1'b0),
    .rega_write_enable(ctrl_reg[ai]), .regb_write_enable(ctrl_reg[bi]),
    .sub_enable(ctrl_reg[su]), .bus_in(alu_in), .bus_out(alu_out),
    .carry_out(alu_carry));

  ram #(.WIDTH(WIDTH),.ADDRESS_WIDTH(ADDRESS_WIDTH)) memory(.clk(clk),
    .enable(ctrl_reg[ro]), .addr_enable(ctrl_reg[mi]),
    .write_enable(ctrl_reg[ri]), .bus_in(mem_in), .bus_out(mem_out));

  //Data transfer paths
  assign leds = out_reg;
  assign pc_in = (ctrl_reg[j] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] : 0;
  assign alu_in = ((ctrl_reg[ai] || ctrl_reg[bi]) && ctrl_reg[ro]) ? mem_out :
                  (ctrl_reg[ai] && ctrl_reg[eo]) ? alu_out :
                  (ctrl_reg[ai] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] : 0;
  assign mem_in = (ctrl_reg[mi] && ctrl_reg[io]) ? ir[ADDRESS_WIDTH-1 : 0] :
                  (ctrl_reg[mi] && ctrl_reg[co]) ? pc_out :
                  (ctrl_reg[ri] && ctrl_reg[ao]) ? alu_out : 0;

  //Control logic
  always @(posedge clk) begin
    stage_reg <= next_stage;
    if (ctrl_reg[ii] && ctrl_reg[ro]) begin
      ir <= mem_out;
    end else if (ctrl_reg[oi] && ctrl_reg[ao]) begin
      out_reg <= alu_out[LED_COUNT-1 : 0];
    end else if (ctrl_reg[ro] && ctrl_reg[bi]) begin
      carry_status <= alu_carry;
    end
  end

  always @(negedge clk) begin
    case (stage_reg)
      STAGE_T1: begin
        ctrl_reg <= (1 << mi) | (1 << co);
        next_stage <= STAGE_T2;
      end
      STAGE_T2: begin
        ctrl_reg <= (1 << ro) | (1 << ii) | (1 << ce);
        next_stage <= STAGE_T3;
      end
      STAGE_T3: begin
        case (ir[WIDTH-1 : ADDRESS_WIDTH])
          LDA: begin
            ctrl_reg <= (1 << mi) | (1 << io);
            next_stage <= STAGE_T4;
          end
          STA: begin
            ctrl_reg <= (1 << mi) | (1 << io);
            next_stage <= STAGE_T4;
          end
          ADD: begin
               ctrl_reg <= (1 << mi) | (1 << io);
               next_stage <= STAGE_T4;
               end
          SUB: begin
            ctrl_reg <= (1 << mi) | (1 << io);
            next_stage <= STAGE_T4;
          end
          OUT: begin
            ctrl_reg <= (1 << ao) | (1 << oi);
            next_stage <= STAGE_T1;
          end
          JMP: begin
            ctrl_reg <= (1 << j) | (1 << io);
            next_stage <= STAGE_T1;
          end
          JC:  begin
            if (carry_status) begin
              ctrl_reg <= (1 << j) | (1 << io);
            end else begin
              ctrl_reg <= 0;
            end
            next_stage <= STAGE_T1;
          end
          LDI: begin
            ctrl_reg = (1 << io) | (1 << ai);
            next_stage <= STAGE_T1;
          end
          NOP: begin
            next_stage <= STAGE_T1;
          end
          HLT: begin
            next_stage <= STAGE_COUNT;
          end
          default: begin
            next_stage <= STAGE_COUNT;
          end
        endcase
      end
      STAGE_T4: begin
        case (ir[WIDTH-1 : ADDRESS_WIDTH])
          LDA: begin
            ctrl_reg <= (1 << ro) | (1 << ai);
            next_stage <= STAGE_T1;
          end
          STA: begin
            ctrl_reg <= (1 << ri) | (1 << ao);
            next_stage <= STAGE_T1;
          end
          ADD: begin
            ctrl_reg <= (1 << ro) | (1 << bi);
            next_stage <= STAGE_T5;
          end
          SUB: begin
            ctrl_reg <= (1 << ro) | (1 << bi) | (1 << su);
            next_stage <= STAGE_T5;
          end
          default: begin
            next_stage <= STAGE_COUNT;
          end
        endcase
      end
      STAGE_T5: begin
        case (ir[WIDTH-1 : ADDRESS_WIDTH])
          ADD: begin
            ctrl_reg <= (1 << ai) | (1 << eo);
            next_stage <= STAGE_T1;
          end
          SUB: begin
            ctrl_reg <= (1 << ai) | (1 << eo) | (1 << su);
            next_stage <= STAGE_T1;
          end
          default: begin
            next_stage <= STAGE_COUNT;
          end
        endcase
      end
      default: begin
        next_stage <= STAGE_COUNT;
      end
    endcase
  end
endmodule

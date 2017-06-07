module ram(input clk, input enable, input addr_enable,
  input write_enable, input [WIDTH-1 : 0] bus_in,
  output [WIDTH-1 : 0] bus_out);

  parameter ADDRESS_WIDTH = 4;
  parameter WIDTH = 8;
  parameter MEMORY_SIZE = 1 << ADDRESS_WIDTH;
  reg [WIDTH-1 : 0] mem [0 : MEMORY_SIZE-1];
  reg [ADDRESS_WIDTH-1 : 0] addr_reg;

  initial begin
    $readmemb("prog.list", mem);
    addr_reg = 0;
  end

  assign bus_out = (enable) ? mem[addr_reg] : {WIDTH{1'b0}};

  always @(posedge clk) begin
    if (write_enable) begin
      mem[addr_reg] <= bus_in;
    end else if (addr_enable) begin
      addr_reg <= bus_in[ADDRESS_WIDTH-1 : 0];
    end
  end
endmodule

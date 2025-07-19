module register_file(clk,read_1_addr,read_2_addr, write_addr, read_bus_1, read_bus_2, write_bus, write_enabled,reset);
	parameter ADDR_WIDTH= 3;
   parameter REG_N = 2**ADDR_WIDTH; 
	parameter REG_WIDTH = 16; 
	output [REG_WIDTH-1:0] read_bus_1, read_bus_2;
	input [REG_WIDTH-1:0] write_bus; 
	input [ADDR_WIDTH-1:0] read_1_addr, read_2_addr, write_addr;
			
	input reset,clk, write_enabled ; 
	wire [REG_N-1:0] write_reg_select; 
	wire [(REG_N*REG_WIDTH)-1:0] register_output; 

	register_address_decoder#(.INPUT_WIDTH(ADDR_WIDTH)) WRITE_REG_DECODE(.in(write_addr),.out(write_reg_select)); 
	
	genvar i; 
	generate
	for (i=0; i < REG_N; i = i +1)
		begin:register_file 
			register REG(.clk(clk),.in(write_bus),.out(register_output[(((i+1)*REG_WIDTH)-1):(i*REG_WIDTH)]), .write_selected(write_reg_select[i]), .write_enabled(write_enabled), .reset(reset)); 
		end 
	endgenerate 
	
	reg_mux#(.REG_N(REG_N), .WIDTH(REG_WIDTH)) READ_BUS_1(.select(read_1_addr), .in(register_output), .out(read_bus_1)); 
	reg_mux#(.REG_N(REG_N), .WIDTH(REG_WIDTH)) READ_BUS_2(.select(read_2_addr), .in(register_output), .out(read_bus_2)); 
	
endmodule 

module register(clk,in, out, write_selected, write_enabled, reset); 
	parameter WIDTH = 8; 
	input reset, write_selected, write_enabled; 
	input [WIDTH-1:0] in; 
	input clk; 
	output wire [WIDTH-1:0] out; 
	
	//generate flip flops 
	genvar i; 
	generate 
	for(i = 0; i < WIDTH; i = i +1)
		begin:REG_BITS
			d_ff D_FF(.clk(clk),.d(write_selected&&write_enabled? in[i] : out[i]),.q(out[i]),.reset(reset)); 
		end 
	endgenerate 
endmodule 

//8 16bit reg output selector  
module reg_mux(select, in, out); 
	parameter REG_N = 8; 
	parameter WIDTH = 16; 
	localparam SELECT_WIDTH = 3; 
	input [(REG_N*WIDTH)-1:0] in;
	output reg [WIDTH-1:0] out; 
	input [3:0] select; 
	
	always@(*) 
		begin
			case(select)
				3'b000:out = in[15:0]; 
				3'b001:out = in[31:16]; 
				3'b010:out = in[47:32]; 
				3'b011:out = in[63:48]; 
				3'b100:out = in[79:64]; 
				3'b101:out = in[95:80]; 
				3'b110:out = in[111:96]; 
				3'b111:out = in[127:112]; 
			endcase
		end
endmodule 
	

//extensible register decoder
module register_address_decoder(in,out);  
	parameter INPUT_WIDTH = 3;
	parameter OUTPUT_WIDTH = 2**INPUT_WIDTH; 
	input [INPUT_WIDTH-1:0] in;  
	output reg [OUTPUT_WIDTH-1:0] out; 
	
	always@(*)
		begin
			out[in] = 1; 
		end 
endmodule 



	

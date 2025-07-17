module register_file(clk,read_1_addr,read_2_addr, write_addr, read_bus_1, read_bus_2, write_bus, write_enabled,reset);
	parameter ADDR_WIDTH= 5;
   parameter REG_N = 2**ADDR_WIDTH; 
	parameter REG_WIDTH = 8; 
	output [REG_WIDTH-1:0] read_bus_1, read_bus_2;
	input [REG_WIDTH-1:0] write_bus; 
	input [ADDR_WIDTH-1:0] read_1_addr, read_2_addr, write_addr;
			
	input reset,clk, write_enabled ; 
	wire [REG_N-1:0] write_reg_select; 
	wire [REG_WIDTH-1:0] register_output [0:REG_N-1]; 

	register_address_decoder#(.INPUT_WIDTH(ADDR_WIDTH)) WRITE_REG_DECODE(.in(write_addr),.out(write_reg_select)); 
	
	genvar i; 
	generate
	for (i=0; i < REG_N; i = i +1)
		begin:register_file 
			register REG(.clk(clk),.in(write_bus),.out(register_output[i]), .write_selected(write_reg_select[i]), write_enabled(write_enabled), .reset(reset)); 
		end 
	endgenerate 
	
	reg_mux#(.REG_N(REG_N), .WIDTH(REG_WIDTH)) READ_BUS_1(.select(read_1_addr), .in(register_output), .out(read_bus_1)); 
	reg_mux#(.REG_N(REG_N), .WIDTH(REG_WIDTH)) READ_BUS_2(.select(read_2_addr), .in(register_output), .out(read_bus_2)); 
	
endmodule 

module register(clk,in, out, write_selected, write_enabled, reset); 
	parameter WIDTH = 8; 
	input reset, write_selected, write_enabled; 
	input [WIDTH-1:0] in;  
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


module reg_mux(select, in, out); 
	parameter REG_N = 16; 
	parameter WIDTH = 8; 
	parameter SELECT_WIDTH = clogb2(REG_N); 
	input [WIDTH-1:0] in [0:REG_N-1];
	output reg [WIDTH-1:0] out; 
	input [SELECT_WIDTH-1:0] select; 
	
	function integer clogb2;
		input [31:0] value;
		integer 	i;
		begin
			clogb2 = 0;
			for(i = 0; 2**i < value; i = i + 1)
				clogb2 = i + 1;
		end
	endfunction
	
	always@(*) 
		begin
			out = 0; 
			out = in[select]; 
		end
endmodule 
	


module register_address_decoder(in,out, enable);  
	parameter INPUT_WIDTH = 3;
	parameter OUTPUT_WIDTH = 2**INPUT_WIDTH; 
	input [INPUT_WIDTH-1:0] in; 
	output reg [OUTPUT_WIDTH-1:0] out; 
	
	always@(*)
		begin
			out = 0; 
			//one hot output 
			out[in] = 1; 
		end 
endmodule 



	
module d_ff(clk, d, q, reset);
	input clk; 
	input d, reset; 
	output reg q; 
	always @(posedge clk, posedge reset)
		begin
			if(reset)
				q <= 0; 
			else
				q <= d; 
		end 
endmodule 
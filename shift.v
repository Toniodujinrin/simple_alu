

//Extensible arithmetic rotate
module rotate(x,y,dir,r); 
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x,y; 
	output [WIDTH-1:0] r; 
	input dir; //0 left , 1 right 
	
endmodule

module shifter(clk, shift_en, load, reset, shift_count, done, data_in,  data_out, arithmetic_logical, left_right);
	parameter WIDTH = 16; 
	parameter SHIFT_COUNT_WIDTH = clogb2(WIDTH); 
	input shift_en, load, reset, clk, arithmetic_logical, left_right;
	output reg done; 
	input [WIDTH-1:0] data_in; 
	output reg [WIDTH-1:0] data_out; 
	reg [SHIFT_COUNT_WIDTH-1:0] current_count; 
	input wire [SHIFT_COUNT_WIDTH-1:0] shift_count; 
	
	function integer clogb2;
   input [31:0] value;
   integer 	i;
   begin
      clogb2 = 0;
      for(i = 0; 2**i < value; i = i + 1)
			clogb2 = i + 1;
   end
	endfunction
	
	
	always@(posedge clk, posedge reset
		begin 
			if(reset) 
				begin
					done <= 0; 
					data_out <= {(WIDTH){1'b0}};
					current_count <= 0; 
				end 
			else if(shift_count == 0)
				begin 
					done <= 1; 
					data_out <= data_in; 
				end
			else if(load)
				begin 
					data_out <= data_in; 
					done <= 0; 
					current_count <= 0;
				end
			else if(shift_en && !done) 
				begin 
					if(left_right)
						begin 
							data_out <= {data_out[WIDTH-1:1], 1'b0}; 
						end 
					else
						begin 
							if(arithmetic_logical)
								begin 
									data_out <= {data_out[WIDTH-1],data_out[WIDTH-1:1]}; 
								end 
							else 
								begin 
									data_out <= {1'b0,data_out[WIDTH-1:1]}; 
								end 
							
						end
					current_count <= current_count + 1; 
					if(current_count + 1 == shift_count)
						done <= 1;
				end 
			else
				begin 
					done<= done; 
					current_count <= current_count;
				end	
		end 
	
endmodule


module n_barrel_rotator_shifter(x,y,shift_count,mode, negative, zero, cout, overflow ); 
	parameter WIDTH = 16;
   function integer clogb2;
		input [31:0] value;
		integer 	i;
		begin
			clogb2 = 0;
			for(i = 0; 2**i < value; i = i + 1)
				clogb2 = i + 1;
		end
	endfunction	
	parameter SHIFT_WIDTH = clogb2(WIDTH); 
	input [WIDTH-1:0] x; 
	output [WIDTH-1:0] y; 
	input [SHIFT_WIDTH-1:0] shift_count; 
	input [2:0] mode; 
	//modes////////
	//LSL = 3'b000
	//LSR = 3'b001 
	//ASR = 3'b010 
	//ROR = 3'b011 
	//ROL = 3'b100
	///////////////
	
	wire [WIDTH-1:0] stage_shift [0:SHIFT_WIDTH-1]; 
	
	genvar i; 
	generate 
	for(i=0; i < SHIFT_WIDTH; i = i+1)
		begin:BARREL_SHIFT 
			if(i == 0)
					chained_mux#(.WIDTH(WIDTH)) N_MUX(
									 .x(x),
									 .y({x[(WIDTH/(1'b1<<i))-1:0],x[WIDTH-1:(WIDTH/(1'b1<<i))]}),
									 .s(shift_count[SHIFT_WIDTH-i-1]),
									 .out(stage_shift[i])); 
			else 
					chained_mux#(.WIDTH(WIDTH)) N_MUX(
									 .x(stage_shift[i-1]),
									 .y({stage_shift[i-1][(WIDTH/(1'b1<<i))-1:0],stage_shift[i-1][WIDTH-1:(WIDTH/(1'b1<<i))]}),
									 .s(shift_count[SHIFT_WIDTH-i-1]),
									 .out(stage_shift[i])); 
		end 
	endgenerate
	assign y = stage_shift[SHIFT_WIDTH-1]; 
endmodule 

module chained_mux(x,y,s,out); 
	parameter WIDTH = 7; 
	input [WIDTH-1:0] x,y; 
	output [WIDTH-1:0] out; 
	
	genvar i; 
	generate 
		for(i=0; i< WIDTH; i = i+1) 
			mux MUX(.x(x[i]),.y(y[i]),.s(s),.out(out[i])); 
	endgenerate 
endmodule 

module mux(x,y,s,out);
	input x,y,s; 
	output out; 
	assign out = s?x:y; 
endmodule

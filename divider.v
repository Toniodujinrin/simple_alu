module divider(x,y,quo,rem,invalid_flag, negative, zero, cout, overflow); 
	parameter WIDTH = 16; 
	
	input [WIDTH-1:0] x,y; 
	output [WIDTH-1:0] quo, rem; 
	inpuy invalid_flag; 
	
	wire [WIDTH-1:0] unsigned_x; 
	wire [WIDTH-1:0] unsigned_y; 
	
	wire [WIDTH-1:0] unsigned_quo;  
	//convert signed to unsigned 
	assign unsigned_x = x[WIDTH-1]? (~x)+1 : x; 
	assign unsigned_y = y[WIDTH-1]? (~y)+1 : y; 
	assign quo = y[WIDTH-1]^x[WIDTH-1]? (~unsigned_quo)+1:unsigned_quo; 
	
	//set invalid signal for division by 0
	assign invalid_flag = y == 0 ? 1:0; 
	
	//perform division 
	unsigned_divider#(.WIDTH(WIDTH)) DIVIDER(.x(unsigned_x),.y(unsigned_y),.quo(unsigned_quo),.rem(rem)); 
	
	//assign cpsr bits 
	assign zero = x == 0 ? 1:0; 
	assign cout = 0; 
	assign overflow = 0; 
	assign negative = y[WIDTH-1]^x[WIDTH-1]; 
endmodule 


//extensible unsigned divider 
module unsigned_divider(x,y,quo,rem); 
	parameter WIDTH = 16;
	input [WIDTH-1:0] x,y; 
	output [WIDTH-1:0] quo,rem; 
	
	wire [WIDTH-1:0] stage_sum [0:WIDTH-1];
	wire [WIDTH-2:0] stage_mux_output [0:WIDTH-2]; 
	wire [WIDTH-2:0] zero_bits; 
	wire [WIDTH-1:0] temp_cout; 
	
	assign zero_bits = {(WIDTH-1){1'b0}}; 
	genvar i,j; 
	generate 
		for (i = 0; i < WIDTH; i = i + 1)
			begin 
				if(i == 0)
					begin 
						simplified_signed_adder#(.WIDTH(WIDTH)) S1(.x({zero_bits,x[WIDTH-1]}),.y(y),.add_sub(1'b1),.cout(temp_cout[i]),.s(stage_sum[i])); 
						chained_mux #(.WIDTH(WIDTH-1)) CM1(.x(zero_bits), .y(stage_sum[i][WIDTH-2:0]),.s(stage_sum[i][WIDTH-1]),.out(stage_mux_output[i])); 
					end 
				else if(i== WIDTH-1) 
						simplified_signed_adder#(.WIDTH(WIDTH)) S3(.x({stage_mux_output[i-1],x[WIDTH-i-1]}), .y(y), .add_sub(1'b1),.cout(temp_cout[i]),.s(stage_sum[i])); 
				else 
					begin
						simplified_signed_adder#(.WIDTH(WIDTH) S2(.x({stage_mux_output[i-1],x[WIDTH-i-1]}), .y(y), .add_sub(1'b1),.cout(temp_cout[i]),.s(stage_sum[i])); 
						chained_mux #(.WIDTH(WIDTH-1)) CM2(.x(stage_mux_output[i-1]),.y(stage_sum[i][WIDTH-2:0]),.s(stage_sum[i][WIDTH-1]),.out(stage_mux_output[i])); 
					end 
			end 
			
		for(i = 0; i < WIDTH; i = i +1) 
			begin 
				assign quo[WIDTH-i-1] = ~(stage_sum[i][WIDTH-1]); 
			end 
		assign rem = stage_sum[WIDTH-1]; 
	endgenerate 
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


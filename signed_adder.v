module signed_adder(x, y, add_sub, overflow,negative,zero,cout,s);
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x, y; 
	input add_sub;
	
	output [WIDTH-1:0] s; 
	output overflow;
	output cout; 
	output negative; 
	output zero; 
	
	simplified_signed_adder#(.WIDTH(WIDTH)) S1(.x(x),.y(y),.add_sub(add_sub),.cout(cout),.s(s)); 

	//set flags 
	assign overflow = (~(x[WIDTH-1] ^ _y[WIDTH-1])) & (s[WIDTH-1] ^ x[WIDTH-1]);
	assign negative = s[WIDTH-1];
	assign zero = ~(|s); 

endmodule


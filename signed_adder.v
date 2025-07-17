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

module simplified_signed_adder(x, y, add_sub, cout, s);
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x, y; 
	input add_sub;
	output [WIDTH-1:0] s; 
	output cout; 

	
	wire [WIDTH-1:0] _y; 
	genvar i; 
	generate
		for(i = 0; i < WIDTH; i = i+1)
			begin: compliment_y
				assign _y[i] = y[i] ^ add_sub;
			end
	endgenerate

	carry_look_adder #(.WIDTH(WIDTH)) A1(x, _y, add_sub, s, cout);
endmodule 

module carry_look_adder #(parameter WIDTH = 8) (
	input [WIDTH-1:0] x, y,
	input cin,
	output [WIDTH-1:0] s,
	output cout
);
	wire [WIDTH:0] c;
	wire [WIDTH-1:0] g, p;
	
	assign g = x & y;
	assign p = x | y;
	assign c[0] = cin;

	genvar i;
	generate
		for (i = 1; i <= WIDTH; i = i + 1) begin: carry_chain
			assign c[i] = g[i-1] | (p[i-1] & c[i-1]);
		end
	endgenerate

	assign s = x ^ y ^ c[WIDTH-1:0];
	assign cout = c[WIDTH];
endmodule
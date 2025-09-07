module signed_adder(x, y, add_sub, overflow,negative,zero,cout,s);
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x, y; 
	input add_sub;
	
	output [WIDTH-1:0] s; 
	output overflow;
	output cout; 
	output negative; 
	output zero; 
	
	wire [WIDTH-1:0] couts; 
	wire [WIDTH-1:0] _y; 
	
	assign cout = couts[WIDTH-1]; 
	
	genvar i; 
	generate
		for(i = 0; i < WIDTH; i = i+1)
			begin: compliment_y
				assign _y[i] = y[i] ^ add_sub;
			end
	endgenerate

	carry_look_adder #(.WIDTH(WIDTH)) A1(x, _y, add_sub, s, couts);
	

	//set flags 
	assign overflow = couts[WIDTH-1] ^ couts[WIDTH-2];
	assign negative = s[WIDTH-1];
	assign zero = ~(|s); 

endmodule


	

	
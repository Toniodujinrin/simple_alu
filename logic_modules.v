//logic ops 
//Extensible AND operation 
module and_mod(x,y,r, negate, negative, zero, cout, overflow); //negate accounts for nand operaton 
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x,y; 
	output [WIDTH-1:0] r; 
	input negate; 
	output negative, zero, cout, overflow; 
	assign r = negate? ~(x&y) : (x&y); 
	assign negative = r[WIDTH-1];  
	assign zero = ~|r; 
	assign cout = 0; 
	assign overflow = 0; 
endmodule 



//Extensible NOT operation
module not_mod(x,r, negative, zero, cout, overflow);
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x; 
	output [WIDTH-1:0] r; 
	output negative, zero, cout, overflow;
	
	assign r = ~x;
	assign negative = r[WIDTH-1];  
	assign zero = ~|r; 
	assign cout = 0; 
	assign overflow = 0; 
endmodule
	
	
//Extensible OR operation 
module or_mod(x,y,r,negate, negative, zero, cout, overflow); //negate accounts for nor operation
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x,y; 
	input negate; 
	output [WIDTH-1:0] r; 
	output negative, zero, cout, overflow;
	assign r = negate? ~(x|y) : (x|y); 
	assign negative = r[WIDTH-1]; 
	assign zero = ~|r; 
	assign cout = 0; 
	assign overflow = 0; 
endmodule 

module xor_mod(x,y,r,negate, negative, zero, cout, overflow); //negate accounts for xnor operation 
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x,y; 
	input negate; 
	output [WIDTH-1:0] r; 
	output negative, zero, cout, overflow; 

	assign r = negate? ~(x^y) : (x^y); 
	assign negative = r[WIDTH-1]; 
	assign zero = ~|r; 
	assign cout = 0; 
	assign overflow = 0; 
endmodule 
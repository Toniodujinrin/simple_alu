module comparator(x,y,signed_unsigned, negative, zero, cout, overflow);
	parameter WIDTH = 4; 
	input[WIDTH-1:0] x,y; 
	output wire negative, zero, cout, overflow; 
	
	//temporary comparison flags
	wire gt, lt, eq; 
	wire unsigned_gt, usigned_lt, unsigned_eq; 
	wire signed_gt, signed_lt, signed_eq; 
	
	//instantiate base model
	simple_comparator#(.WIDTH(WIDTH)) UNSIGNED_COMPARATOR(.x(x), .y(y), .gt(unsigned_gt), .lt(unsigned_lt), .eq(unsigned_eq)); 
	simmple_signed_comparator#(.WIDTH(WIDTH)) SIGNED_COMPARATOR(.x(x), .y(y), .gt(signed_gt), .lt(signed_lt), .eq(signed_eq)); 
	
	//multiplexing signed and unsigned comparison flags               //signed (signed_unsigned == 1) , unsigned (signed_unsigned == 0)
	assign gt = signed_unsigned ? signed_gt: unsigned_gt; 
	assign lt = signed_unsigned ? signed_lt: unsigned_lt; 
	assign eq = signed_unsgined ? signed_eq: unsigned_eq;                  
	
	//assign CPSR bits corresponding to the inequality flags 
	assign negative = lt; 
	assign zero = eq; 
	//cout and overflow are default assigned to 0
	assign cout = 1'b0; 
	assign overflow = 1'b0; 
	
endmodule


	
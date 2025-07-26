//half precision floating point comparator 
module fp_comparator(x,y, negative, zero, overflow, cout); 
	input [15:0] x,y; 
	output wire negative, zero, cout, overflow; 
	
	wire x_sign, y_sign;  
	wire [4:0] x_exponent, y_exponent; 
	wire [9:0] x_mantisa, y_mantisa;
	
	assign x_sign = x[15];
	assign y_sign = y[15];
	assign x_exponent = x[14:10];
	assign y_exponent = y[14:10];
	assign x_mantisa = x[9:0];
	assign y_mantisa = y[9:0];
	
	//individual section comparison bits 
	wire sign_eq;  
	wire exponent_gt, exponent_eq, exponent_lt; 
	wire mantisa_gt, mantisa_eq, mantisa_lt; 
	wire gt, lt, eq; 
	wire mag_lt, mag_gt, mag_eq; 

	//compare exponent magnitude
	simple_comparator#(.WIDTH(5))  EXPONENT_COMPARE(.x(x_exponent), .y(y_exponent), .gt(exponent_gt), .lt(exponent_lt), .eq(exponent_eq)); 
	//compare mantisa magnitude
	simple_comparator#(.WIDTH(10)) MANTISA_COMPARE (.x(x_mantisa), .y(y_mantisa), .gt(mantisa_gt), .lt(mantisa_lt), .eq(mantisa_eq)); 
	
	//overal magnitude comparison
	assign mag_gt = exponent_gt | (exponent_eq&mantisa_gt); 
	assign mag_lt = exponent_lt | (exponent_eq&mantisa_lt); 
	assign mag_eq = exponent_eq&mantisa_eq; 
	
	//overal signed comparison
	assign sign_eq = ~(x_sign ^ y_sign); 
	assign gt = (~x_sign&y_sign) | (~x_sign & ~y_sign & mag_gt ) | (x_sign & y_sign & mag_lt); //if x is +ve and y is -ve (gt), if x is +ve and y is +ve and x magnitude > y magnitude (gt), if x is -ve and y is -ve and x magnitude < y magnitude (gt)
	assign eq = sign_eq & mag_eq; 
	assign lt = ~(gt | eq); 
	
	assign negative = lt; 
	assign zero = eq; 
	//cout and overflow are default assigned to 0
	assign cout = 1'b0; 
	assign overflow = 1'b0; 


endmodule 
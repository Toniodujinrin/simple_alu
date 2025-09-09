module shift(x,y,shift_count,mode, negative, zero, cout, overflow); 
	parameter WIDTH = 16;

	parameter SHIFT_WIDTH = $clog2(WIDTH); 
	input [WIDTH-1:0] x; 
	// negative: Set to 1 if the result 'y' is negative (MSB is 1), else 0.
	// zero: Set to 1 if the result 'y' is zero, else 0.
	// cout: Carry out from the shift operation (not used, always 0).
	// overflow: Set to 1 if a signed overflow occurs during left shifts (LSL/ASL), else 0.
		output negative, zero, cout, overflow; 
	output [WIDTH-1:0] y; 
	input [SHIFT_WIDTH-1:0] shift_count; 
	input [2:0] mode; 
	//modes////////
	//LSL = 3'b000
	//LSR = 3'b001 
	//ASR = 3'b010 
	//ASL = 3'b011 
	//ROR = 3'b100
	///////////////
	
	wire [WIDTH-1:0] stage_shift [0:SHIFT_WIDTH-1];
	wire [WIDTH-1:0] zero_input = 0;
	wire [WIDTH-1:0] sign_bit_input = {(WIDTH){x[WIDTH-1]}}; 
   
	
	genvar i; 
	generate 
	for(i=0; i < SHIFT_WIDTH; i = i+1)
		begin:BARREL_SHIFT 
			if(i == 0)
					chained_mux#(.WIDTH(WIDTH)) N_MUX(
									 .y(x),
									 .x(
									 mode==3'b100 ? {x[(1 << i)-1:0],x[WIDTH-1:(1 << i)]}: //ROR 
									 mode==3'b001 ? {zero_input[(1 << i)-1:0],x[WIDTH-1:(1 << i)]}:       //LSR
									 mode==3'b010 ? {sign_bit_input[(1 << i)-1:0],x[WIDTH-1:(1 << i)]}:   //ASR
                                       mode==3'b000 ? {x[WIDTH-1-(1<< i):0],{(1<<i){1'b0}}}: //LSL
                                       {x[WIDTH-1-(1 << i):0],{(1<<i){1'b0}}} //ASL
									 ), 
									 .s(shift_count[i]),
									 .out(stage_shift[i])); 
			else 
					chained_mux#(.WIDTH(WIDTH)) N_MUX(
									 .y(stage_shift[i-1]),
									 .x(
									 mode==3'b100 ? {stage_shift[i-1][(1 << i)-1:0],stage_shift[i-1][WIDTH-1:(1 << i)]}: //ROR 
									 mode==3'b001 ? {zero_input[(1 << i)-1:0],stage_shift[i-1][WIDTH-1:(1 << i)]}:       //LSR
									 mode==3'b010 ? {sign_bit_input[(1 << i)-1:0],stage_shift[i-1][WIDTH-1:(1 << i)]}:   //ASR
                                       mode==3'b000 ? {stage_shift[i-1][WIDTH-1-(1 << i):0],{(1<<i){1'b0}}}: //LSL
                                       {stage_shift[i-1][WIDTH-1-(1 << i):0],{(1<<i){1'b0}}} //ASL
									 ), 
									 .s(shift_count[i]), .out(stage_shift[i])); 
		end 
	endgenerate
	assign y = stage_shift[SHIFT_WIDTH-1]; 
	assign negative = y[WIDTH-1]; 
	assign zero = ~|y; 
	assign cout = 0; 
	assign overflow = (mode == 3'b000) || (mode == 3'b011) && 
	(x[WIDTH-1] ^ y[WIDTH-1]); 
endmodule 
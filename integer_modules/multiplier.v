module multiplier(x,y,r,signed_unsigned, negative,zero, overflow, cout ); 
	parameter WIDTH = 4; 
	input [WIDTH-1:0] x,y; 
	input signed_unsigned;
	output negative, zero, overflow, cout; 
	output [2*WIDTH-1:0] r; 
	
	wire [2*WIDTH-1:0] signed_output; 
	wire [2*WIDTH-1:0] unsigned_output; 
	
	
	signed_multiplier#(WIDTH) SM(.x(x),.y(y), .r(signed_output)); 
	unsigned_multiplier#(WIDTH) UM(.x(x), .y(y), .r(unsigned_output)); 
	
	assign r = signed_unsigned?signed_output:unsigned_output; 
	assign negative = signed_unsigned&r[WIDTH-1]; 
	assign zero = r==0 ? 1:0; 
	assign cout = 0; 
	assign overflow = 0; 
	
endmodule 


//Extensible signed multiplier using Baugh-Wooley multiplication algorithm 
module signed_multiplier(x,y,r); 
	parameter WIDTH = 4; 
	parameter RES_WIDTH = 2*WIDTH; 
	input [WIDTH-1:0] x,y; 
	output [RES_WIDTH-1:0] r; 
	
	wire [WIDTH-1:0] stage_sum [0:WIDTH-1]; 
	wire [WIDTH-1:0] stage_cout[0:WIDTH-1]; 
	wire [WIDTH-1:0] full_adder_cout; 

	
	genvar i,j, k; 
	generate
	for (i=0; i<WIDTH ; i = i+1)
		begin: MULTIPLY_ROW
			for(j = 0; j<WIDTH; j = j+1)
				begin: MULTIPLY_BIT
 					if(j != i && (j==WIDTH-1 || i == WIDTH -1))
							bw_gray_cell GC(.sum_prev(i?(j==WIDTH-1)?0:stage_sum[i-1][j+1]:1'b0),.x(x[i]), .y(y[j]), .cin(i?stage_cout[i-1][j]:1'b0),.sum(stage_sum[i][j]),.cout(stage_cout[i][j])); 
					else 
							bw_white_cell WC(.sum_prev(i?(j==WIDTH-1)?0:stage_sum[i-1][j+1]:1'b0),.x(x[i]), .y(y[j]), .cin(i?stage_cout[i-1][j]:1'b0),.sum(stage_sum[i][j]),.cout(stage_cout[i][j])); 
				end 
		end 
	
	//final full adder implementation 
	for (k = 0; k < WIDTH; k = k+1)
		begin: FINAL_FULL_ADDER
			full_adder FA(.x((k==WIDTH-1)?1'b1:stage_sum[WIDTH-1][k+1]), .y(stage_cout[WIDTH-1][k]), .cin(k?full_adder_cout[k-1]:1'b0),.s(r[WIDTH+k]), .cout(full_adder_cout[k])); 
		end
	endgenerate 
	
	//assign result bits from stage_sum 
	genvar p; 
	generate 
	for (p=0; p<WIDTH; p = p+1)
		begin: RESULT_ASSIGN
			assign r[p] = stage_sum[p][0]; 
		end 
	endgenerate
		
endmodule 

module bw_gray_cell(sum_prev, x, y,cin, cout, sum); 
	input x, y, cin, sum_prev; 
	output cout, sum; 
	full_adder F1(.x(sum_prev),.y(~(x&y)),.cin(cin),.s(sum),.cout(cout)); 

endmodule 

module bw_white_cell(sum_prev, x, y, cin, cout, sum); 
	input x, y, cin, sum_prev; 
	output cout, sum; 
	full_adder F1(.x(sum_prev),.y(x&y),.cin(cin),.s(sum),.cout(cout)); 
endmodule

module full_adder(x,y,cin,s, cout); 
	
	input x,y,cin; 
	output cout,s; 
	assign s = x ^ y ^ cin; 
	assign cout = (cin & x) | (cin & y) | (x & y); 
	
endmodule



//Exstensible unsigned multiplier (array multiplier implementation)
module unsigned_multiplier(x,y,r);
	parameter  WIDTH = 4; 
	input  [WIDTH-1:0] x,y; 
	output [(WIDTH*2)-1:0] r; 
	
	wire [WIDTH-1:0] stage_cout;
	wire [WIDTH-1:0] stage_pprod [0:WIDTH-1]; 
	wire [WIDTH-1:0] stage_sum [0:WIDTH-3]; 
	wire [WIDTH-1:0] temp_sum [0:WIDTH-3]; 

		
	genvar i,j; 
	
	generate
		for (i = 0; i < WIDTH; i = i+1)
			begin:stage_partial_product_array 
			for (j = 0; j < WIDTH; j = j+1) 
				begin:stage_partial_product
					assign stage_pprod[i][j] = x[j] & y[i]; 
				end
			end 
	endgenerate 
	
	
	assign r[0] = stage_pprod[0][0];
	genvar k; 
	generate
		for (k = 0; k<WIDTH-1; k = k+1) 
			begin:multiply_stage
						if(k == 0) 
							begin
								simplified_signed_adder#(WIDTH) ADD_SUB(.x({1'b0,stage_pprod[k][WIDTH-1:1]}),
										.y(stage_pprod[k+1]),.add_sub(0),.cout(stage_cout[k]), .s(temp_sum[k])); 
								assign stage_sum[k][WIDTH-1:1] = temp_sum[k][WIDTH-1:1]; 
								assign r[k+1] = temp_sum[k][0]; 	
							end
						else if (k== WIDTH-2) 
							begin
								simplified_signed_adder#(WIDTH) ADD_SUB(.x({stage_cout[k-1],stage_sum[k-1][WIDTH-1:1]}),
								.y(stage_pprod[k+1]),.add_sub(0),.cout(r[(WIDTH*2)-1]), .s(r[(WIDTH*2)-2-:WIDTH])); 	
							end 
						else 
							begin
								simplified_signed_adder#(WIDTH) ADD_SUB(.x({stage_cout[k-1],stage_sum[k-1][WIDTH-1:1]}),
									.y(stage_pprod[k+1]),.add_sub(0),.cout(stage_cout[k]), .s(temp_sum[k])); 	
								assign stage_sum[k][WIDTH-1:1] = temp_sum[k][WIDTH-1:1]; 
								assign r[k+1] = temp_sum[k][0];
							end	
						end
	endgenerate 
endmodule

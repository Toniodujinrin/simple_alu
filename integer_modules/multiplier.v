module multiplier(x,y,r,signed_unsigned, negative,zero, overflow, cout ); 
	parameter WIDTH = 16; 
  	localparam RESULT_WIDTH = WIDTH*2; 
	input [WIDTH-1:0] x,y; 
	input signed_unsigned;
	output negative, zero, overflow, cout; 
	output [2*WIDTH-1:0] r; 
	
	wire [2*WIDTH-1:0] signed_output; 
	wire [2*WIDTH-1:0] unsigned_output; 
	
	
	signed_multiplier#(WIDTH) SM(.x(x),.y(y), .r(signed_output)); 
	unsigned_multiplier#(WIDTH) UM(.x(x), .y(y), .r(unsigned_output)); 
	
	assign r = signed_unsigned?signed_output:unsigned_output; 
  assign negative = signed_unsigned&r[RESULT_WIDTH-1]; 
	assign zero = r==0 ? 1:0; 
	assign cout = 0; 
	assign overflow = 0; 
	
endmodule 


module signed_multiplier #(
    parameter WIDTH = 16,
    localparam RES_WIDTH = 2*WIDTH
)(
    input [WIDTH-1:0] x, y,
    output [RES_WIDTH-1:0] r
);

    wire sign_x = x[WIDTH-1];
    wire sign_y = y[WIDTH-1];
    wire product_sign = sign_x ^ sign_y;

    wire [WIDTH-1:0] abs_x = sign_x ? (~x + 1'b1) : x;
    wire [WIDTH-1:0] abs_y = sign_y ? (~y + 1'b1) : y;

    wire [RES_WIDTH-1:0] abs_product;
    unsigned_multiplier #( .WIDTH(WIDTH) ) UM (
        .x(abs_x),
        .y(abs_y),
        .r(abs_product)
    );

    assign r = product_sign ? (~abs_product + 1'b1) : abs_product;

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
                                                                        .y(stage_pprod[k+1]),.add_sub(1'b0),.cout(stage_cout[k]), .s(temp_sum[k])); 
								assign stage_sum[k][WIDTH-1:1] = temp_sum[k][WIDTH-1:1]; 
								assign r[k+1] = temp_sum[k][0]; 	
							end
						else if (k== WIDTH-2) 
							begin
								simplified_signed_adder#(WIDTH) ADD_SUB(.x({stage_cout[k-1],stage_sum[k-1][WIDTH-1:1]}),
                                                                        .y(stage_pprod[k+1]),.add_sub(1'b0),.cout(r[(WIDTH*2)-1]), .s(r[(WIDTH*2)-2-:WIDTH])); 	
							end 
						else 
							begin
								simplified_signed_adder#(WIDTH) ADD_SUB(.x({stage_cout[k-1],stage_sum[k-1][WIDTH-1:1]}),
                                                                        .y(stage_pprod[k+1]),.add_sub(1'b0),.cout(stage_cout[k]), .s(temp_sum[k])); 	
								assign stage_sum[k][WIDTH-1:1] = temp_sum[k][WIDTH-1:1]; 
								assign r[k+1] = temp_sum[k][0];
							end	
						end
	endgenerate 
endmodule
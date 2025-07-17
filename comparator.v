module comparator(x,y,negative, zero, cout, overflow);

	parameter WIDTH = 4; 
	input[WIDTH-1:0] x,y; 
	output gt,lt, eq; 
   wire [WIDTH-1:0] i;
   wire [WIDTH-1:0] xgty_bit;
   wire [WIDTH-1:0] eqn_prefix;
	
	//temporary inequality flags 
	wire eq, gt, lt; 

   assign i = x ~^ y;

   genvar j;
   generate
	  for (j = 0; j < WIDTH; j = j + 1) begin: eq_prefix_block
			if (j == WIDTH - 1) begin
				 assign eqn_prefix[j] = 1'b1;
			end else begin
				 assign eqn_prefix[j] = eqn_prefix[j + 1] & i[j + 1];
			end
	  end
   endgenerate

   genvar k;
   generate
	  for (k = 0; k < WIDTH; k = k + 1) begin: x_gt_y_block
			assign xgty_bit[k] = x[k] & ~y[k] & eqn_prefix[k];
   endgenerate

   assign eq = &i;
   assign gt = |xgty_bit;
   assign lt = ~(gt | eq);
	
	
	//assign CPSR bits corresponding to the inequality flags 
	assign negative = lt; 
	assign zero = eq; 
	//cout and overflow are default assigned to 0
	assign cout = 1'b0; 
	assign overflow = 1'b0; 
	
endmodule

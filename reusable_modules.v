

//simplified adder implementation with no output flags
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

//carry look ahead adder implementation
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

//D type flip flop 
module d_ff(clk, d, q, reset);
	input clk; 
	input d, reset; 
	output reg q; 
	always @(posedge clk, posedge reset)
		begin
			if(reset)
				q <= 0; 
			else
				q <= d; 
		end 
endmodule 

//n bit chained 2 to 1 MUX with shared select line 
module chained_mux(x,y,s,out); 
	parameter WIDTH = 7; 
	input [WIDTH-1:0] x,y; 
	output [WIDTH-1:0] out; 
	
	genvar i; 
	generate 
		for(i=0; i< WIDTH; i = i+1) 
			mux MUX(.x(x[i]),.y(y[i]),.s(s),.out(out[i])); 
	endgenerate 
endmodule 


//2 to 1 MUX implementation 
module mux(x,y,s,out);
	input x,y,s; 
	output out; 
	assign out = s?x:y; 
endmodule


//nbit shift register 
module shift_register_n(clk,enable,q,preset,reset,load,shift_load,in); 
	parameter WIDTH = 16; 
	input clk,enable,shift_load,in; 
	input [WIDTH-1:0] load, preset, reset; 
	output [WIDTH-1:0] q; 
	wire [WIDTH-1:0] mux_1_out; 
	wire [WIDTH-1:0] mux_2_out; 
	genvar i; 
	generate 
	for (i = 0; i< WIDTH; i = i +1)
		begin:n_bit_register
			if(i == 0)
				begin
					mux_2_1 MUX(in,q[i],enable,mux_1_out[i]); 
				end
			else
				begin 
					mux_2_1 MUX(q[i-1],q[i],enable,mux_1_out[i]); 
				end 
			mux_2_1 MUX(mux_1_out[i],load[i], shift_load, mux_2_out[i]); 
			d_flip D(clk,mux_2_out[i],q[i],preset,reset); 
		end 
	endgenerate
	
endmodule 


//11bit leading zero counter
module leading_zero_counter (
    input [10:0] x,
    output reg [3:0] q,
    output a
);
    assign a = ~|x;
    always @(*) begin
        if (x[10]) q = 4'd0;
        else if (x[9]) q = 4'd1;
        else if (x[8]) q = 4'd2;
        else if (x[7]) q = 4'd3;
        else if (x[6]) q = 4'd4;
        else if (x[5]) q = 4'd5;
        else if (x[4]) q = 4'd6;
        else if (x[3]) q = 4'd7;
        else if (x[2]) q = 4'd8;
        else if (x[1]) q = 4'd9;
        else if (x[0]) q = 4'd10;
        else q = 4'd11;
    end
endmodule

//extensible signed magnitude comparator
module simple_signed_comparator(x,y,gt,lt,eq)
	parameter WIDTH = 16; 
	input [WIDTH-1:0] x,y; 
	output gt, lt, eq; 
	//internal wires
	wire x_msb = x[WIDTH-1] ; 
	wire y_msb = y[WIDTH-1]; 
	wire x_pos_y_neg, x_neg_y_pos, equal_sign; //sign comparison bits
	wire mag_gt, mag_lt, mag_eq; //magnitude comparison bits
	//compare signs
	simple_comparator#(.WIDTH(1)) MSB_COMPARATOR(.x(x_msb), .y(y_msb), .gt(x_pos_y_neg), .lt(x_neg_y_pos), .eq(equal_sign)); 
	simple_comparator#(.WIDTH(WIDTH-1)) MAG_COMPARATOR(.x(x[WIDTH-2:0]),.y(y[WIDTH-2:0]), .gt(mag_gt), .lt(mag_lt), .eq(mag_eq)); 
	assign gt = x_pos_y_neg | (equal_sign & mag_gt); 
	assign lt = x_neg_y_pos | (equal_sign & mag_lt); 
	assign eq = equal_sign & mag_eq; 
endmodule 


//extensible unsigned magnitude comparator 
module simple_comparator(x,y,gt,lt,eq); 
	parameter WIDTH = 4; 
	input[WIDTH-1:0] x,y; 
	output gt,lt, eq; 
   wire [WIDTH-1:0] i;
   wire [WIDTH-1:0] xgty_bit;
   wire [WIDTH-1:0] eqn_prefix;
	

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
		begin
			assign xgty_bit[k] = x[k] & ~y[k] & eqn_prefix[k];
		end
   endgenerate

   assign eq = &i;
   assign gt = |xgty_bit;
   assign lt = ~(gt | eq);
endmodule 



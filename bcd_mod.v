module bcd_mod(x, out_hundreds, out_tens, out_units); 
   
	input [7:0] x; 
	output [6:0] out_hundreds, out_tens, out_units; 
	
	wire [3:0] hundreds_place = (x - x%100)/100; 
	wire [3:0] tens_place = ((x%100)-(x%10))/10; 
	wire [3:0] units_place = x%10;
	
	ssd_encoder_mod S0(hundreds_place,out_hundreds); 
	ssd_encoder_mod S1(units_place,out_units); 
	ssd_encoder_mod S2(tens_place,out_tens); 
	
endmodule

//gated D-flip flop 
module d_flip(clk,d,q,preset,reset); 
	input d, clk, preset, reset;
	output reg q; 
	always @(posedge clk)
		begin 
			if(preset)
				q <= 1; 
			else if(reset)
				q <= 0;
			else	
				q <= d; 
		end 
endmodule 

//  n-bit register


module mux_2_1(x1,x2,s,out); 
	input x1,x2,s; 
	output out; 
	assign out = (s&x1) | (~s&x2); 
endmodule 
	

//SSD encoder with 4 bit input and default 'E' output for n > 9 
module ssd_encoder_mod (x,s);
 input [3:0] x; 
 output [6:0] s; 
 
 assign s[0] = ~x[3] & ~x[1] & (x[0] ^ x[2]); 
 assign s[1] = x[3] & (x[2] | x[1]) | x[2] & (x[1] ^ x[0]); 
 assign s[2] = (x[3] & x[2]) | (x[3] & x[1]) | (~x[2] & x[1] & ~x[0]);
 assign s[3] = (~x[3] & x[2] & ~x[1] & ~x[0]) | (~x[2] & ~x[1] & x[0]) | (~x[3] & x[2] & x[1] & x[0]); 
 assign s[4] = (~x[3] & x[0]) | (~x[2] & ~x[1] & x[0]) | (~x[1] & ~x[3] & x[2]); 
 assign s[5] = (~x[3] & ~x[2] & x[0]) | (~x[3] & ~x[2] & x[1]) | (x[1] & x[0] & ~x[3]); 
 assign s[6] = (~x[1] & ~x[3] & ~x[2]) | (~x[3] & x[2] & x[1] & x[0]);  
endmodule
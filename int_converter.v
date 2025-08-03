module int_converter(x, r, negative, cout, overflow, zero); 

input [15:0] x; 
output [15:0] r; 
output negative, cout, overflow, zero; 

wire unsigned_x; 
wire x_sign = x[15]; 
wire [4:0] ldz_count; 
wire value_zero, adder_cout, sub_cout; 
wire [4:0] mantissa_shift_count; 
wire [4:0] exponent;
wire [15:0] shifted_mantissa;
wire [9:0] truncated_mantissa;


wire [9:0] r_mantissa; 
wire r_sign; 
wire [4:0] r_exponent; 
 
complimenter_2 #(.WIDTH(16))          COMPLIMENTER(.x(x), .r(unsigned_x), .enable(x_sign));
leading_zero_counter_16               LEADING_ZERO_COUNTER(.x(unsigned_x), .q(ldz_count), .a(value_zero)); 
simplified_signed_adder#(.WIDTH(5))   ADDER(.x(5'd1), .y(ldz_count), .add_sub(1'b0), .cout(adder_cout), .s(mantissa_shift_count));
simplified_signed_adder#(.WIDTH(5))   SUBTRACTOR(.x(5'd30), .y(ldz_count), .add_sub(1'b1), .cout(sub_cout), .s(exponent));
barrel_shifter_11_13#(.WIDTH(16))     LEFT_SHIFTER(.x(x), .r(shifted_mantissa), .shift_count(mantissa_shift_count), .mode(1'b1));
assign truncated_mantissa = shifted_mantissa[15:6]; 

assign  r_sign = x_sign; 
assign r_exponent = value_zero? 5'd0: exponent;
assign r_mantissa = value_zero? 10'd0: truncated_mantissa;    

assign r = {r_sign, r_exponent, r_mantissa}; 
assign negative = r_sign;
assign cout = 1'b0;
assign overflow = 1'b0; 
assign zero = value_zero; 
endmodule 

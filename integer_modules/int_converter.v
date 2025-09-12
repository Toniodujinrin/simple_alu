module int_converter (
    input  [15:0] x, 
    output [15:0] r, 
    output negative, cout, overflow, zero
);
    wire [15:0] unsigned_x; 
    wire x_sign = x[15]; 
    wire [4:0] ldz_count; 
    wire value_zero, adder_cout, sub_cout; 
    wire [4:0] mantissa_shift_count; 
    wire [4:0] exponent;
    wire [15:0] shifted_mantissa;

    // Mantissa/exponent wires
    wire [9:0] truncated_mantissa;
    wire       round_bit, sticky_bit, round_increment;
    wire [10:0] rounded_ext; 
    wire [9:0] final_mantissa;
    wire       mantissa_overflow;
    wire [4:0] final_exponent;

    wire [9:0] r_mantissa; 
    wire       r_sign; 
    wire [4:0] r_exponent; 

    // --- Normalization path ---
    complimenter_2 #(.WIDTH(16)) COMPLIMENTER(
        .x(x), 
        .r(unsigned_x), 
        .enable(x_sign)
    );

    leading_zero_counter_16 LEADING_ZERO_COUNTER(
        .x(unsigned_x), 
        .q(ldz_count), 
        .a(value_zero)
    ); 

    // Remove +1, use ldz_count directly
    assign mantissa_shift_count = ldz_count;

    simplified_signed_adder #(.WIDTH(5)) SUBTRACTOR(
        .x(5'd30), 
        .y(ldz_count), 
        .add_sub(1'b1), 
        .cout(sub_cout), 
        .s(exponent)
    );

    barrel_shifter_11_13 #(.WIDTH(16)) LEFT_SHIFTER(
        .x(unsigned_x), 
        .r(shifted_mantissa), 
        .shift_count(mantissa_shift_count), 
        .mode(1'b1)
    );

    // --- Truncation & Rounding ---
    assign truncated_mantissa = shifted_mantissa[15:6];   // top 10 fraction bits
    assign round_bit          = shifted_mantissa[5];      // guard
    assign sticky_bit         = |shifted_mantissa[4:0];   // sticky OR

    // Round-to-nearest-even increment condition
    assign round_increment = round_bit & (sticky_bit | truncated_mantissa[0]);

    // Extended adder for rounding (11 bits to capture carry)
    assign rounded_ext = {1'b0, truncated_mantissa} + (round_increment ? 11'd1 : 11'd0);

    assign final_mantissa    = rounded_ext[9:0];
    assign mantissa_overflow = rounded_ext[10];

    // Adjust exponent if mantissa overflowed
    assign final_exponent = exponent + (mantissa_overflow ? 5'd1 : 5'd0);

    // --- Final assignments ---
    assign r_sign     = x_sign; 
    assign r_exponent = value_zero ? 5'd0  : final_exponent;
    assign r_mantissa = value_zero ? 10'd0 : final_mantissa;    

    assign r        = {r_sign, r_exponent, r_mantissa}; 
    assign negative = r_sign;
    assign cout     = 1'b0;
    assign overflow = (final_exponent >= 5'd31); // exponent overflow → Inf
    assign zero     = value_zero; 
endmodule
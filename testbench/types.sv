`ifndef TYPES_PKG_SV
`define TYPES_PKG_SV

`ifndef DATA_WIDTH
`define DATA_WIDTH 16
`endif


package types_pkg;
   
// Formula resources: https://en.wikipedia.org/wiki/Half-precision_floating-point_format
class float16;

    bit [9:0] mantissa; 
    bit [4:0] exponent; 
    bit sign;
    bit is_inf;
    bit is_nan; 
    bit is_subnormal;    

    function new(bit [15:0] float_val); 
        mantissa = float_val[9:0]; 
        exponent = float_val[14:10]; 
        sign     = float_val[15]; 
    endfunction : new

    static function float16 real_to_float16(real val); 
        bit [63:0] float64_bits;
        bit sign_field_64;
        bit [10:0] exponent_field_64;
        bit [51:0] mantissa_field_64;
        float16 res;
        int real_exponent;
        bit [4:0] m_exponent;
        bit [9:0] m_mantissa;
        bit round_bit;
        bit sticky_bit;

        float64_bits = $realtobits(val); 
        sign_field_64 = float64_bits[63]; 
        exponent_field_64 = float64_bits[62:52]; 
        mantissa_field_64 = float64_bits[51:0]; 

        // Special cases
        if (exponent_field_64 == 11'h000 && mantissa_field_64 == 52'h0) begin
            res = new({sign_field_64, 15'b0}); // ±0
            return res;  
        end 
        else if (exponent_field_64 == 11'h7ff && mantissa_field_64 == 52'h0) begin 
            res = new({sign_field_64, 5'b11111, 10'b0}); // ±inf
            return res; 
        end 
        else if (exponent_field_64 == 11'h7ff && mantissa_field_64 != 52'h0) begin
            res = new({sign_field_64, 5'b11111, 10'b1}); // NaN
            return res; 
        end

        // Normal / subnormal handling
        real_exponent = exponent_field_64 - 1023; // Bias adjustment

        if (real_exponent > 15) begin 
            // Overflow -> Inf
            res = new({sign_field_64, 5'b11111, 10'b0}); 
            return res; 
        end 
        else if (real_exponent < -14) begin 
            // Underflow -> 0 (TODO: subnormals)
            res = new({sign_field_64, 15'b0}); 
            return res;  
        end 
        else begin 
            m_exponent = 5'd15 + real_exponent; // Re-bias
            m_mantissa = mantissa_field_64[51:42]; 
            round_bit  = mantissa_field_64[41];
            sticky_bit = |mantissa_field_64[40:0];
            if (round_bit && (sticky_bit || m_mantissa[0]))
                m_mantissa++;
            res = new({sign_field_64, m_exponent, m_mantissa}); 
            return res; 
        end 
    endfunction : real_to_float16

    function real convert_to_real(); 
        bit implicit_leading_one;
        int real_exponent;
        real frac, result;

        // Special cases
        if (exponent == 5'b0 && mantissa == 10'b0) begin
            return sign ? -0.0 : 0.0;
        end else if (exponent == 5'b11111 && mantissa == 10'b0) begin
            return sign ? -1.0/0.0 : 1.0/0.0; // ±inf
        end else if (exponent == 5'b11111 && mantissa != 10'b0) begin
            return 0.0/0.0; // NaN
        end

        // Normal/denormal
        if (exponent == 0) begin
            real_exponent = -14; // Denormal exponent
            implicit_leading_one = 0;
        end else begin
            real_exponent = exponent - 15; // Re-bias
            implicit_leading_one = 1;
        end

        // Fraction = implicit + mantissa/1024.0
        frac = implicit_leading_one + (mantissa / 1024.0);

        // Final result
        result = (sign ? -1.0 : 1.0) * (2.0 ** real_exponent) * frac;
        return result;
    endfunction : convert_to_real
endclass : float16

class generator; 
    mailbox gen_drv; 
    int samples;
    
    transaction tr;
    function new(mailbox mbx, int samples); 
        this.gen_drv = mbx;
        this.samples = samples;
    endfunction : new

    task run(); 
        repeat (samples) begin
            tr = new();
            assert(tr.randomize());
            gen_drv.put(tr);
        end
    endtask : run
endclass : generator

endpackage : types_pkg

`endif //TYPES_PKG_SV
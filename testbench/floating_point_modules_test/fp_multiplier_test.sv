`ifndef FP_MULTIPLIER_TEST_SV
`define FP_MULTIPLIER_TEST_SV

`include "types.sv"

import types_pkg::*;

module testbench;

    fp_multiplier_if  fp_multiplier_if();
    test tst(fp_multiplier_if);

    //DUT intialization
    fp_multiplier  DUT(
        .x(fp_multiplier_if.x),
        .y(fp_multiplier_if.y),
        .overflow(fp_multiplier_if.overflow),
        .negative(fp_multiplier_if.negative),
        .zero(fp_multiplier_if.zero),
        .cout(fp_multiplier_if.cout),
        .r(fp_multiplier_if.s),
        .inf(fp_multiplier_if.inf),
        .nan(fp_multiplier_if.nan),
        .subnormal(fp_multiplier_if.subnormal)
    );

    initial begin
        $dumpfile("fp_multiplier_test.vcd");
        $dumpvars; 
    end

    initial begin
        #1000;
        $finish;
    end

endmodule : testbench

interface fp_multiplier_if;
    logic [`DATA_WIDTH-1:0] x;
    logic [`DATA_WIDTH-1:0] y;
    logic [`DATA_WIDTH-1:0] s;
    logic overflow;
    logic negative;
    logic zero;
    logic cout;
    logic inf;
    logic nan;
    logic subnormal;
endinterface : fp_multiplier_if

class transaction; 
    rand logic [`DATA_WIDTH-1:0] x;
    rand logic [`DATA_WIDTH-1:0] y;
    logic overflow; 
    logic negative; 
    logic zero; 
    logic cout; 
    logic inf;
    logic nan;
    logic subnormal;
    logic [`DATA_WIDTH-1:0] s;

    function void display(string tag = ""); 
        float16 x_float, y_float, s_float;
        real x_real, y_real, s_real;
        x_float = new(x);
        y_float = new(y);
        s_float = new(s);
        x_real = x_float.convert_to_real();
        y_real = y_float.convert_to_real();
        s_real = s_float.convert_to_real();
      $display("%s x_real = %9.2f, y_real = %9.2f,s_raw = %016b, s_real = %9.2f,  overflow = %0b, negative = %0b, zero = %0b, cout = %0b, subnormal = %0b, inf = %0b, nan = %0b", tag, x_real, y_real, s, s_real, overflow, negative, zero, cout, subnormal, inf, nan);
    endfunction : display
endclass : transaction


class driver; 
    virtual fp_multiplier_if fp_multiplier_if;
    mailbox gen_drv;
    int samples;
    function new(virtual fp_multiplier_if fp_multiplier_if, mailbox mbx, int samples); 
        this.fp_multiplier_if = fp_multiplier_if;
        this.gen_drv = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            gen_drv.get(tr);
            fp_multiplier_if.x = tr.x;
            fp_multiplier_if.y = tr.y;
            #10; // wait for DUT to process
        end 
    endtask : run
endclass : driver

class monitor; 
    mailbox mon_score;
    virtual fp_multiplier_if fp_multiplier_if;
    int samples;
    function new(virtual fp_multiplier_if fp_multiplier_if, mailbox mbx, int samples); 
        this.fp_multiplier_if = fp_multiplier_if;
        this.mon_score = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            #11; // wait for DUT output to change
            tr = new();
            tr.x = fp_multiplier_if.x;
            tr.y = fp_multiplier_if.y;
            tr.s = fp_multiplier_if.s;
            tr.overflow = fp_multiplier_if.overflow;
            tr.negative = fp_multiplier_if.negative;
            tr.zero = fp_multiplier_if.zero;
            tr.cout = fp_multiplier_if.cout;
            tr.inf = fp_multiplier_if.inf;
            tr.nan = fp_multiplier_if.nan;
            tr.subnormal = fp_multiplier_if.subnormal;
            mon_score.put(tr);
        end
    endtask : run
endclass : monitor

class scoreboard; 
    mailbox mon_score;
    int samples;
    // DUT output
    logic [`DATA_WIDTH-1:0] x; 
    logic [`DATA_WIDTH-1:0] y;
    logic [`DATA_WIDTH-1:0] s;
    float16 x_float, y_float, s_float;
    real x_real, y_real, s_real;
    logic overflow;
    logic negative; 
    logic zero;
    logic cout;
    logic inf; 
    logic subnormal; 
    logic nan;

    // expected values
    real expected_s;
    float16 expected_s_float;
    logic expected_overflow; 
    logic expected_negative;
    logic expected_zero;
    logic expected_cout;
    logic expected_inf;
    logic expected_subnormal;
    logic expected_nan;
    transaction tr;
    function new(mailbox mbx, int samples); 
        this.mon_score = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            mon_score.get(tr);
            tr.display("SB"); 
            //DUT output
            x = tr.x;
            y = tr.y;
            s = tr.s;
            overflow = tr.overflow;
            negative = tr.negative;
            zero = tr.zero;
            cout = tr.cout;
            inf = tr.inf;
            nan = tr.nan;
            subnormal = tr.subnormal;
            x_float = new(x);
            y_float = new(y);
            s_float = new(s);
            x_real = x_float.convert_to_real();
            y_real = y_float.convert_to_real();
            s_real = s_float.convert_to_real();


            //golden model
            expected_s = x_real * y_real; 
            expected_s_float = float16::real_to_float16(expected_s);
            expected_negative = (expected_s < 0);
            expected_zero = (expected_s == 0);
            expected_subnormal = (expected_s_float.exponent == 5'b0 && expected_s_float.mantissa != 0);
          $display("expected_s %9.2f",expected_s); 
            expected_inf = (expected_s_float.exponent == 5'b11111 && expected_s_float.mantissa == 0);
            expected_nan = (expected_s_float.exponent == 5'b11111 && expected_s_float.mantissa != 0);
            expected_overflow =  expected_s > 65504.0 || expected_s < -65504.0 ||expected_nan || expected_inf; 
           // max and min representable values in float16
            expected_cout = 1'b0; //signed adder does not use cout
            //compare DUT output with expected values
          if () begin
                $error("Mismatch in sum: got %0d, expected %0d", s_real, expected_s);
            end
//            if (overflow !== expected_overflow) begin
//                 $error("Mismatch in overflow: got %0b, expected %0b", overflow, expected_overflow);
//             end
//             if (negative !== expected_negative) begin
//                 $error("Mismatch in negative: got %0b, expected %0b", negative, expected_negative);
//             end
//             if (zero !== expected_zero) begin
//                 $error("Mismatch in zero: got %0b, expected %0b", zero, expected_zero);
//             end
//             if (inf !== expected_inf) begin
//                 $error("Mismatch in inf: got %0b, expected %0b", inf, expected_inf);
//             end
//             if (nan !== expected_nan) begin
//                 $error("Mismatch in nan: got %0b, expected %0b", nan, expected_nan);
//             end
//             if (subnormal !== expected_subnormal) begin
//                 $error("Mismatch in subnormal: got %0b, expected %0b",
//                 subnormal, expected_subnormal);
//             end
//             if (cout !== expected_cout) begin
//                 $error("Mismatch in cout: got %0b, expected %0b", cout, expected_cout);
//             end
       end
    endtask : run
endclass : scoreboard


program test(fp_multiplier_if fp_multiplier_if);
    int samples = 50;
    typedef virtual fp_multiplier_if fp_multiplier_if_vt;
    typedef generator #(transaction) fp_multiplier_generator_t;
    environment #(transaction, driver, fp_multiplier_generator_t, monitor, scoreboard, fp_multiplier_if_vt) env;  
    initial begin
        env = new(fp_multiplier_if, samples);
        env.run();
    end
endprogram : test

`endif // FP_MULTIPLIER_TEST_SV
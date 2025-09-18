`ifndef FP_ADDER_TEST_SV
`define FP_ADDER_TEST_SV

`include "types.sv"

import types_pkg::*;

module testbench;

    fp_adder_if  fp_adder_if();
    test tst(fp_adder_if);

    //DUT intialization
    fp_adder_subtractor  DUT(
        .x(fp_adder_if.x),
        .y(fp_adder_if.y),
        .add_sub(fp_adder_if.add_sub),
        .overflow(fp_adder_if.overflow),
        .negative(fp_adder_if.negative),
        .zero(fp_adder_if.zero),
        .cout(fp_adder_if.cout),
        .r(fp_adder_if.s),
        .inf(fp_adder_if.inf),
        .nan(fp_adder_if.nan),
        .subnormal(fp_adder_if.subnormal)
    );

    initial begin
        $dumpfile("fp_adder_test.vcd");
        $dumpvars; 
    end

    initial begin
        #1000;
        $finish;
    end

endmodule : testbench

interface fp_adder_if;
    logic [`DATA_WIDTH-1:0] x;
    logic [`DATA_WIDTH-1:0] y;
    logic [`DATA_WIDTH-1:0] s;
    logic add_sub; // 0 for addition, 1 for subtraction
    logic overflow;
    logic negative;
    logic zero;
    logic cout;
    logic inf;
    logic nan;
    logic subnormal;
endinterface : fp_adder_if

class transaction; 
    rand logic [`DATA_WIDTH-1:0] x;
    rand logic [`DATA_WIDTH-1:0] y;
    rand logic add_sub; // 0 for addition, 1 for subtraction
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
      $display("%s x_real = %9.2f, y_real = %9.2f,s_raw = %016b, s_real = %9.2f, add_sub = %0b, overflow = %0b, negative = %0b, zero = %0b, cout = %0b, subnormal = %0b, inf = %0b, nan = %0b", tag, x_real, y_real, s, s_real, add_sub, overflow, negative, zero, cout, subnormal, inf, nan);
    endfunction : display
endclass : transaction


class driver; 
    virtual fp_adder_if fp_adder_if;
    mailbox gen_drv;
    int samples;
    function new(virtual fp_adder_if fp_adder_if, mailbox mbx, int samples); 
        this.fp_adder_if = fp_adder_if;
        this.gen_drv = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            gen_drv.get(tr);
            fp_adder_if.x = tr.x;
            fp_adder_if.y = tr.y;
            fp_adder_if.add_sub = tr.add_sub;
            #10; // wait for DUT to process
        end 
    endtask : run
endclass : driver

class monitor; 
    mailbox mon_score;
    virtual fp_adder_if fp_adder_if;
    int samples;
    function new(virtual fp_adder_if fp_adder_if, mailbox mbx, int samples); 
        this.fp_adder_if = fp_adder_if;
        this.mon_score = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            #11; // wait for DUT output to change
            tr = new();
            tr.x = fp_adder_if.x;
            tr.y = fp_adder_if.y;
            tr.s = fp_adder_if.s;
            tr.add_sub = fp_adder_if.add_sub;
            tr.overflow = fp_adder_if.overflow;
            tr.negative = fp_adder_if.negative;
            tr.zero = fp_adder_if.zero;
            tr.cout = fp_adder_if.cout;
            tr.inf = fp_adder_if.inf;
            tr.nan = fp_adder_if.nan;
            tr.subnormal = fp_adder_if.subnormal;
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
    logic add_sub; // 0 for addition, 1 for subtraction
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
            add_sub = tr.add_sub;
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
            expected_s = add_sub? (x_real - y_real): (x_real + y_real); 
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
          if (s_real - expected_s > 3 || s_real - expected_s < -3) begin
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


program test(fp_adder_if fp_adder_if);
    int samples = 50;
    typedef virtual fp_adder_if fp_adder_if_vt;
    typedef generator #(transaction) fp_adder_generator_t;
    environment #(transaction, driver, fp_adder_generator_t, monitor, scoreboard, fp_adder_if_vt) env;  
    initial begin
        env = new(fp_adder_if, samples);
        env.run();
    end
endprogram : test

`endif // FP_ADDER_TEST_SV
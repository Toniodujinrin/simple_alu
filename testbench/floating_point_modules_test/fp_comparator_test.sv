`ifndef FP_COMPARATOR_TEST_SV
`define FP_COMPARATOR_TEST_SV

`ifndef DATA_WIDTH
`define DATA_WIDTH 16
`endif

`include "types.sv"

import types_pkg::*;

module fp_comparator_testbench;

    fp_comparator_if  fp_comp_if();
    test tst(fp_comp_if);

    //DUT initialization
    fp_comparator DUT(
        .x(fp_comp_if.x), 
        .y(fp_comp_if.y), 
        .negative(fp_comp_if.negative), 
        .zero(fp_comp_if.zero), 
        .cout(fp_comp_if.cout), 
        .overflow(fp_comp_if.overflow),
        .inf(fp_comp_if.inf),
        .nan(fp_comp_if.nan),
        .subnormal(fp_comp_if.subnormal)
    );

    initial begin
        $dumpfile("comparator_test.vcd");
        $dumpvars; 
    end

    initial begin
        #10000;
        $finish;
    end

endmodule: fp_comparator_testbench

interface fp_comparator_if;
    logic [`DATA_WIDTH-1:0] x;
    logic [`DATA_WIDTH-1:0] y; //input
    logic signed_unsigned; //1 for signed comparison
    logic overflow;
    logic negative;
    logic zero;
    logic cout;
    logic inf;
    logic nan;
    logic subnormal;
endinterface : fp_comparator_if



class transaction; 
    rand logic [`DATA_WIDTH-1:0] x;
    rand logic [`DATA_WIDTH-1:0] y;
    logic overflow; 
    logic negative; 
    logic zero; 
    logic cout; 
    logic nan; 
    logic inf; 
    logic subnormal; 
  
    function void display();       
        float16 x_float16, y_float16; 
        real x_real, y_real; 

        x_float16 = new(x); 
        x_real = x_float16.convert_to_real(); 
        y_float16 = new(y); 
        y_real = y_float16.convert_to_real(); 


        $display("x_raw = %016b, x_real = %9.2f, x_float16 = %9.2f  y_raw = %016b, y_real = %9.2f, y_float16 = %9.2f, signed_unsigned = %0b, overflow = %0b, negative = %0b, zero = %0b, cout = %0b", x, x_real, x_float16, y, y_real, y_float16, signed_unsigned, overflow, negative, zero, cout);
    endfunction : display
endclass : transaction

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

class driver; 
    virtual fp_comparator_if fp_comp_if;
    mailbox gen_drv;
    int samples;
    function new(virtual fp_comparator_if fp_comp_if, mailbox mbx, int samples); 
        this.fp_comp_if = fp_comp_if;
        this.gen_drv = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            gen_drv.get(tr);
            fp_comp_if.x = tr.x;
            fp_comp_if.y = tr.y;
            #10; // wait for DUT to process
        end

    endtask : run
endclass : driver

class monitor; 
    mailbox mon_score;
    virtual fp_comparator_if fp_comp_if;
    int samples;
    function new(virtual fp_comparator_if fp_comp_if, mailbox mbx, int samples); 
        this.fp_comp_if = fp_comp_if;
        this.mon_score = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            #11; // wait for DUT output to change
            tr = new();
            tr.x = fp_comp_if.x;
            tr.y = fp_comp_if.y;
            tr.overflow = fp_comp_if.overflow;
            tr.negative = fp_comp_if.negative;
            tr.zero = fp_comp_if.zero;
            tr.cout = fp_comp_if.cout;
            tr.subnormal = fp_comp_if.subnormal; 
            tr.nan = fp_comp_if.nan; 
            tr.inf = fp_comp_if.inf;
            mon_score.put(tr);
        end
    endtask : run
endclass : monitor

class scoreboard; 
    mailbox mon_score;
    int samples; 
    //DUT output values
    logic [`DATA_WIDTH-1:0] x;
    logic [`DATA_WIDTH-1:0] y;
    float16 x_float16, y_float16;
    real x_real, y_real;
    logic overflow; 
    logic negative;
    logic zero; 
    logic cout;
    logic inf;
    logic nan;
    logic subnormal;

    //expected values
    logic expected_overflow;
    logic expected_negative;
    logic expected_zero;
    logic expected_cout;
    logic expected_inf;
    logic expected_nan;
    logic expected_subnormal;

    transaction tr;
    function new(mailbox mbx, int samples); 
        this.mon_score = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            mon_score.get(tr);
            //DUT output values
            tr.display(); 
            x = tr.x;
            y = tr.y;
            x_float16 = new(x); 
            y_float16 = new(y);
            x_real = x_float16.convert_to_real();
            y_real = y_float16.convert_to_real();
            overflow = tr.overflow;
            negative = tr.negative;
            zero = tr.zero;
            cout = tr.cout;
            inf = tr.inf;
            nan = tr.nan;
            subnormal = tr.subnormal;

            //golden model
            x_float16_inf = (x_float16.exponent == 5'b11111) && (x_float16.mantissa == 10'b0);
            y_float16_inf = (y_float16.exponent == 5'b11111) && (y_float16.mantissa == 10'b0);
            x_float16_nan = (x_float16.exponent == 5'b11111) && (x_float16.mantissa != 10'b0);
            y_float16_nan = (y_float16.exponent == 5'b11111) && (y_float16.mantissa != 10'b0);
            x_float16_subnormal = (x_float16.exponent == 5'b0) && (x_float16.mantissa != 10'b0);
            y_float16_subnormal = (y_float16.exponent == 5'b0) && (y_float16.mantissa != 10'b0);
            expected_nan = y_float16_nan || x_float16_nan;
            expected_inf = x_float16_inf || y_float16_inf;
            expected_subnormal = x_float16_subnormal || y_float16_subnormal;
            expected_zero = (x_real == y_real);
            expected_negative = (x_real < y_real);
            expected_cout = 1'b0; 
            expected_overflow = 1'b0; //not used
            

            //compare DUT output with expected values
            if (tr.overflow !== expected_overflow) begin
                $error("Mismatch in overflow: got %0b, expected %0b", tr.overflow, expected_overflow);
            end
            if (tr.negative !== expected_negative) begin
                $error("Mismatch in negative: got %0b, expected %0b", tr.negative, expected_negative);
            end
            if (tr.zero !== expected_zero) begin
                $error("Mismatch in zero: got %0b, expected %0b", tr.zero, expected_zero);
            end
            if (tr.cout !== expected_cout) begin
                $error("Mismatch in cout: got %0b, expected %0b", tr.cout, expected_cout);
            end
            if (tr.inf !== expected_inf) begin
                $error("Mismatch in inf: got %0b, expected %0b", tr.inf, expected_inf);
            end
            if (tr.nan !== expected_nan) begin
                $error("Mismatch in nan: got %0b, expected %0b", tr.nan, expected_nan);
            end
            if (tr.subnormal !== expected_subnormal) begin
                $error("Mismatch in subnormal: got %0b, expected %0b", tr.subnormal, expected_subnormal);
            end
        end
    endtask : run
endclass : scoreboard


class environment; 
    mailbox gen_drv;
    mailbox mon_score;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard score;
    virtual fp_comparator_if fp_comp_if;
    int samples;
    function new(virtual fp_comparator_if fp_comp_if, int samples); 
        this.fp_comp_if = fp_comp_if;
        this.samples = samples;
        gen_drv = new();
        mon_score = new();
        gen = new(gen_drv, samples);
        drv = new(fp_comp_if, gen_drv, samples);
        mon = new(fp_comp_if, mon_score, samples);
        score = new(mon_score, samples);
    endfunction : new

    task run(); 
        fork
            gen.run();
            drv.run();
            mon.run();
            score.run();
        join
    endtask : run
endclass : environment

program test(fp_comparator_if fp_comp_if);
    int samples = 500;
    environment env;
    initial begin
        env = new(fp_comp_if, samples);
        env.run();
    end
endprogram : test

`endif //FP_COMPARATOR_TEST_SV
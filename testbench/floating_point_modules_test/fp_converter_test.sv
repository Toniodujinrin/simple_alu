`ifndef FP_CONVERTER_TEST_SV
`define FP_CONVERTER_TEST_SV

`ifndef DATA_WIDTH
`define DATA_WIDTH 16
`endif 

`include "types.sv"

import types_pkg::*; 

module fp_converter_testbench; 
    fp_converter_interface fp_inf(); 
    test tst(fp_inf); 
   
    fp_converter DUT(
        .x(fp_inf.x), 
        .r(fp_inf.r), 
        .negative(fp_inf.negative), 
        .cout(fp_inf.cout), 
        .overflow(fp_inf.overflow), 
        .zero(fp_inf.zero),
        .inf(fp_inf.inf),
        .nan(fp_inf.nan),
        .subnormal(fp_inf.subnormal)
    );

    initial begin
        $dumpfile("fp_converter_test.vcd");
        $dumpvars; 
    end

    initial begin
        #100000;
        $finish;
    end
endmodule : fp_converter_testbench

interface fp_converter_interface; 
    bit [`DATA_WIDTH-1:0] x;
    shortint r;
    logic negative; 
    logic zero; 
    logic overflow; 
    logic cout;
    logic subnormal; 
    logic nan; 
    logic inf; 
endinterface 


class transaction; 
    rand bit [`DATA_WIDTH-1:0] x;
    shortint r; 
    logic negative; 
    logic zero; 
    logic overflow; 
    logic cout;
    logic inf;
    logic subnormal; 
    logic nan; 

    function void display();
        float16 x_real = new(x); 
        float16 x_float16 = float16::real_to_float16(x_real.convert_to_real());
      $display("x_raw = %0b, x_float16 = {sign=%0b, exp=%0d, mant=%0d}, x_real = %9.2f, r = %0d, overflow = %0b, negative = %0b, zero = %0b, cout = %0b, inf = %0b, nan = %0b, subnormal = %0b",
            x,
            x_float16.sign, x_float16.exponent, x_float16.mantissa,
                 x_real.convert_to_real(),
            r, overflow, negative, zero, cout, inf, nan, subnormal
        );
    endfunction : display
endclass : transaction 

class generator; 
    mailbox gen_drv; 
    int samples;
    transaction fp_conv_transaction;  

    function new(mailbox gen_drv, int samples); 
        this.gen_drv = gen_drv; 
        this.samples = samples; 
    endfunction : new

    task run(); 
        repeat(samples) begin
            fp_conv_transaction = new(); 
            assert(fp_conv_transaction.randomize()); 
            gen_drv.put(fp_conv_transaction); 
        end
    endtask : run
endclass : generator

class driver; 
    mailbox gen_drv; 
    int samples; 
    virtual fp_converter_interface fp_conv_inf; 

    function new(mailbox gen_drv, int samples, virtual fp_converter_interface fp_conv_inf);
        this.samples = samples; 
        this.gen_drv = gen_drv;
        this.fp_conv_inf = fp_conv_inf; 
    endfunction : new

    task run();
        repeat(samples) begin
            transaction fp_conv_transaction; 
            gen_drv.get(fp_conv_transaction); 
            fp_conv_inf.x = fp_conv_transaction.x; 
            #10; // Wait 10 for DUT to process outputs  
        end
    endtask : run
endclass : driver 

class monitor; 
    mailbox mon_sb; 
    int samples; 
    virtual fp_converter_interface fp_conv_inf; 

    function new(virtual fp_converter_interface fp_conv_inf, int samples, mailbox mon_sb); 
        this.fp_conv_inf = fp_conv_inf; 
        this.samples = samples; 
        this.mon_sb = mon_sb; 
    endfunction : new

    task run(); 
        repeat(samples) begin
            transaction fp_conv_transaction;
            fp_conv_transaction = new(); 
            #11; 
            fp_conv_transaction.x = fp_conv_inf.x; 
            fp_conv_transaction.r = fp_conv_inf.r; 
            fp_conv_transaction.negative = fp_conv_inf.negative; 
            fp_conv_transaction.zero = fp_conv_inf.zero; 
            fp_conv_transaction.overflow = fp_conv_inf.overflow; 
            fp_conv_transaction.cout = fp_conv_inf.cout; 
            fp_conv_transaction.inf = fp_conv_inf.inf; 
            fp_conv_transaction.nan = fp_conv_inf.nan; 
            fp_conv_transaction.subnormal = fp_conv_inf.subnormal; 
            mon_sb.put(fp_conv_transaction); 
        end
    endtask : run
endclass : monitor 

class scoreboard; 
    mailbox mon_sb;
    int samples;
    transaction fp_conv_transaction;

    // DUT output
    bit [`DATA_WIDTH-1:0] x; 
    shortint r;
    bit overflow, negative, zero, cout, inf, nan, subnormal;
	float16 x_float16; 
    // Expected
    shortint expected_r; 
    bit expected_overflow, expected_negative, expected_zero, expected_cout, expected_inf, expected_nan, expected_subnormal;

    function new(mailbox mon_sb, int samples); 
        this.mon_sb = mon_sb; 
        this.samples = samples; 
    endfunction : new

    task run(); 
        repeat(samples) begin
            mon_sb.get(fp_conv_transaction); 

            // DUT output
            x = fp_conv_transaction.x;
            r = fp_conv_transaction.r;
            overflow = fp_conv_transaction.overflow;
            negative = fp_conv_transaction.negative;
            zero = fp_conv_transaction.zero;
            cout = fp_conv_transaction.cout;
            inf = fp_conv_transaction.inf;
            nan = fp_conv_transaction.nan;
            subnormal = fp_conv_transaction.subnormal;

            // Golden model
            x_float16 = new(x);
            expected_r = $rtoi(x_float16.convert_to_real()); // Explicit cast to real
            expected_negative = (expected_r < 0);
            expected_zero = (expected_r == 0);
            expected_cout = 1'b0;
            expected_inf = (x_float16.exponent == 5'b11111 && x_float16.mantissa == 10'b0);
            expected_nan = (x_float16.exponent == 5'b11111 && x_float16.mantissa != 10'b0);
            expected_subnormal = (x_float16.exponent == 5'b0 && x_float16.mantissa != 10'b0);
          expected_overflow = expected_inf | expected_nan; 
          expected_zero = (expected_r == 0);

            fp_conv_transaction.display();

            // Compare results
          if (expected_r !== r && !expected_overflow) // Use an accuracy of ±2 for float comparison
                $error("Int→Float result mismatch: DUT r = %0d, expected r = %0d", r, expected_r);
            if (expected_negative !== negative)
                $error("Int→Float negative flag mismatch: DUT negative = %0b, expected = %0b", negative, expected_negative);
            if (expected_zero !== zero) 
                $error("Int→Float zero flag mismatch: DUT zero = %0b, expected = %0b", zero, expected_zero);
            if (expected_overflow !== overflow)
                $error("Int→Float overflow flag mismatch: DUT overflow = %0b, expected = %0b", overflow, expected_overflow);
            if (expected_cout !== cout) 
                $error("Int→Float cout flag mismatch: DUT cout = %0b, expected = %0b", cout, expected_cout);
            if (expected_inf !== inf)
                $error("Int→Float inf flag mismatch: DUT inf = %0b, expected = %0b", inf, expected_inf);
            if (expected_nan !== nan)
                $error("Int→Float nan flag mismatch: DUT nan = %0b, expected = %0b", nan, expected_nan);
            if (expected_subnormal !== subnormal)
                $error("Int→Float subnormal flag mismatch: DUT subnormal = %0b, expected = %0b", subnormal, expected_subnormal);    
        end
    endtask : run
endclass : scoreboard

class environment; 
    mailbox gen_drv;
    mailbox mon_sb; 
    int samples; 

    generator gen; 
    driver drv; 
    monitor mon; 
    scoreboard sb; 

    virtual fp_converter_interface fp_conv_inf;

    function new(virtual fp_converter_interface fp_conv_inf, int samples); 
        this.fp_conv_inf = fp_conv_inf; 
        this.samples = samples; 

        gen_drv = new(); 
        mon_sb = new(); 

        gen = new(gen_drv, samples); 
        drv = new(gen_drv, samples, fp_conv_inf); 
        mon = new(fp_conv_inf, samples, mon_sb); 
        sb = new(mon_sb, samples); 
    endfunction : new

    task run(); 
        fork
            gen.run();
            drv.run();
            mon.run();
            sb.run();
        join
    endtask : run
endclass : environment

program test (fp_converter_interface fp_conv_inf); 
    int samples = 1000;
    environment env; 

    initial begin
        env = new(fp_conv_inf, samples); 
        env.run();
    end
endprogram : test

`endif // FP_CONVERTER_TEST_SV
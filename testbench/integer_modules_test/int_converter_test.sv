`ifndef INT_CONVERTER_TEST_SV
`define INT_CONVERTER_TEST_SV 


`ifndef DATA_WIDTH
`define DATA_WIDTH 16
`endif 

`include "types.sv"

import types_pkg::*; 

module int_converter_testbench; 
    int_converter_interface int_inf(); 
    test tst(int_inf); 
    int_converter DUT(
        .x(int_inf.x), 
        .r(int_inf.r), 
        .negative(int_inf.negative), 
        .cout(int_inf.cout), 
        .overflow(int_inf.overflow), 
        .zero(int_inf.zero)
  );


    initial begin
        $dumpfile("int_converter_test.vcd");
        $dumpvars; 
    end

    initial begin
        #100000;
        $finish;
    end

endmodule:int_converter_testbench


interface int_converter_interface; 
    shortint x;
    bit  [`DATA_WIDTH-1:0] r;
    logic negative; 
    logic zero; 
    logic overflow; 
    logic cout;
endinterface 


class transaction; 
    rand shortint  x;
    bit  [`DATA_WIDTH-1:0] r; 
    logic negative; 
    logic zero; 
    logic overflow; 
    logic cout;



    function void display();
        float16 r_float = new(r);
        real r_real = r_float.convert_to_real();
      $display("x = %0d, r = %0d, r_raw = %0b,  overflow = %0b, negative = %0b, zero = %0b, cout = %0b", x, r_real,r, overflow, negative, zero, cout);
    endfunction:display

endclass: transaction 



class driver; 
    mailbox gen_drv; 
    int samples; 
    virtual int_converter_interface int_conv_inf; 


  function new(mailbox gen_drv, int samples, virtual int_converter_interface int_conv_inf);
        this.samples = samples; 
        this.gen_drv = gen_drv;
        this.int_conv_inf = int_conv_inf; 
    endfunction:new

    task run();
        repeat(samples)
        begin
          	transaction int_conv_transaction; 
            gen_drv.get(int_conv_transaction); 
            int_conv_inf.x = int_conv_transaction.x; 
            #10; //wait 10 for DUT to process outputs  
        end
    endtask:run

endclass: driver 


class monitor; 
    mailbox mon_sb; n-
    int samples; 
    virtual int_converter_interface int_conv_inf; 


    function new(virtual int_converter_interface int_conv_inf, int samples, mailbox mon_sb); 
        this.int_conv_inf = int_conv_inf; 
        this.samples = samples; 
        this.mon_sb = mon_sb; 
    endfunction:new

    task run(); 
        repeat(samples)
        begin
            transaction int_conv_transaction;
            int_conv_transaction = new(); 
            #11; 
            int_conv_transaction.x = int_conv_inf.x; 
            int_conv_transaction.r = int_conv_inf.r; 
            int_conv_transaction.negative = int_conv_inf.negative; 
            int_conv_transaction.zero = int_conv_inf.zero; 
            int_conv_transaction.overflow = int_conv_inf.overflow; 
            int_conv_transaction.cout = int_conv_inf.cout; 
            mon_sb.put(int_conv_transaction); 

        end
    endtask:run

endclass: monitor 


class scoreboard; 
    mailbox mon_sb;
    int samples;
    transaction int_conv_transaction;

    // DUT output
    shortint signed_x; 
    bit [`DATA_WIDTH-1:0] r;
    float16 r_float;
    real r_real; 
    bit overflow, negative, zero, cout;

    // Expected
    shortint expected_x; 
    real expected_r; 
    bit expected_overflow, expected_negative, expected_zero, expected_cout;

    function new(mailbox mon_sb, int samples); 
        this.mon_sb = mon_sb; 
        this.samples = samples; 
    endfunction : new

    task run(); 
        repeat(samples) begin
            mon_sb.get(int_conv_transaction); 

            // DUT output
            signed_x = int_conv_transaction.x;
            r        = int_conv_transaction.r;
            r_float  = new(r);
            r_real   = r_float.convert_to_real();
            overflow = int_conv_transaction.overflow;
            negative = int_conv_transaction.negative;
            zero     = int_conv_transaction.zero;
            cout     = int_conv_transaction.cout;

            // Golden model
            expected_x        = signed_x;
            expected_r        = expected_x; // direct cast to real
            expected_negative = (expected_r < 0);
            expected_zero     = (expected_r == 0);
            expected_overflow = 1'b0; // TODO: implement overflow modeling if needed
            expected_cout     = 1'b0;

            int_conv_transaction.display();

            // Compare results
          if ((expected_r - r_real > 8)|| (expected_r - r_real < -8)) //use an accuracy of ±8 for float comparison
                $error("Int→Float result mismatch: DUT r = %0f, expected r = %0f", r_real, expected_r);
            if (expected_negative !== negative)
                $error("Int→Float negative flag mismatch: DUT negative = %0b, expected = %0b", negative, expected_negative);
            if (expected_zero !== zero) 
                $error("Int→Float zero flag mismatch: DUT zero = %0b, expected = %0b", zero, expected_zero);
            if (expected_overflow !== overflow)
                $error("Int→Float overflow flag mismatch: DUT overflow = %0b, expected = %0b", overflow, expected_overflow);
            if (expected_cout !== cout) 
                $error("Int→Float cout flag mismatch: DUT cout = %0b, expected = %0b", cout, expected_cout);
        end
    endtask : run
endclass : scoreboard


program test (int_converter_interface int_conv_inf); 
    int samples = 1000;
    typedef generator #(int_converter_interface) int_converter_generator_t;
    environment #(transaction, driver, int_converter_generator_t, monitor, scoreboard, int_converter_interface) env;

    initial begin
        env = new(int_conv_inf, samples); 
        env.run();
    end

endprogram:test


`endif //MULTIPLIER_TEST_SV
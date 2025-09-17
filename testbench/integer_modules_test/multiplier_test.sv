`ifndef MULTIPLIER_TEST_SV 
`define MULTIPLIER_TEST_SV

`ifndef DATA_WIDTH
`define DATA_WIDTH 16
`endif 

module multiplier_testbench; 
    multiplier_interface mult_inf(); 
    test tst(mult_inf); 
    multiplier DUT(
        .x(mult_inf.x),
        .y(mult_inf.y),
        .r(mult_inf.r),
        .signed_unsigned(mult_inf.signed_unsigned),
        .negative(mult_inf.negative),
        .zero(mult_inf.zero), 
        .overflow(mult_inf.overflow), 
        .cout(mult_inf.cout)
    ); 

    initial begin
        $dumpfile("multiplier_test.vcd");
        $dumpvars; 
    end

    initial begin
        #1000;
        $finish;
    end

endmodule:multiplier_testbench


interface multiplier_interface; 
    bit  [`DATA_WIDTH-1:0] x;
    bit  [`DATA_WIDTH-1:0] y; 
    bit  [(`DATA_WIDTH*2)-1:0] r; 
    logic signed_unsigned; 
    logic negative; 
    logic zero; 
    logic overflow; 
    logic cout;
endinterface 

class transaction; 
    rand bit  [`DATA_WIDTH-1:0] x;
    rand bit  [`DATA_WIDTH-1:0] y; 
    bit  [(`DATA_WIDTH*2)-1:0] r; 
    rand bit signed_unsigned; 
    logic negative; 
    logic zero; 
    logic overflow; 
    logic cout;

    shortint signed_x; 
    shortint signed_y; 
    int signed_r; 

    function void display();

        $cast(signed_x,x);
        $cast(signed_y,y); 
        $cast(signed_r,r); 

        if(this.signed_unsigned)
            $display("x = %0d, y = %0d, signed_unsigned = %0b, overflow = %0b, negative = %0b, zero = %0b, cout = %0b, r = %0d", signed_x, signed_y, signed_unsigned, overflow, negative, zero, cout, signed_r);
        else 
            $display("x = %0d, y = %0d, signed_unsigned = %0b, overflow = %0b, negative = %0b, zero = %0b, cout = %0b, r = %0d", x, y, signed_unsigned, overflow, negative, zero, cout, r);
          
    endfunction:display
endclass: transaction 


class driver; 
    mailbox gen_drv; 
    int samples; 
    virtual multiplier_interface mult_inf; 
    

  function new(mailbox gen_drv, int samples, virtual multiplier_interface mult_inf);
        this.samples = samples; 
    this.gen_drv = gen_drv;
        this.mult_inf = mult_inf; 
    endfunction:new

    task run();
        repeat(samples)
        begin
             
          	transaction multiplier_transaction; 
            gen_drv.get(multiplier_transaction); 
            mult_inf.x = multiplier_transaction.x; 
            mult_inf.y = multiplier_transaction.y; 
            mult_inf.signed_unsigned = multiplier_transaction.signed_unsigned; 
            #10; //wait 10 for DUT to process outputs  
        end
    endtask:run

endclass: driver 


class monitor; 
    mailbox mon_sb; 
    int samples; 
    virtual multiplier_interface mult_inf; 
     
    
    function new(virtual multiplier_interface mult_inf, int samples, mailbox mon_sb); 
        this.mult_inf = mult_inf; 
        this.samples = samples; 
        this.mon_sb = mon_sb; 
    endfunction:new

    task run(); 
        repeat(samples)
        begin
            transaction multiplier_transaction;
            multiplier_transaction = new(); 
            #11; 
            multiplier_transaction.x = mult_inf.x; 
            multiplier_transaction.y = mult_inf.y; 
            multiplier_transaction.signed_unsigned = mult_inf.signed_unsigned; 
            multiplier_transaction.r = mult_inf.r; 
            multiplier_transaction.negative = mult_inf.negative; 
            multiplier_transaction.zero = mult_inf.zero; 
            multiplier_transaction.overflow = mult_inf.overflow; 
            multiplier_transaction.cout = mult_inf.cout; 
            mon_sb.put(multiplier_transaction); 
          
        end
    endtask:run

endclass: monitor 


class scoreboard; 
    mailbox mon_sb;
    int samples;
    transaction multiplier_transaction;
    //DUT output values
    shortint signed_x; 
    shortint signed_y;
    int signed_r;
    bit [(`DATA_WIDTH*2)-1:0] unsigned_r;
    bit [`DATA_WIDTH-1:0] unsigned_x;
    bit [`DATA_WIDTH-1:0] unsigned_y;
    bit overflow;
    bit negative;
    bit zero;
    bit cout;
    //expected values
    shortint expected_signed_x; 
    shortint expected_signed_y;
    int expected_signed_r;
    bit [(`DATA_WIDTH*2)-1:0] expected_unsigned_r;
    bit [`DATA_WIDTH-1:0] expected_unsigned_x;
    bit [`DATA_WIDTH-1:0] expected_unsigned_y;
    bit expected_overflow;
    bit expected_negative;
    bit expected_zero;
    bit expected_cout;

    function new(mailbox mon_sb, int samples); 
        this.mon_sb = mon_sb; 
        this.samples = samples; 
    endfunction:new

    task run(); 
        repeat(samples)
        begin
            mon_sb.get(multiplier_transaction); 
            //golden model
            $cast(signed_x,multiplier_transaction.x);
            $cast(signed_y,multiplier_transaction.y);
            $cast(signed_r,multiplier_transaction.r);
            unsigned_x = multiplier_transaction.x;
            unsigned_y = multiplier_transaction.y;
            unsigned_r = multiplier_transaction.r;
            overflow = multiplier_transaction.overflow;
            negative = multiplier_transaction.negative;
            zero = multiplier_transaction.zero;
            cout = multiplier_transaction.cout;

            if(multiplier_transaction.signed_unsigned) begin
                expected_signed_r = signed_x * signed_y; 
                expected_negative = (expected_signed_r < 0); 
                expected_zero = (expected_signed_r == 0); 
                
            end else begin
                expected_unsigned_r = unsigned_x * unsigned_y; 
                expected_negative = 1'b0; //not used in unsigned multiplication
                expected_zero = (expected_unsigned_r == 0); 
            end
            expected_overflow = 1'b0; //overflow not used in multiplication
            expected_cout = 1'b0; //not used in signed multiplication
            multiplier_transaction.display(); 

            //compare DUT output with expected values
            if(multiplier_transaction.signed_unsigned) begin
                if(expected_signed_r !== signed_r)
                    $error("Signed multiplication result mismatch: DUT r = %0d, expected r = %0d", signed_r, expected_signed_r);
            end else begin
                if(expected_unsigned_r !== unsigned_r) 
                    $error("Unsigned multiplication result mismatch: DUT r = %0d, expected r = %0d", unsigned_r, expected_unsigned_r);
            end
            if (expected_negative !== negative)
                    $error("Signed multiplication negative flag mismatch: DUT negative = %0b, expected negative = %0b", negative, expected_negative);
            if (expected_zero !== zero) 
                    $error("Signed multiplication zero flag mismatch: DUT zero = %0b, expected zero = %0b", zero, expected_zero);
            if (expected_overflow !== overflow)
                    $error("Signed multiplication overflow flag mismatch: DUT overflow = %0b, expected overflow = %0b", overflow, expected_overflow);
            if (expected_cout !== cout) 
                    $error("Signed multiplication cout flag mismatch: DUT cout = %0b, expected cout = %0b", cout, expected_cout);
          
        end
    endtask:run
endclass:scoreboard


program test (multiplier_interface mult_inf); 
    int samples = 10;
    typedef generator #(multiplier_interface) multiplier_generator_t;
    environment #(transaction, driver, multiplier_generator_t, monitor, scoreboard, multiplier_interface) env; 

    initial begin
        env = new(mult_inf, samples); 
        env.run();
    end

endprogram:test


`endif //MULTIPLIER_TEST_SV
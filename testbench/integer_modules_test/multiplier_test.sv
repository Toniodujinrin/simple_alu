`ifndef MULTIPLIER_TEST_SV 
`define MULTIPLIER_TEST_SV

`ifndef DATA_WIDTH
`define DATA_WIDTH 16
`endif 

module testbench; 
    multiplier_interface mult_inf; 

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

endmodule:testbench


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
    rand logic signed_unsigned; 
    logic negative; 
    logic zero; 
    logic overflow; 
    logic cout;

    shortint signed_x; 
    shortint signed_y; 
    shortint signed_r; 

    function display();

        $cast(signed_x,x);
        $cast(signed_y,y); 
        $cast(signed_r,r); 

        if(this.signed_unsigned); 
            $display("x = %0d, y = %0d, signed_unsigned = %0b, overflow = %0b, negative = %0b, zero = %0b, cout = %0b, r = %0d", signed_x, signed_y, signed_unsigned, overflow, negative, zero, cout, signed_r);
        else 
            $display("x = %0d, y = %0d, signed_unsigned = %0b, overflow = %0b, negative = %0b, zero = %0b, cout = %0b, r = %0d", x, y, signed_unsigned, overflow, negative, zero, cout, r);
    endfunction:display
endclass: transaction 


class generator; 
    mailbox gen_drv; 
    int samples;
    transaction multiplier_transaction;  

    function new(mailbox gen_drv, int samples); 
        this.gen_drv = gen_drv; 
        this.samples = samples
    endfunction:new

    task run(); 
        repeat(samples)
            begin
                multiplier_transaction = new(); 
                assert(multiplier_transaction.randomize()); 
                gen_drv.put(multiplier_transaction); 
            end
    endtask 

endclass:generator


class driver
    mailbox drv_if; 
    int samples; 
    virtual multiplier_interface mult_inf; 
    transaction multiplier_transaction; 

    function new(mailbox drv_if, int samples, virtual multiplier_interface mult_inf);
        this.samples = samples; 
        this.drv_inf = drv_if;
        this.mult_inf = mult_inf; 
    endfunction:new

    task run(); 
        drv_if.get(multiplier_transaction); 
        mult_inf.x = multiplier_transaction.x; 
        mult_inf.y = multiplier_transaction.y; 
        mult_inf.signed_unsigned = multiplier_transaction.signed_unsigned; 
        #10 //wait 10 for DUT to process outputs

    endtask:run

endclass driver 


class monitor 
    mailbox mon_sb; 
    int samples; 
    virtual multiplier_interface mult_inf; 
    transaction multipler_transaction; 

    function new(); 

    endfunction:new

    task run(); 

    endtask:run

endclass monitor 


class scoreboard; 

    function new(); 

    endfunction:new

    task run(); 

    endtask:run
endclass:scoreboard

class environment; 


endclass environment


program test; 

endprogram test


`endif //MULTIPLIER_TEST_SV
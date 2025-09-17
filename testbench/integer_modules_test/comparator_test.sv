`ifndef COMPARATOR_TEST_SV
`define COMPARATOR_TEST_SV

`ifndef DATA_WIDTH
`define DATA_WIDTH 16
`endif

`include "types.sv"
import types_pkg::*;

module comparator_testbench;

    comparator_if  comp_if();
    test tst(comp_if);

    //DUT initialization
    comparator DUT(
        .x(comp_if.x), 
        .y(comp_if.y), 
        .signed_unsigned(comp_if.signed_unsigned), //1 for signed comparison
        .negative(comp_if.negative), 
        .zero(comp_if.zero), 
        .cout(comp_if.cout), 
        .overflow(comp_if.overflow)
    );

    initial begin
        $dumpfile("comparator_test.vcd");
        $dumpvars; 
    end

    initial begin
        #10000;
        $finish;
    end

endmodule: comparator_testbench

interface comparator_if;
    logic [`DATA_WIDTH-1:0] x;
    logic [`DATA_WIDTH-1:0] y; //output
    logic signed_unsigned; //1 for signed comparison
    logic overflow;
    logic negative;
    logic zero;
    logic cout;
endinterface : comparator_if



class transaction; 
    rand logic [`DATA_WIDTH-1:0] x;
    rand logic [`DATA_WIDTH-1:0] y;
    rand logic signed_unsigned; //1 for signed comparison
    shortint signed_x;
    shortint signed_y;
    logic overflow; 
    logic negative; 
    logic zero; 
    logic cout; 
  
    function void display(); 
      $cast(signed_x,x);
      $cast(signed_y,y); 
      
        if(signed_unsigned) 
        $display("signed_x = %0d, signed_y = %0d, signed_unsigned = %0b, overflow = %0b, negative = %0b, zero = %0b, cout = %0b", signed_x, signed_y, signed_unsigned, overflow, negative, zero, cout);
        else
        $display("x = %0d, y = %0d, signed_unsigned = %0b, overflow = %0b, negative = %0b, zero = %0b, cout = %0b", x, y, signed_unsigned, overflow, negative, zero, cout);
    endfunction : display
endclass : transaction



class driver; 
    virtual comparator_if comp_if;
    mailbox gen_drv;
    int samples;
    function new(virtual comparator_if comp_if, mailbox mbx, int samples); 
        this.comp_if = comp_if;
        this.gen_drv = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            gen_drv.get(tr);
            comp_if.x = tr.x;
            comp_if.y = tr.y;
            comp_if.signed_unsigned = tr.signed_unsigned;
            #10; // wait for DUT to process
        end

    endtask : run
endclass : driver

class monitor; 
    mailbox mon_score;
    virtual comparator_if comp_if;
    int samples;
    function new(virtual comparator_if comp_if, mailbox mbx, int samples); 
        this.comp_if = comp_if;
        this.mon_score = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            #11; // wait for DUT output to change
            tr = new();
            tr.x = comp_if.x;
            tr.y = comp_if.y;
            tr.signed_unsigned = comp_if.signed_unsigned;
            tr.overflow = comp_if.overflow;
            tr.negative = comp_if.negative;
            tr.zero = comp_if.zero;
            tr.cout = comp_if.cout;
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
    logic overflow; 
    logic negative;
  	logic signed_unsigned; 
    logic zero; 
    logic cout;
    shortint signed_x;
    shortint signed_y;
    //expected values
    logic expected_overflow;
    logic expected_negative;
    logic expected_zero;
    logic expected_cout;

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
            signed_unsigned = tr.signed_unsigned;
            overflow = tr.overflow;
            negative = tr.negative;
            zero = tr.zero;
            cout = tr.cout;
            $cast(signed_y,y);
            $cast(signed_x,x);

            //golden model
            if(signed_unsigned) begin
                expected_negative = (signed_x < signed_y); 
                expected_zero = (signed_x == signed_y);
            end
            else begin
                expected_negative = (x < y); 
                expected_zero = (x == y);
            end
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
        end
    endtask : run
endclass : scoreboard



program test(comparator_if comp_if);
    int samples = 500;
    typedef generator #(comparator_if) comparator_generator_t;
    environment #(transaction, driver, comparator_generator_t, monitor, scoreboard, comparator_if) env; 
    initial begin
        env = new(comp_if, samples);
        env.run();
    end
endprogram : test

`endif // COMPARATOR_TEST_SV
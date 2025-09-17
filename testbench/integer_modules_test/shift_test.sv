`ifndef SHIFTER_TEST_SV
`define SHIFTER_TEST_SV

`ifndef DATA_WIDTH
`define DATA_WIDTH 16
`endif

`ifndef SHIFT_WIDTH
`define SHIFT_WIDTH $clog2(16)
`endif 

`include "types.sv"

import types_pkg::*;

module shifter_testbench;

    shifter_if  shift_if();
    test tst(shift_if);

    //DUT initialization
    shift DUT(
        .x(shift_if.x), 
        .y(shift_if.y), 
        .shift_count(shift_if.shift_count), 
        .mode(shift_if.mode), 
        .negative(shift_if.negative), 
        .zero(shift_if.zero), 
        .cout(shift_if.cout), 
        .overflow(shift_if.overflow)
    );

    initial begin
        $dumpfile("shifter_test.vcd");
        $dumpvars; 
    end

    initial begin
        #1000;
        $finish;
    end

endmodule: shifter_testbench


interface shifter_if;
    logic [`DATA_WIDTH-1:0] x;
    logic [`DATA_WIDTH-1:0] y; //output

    logic [2:0] mode; // 3-bit mode for different shift operations
  logic [`SHIFT_WIDTH-1:0] shift_count; // 5-bit shift count
    logic overflow;
    logic negative;
    logic zero;
    logic cout;
endinterface : shifter_if



class transaction; 
    rand logic [`DATA_WIDTH-1:0] x;
    logic [`DATA_WIDTH-1:0] y;
    shortint signed_x;
    shortint signed_y;
    rand logic [2:0] mode; // 3-bit mode for different shift operations
  rand logic [`SHIFT_WIDTH-1:0] shift_count; // 5-bit shift count
    logic overflow; 
    logic negative; 
    logic zero; 
    logic cout; 
    constraint mode_constraint {mode inside {3'b000, 3'b001, 3'b010, 3'b011, 3'b100}; }; // limit mode to valid values

    function void display(); 
      $cast(signed_x,x);
      $cast(signed_y,y); 
      
        if(mode == 3'b010 || mode == 3'b011) //ASR or ASL
        $display("signed_x = %0d, signed_y = %0d, mode = %0b, shift_count = %0d, overflow = %0b, negative = %0b, zero = %0b, cout = %0b", signed_x, signed_y, mode, shift_count, overflow, negative, zero, cout);
        else
          $display("x = %0d, y = %0d, mode = %0b, shift_count = %0d, overflow = %0b, negative = %0b, zero = %0b, cout = %0b", x, y, mode, shift_count, overflow, negative, zero, cout);
    endfunction : display
endclass : transaction


class driver; 
    virtual shifter_if shift_if;
    mailbox gen_drv;
    int samples;
    function new(virtual shifter_if shift_if, mailbox mbx, int samples); 
        this.shift_if = shift_if;
        this.gen_drv = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            gen_drv.get(tr);
            shift_if.x = tr.x;
            shift_if.y = tr.y;
            shift_if.mode = tr.mode;
            shift_if.shift_count = tr.shift_count;
            #10; // wait for DUT to process
        end

    endtask : run
endclass : driver

class monitor; 
    mailbox mon_score;
    virtual shifter_if shift_if;
    int samples;
    function new(virtual shifter_if shift_if, mailbox mbx, int samples); 
        this.shift_if = shift_if;
        this.mon_score = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            #11; // wait for DUT output to change
            tr = new();
            tr.x = shift_if.x;
            tr.y = shift_if.y;
            tr.mode = shift_if.mode;
            tr.shift_count = shift_if.shift_count;
            tr.overflow = shift_if.overflow;
            tr.negative = shift_if.negative;
            tr.zero = shift_if.zero;
            tr.cout = shift_if.cout;
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
    logic [2:0] mode; // 3-bit mode for different shift operations
  logic [`SHIFT_WIDTH-1:0] shift_count; // 5-bit shift count
    logic overflow; 
    logic negative; 
    logic zero; 
    logic cout;
    shortint signed_x;
    shortint signed_y;
    //expected values
    logic [`DATA_WIDTH-1:0] expected_y;
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
            mode = tr.mode;
            shift_count = tr.shift_count; 
            $cast(signed_x,x);
            $cast(signed_y,y);
            overflow = tr.overflow;
            negative = tr.negative;
            zero = tr.zero;
            cout = tr.cout;
            //expected values
            if (mode == 3'b000) begin //LSL
                expected_y = x << shift_count;
            end else if (mode == 3'b001) begin //LSR
                expected_y = x >> shift_count;
            end else if (mode == 3'b010) begin //ASR
                expected_y = signed_x >>> shift_count;
            end else if (mode == 3'b011) begin //ASL
                expected_y = signed_x <<< shift_count;
            end else if (mode == 3'b100) begin //ROR
                expected_y = ((x >> shift_count) | (x << (`DATA_WIDTH - shift_count))) & ((1 << `DATA_WIDTH) - 1);
            end else begin
                expected_y = '0; // default case, should not occur due to constraints
            end
            expected_cout = 1'b0; 
            expected_negative = (expected_y[`DATA_WIDTH-1] == 1'b1);
            expected_zero = (expected_y == 0);
            expected_overflow = ((mode == 3'b000) || (mode == 3'b011)) && (x[`DATA_WIDTH-1] ^ y[`DATA_WIDTH-1]);

            //compare DUT output with expected values
            if (tr.y !== expected_y) begin
                $error("Mismatch in shift: got %0d, expected %0d", tr.y, expected_y);
            end
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




program test(shifter_if shift_if);
    int samples = 1000;
    typedef generator #(shifter_if) shifter_generator_t;
    environment #(transaction, driver, shifter_generator_t, monitor, scoreboard, shifter_if) env;
    initial begin
        env = new(shift_if, samples);
        env.run();
    end
endprogram : test

`endif // SHIFTER_TEST_SV

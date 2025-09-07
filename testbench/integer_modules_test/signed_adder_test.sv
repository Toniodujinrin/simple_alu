`ifndef SIGNED_ADDER_TEST_SV
`define SIGNED_ADDER_TEST_SV

`ifndef DATA_WIDTH
`define DATA_WIDTH 16
`endif

module signed_adder_testbench;

    signed_adder_if #(.WIDTH(`DATA_WIDTH)) adder_if();
    test tst(adder_if);

    //DUT intialization
    signed_adder #(.WIDTH(`DATA_WIDTH)) DUT(.x(adder_if.x), .y(adder_if.y), .add_sub(adder_if.add_sub), .overflow(adder_if.overflow), .negative(adder_if.negative), .zero(adder_if.zero), .cout(adder_if.cout), .s(adder_if.s));

    initial begin
        $dumpfile("signed_adder_test.vcd");
        $dumpvars; 
    end

    initial begin
        #1000;
        $finish;
    end

endmodule signed_adder_testbench

interface signed_adder_if  ();
    logic signed [`DATA_WIDTH-1:0] x;
    logic signed [`DATA_WIDTH-1:0] y;
    logic add_sub; // 0 for addition, 1 for subtraction
    logic overflow;
    logic negative;
    logic zero;
    logic cout;
    logic signed [`DATA_WIDTH-1:0] s;
endinterface : signed_adder_if

class transaction; 
     int WIDTH
    function new(int WIDTH); 
        this.WIDTH = WIDTH;
    endfunction : new
    rand logic signed [WIDTH-1:0] x;
    rand logic signed [WIDTH-1:0] y;
    rand logic add_sub; //1 0 for addition, 1 for subtraction
    constraint c_add_sub {add_sub == 1'b0 || add_sub == 1'b1;}
    logic overflow; 
    logic negative; 
    logic zero; 
    logic cout; 
    bit [WIDTH-1:0] s;

    function void display(string class_name); 
        $display("x = %0d, y = %0d, add_sub = %0b, overflow = %0b, negative = %0b, zero = %0b, cout = %0b, s = %0d", x, y, add_sub, overflow, negative, zero, cout, s);
    endfunction : display
endclass : transaction

class generator; 
    mailbox gen_drv
    int samples;
    
    transaction tr;
    function new(mailbox mbx, int samples); 
        this.gen_drv = mbx;
        this.samples = samples;
    endfunction : new

    task run(int WIDTH); 
        repeat (samples) begin
            tr = new(WIDTH);
            assert(tr.randomize());
            tr.display("Generator");
            gen_drv.put(tr);
        end
    endtask : run
endclass : generator

class driver; 
    virtual signed_adder_if adder_if;
    mailbox gen_drv;
    int samples;
    function new(virtual signed_adder_if adder_if, mailbox mbx, int samples); 
        this.adder_if = adder_if;
        this.gen_drv = mbx;
        this.samples = samples;
    endfunction : new
    task run(); 
        repeat(samples) begin
            transaction tr;
            gen_drv.get(tr);
            adder_if.x = tr.x;
            adder_if.y = tr.y;
            adder_if.add_sub = tr.add_sub;
            #10; // wait for DUT to process
            tr.overflow = adder_if.overflow;
            tr.negative = adder_if.negative;
            tr.zero = adder_if.zero;
            tr.cout = adder_if.cout;
            tr.s = adder_if.s;
            tr.display("Driver");
        end

    endtask : run
endclass : driver

class monitor; 
    mailbox mon_score;
    virtual signed_adder_if adder_if;
    int samples;
    function new(virtual signed_adder_if adder_if, mailbox mbx, int samples); 
        this.adder_if = adder_if;
        this.mon_score = mbx;
        this.samples = samples;
    endfunction : new
    task run(int WIDTH); 
        repeat(samples) begin
            transaction tr;
            #10; // wait for DUT to process
            tr = new(WIDTH);
            tr.x = adder_if.x;
            tr.y = adder_if.y;
            tr.add_sub = adder_if.add_sub;
            tr.overflow = adder_if.overflow;
            tr.negative = adder_if.negative;
            tr.zero = adder_if.zero;
            tr.cout = adder_if.cout;
            tr.s = adder_if.s;
            mon_score.put(tr);
            tr.display("Monitor");
        end
    endtask : run
endclass : monitor

class scoreboard; 
    mailbox mon_score;
    int samples; 
    function new(mailbox mbx, int samples); 
        this.mon_score = mbx;
        this.samples = samples;
    endfunction : new
    task run(int WIDTH); 
        repeat(samples) begin
            transaction tr;
            mon_score.get(tr);
            bit signed [WIDTH-1:0] expected_s;
            bit expected_overflow;
            bit expected_negative;
            bit expected_zero;
            bit expected_cout;
            //golden model
            if (tr.add_sub == 1'b0) begin
                expected_s = tr.x + tr.y;
                expected_cout = (tr.x[WIDTH-1] == tr.y[WIDTH-1]) && (expected_s[WIDTH-1] != tr.x[WIDTH-1]);
            end else begin
                expected_s = tr.x - tr.y;
                expected_cout = (tr.x[WIDTH-1] != tr.y[WIDTH-1]) && (expected_s[WIDTH-1] != tr.x[WIDTH-1]);
            end
            expected_overflow = (tr.x[WIDTH-1] == tr.y[WIDTH-1]) && (expected_s[WIDTH-1] != tr.x[WIDTH-1]);
            expected_negative = (expected_s < 0);
            expected_zero = (expected_s == 0);
        
            //compare DUT output with expected values
            if (tr.s !== expected_s) begin
                $error("Mismatch in sum: got %0d, expected %0d", tr.s, expected_s);
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


class environment; 
    mailbox gen_drv;
    mailbox mon_score;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard score;
    virtual signed_adder_if adder_if;
    int samples;
    function new(virtual signed_adder_if adder_if, int samples); 
        this.adder_if = adder_if;
        this.samples = samples;
        gen_drv = new();
        mon_score = new();
        gen = new(gen_drv, samples);
        drv = new(adder_if, gen_drv, samples);
        mon = new(adder_if, mon_score, samples);
        score = new(mon_score, samples);
    endfunction : new

    task run(int WIDTH); 
        fork
            gen.run(WIDTH);
            drv.run();
            mon.run(WIDTH);
            score.run(WIDTH);
        join
    endtask : run
endclass : environment

program test(signed_adder_if adder_if);
    int samples = 20;
    environment env;
    initial begin
        env = new(adder_if, samples);
        env.run(`DATA_WIDTH);
    end
endprogram : test

`endif // SIGNED_ADDER_TEST_SV
interface uart_if (input bit clk);
    logic rst;
    logic [7:0] data_in;
    logic rx;
    logic tx;
    logic busy;
    logic start;
    logic ready;
    logic [7:0] data_out;

    clocking drv_cb @(posedge clk);
        default input #1step output #1ns;
        output rst;
        output data_in;
        output start;
        output rx;
        input tx;
        input busy;
        input data_out;
        input ready;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #1ns;
        input rst;
        input data_in;
        input rx;
        input tx;
        input busy;
        input start;
        input ready;
        input data_out;
    endclocking

    modport DRV (clocking drv_cb, input clk);
    modport MON (clocking mon_cb, input clk);
endinterface

class transaction;
    rand bit [7:0] data_in;
    bit start;
    bit rst;
    logic rx;
    logic tx;
    bit busy;
    bit ready;
    logic [7:0] data_out;

    constraint dist_data_c {
        data_in dist {
            8'h00 := 10,
            8'hFF := 10,
            8'hAA := 10,
            8'h55 := 10,
            [8'h01 : 8'hEF] :/ 40
        };
    }

    function void print(input string tag = "");
        $display("%0t | [%s] | data_in=0x%0h | start=%0d | rx=%0d | tx=%0d | busy=%0d | ready=%0d | data_out=0x%0h",
                 $time, tag, data_in, start, rx, tx, busy, ready, data_out);
    endfunction
endclass

class generator;
    mailbox #(transaction) drv_mbx;
    event drv_done;

    function new(mailbox #(transaction) drv_mbx, event drv_done);
        this.drv_mbx = drv_mbx;
        this.drv_done = drv_done;
    endfunction

    task run();
        forever begin
            transaction trans = new();
            if (!trans.randomize()) begin
                $display("randomization failed!");
            end else begin
                drv_mbx.put(trans);
                trans.print("GEN");
                @(drv_done);
            end
        end
    endtask
endclass

class driver;
    mailbox #(transaction) drv_mbx;
    virtual uart_if.DRV vif;
    event drv_done;

    function new(mailbox #(transaction) drv_mbx, virtual uart_if.DRV vif, event drv_done);
        this.drv_mbx = drv_mbx;
        this.vif = vif;
        this.drv_done = drv_done;
    endfunction

    task clear();
        vif.drv_cb.rst <= 1'b1;
        vif.drv_cb.data_in <= '0;
        vif.drv_cb.start <= 1'b0;
        repeat(2) @(vif.drv_cb);
        vif.drv_cb.rst <= 1'b0;
        @(vif.drv_cb);
        $display("done resetting");
    endtask

    task run();
        forever begin
            transaction trans;
            drv_mbx.get(trans);

            @(vif.drv_cb);
            wait(vif.drv_cb.busy == 1'b0);
            vif.drv_cb.data_in <= trans.data_in;
            vif.drv_cb.start <= 1'b1;
            @(vif.drv_cb);
            vif.drv_cb.start <= 1'b0;
            wait(vif.drv_cb.busy == 1'b1);

            trans.print("DRV");

            wait(vif.drv_cb.busy == 1'b0);
            ->drv_done;
        end
    endtask
endclass

class monitor;
    mailbox #(transaction) scb_mbx;
    mailbox #(transaction) ref_mbx;
    virtual uart_if.MON vif;

    transaction cov_trans;

    covergroup uart_cg;
        DATA_IN_CP : coverpoint cov_trans.data_in iff(cov_trans.start == 1'b1) {
            bins all_zeros = {8'h00};
            bins all_ones = {8'hFF};
            bins alt_10 = {8'hAA};
            bins alt_01 = {8'h55};
            bins range[4] = {[8'h01 : 8'hEF]};
        }
        DATA_OUT_CP : coverpoint cov_trans.data_out iff(cov_trans.ready == 1'b1) {
            bins all_zeros = {8'h00};
            bins all_ones = {8'hFF};
            bins alt_10 = {8'hAA};
            bins alt_01 = {8'h55};
            bins range[4] = {[8'h01 : 8'hEF]};
        }
        CP_START : coverpoint cov_trans.start {
            bins started = {1'b1};
        }
        CP_READY : coverpoint cov_trans.ready {
            bins completed = {1'b1};
        }
    endgroup

    function new(mailbox #(transaction) scb_mbx, mailbox #(transaction) ref_mbx, virtual uart_if.MON vif);
        this.scb_mbx = scb_mbx;
        this.ref_mbx = ref_mbx;
        this.vif = vif;
        uart_cg = new();
    endfunction

    task transmit();
        forever begin
            transaction trans;
            @(vif.mon_cb);
            if (vif.mon_cb.start == 1'b1 && vif.mon_cb.busy == 1'b0) begin
                trans = new();
                trans.rst = vif.mon_cb.rst;
                trans.data_in = vif.mon_cb.data_in;
                trans.start = vif.mon_cb.start;
                trans.tx = vif.mon_cb.tx;
                trans.busy = vif.mon_cb.busy;

                cov_trans = trans;
                uart_cg.sample();

                trans.print("MON-TRANSMIT");
                ref_mbx.put(trans);
            end
        end
    endtask

    task receive();
        forever begin
            transaction trans;
            @(vif.mon_cb);
            if (vif.mon_cb.ready == 1'b1) begin
                trans = new();
                trans.rst = vif.mon_cb.rst;
                trans.rx = vif.mon_cb.rx;
                trans.ready = vif.mon_cb.ready;
                trans.data_out = vif.mon_cb.data_out;

                cov_trans = trans;
                uart_cg.sample();

                trans.print("MON-RECEIVE");
                scb_mbx.put(trans);
            end
        end
    endtask

    task run();
        fork
            transmit();
            receive();
        join_none
    endtask
endclass

class ref_model;
    mailbox #(transaction) ref_mbx;
    mailbox #(transaction) exp_mbx;

    function new(mailbox #(transaction) ref_mbx, mailbox #(transaction) exp_mbx);
        this.ref_mbx = ref_mbx;
        this.exp_mbx = exp_mbx;
    endfunction

    task run();
        transaction trans, exp_trans;
        forever begin
            ref_mbx.get(trans);
            exp_trans = new();
            exp_trans.data_out = trans.data_in;
            exp_mbx.put(exp_trans);
        end
    endtask
endclass

class scoreboard;
    mailbox #(transaction) exp_mbx;
    mailbox #(transaction) scb_mbx;
    int pass_count = 0;
    int fail_count = 0;

    function new(mailbox #(transaction) exp_mbx, mailbox #(transaction) scb_mbx);
        this.exp_mbx = exp_mbx;
        this.scb_mbx = scb_mbx;
    endfunction

    task run();
        transaction exp_val, act_val;
        forever begin
            exp_mbx.get(exp_val);
            scb_mbx.get(act_val);

            if (exp_val.data_out === act_val.data_out) begin
                pass_count++;
                $display("[Scoreboard Pass] expected_data_out=%0h actual_data_out=%0h",
                         exp_val.data_out, act_val.data_out);
            end else begin
                fail_count++;
                $error("[Scoreboard Failed] expected_data_out=%0h actual_data_out=%0h",
                       exp_val.data_out, act_val.data_out);
            end
        end
    endtask
endclass

class environment;
    generator gen;
    driver drv;
    monitor mon;
    ref_model rm;
    scoreboard scb;

    mailbox #(transaction) drv_mbx;
    mailbox #(transaction) scb_mbx;
    mailbox #(transaction) ref_mbx;
    mailbox #(transaction) exp_mbx;

    event drv_done;
    virtual uart_if vif;

    function new(virtual uart_if vif);
        this.vif = vif;
        drv_mbx = new();
        scb_mbx = new();
        ref_mbx = new();
        exp_mbx = new();

        gen = new(drv_mbx, drv_done);
        drv = new(drv_mbx, vif.DRV, drv_done);
        mon = new(scb_mbx, ref_mbx, vif.MON);
        rm = new(ref_mbx, exp_mbx);
        scb = new(exp_mbx, scb_mbx);
    endfunction

    task test();
        fork
            gen.run();
            drv.run();
            mon.run();
            rm.run();
            scb.run();
        join_none
    endtask

    task run();
        drv.clear();
        test();
        fork
            wait(mon.uart_cg.get_coverage() == 100.0);
            #20000000;
        join_any

        $display("========================================");
        $display("FUNCTIONAL COVERAGE = %0.2f%%", mon.uart_cg.get_coverage());
        $display("SCOREBOARD: pass=%0d fail=%0d", scb.pass_count, scb.fail_count);
        $display("========================================");
        if (scb.fail_count > 0 || scb.pass_count == 0)
            $fatal(1, "UART verification failed or no transactions compared");
        $finish;
    endtask
endclass

module tb_top;
    bit clk;
    wire connect;

    // 10 MHz system clock, matching baud_rate.CLK_FREQ = 10_000_000
    always #50 clk = ~clk;

    uart_if vif(clk);

    top_uart dut(
        .clk(clk),
        .rst(vif.rst),
        .data_in(vif.data_in),
        .start(vif.start),
        .busy(vif.busy),
        .tx(connect),
        .rx(connect),
        .ready(vif.ready),
        .data_out(vif.data_out)
    );

    environment env;

    initial begin
        clk = 0;
        env = new(vif);
        env.run();
    end
endmodule

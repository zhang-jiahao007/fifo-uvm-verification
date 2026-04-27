`include "uvm_macros.svh"
import uvm_pkg::*;

interface fifo_if;
    logic        clk;
    logic        rst_n;
    logic        wr_en;
    logic [7:0]  wr_data;
    logic        rd_en;
    logic [7:0]  rd_data;
    logic        full;
    logic        empty;
endinterface

// 1. Item
class fifo_seq_item extends uvm_sequence_item;
    `uvm_object_utils(fifo_seq_item)
    rand bit        wr_en;
    rand bit        rd_en;
    rand bit [7:0]  wr_data;
    bit [7:0]       rd_data;
    bit             full;
    bit             empty;

    constraint c_wr_rd{ !(wr_en && rd_en); }

    function new(string name = "fifo_seq_item");
        super.new(name);
    endfunction 
endclass 

// 2. Sequences
class fifo_base_seq extends uvm_sequence#(fifo_seq_item);
    `uvm_object_utils(fifo_base_seq)
    function new(string name = "fifo_base_seq"); 
        super.new(name); 
    endfunction
endclass

class fifo_write_full_seq extends fifo_base_seq;
    `uvm_object_utils(fifo_write_full_seq)
    function new(string name = "fifo_write_full_seq"); 
        super.new(name); 
    endfunction 
    virtual task body();
        fifo_seq_item req;
        repeat(16) begin
            req = fifo_seq_item::type_id::create("req");
            start_item(req);
            assert(req.randomize() with{wr_en == 1; rd_en == 0;});
            finish_item(req);
        end
    endtask
endclass

class fifo_read_empty_seq extends fifo_base_seq;
    `uvm_object_utils(fifo_read_empty_seq)
    function new(string name = "fifo_read_empty_seq"); 
        super.new(name); 
    endfunction 
    virtual task body();
        fifo_seq_item req;
        repeat(16) begin
            req = fifo_seq_item::type_id::create("req");
            start_item(req);
            assert(req.randomize() with{wr_en == 0; rd_en == 1;});
            finish_item(req);
        end
    endtask
endclass

// 3. Driver
class fifo_driver extends uvm_driver#(fifo_seq_item);
    `uvm_component_utils(fifo_driver)
    virtual fifo_if vif;
    function new(string name,uvm_component parent); 
        super.new(name,parent); 
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        uvm_config_db#(virtual fifo_if)::get(this,"","vif",vif);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            @(posedge vif.clk);
            vif.wr_en   <= req.wr_en;
            vif.rd_en   <= req.rd_en;
            vif.wr_data <= req.wr_data;
            seq_item_port.item_done();
        end
    endtask
endclass

// 4. Monitor
class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)
    virtual fifo_if vif;
    uvm_analysis_port#(fifo_seq_item) ap;
    function new(string name,uvm_component parent);
        super.new(name,parent);
        ap = new("ap",this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_db#(virtual fifo_if)::get(this,"","vif",vif);
    endfunction

    virtual task run_phase(uvm_phase phase);
        fifo_seq_item tr;
        forever begin
            @(posedge vif.clk);
            tr = fifo_seq_item::type_id::create("tr");
            tr.wr_en   = vif.wr_en;
            tr.rd_en   = vif.rd_en;
            tr.wr_data = vif.wr_data;
            tr.rd_data = vif.rd_data;
            tr.full    = vif.full;
            tr.empty   = vif.empty;
            ap.write(tr);
        end
    endtask
endclass

// 5. Agent
class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)
    fifo_driver                drv;
    fifo_monitor               mon;
    uvm_sequencer#(fifo_seq_item) seqr;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seqr = uvm_sequencer#(fifo_seq_item)::type_id::create("seqr",this);
        drv  = fifo_driver::type_id::create("drv",this);
        mon  = fifo_monitor::type_id::create("mon",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass

// 6. Scoreboard
class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)
    uvm_analysis_imp#(fifo_seq_item,fifo_scoreboard) imp;
    logic [7:0] ref_q[$];
    function new(string name, uvm_component parent);
        super.new(name,parent);
        imp = new("imp",this);
    endfunction

    virtual function void write(fifo_seq_item tr);
        if(tr.wr_en && !tr.full) ref_q.push_back(tr.wr_data);
        if(tr.rd_en && !tr.empty && ref_q.size()>0) begin
            logic [7:0] exp = ref_q.pop_front();
            if(exp !== tr.rd_data)
                `uvm_error("SCB","Data Mismatch");
        end
    endfunction
endclass

// 7. Coverage 【放在Env前面，解决未定义】
class fifo_coverage extends uvm_subscriber#(fifo_seq_item);
    `uvm_component_utils(fifo_coverage)
    fifo_seq_item tr;

    covergroup cg_fifo;
        coverpoint tr.wr_en;
        coverpoint tr.rd_en;
        coverpoint tr.full;
        coverpoint tr.empty;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name,parent);
        cg_fifo = new();
    endfunction

    virtual function void write(fifo_seq_item t);
        tr = t;
        cg_fifo.sample();
    endfunction
endclass

// 8. Env
class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)
    fifo_agent      agt;
    fifo_scoreboard scb;
    fifo_coverage   cov;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = fifo_agent::type_id::create("agt",this);
        scb = fifo_scoreboard::type_id::create("scb",this);
        cov = fifo_coverage::type_id::create("cov",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        agt.mon.ap.connect(scb.imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction
endclass

// 9. Test
class fifo_base_test extends uvm_test;
    `uvm_component_utils(fifo_base_test)
    fifo_env env;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env::type_id::create("env",this);
    endfunction
    virtual task run_phase(uvm_phase phase);
        fifo_write_full_seq  wseq;
        fifo_read_empty_seq  rseq;
        phase.raise_objection(this);
        wseq = fifo_write_full_seq::type_id::create("wseq");
        rseq = fifo_read_empty_seq::type_id::create("rseq");
        wseq.start(env.agt.seqr);
        #200;
        rseq.start(env.agt.seqr);
        #200;
        phase.drop_objection(this);
    endtask
endclass

// 10. Top TB
module tb_top;
    fifo_if vif();
    fifo u_dut(
        .clk(vif.clk), .rst_n(vif.rst_n),
        .wr_en(vif.wr_en), .wr_data(vif.wr_data),
        .rd_en(vif.rd_en), .rd_data(vif.rd_data),
        .full(vif.full), .empty(vif.empty)
    );

    initial begin
        vif.clk = 0;
        forever #10 vif.clk = ~vif.clk;
    end
    initial begin
        vif.rst_n = 0;
        #30;
        vif.rst_n = 1;
    end
    initial begin
        uvm_config_db#(virtual fifo_if)::set(null,"*","vif",vif);
      run_test("fifo_base_test");
    end
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0,tb_top);
    end
endmodule

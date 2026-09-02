package axi_apb_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum bit {AXI_READ, AXI_WRITE} axi_op_e;

  class axi_item extends uvm_sequence_item;
    rand axi_op_e op;
    rand bit [7:0] addr;
    rand bit [31:0] data;
    rand bit [3:0] strb;
    rand bit misaligned;
    rand int unsigned channel_delay;
    rand int unsigned backpressure;
    bit [31:0] read_data;
    bit [1:0] resp;

    constraint c_alignment {
      misaligned dist {1'b0 := 9, 1'b1 := 1};
      if (misaligned) addr[1:0] != 0; else addr[1:0] == 0;
    }
    constraint c_short_delays { channel_delay inside {[0:3]}; backpressure inside {[0:3]}; }
    constraint c_strb { if (op == AXI_WRITE) strb != 0; }
    `uvm_object_utils_begin(axi_item)
      `uvm_field_enum(axi_op_e, op, UVM_ALL_ON)
      `uvm_field_int(addr, UVM_HEX)
      `uvm_field_int(data, UVM_HEX)
      `uvm_field_int(strb, UVM_HEX)
      `uvm_field_int(misaligned, UVM_BIN)
      `uvm_field_int(channel_delay, UVM_DEC)
      `uvm_field_int(backpressure, UVM_DEC)
      `uvm_field_int(read_data, UVM_HEX)
      `uvm_field_int(resp, UVM_BIN)
    `uvm_object_utils_end
    function new(string name="axi_item"); super.new(name); endfunction
  endclass

  class axi_smoke_sequence extends uvm_sequence #(axi_item);
    `uvm_object_utils(axi_smoke_sequence)
    function new(string name="axi_smoke_sequence"); super.new(name); endfunction
    task body();
      req=axi_item::type_id::create("write_req"); start_item(req);
      req.op=AXI_WRITE; req.addr=8'h04; req.data=32'h1234_ABCD; req.strb=4'hf;
      req.channel_delay=0; req.backpressure=0; req.misaligned=0; finish_item(req);
      req=axi_item::type_id::create("read_req"); start_item(req);
      req.op=AXI_READ; req.addr=8'h04; req.data=0; req.strb=0;
      req.channel_delay=0; req.backpressure=0; req.misaligned=0; finish_item(req);
    endtask
  endclass

  class axi_error_sequence extends uvm_sequence #(axi_item);
    `uvm_object_utils(axi_error_sequence)
    function new(string name="axi_error_sequence"); super.new(name); endfunction
    task body();
      req=axi_item::type_id::create("misaligned_read"); start_item(req);
      req.op=AXI_READ; req.addr=8'h03; req.data=0; req.strb=0;
      req.channel_delay=0; req.backpressure=2; req.misaligned=1; finish_item(req);
    endtask
  endclass

  class axi_mixed_sequence extends uvm_sequence #(axi_item);
    rand int unsigned count = 50;
    `uvm_object_utils(axi_mixed_sequence)
    function new(string name="axi_mixed_sequence"); super.new(name); endfunction
    task body();
      repeat (count) begin
        req = axi_item::type_id::create("req");
        start_item(req);
        if (!req.randomize() with { addr inside {[8'h00:8'h7c]}; })
          `uvm_fatal("RAND", "axi_item randomization failed")
        finish_item(req);
      end
    endtask
  endclass

  class axi_sequencer extends uvm_sequencer #(axi_item);
    `uvm_component_utils(axi_sequencer)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
  endclass

  class axi_driver extends uvm_driver #(axi_item);
    `uvm_component_utils(axi_driver)
    virtual axi_lite_if vif;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual axi_lite_if)::get(this,"","axi_vif",vif))
        `uvm_fatal("NOVIF","axi_vif was not configured")
    endfunction
    task reset_outputs();
      vif.AWADDR<=0; vif.AWVALID<=0; vif.WDATA<=0; vif.WSTRB<=0; vif.WVALID<=0;
      vif.BREADY<=0; vif.ARADDR<=0; vif.ARVALID<=0; vif.RREADY<=0;
      wait(vif.ARESETn); @(posedge vif.ACLK);
    endtask
    task drive_write(axi_item tr);
      fork
        begin repeat(tr.channel_delay) @(posedge vif.ACLK); vif.AWADDR<=tr.addr; vif.AWVALID<=1;
              do @(posedge vif.ACLK); while(!vif.AWREADY); vif.AWVALID<=0; end
        begin vif.WDATA<=tr.data; vif.WSTRB<=tr.strb; vif.WVALID<=1;
              do @(posedge vif.ACLK); while(!vif.WREADY); vif.WVALID<=0; end
      join
      repeat(tr.backpressure) @(posedge vif.ACLK); vif.BREADY<=1;
      do @(posedge vif.ACLK); while(!vif.BVALID); tr.resp=vif.BRESP;
      vif.BREADY<=0;
    endtask
    task drive_read(axi_item tr);
      vif.ARADDR<=tr.addr; vif.ARVALID<=1;
      do @(posedge vif.ACLK); while(!vif.ARREADY); vif.ARVALID<=0;
      repeat(tr.backpressure) @(posedge vif.ACLK); vif.RREADY<=1;
      do @(posedge vif.ACLK); while(!vif.RVALID);
      tr.read_data=vif.RDATA; tr.resp=vif.RRESP; vif.RREADY<=0;
    endtask
    task run_phase(uvm_phase phase);
      reset_outputs();
      forever begin
        seq_item_port.get_next_item(req);
        if(req.op==AXI_WRITE) drive_write(req); else drive_read(req);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)
    virtual axi_lite_if vif;
    uvm_analysis_port #(axi_item) ap;
    bit [7:0] awaddr, araddr; bit [31:0] wdata; bit [3:0] wstrb;
    bit have_aw, have_w;
    function new(string name,uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction
    function void build_phase(uvm_phase phase);
      if(!uvm_config_db#(virtual axi_lite_if)::get(this,"","axi_vif",vif)) `uvm_fatal("NOVIF","axi_vif missing")
    endfunction
    task run_phase(uvm_phase phase);
      axi_item tr;
      forever begin
        @(posedge vif.ACLK); if(!vif.ARESETn) begin have_aw=0; have_w=0; continue; end
        if(vif.AWVALID&&vif.AWREADY) begin awaddr=vif.AWADDR; have_aw=1; end
        if(vif.WVALID&&vif.WREADY) begin wdata=vif.WDATA; wstrb=vif.WSTRB; have_w=1; end
        if(vif.ARVALID&&vif.ARREADY) araddr=vif.ARADDR;
        if(vif.BVALID&&vif.BREADY) begin
          tr=axi_item::type_id::create("observed_write"); tr.op=AXI_WRITE; tr.addr=awaddr;
          tr.data=wdata; tr.strb=wstrb; tr.resp=vif.BRESP; ap.write(tr); have_aw=0; have_w=0;
        end
        if(vif.RVALID&&vif.RREADY) begin
          tr=axi_item::type_id::create("observed_read"); tr.op=AXI_READ; tr.addr=araddr;
          tr.read_data=vif.RDATA; tr.resp=vif.RRESP; ap.write(tr);
        end
      end
    endtask
  endclass

  class apb_item extends uvm_sequence_item;
    bit [7:0] addr; bit write; bit [31:0] wdata, rdata; bit [3:0] strb; bit error;
    `uvm_object_utils_begin(apb_item)
      `uvm_field_int(addr,UVM_HEX) `uvm_field_int(write,UVM_BIN)
      `uvm_field_int(wdata,UVM_HEX) `uvm_field_int(rdata,UVM_HEX)
      `uvm_field_int(strb,UVM_HEX) `uvm_field_int(error,UVM_BIN)
    `uvm_object_utils_end
    function new(string name="apb_item"); super.new(name); endfunction
  endclass

  class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)
    virtual apb_if vif; uvm_analysis_port #(apb_item) ap;
    function new(string name,uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction
    function void build_phase(uvm_phase phase);
      if(!uvm_config_db#(virtual apb_if)::get(this,"","apb_vif",vif)) `uvm_fatal("NOVIF","apb_vif missing")
    endfunction
    task run_phase(uvm_phase phase); apb_item tr;
      forever begin @(posedge vif.PCLK);
        if(vif.PRESETn&&vif.PSEL&&vif.PENABLE&&vif.PREADY) begin
          tr=apb_item::type_id::create("apb_observed"); tr.addr=vif.PADDR; tr.write=vif.PWRITE;
          tr.wdata=vif.PWDATA; tr.rdata=vif.PRDATA; tr.strb=vif.PSTRB; tr.error=vif.PSLVERR; ap.write(tr);
        end
      end
    endtask
  endclass

  `uvm_analysis_imp_decl(_axi)
  `uvm_analysis_imp_decl(_apb)
  class bridge_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(bridge_scoreboard)
    uvm_analysis_imp_axi #(axi_item,bridge_scoreboard) axi_imp;
    uvm_analysis_imp_apb #(apb_item,bridge_scoreboard) apb_imp;
    axi_item expected_q[$]; bit [31:0] model_mem[bit[7:0]]; int checks,errors;
    function new(string name,uvm_component parent); super.new(name,parent); axi_imp=new("axi_imp",this); apb_imp=new("apb_imp",this); endfunction
    function void write_apb(apb_item t); axi_item exp=axi_item::type_id::create("expected");
      exp.op=t.write?AXI_WRITE:AXI_READ; exp.addr=t.addr; exp.resp=t.error?2'b10:2'b00;
      if(t.write&&!t.error) begin
        bit [31:0] old=model_mem.exists(t.addr)?model_mem[t.addr]:'0;
        for(int b=0;b<4;b++) if(t.strb[b]) old[8*b+:8]=t.wdata[8*b+:8]; model_mem[t.addr]=old;
      end else if(!t.write&&!t.error) exp.read_data=model_mem.exists(t.addr)?model_mem[t.addr]:'0;
      expected_q.push_back(exp);
    endfunction
    function void write_axi(axi_item got); axi_item exp; checks++;
      if(expected_q.size()==0) begin errors++; `uvm_error("SCB","AXI response without completed APB transfer") return; end
      exp=expected_q.pop_front();
      if(got.op!=exp.op || got.resp!=exp.resp || (got.op==AXI_READ&&got.resp==0&&got.read_data!=exp.read_data)) begin
        errors++; `uvm_error("SCB",$sformatf("Mismatch exp=%s got=%s",exp.sprint(),got.sprint()))
      end else `uvm_info("SCB",$sformatf("CHECK_PASS %0d",checks),UVM_MEDIUM)
    endfunction
    function void report_phase(uvm_phase phase);
      if(errors==0) `uvm_info("RESULT",$sformatf("AXI_APB_UVM_PASS checks=%0d errors=0",checks),UVM_NONE)
      else `uvm_error("RESULT",$sformatf("AXI_APB_UVM_FAIL checks=%0d errors=%0d",checks,errors))
    endfunction
  endclass

  class bridge_coverage extends uvm_subscriber #(axi_item);
    `uvm_component_utils(bridge_coverage)
    axi_op_e op; bit [1:0] resp; bit [7:0] addr;
    covergroup cg; option.per_instance=1;
      cp_op:coverpoint op; cp_resp:coverpoint resp { bins okay={0}; bins error={2}; }
      cp_region:coverpoint addr[7:5]; op_x_resp:cross cp_op,cp_resp;
    endgroup
    function new(string name,uvm_component parent); super.new(name,parent); cg=new; endfunction
    function void write(axi_item t); op=t.op; resp=t.resp; addr=t.addr; cg.sample(); endfunction
  endclass

  class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)
    axi_sequencer seqr; axi_driver drv; axi_monitor mon;
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase); seqr=axi_sequencer::type_id::create("seqr",this); drv=axi_driver::type_id::create("drv",this); mon=axi_monitor::type_id::create("mon",this); endfunction
    function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(seqr.seq_item_export); endfunction
  endclass

  class bridge_env extends uvm_env;
    `uvm_component_utils(bridge_env)
    axi_agent axi; apb_monitor apb; bridge_scoreboard scb; bridge_coverage cov;
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
      axi=axi_agent::type_id::create("axi",this); apb=apb_monitor::type_id::create("apb",this);
      scb=bridge_scoreboard::type_id::create("scb",this); cov=bridge_coverage::type_id::create("cov",this);
    endfunction
    function void connect_phase(uvm_phase phase);
      axi.mon.ap.connect(scb.axi_imp); axi.mon.ap.connect(cov.analysis_export); apb.ap.connect(scb.apb_imp);
    endfunction
  endclass

  class bridge_base_test extends uvm_test;
    `uvm_component_utils(bridge_base_test)
    bridge_env env;
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase); env=bridge_env::type_id::create("env",this); endfunction
    task run_phase(uvm_phase phase); axi_mixed_sequence seq=axi_mixed_sequence::type_id::create("seq");
      phase.raise_objection(this); wait(env.axi.drv.vif.ARESETn); seq.start(env.axi.seqr); #100ns; phase.drop_objection(this);
    endtask
  endclass

  class bridge_smoke_test extends bridge_base_test;
    `uvm_component_utils(bridge_smoke_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase); axi_smoke_sequence seq=axi_smoke_sequence::type_id::create("seq");
      phase.raise_objection(this); wait(env.axi.drv.vif.ARESETn); seq.start(env.axi.seqr); #100ns; phase.drop_objection(this);
    endtask
  endclass

  class bridge_error_test extends bridge_base_test;
    `uvm_component_utils(bridge_error_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase); axi_error_sequence seq=axi_error_sequence::type_id::create("seq");
      phase.raise_objection(this); wait(env.axi.drv.vif.ARESETn); seq.start(env.axi.seqr); #100ns; phase.drop_objection(this);
    endtask
  endclass
endpackage

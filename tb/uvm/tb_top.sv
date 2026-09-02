`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  import axi_apb_uvm_pkg::*;
  localparam int AW=8,DW=32;
`ifdef INJECT_ADDR_BUG
  localparam bit ADDR_BUG=1'b1;
`else
  localparam bit ADDR_BUG=1'b0;
`endif
`ifdef INJECT_RESP_BUG
  localparam bit RESP_BUG=1'b1;
`else
  localparam bit RESP_BUG=1'b0;
`endif
  logic clk=0; always #5 clk=~clk;
  axi_lite_if #(AW,DW) axi(clk); apb_if #(AW,DW) apb(clk);

  axi4lite_to_apb_bridge #(.ADDR_WIDTH(AW),.DATA_WIDTH(DW),
    .INJECT_ADDR_BUG(ADDR_BUG),.INJECT_RESP_BUG(RESP_BUG)) dut (
    .aclk(clk),.aresetn(axi.ARESETn),
    .s_axi_awaddr(axi.AWADDR),.s_axi_awvalid(axi.AWVALID),.s_axi_awready(axi.AWREADY),
    .s_axi_wdata(axi.WDATA),.s_axi_wstrb(axi.WSTRB),.s_axi_wvalid(axi.WVALID),.s_axi_wready(axi.WREADY),
    .s_axi_bresp(axi.BRESP),.s_axi_bvalid(axi.BVALID),.s_axi_bready(axi.BREADY),
    .s_axi_araddr(axi.ARADDR),.s_axi_arvalid(axi.ARVALID),.s_axi_arready(axi.ARREADY),
    .s_axi_rdata(axi.RDATA),.s_axi_rresp(axi.RRESP),.s_axi_rvalid(axi.RVALID),.s_axi_rready(axi.RREADY),
    .paddr(apb.PADDR),.psel(apb.PSEL),.penable(apb.PENABLE),.pwrite(apb.PWRITE),
    .pwdata(apb.PWDATA),.pstrb(apb.PSTRB),.prdata(apb.PRDATA),.pready(apb.PREADY),.pslverr(apb.PSLVERR));
  apb_memory_slave #(.ADDR_WIDTH(AW),.DATA_WIDTH(DW)) mem (
    .pclk(clk),.presetn(apb.PRESETn),.paddr(apb.PADDR),.psel(apb.PSEL),.penable(apb.PENABLE),
    .pwrite(apb.PWRITE),.pwdata(apb.PWDATA),.pstrb(apb.PSTRB),.prdata(apb.PRDATA),.pready(apb.PREADY),.pslverr(apb.PSLVERR));
  axi_apb_assertions #(.ADDR_WIDTH(AW),.DATA_WIDTH(DW)) sva (
    .aclk(clk),.aresetn(axi.ARESETn),.paddr(apb.PADDR),.psel(apb.PSEL),.penable(apb.PENABLE),
    .pwrite(apb.PWRITE),.pready(apb.PREADY),.pwdata(apb.PWDATA),.pstrb(apb.PSTRB),
    .s_axi_bvalid(axi.BVALID),.s_axi_bready(axi.BREADY),.s_axi_bresp(axi.BRESP),
    .s_axi_rvalid(axi.RVALID),.s_axi_rready(axi.RREADY),.s_axi_rdata(axi.RDATA),.s_axi_rresp(axi.RRESP));

  assign apb.PRESETn=axi.ARESETn;
  initial begin axi.ARESETn=0; repeat(5) @(posedge clk); axi.ARESETn=1; end
  initial begin
`ifdef FSDB
    $fsdbDumpfile("proof/axi_apb_wave.fsdb");
    $fsdbDumpvars(0,tb_top,"+all");
`else
    $dumpfile("proof/axi_apb_wave.vcd");
    $dumpvars(0,tb_top);
`endif
  end
  initial begin
    uvm_config_db#(virtual axi_lite_if)::set(null,"uvm_test_top.env.axi.*","axi_vif",axi);
    uvm_config_db#(virtual apb_if)::set(null,"uvm_test_top.env.apb","apb_vif",apb);
    run_test("bridge_base_test");
  end
endmodule

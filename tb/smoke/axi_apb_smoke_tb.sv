`timescale 1ns/1ps

module axi_apb_smoke_tb;
  localparam int AW=8, DW=32;
  logic aclk=0, aresetn=0;
  always #5 aclk = ~aclk;

  logic [AW-1:0] awaddr, araddr, paddr;
  logic awvalid, awready, wvalid, wready, bvalid, bready;
  logic [DW-1:0] wdata, rdata, pwdata, prdata;
  logic [DW/8-1:0] wstrb, pstrb;
  logic [1:0] bresp, rresp;
  logic arvalid, arready, rvalid, rready;
  logic psel, penable, pwrite, pready, pslverr;
  int checks=0, errors=0;

  axi4lite_to_apb_bridge #(.ADDR_WIDTH(AW),.DATA_WIDTH(DW)) dut (
    .aclk, .aresetn,
    .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
    .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
    .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
    .s_axi_araddr(araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
    .s_axi_rdata(rdata), .s_axi_rresp(rresp), .s_axi_rvalid(rvalid), .s_axi_rready(rready),
    .paddr, .psel, .penable, .pwrite, .pwdata, .pstrb, .prdata, .pready, .pslverr
  );
  apb_memory_slave #(.ADDR_WIDTH(AW),.DATA_WIDTH(DW)) mem ( .pclk(aclk), .presetn(aresetn), .* );
  axi_apb_assertions #(.ADDR_WIDTH(AW),.DATA_WIDTH(DW)) sva (
    .aclk, .aresetn, .paddr, .psel, .penable, .pwrite, .pready, .pwdata, .pstrb,
    .s_axi_bvalid(bvalid), .s_axi_bready(bready), .s_axi_bresp(bresp),
    .s_axi_rvalid(rvalid), .s_axi_rready(rready), .s_axi_rdata(rdata), .s_axi_rresp(rresp)
  );

  task automatic axi_write(input logic [AW-1:0] addr, input logic [DW-1:0] data,
                           input logic [1:0] exp_resp=2'b00);
    awaddr=addr; awvalid=1; wdata=data; wstrb='1; wvalid=1; bready=1;
    do @(posedge aclk); while (!(awready && wready));
    awvalid=0; wvalid=0;
    do @(posedge aclk); while (!bvalid);
    checks++;
    if (bresp !== exp_resp) begin errors++; $error("WRITE resp addr=%h exp=%b got=%b",addr,exp_resp,bresp); end
    @(posedge aclk); bready=0;
  endtask

  task automatic axi_read(input logic [AW-1:0] addr, input logic [DW-1:0] exp_data,
                          input logic [1:0] exp_resp=2'b00);
    araddr=addr; arvalid=1; rready=1;
    do @(posedge aclk); while (!arready);
    arvalid=0;
    do @(posedge aclk); while (!rvalid);
    checks++;
    if (rresp !== exp_resp) begin errors++; $error("READ resp addr=%h exp=%b got=%b",addr,exp_resp,rresp); end
    if (exp_resp==2'b00 && rdata !== exp_data) begin errors++; $error("READ data addr=%h exp=%h got=%h",addr,exp_data,rdata); end
    @(posedge aclk); rready=0;
  endtask

  initial begin
    awaddr='0; awvalid=0; wdata='0; wstrb='0; wvalid=0; bready=0;
    araddr='0; arvalid=0; rready=0;
    $dumpfile("proof/axi_apb_wave.vcd");
    $dumpvars(0, axi_apb_smoke_tb);
    repeat(4) @(posedge aclk); aresetn=1;
    axi_write(8'h04,32'h1234_ABCD);
    axi_read (8'h04,32'h1234_ABCD);
    axi_write(8'h10,32'hCAFE_BABE);
    axi_read (8'h10,32'hCAFE_BABE);
    axi_read (8'h03,32'h0,2'b10);
    repeat(3) @(posedge aclk);
    if (errors==0) $display("AXI_APB_TEST_PASS checks=%0d errors=%0d",checks,errors);
    else           $display("AXI_APB_TEST_FAIL checks=%0d errors=%0d",checks,errors);
    $finish;
  end
endmodule

interface axi_lite_if #(parameter int AW=8, DW=32) (input logic ACLK);
  logic ARESETn;
  logic [AW-1:0] AWADDR; logic AWVALID, AWREADY;
  logic [DW-1:0] WDATA; logic [DW/8-1:0] WSTRB; logic WVALID, WREADY;
  logic [1:0] BRESP; logic BVALID, BREADY;
  logic [AW-1:0] ARADDR; logic ARVALID, ARREADY;
  logic [DW-1:0] RDATA; logic [1:0] RRESP; logic RVALID, RREADY;
endinterface

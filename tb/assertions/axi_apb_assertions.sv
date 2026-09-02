module axi_apb_assertions #(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 32
) (
  input logic aclk, aresetn,
  input logic [ADDR_WIDTH-1:0] paddr,
  input logic psel, penable, pwrite, pready,
  input logic [DATA_WIDTH-1:0] pwdata,
  input logic [DATA_WIDTH/8-1:0] pstrb,
  input logic s_axi_bvalid, s_axi_bready,
  input logic [1:0] s_axi_bresp,
  input logic s_axi_rvalid, s_axi_rready,
  input logic [DATA_WIDTH-1:0] s_axi_rdata,
  input logic [1:0] s_axi_rresp
);
  default clocking cb @(posedge aclk); endclocking
  default disable iff (!aresetn);

  apb_enable_requires_select:
    assert property (penable |-> psel)
      else $error("APB protocol: PENABLE without PSEL");

  apb_setup_before_access:
    assert property ($rose(penable) |-> $past(psel && !penable))
      else $error("APB protocol: access phase missing setup phase");

  apb_control_stable_during_wait:
    assert property (psel && penable && !pready |=>
                     $stable({paddr,pwrite,pwdata,pstrb}))
      else $error("APB protocol: control changed during wait state");

  axi_b_stable_under_backpressure:
    assert property (s_axi_bvalid && !s_axi_bready |=>
                     s_axi_bvalid && $stable(s_axi_bresp))
      else $error("AXI protocol: B channel changed under backpressure");

  axi_r_stable_under_backpressure:
    assert property (s_axi_rvalid && !s_axi_rready |=>
                     s_axi_rvalid && $stable({s_axi_rdata,s_axi_rresp}))
      else $error("AXI protocol: R channel changed under backpressure");

  cover property (psel && penable && !pready ##1 psel && penable && pready);
  cover property (s_axi_bvalid && s_axi_bready && s_axi_bresp == 2'b00);
  cover property (s_axi_rvalid && s_axi_rready && s_axi_rresp == 2'b10);
endmodule

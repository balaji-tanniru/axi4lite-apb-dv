`timescale 1ns/1ps

module axi4lite_to_apb_bridge #(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 32,
  parameter bit INJECT_ADDR_BUG = 1'b0,
  parameter bit INJECT_RESP_BUG = 1'b0
) (
  input  logic                  aclk,
  input  logic                  aresetn,

  input  logic [ADDR_WIDTH-1:0] s_axi_awaddr,
  input  logic                  s_axi_awvalid,
  output logic                  s_axi_awready,
  input  logic [DATA_WIDTH-1:0] s_axi_wdata,
  input  logic [DATA_WIDTH/8-1:0] s_axi_wstrb,
  input  logic                  s_axi_wvalid,
  output logic                  s_axi_wready,
  output logic [1:0]            s_axi_bresp,
  output logic                  s_axi_bvalid,
  input  logic                  s_axi_bready,

  input  logic [ADDR_WIDTH-1:0] s_axi_araddr,
  input  logic                  s_axi_arvalid,
  output logic                  s_axi_arready,
  output logic [DATA_WIDTH-1:0] s_axi_rdata,
  output logic [1:0]            s_axi_rresp,
  output logic                  s_axi_rvalid,
  input  logic                  s_axi_rready,

  output logic [ADDR_WIDTH-1:0] paddr,
  output logic                  psel,
  output logic                  penable,
  output logic                  pwrite,
  output logic [DATA_WIDTH-1:0] pwdata,
  output logic [DATA_WIDTH/8-1:0] pstrb,
  input  logic [DATA_WIDTH-1:0] prdata,
  input  logic                  pready,
  input  logic                  pslverr
);

  typedef enum logic [2:0] {
    IDLE, APB_SETUP, APB_ACCESS, WRITE_RESP, READ_RESP
  } state_t;

  state_t state;
  logic aw_hold, w_hold;
  logic [ADDR_WIDTH-1:0] awaddr_hold;
  logic [DATA_WIDTH-1:0] wdata_hold;
  logic [DATA_WIDTH/8-1:0] wstrb_hold;

  wire aw_fire = s_axi_awvalid && s_axi_awready;
  wire w_fire  = s_axi_wvalid  && s_axi_wready;
  wire ar_fire = s_axi_arvalid && s_axi_arready;
  wire write_complete = (aw_hold || aw_fire) && (w_hold || w_fire);

  always_comb begin
    s_axi_awready = (state == IDLE) && !aw_hold;
    s_axi_wready  = (state == IDLE) && !w_hold;
    s_axi_arready = (state == IDLE) && !aw_hold && !w_hold &&
                    !s_axi_awvalid && !s_axi_wvalid;
    psel          = (state == APB_SETUP) || (state == APB_ACCESS);
    penable       = (state == APB_ACCESS);
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state         <= IDLE;
      aw_hold       <= 1'b0;
      w_hold        <= 1'b0;
      awaddr_hold   <= '0;
      wdata_hold    <= '0;
      wstrb_hold    <= '0;
      paddr         <= '0;
      pwrite        <= 1'b0;
      pwdata        <= '0;
      pstrb         <= '0;
      s_axi_bresp   <= 2'b00;
      s_axi_bvalid  <= 1'b0;
      s_axi_rdata   <= '0;
      s_axi_rresp   <= 2'b00;
      s_axi_rvalid  <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (aw_fire) begin
            awaddr_hold <= s_axi_awaddr;
            aw_hold     <= 1'b1;
          end
          if (w_fire) begin
            wdata_hold <= s_axi_wdata;
            wstrb_hold <= s_axi_wstrb;
            w_hold     <= 1'b1;
          end

          if (write_complete) begin
            paddr   <= aw_fire ? s_axi_awaddr : awaddr_hold;
            pwdata  <= w_fire  ? s_axi_wdata : wdata_hold;
            pstrb   <= w_fire  ? s_axi_wstrb : wstrb_hold;
            pwrite  <= 1'b1;
            aw_hold <= 1'b0;
            w_hold  <= 1'b0;
            state   <= APB_SETUP;
          end else if (ar_fire) begin
            paddr  <= INJECT_ADDR_BUG ? s_axi_araddr + ADDR_WIDTH'(4) : s_axi_araddr;
            pwrite <= 1'b0;
            pwdata <= '0;
            pstrb  <= '0;
            state  <= APB_SETUP;
          end
        end

        APB_SETUP: state <= APB_ACCESS;

        APB_ACCESS: begin
          if (pready) begin
            if (pwrite) begin
              s_axi_bresp  <= (pslverr && !INJECT_RESP_BUG) ? 2'b10 : 2'b00;
              s_axi_bvalid <= 1'b1;
              state        <= WRITE_RESP;
            end else begin
              s_axi_rdata  <= prdata;
              s_axi_rresp  <= (pslverr && !INJECT_RESP_BUG) ? 2'b10 : 2'b00;
              s_axi_rvalid <= 1'b1;
              state        <= READ_RESP;
            end
          end
        end

        WRITE_RESP: begin
          if (s_axi_bvalid && s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            state        <= IDLE;
          end
        end

        READ_RESP: begin
          if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
            state        <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule

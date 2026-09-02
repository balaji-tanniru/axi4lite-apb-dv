`timescale 1ns/1ps

module apb_memory_slave #(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 32
) (
  input  logic                  pclk,
  input  logic                  presetn,
  input  logic [ADDR_WIDTH-1:0] paddr,
  input  logic                  psel,
  input  logic                  penable,
  input  logic                  pwrite,
  input  logic [DATA_WIDTH-1:0] pwdata,
  input  logic [DATA_WIDTH/8-1:0] pstrb,
  output logic [DATA_WIDTH-1:0] prdata,
  output logic                  pready,
  output logic                  pslverr
);
  localparam int WORDS = 64;
  logic [DATA_WIDTH-1:0] mem [0:WORDS-1];
  logic wait_seen;
  integer i;

  always_comb begin
    prdata  = mem[paddr[ADDR_WIDTH-1:2]];
    pslverr = psel && penable && (paddr[1:0] != 2'b00);
    pready  = psel && penable && wait_seen;
  end

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      wait_seen <= 1'b0;
      for (i = 0; i < WORDS; i++) mem[i] <= '0;
    end else begin
      if (psel && penable && !wait_seen)
        wait_seen <= 1'b1;
      else if (psel && penable && pready) begin
        wait_seen <= 1'b0;
        if (pwrite && !pslverr) begin
          for (int b = 0; b < DATA_WIDTH/8; b++)
            if (pstrb[b]) mem[paddr[ADDR_WIDTH-1:2]][8*b +: 8] <= pwdata[8*b +: 8];
        end
      end else if (!psel)
        wait_seen <= 1'b0;
    end
  end
endmodule

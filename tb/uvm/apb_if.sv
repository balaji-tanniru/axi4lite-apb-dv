interface apb_if #(parameter int AW=8, DW=32) (input logic PCLK);
  logic PRESETn;
  logic [AW-1:0] PADDR;
  logic PSEL, PENABLE, PWRITE;
  logic [DW-1:0] PWDATA, PRDATA;
  logic [DW/8-1:0] PSTRB;
  logic PREADY, PSLVERR;
endinterface

`ifndef QSTREAM_PKG_SV
`define QSTREAM_PKG_SV

package qstream_pkg;

  localparam int AXI_ADDR_W      = 32;
  localparam int DESC_DEPTH       = 16;
  localparam int NUM_BANKS        = 4;
  localparam int BANK_SIZE_BYTES  = 8192;
  localparam int DESC_TOTAL_W     = AXI_ADDR_W + 64;

  localparam logic [15:0] STAT_OK            = 16'h0000;
  localparam logic [15:0] ERR_DESC_MALFORMED = 16'hC002;

  typedef struct packed {
    logic [17:0]          rsvd;
    logic [7:0]           nxt_idx;
    logic                 chain_en;
    logic [1:0]           perm;
    logic [13:0]          len;
    logic [13:0]          pad_off;
    logic [AXI_ADDR_W-1:0] sys_addr;
    logic                 dir;
    logic [4:0]           ctx_id;
    logic                 valid;
  } desc_entry_t;

  typedef enum logic [1:0] {
    IDLE      = 2'd0,
    CHECK_CFG = 2'd1,
    RUN_XFER  = 2'd2
  } dma_st_e;

endpackage : qstream_pkg

`endif

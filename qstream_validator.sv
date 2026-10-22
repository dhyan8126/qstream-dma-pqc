`timescale 1ns/1ps

module qstream_validator 
  import qstream_pkg::*;
(
  input  desc_entry_t cfg,
  output logic        cfg_ok,
  output logic [15:0] err_stat
);

  logic [14:0] end_addr;
  logic        len_zero;
  logic        overflow;
  logic        bad_perm;
  logic        bad_chain;
  logic        rsvd_set;

  always_comb begin
    end_addr  = {1'b0, cfg.pad_off} + {1'b0, cfg.len};
    len_zero  = (cfg.len == '0);
    overflow  = (end_addr > BANK_SIZE_BYTES);
    rsvd_set  = |cfg.rsvd;
    bad_chain = cfg.chain_en && (cfg.nxt_idx >= DESC_DEPTH);

    bad_perm  = (cfg.dir == 1'b0) ? (cfg.perm != 2'b10) : (cfg.perm != 2'b01);

    if (len_zero || overflow || rsvd_set || bad_perm || bad_chain) begin
      cfg_ok   = 1'b0;
      err_stat = ERR_DESC_MALFORMED;
    end else begin
      cfg_ok   = 1'b1;
      err_stat = STAT_OK;
    end
  end

endmodule

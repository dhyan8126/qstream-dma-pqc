`timescale 1ns/1ps

module qstream_desc_table 
  import qstream_pkg::*;
(
  input  logic        clk,
  input  logic        rst_n,

  input  logic        clr_all,

  input  logic        wr_en,
  input  logic [3:0]  wr_slot,
  input  desc_entry_t wr_entry,

  input  logic [3:0]  rd_slot,
  output desc_entry_t rd_entry,

  input  logic        retire_pulse,
  input  logic [3:0]  retire_slot
);

  desc_entry_t ram [0:DESC_DEPTH-1];
  integer idx;

  assign rd_entry = ram[rd_slot];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (idx = 0; idx < DESC_DEPTH; idx = idx + 1)
        ram[idx] <= '0;
    end else if (clr_all) begin
      for (idx = 0; idx < DESC_DEPTH; idx = idx + 1)
        ram[idx] <= '0;
    end else begin
      if (wr_en)
        ram[wr_slot] <= wr_entry;

      if (retire_pulse)
        ram[retire_slot].valid <= 1'b0;
    end
  end

endmodule

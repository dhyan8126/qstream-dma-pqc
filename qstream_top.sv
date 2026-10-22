`timescale 1ns/1ps

module qstream_top 
  import qstream_pkg::*;
(
  input  logic                  clk,
  input  logic                  rst_n,

  input  logic [7:0]            ptr_in,
  input  logic                  start_pulse,
  input  logic                  abort_req,
  input  logic                  zeroize_cmd,
  output logic                  done_irq,
  output logic [1:0]            ecc_stat,
  output logic [15:0]           fault_code,

  input  logic                  reg_wr,
  input  logic [3:0]            reg_addr,
  input  desc_entry_t           reg_wdata,

  output logic                  active_flag,
  output logic [AXI_ADDR_W-1:0] m_axi_addr,
  output logic                  m_axi_ren,
  output logic                  m_axi_wen,
  input  logic                  m_axi_ack,

  output logic [13:0]           pad_addr_out,
  output logic                  pad_wr_out,
  output logic                  pad_cs_out
);

  dma_st_e     c_state, n_state;
  logic [3:0]  act_idx;
  desc_entry_t curr_desc;
  logic        check_passed;
  logic [15:0] check_code;

  logic        retire_trig;
  logic [3:0]  retire_idx;
  logic [13:0] byte_cnt;

  assign ecc_stat = 2'b00;

  qstream_desc_table u_ram (
    .clk          (clk),
    .rst_n        (rst_n),
    .clr_all      (zeroize_cmd),
    .wr_en        (reg_wr),
    .wr_slot      (reg_addr),
    .wr_entry     (reg_wdata),
    .rd_slot      (act_idx),
    .rd_entry     (curr_desc),
    .retire_pulse (retire_trig),
    .retire_slot  (retire_idx)
  );

  qstream_validator u_chk (
    .cfg      (curr_desc),
    .cfg_ok   (check_passed),
    .err_stat (check_code)
  );

  always_comb begin
    n_state      = c_state;
    retire_trig  = 1'b0;
    retire_idx   = act_idx;
    done_irq     = 1'b0;
    fault_code   = STAT_OK;
    active_flag  = 1'b0;

    m_axi_ren    = 1'b0;
    m_axi_wen    = 1'b0;
    m_axi_addr   = curr_desc.sys_addr + byte_cnt;
    pad_addr_out = curr_desc.pad_off + byte_cnt;
    pad_cs_out   = 1'b0;
    pad_wr_out   = 1'b0;

    case (c_state)
      IDLE: begin
        if (start_pulse && (ptr_in < DESC_DEPTH))
          n_state = CHECK_CFG;
      end

      CHECK_CFG: begin
        if (!curr_desc.valid) begin
          n_state = IDLE;
        end else if (check_passed) begin
          n_state = RUN_XFER;
        end else begin
          retire_trig = 1'b1;
          fault_code  = check_code;
          done_irq    = 1'b1;
          n_state     = IDLE;
        end
      end

      RUN_XFER: begin
        active_flag = 1'b1;
        pad_cs_out  = 1'b1;

        if (!curr_desc.dir) begin
          m_axi_ren  = 1'b1;
          pad_wr_out = 1'b1;
        end else begin
          m_axi_wen  = 1'b1;
          pad_wr_out = 1'b0;
        end

        if (abort_req) begin
          retire_trig = 1'b1;
          n_state     = IDLE;
        end else if (m_axi_ack || (byte_cnt >= curr_desc.len)) begin
          retire_trig = 1'b1;
          done_irq    = 1'b1;

          if (curr_desc.chain_en && (curr_desc.nxt_idx < DESC_DEPTH))
            n_state = CHECK_CFG;
          else
            n_state = IDLE;
        end
      end

      default: n_state = IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      c_state  <= IDLE;
      act_idx  <= 4'd0;
      byte_cnt <= 14'd0;
    end else if (zeroize_cmd) begin
      c_state  <= IDLE;
      act_idx  <= 4'd0;
      byte_cnt <= 14'd0;
    end else begin
      c_state <= n_state;

      if (c_state == IDLE && start_pulse) begin
        act_idx  <= ptr_in[3:0];
        byte_cnt <= 14'd0;
      end else if (c_state == RUN_XFER) begin
        if (byte_cnt < curr_desc.len) begin
          byte_cnt <= byte_cnt + 1'b1;
        end else if (curr_desc.chain_en && (curr_desc.nxt_idx < DESC_DEPTH)) begin
          act_idx  <= curr_desc.nxt_idx[3:0];
          byte_cnt <= 14'd0;
        end
      end
    end
  end

endmodule

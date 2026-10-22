`timescale 1ns/1ps

module tb_qstream_dma;
  import qstream_pkg::*;

  logic            clk;
  logic            rst_n;
  logic [7:0]      ptr_in;
  logic            start_pulse;
  logic            abort_req;
  logic            zeroize_cmd;
  logic            done_irq;
  logic [1:0]      ecc_stat;
  logic [15:0]     fault_code;
  logic            reg_wr;
  logic [3:0]      reg_addr;
  desc_entry_t     reg_wdata;
  logic            active_flag;
  logic [31:0]     m_axi_addr;
  logic            m_axi_ren;
  logic            m_axi_wen;
  logic            m_axi_ack;
  logic [13:0]     pad_addr_out;
  logic            pad_wr_out;
  logic            pad_cs_out;

  qstream_top dut (.*);

  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  task static send_desc(
    input [3:0]  slot,
    input [4:0]  ctx,
    input        direction,
    input [31:0] addr,
    input [13:0] offset,
    input [13:0] bytes,
    input [1:0]  permission
  );
    @(negedge clk);
    reg_addr             = slot;
    reg_wdata            = '0;
    reg_wdata.valid      = 1'b1;
    reg_wdata.ctx_id     = ctx;
    reg_wdata.dir        = direction;
    reg_wdata.sys_addr   = addr;
    reg_wdata.pad_off    = offset;
    reg_wdata.len        = bytes;
    reg_wdata.perm       = permission;
    reg_wr               = 1'b1;
    @(negedge clk);
    reg_wr               = 1'b0;
  endtask

  initial begin
    rst_n       = 0;
    ptr_in      = '0;
    start_pulse = 0;
    abort_req   = 0;
    zeroize_cmd = 0;
    reg_wr      = 0;
    reg_addr    = '0;
    reg_wdata   = '0;
    m_axi_ack   = 0;

    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    send_desc(4'd0, 5'd1, 1'b0, 32'h8000_0000, 14'd0, 14'd64, 2'b10);

    @(negedge clk);
    ptr_in      = 8'd0;
    start_pulse = 1'b1;
    @(negedge clk);
    start_pulse = 1'b0;

    wait(active_flag);
    repeat (5) @(posedge clk);
    @(negedge clk);
    m_axi_ack = 1'b1;
    @(negedge clk);
    m_axi_ack = 1'b0;
    wait(done_irq);

    repeat (5) @(posedge clk);

    send_desc(4'd1, 5'd2, 1'b0, 32'h8000_1000, 14'd0, 14'd32, 2'b01);

    @(negedge clk);
    ptr_in      = 8'd1;
    start_pulse = 1'b1;
    @(negedge clk);
    start_pulse = 1'b0;

    wait(done_irq);
    repeat (10) @(posedge clk);

    $finish;
  end

endmodule

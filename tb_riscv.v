`timescale 1ns/1ps

module tb_riscv;

  // ===== Clock & Reset =====
  reg clk;
  initial clk = 1'b0;
  always #5 clk = ~clk;   // 100 MHz

  reg rst_n;
  initial begin
    rst_n = 1'b0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
  end

  // ===== DUT =====
  riscv_pipeline_5stages dut (
    .clk   (clk),
    .rst_n (rst_n)
  );

  // ===== Cycle counter =====
  integer cycle;
  initial cycle = 0;
  always @(posedge clk) if (rst_n) cycle <= cycle + 1;

  // ===== Lấy tín hiệu hữu ích =====
  // Nếu khác tên instance, sửa lại 2 đường dẫn dưới cho khớp với code của bạn:
  wire        RegWriteW = dut.u_pipeline_5stages_core.u_datapath.RegWriteW;
  wire [4:0]  rdW       = dut.u_pipeline_5stages_core.u_datapath.rdW;
  wire [31:0] ResultW   = dut.u_pipeline_5stages_core.u_datapath.ResultW;
  wire [31:0] PCPlus4W  = dut.u_pipeline_5stages_core.u_datapath.PCPlus4W;
  wire [31:0] PCW       = PCPlus4W - 32'd4;

  // DMEM bus ở top
  wire        dmem_WE   = dut.dmem_WE;
  wire [31:0] dmem_Addr = dut.dmem_Addr; // nếu top của bạn vẫn dùng dmem_A thì đổi lại tên này
  wire [3:0]  dmem_BE   = dut.dmem_BE;
  wire [31:0] dmem_WD   = dut.dmem_WD;

  // Tham số DMEM theo top
  localparam [31:0] DMEM_BASE = 32'h0000_1000;
  wire [31:0] dmem_word_idx = (dmem_Addr - DMEM_BASE) >> 2;

  // ===== Plusargs: điều kiện PASS linh hoạt =====
  integer     PASS_RD;
  reg [31:0]  PASS_VAL;
  reg         USE_PASS_RD;
  reg         HAS_PASS_VAL;

  reg [31:0]  PASS_ADDR, PASS_DATA;
  reg         USE_PASS_STORE, HAS_PASS_DATA;

  integer     MAX_CYCLES;
  integer     tmp; // biến tạm cho $value$plusargs

  initial begin
    // Mặc định
    USE_PASS_RD     = 1'b0;
    HAS_PASS_VAL    = 1'b0;
    USE_PASS_STORE  = 1'b0;
    HAS_PASS_DATA   = 1'b0;
    MAX_CYCLES      = 2000;

    if ($value$plusargs("PASS_RD=%d", PASS_RD)) begin
      USE_PASS_RD = 1'b1;
      if ($value$plusargs("PASS_VAL=%h", PASS_VAL)) HAS_PASS_VAL = 1'b1;
    end

    if ($value$plusargs("PASS_ADDR=%h", PASS_ADDR)) begin
      USE_PASS_STORE = 1'b1;
      if ($value$plusargs("PASS_DATA=%h", PASS_DATA)) HAS_PASS_DATA = 1'b1;
    end

    if ($value$plusargs("MAX_CYCLES=%d", tmp)) MAX_CYCLES = tmp;
  end

  // ===== Dump waveform (Icarus/GTKWave). ModelSim thì add wave thủ công =====
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_riscv);
  end

  // ===== Log WB & Store =====
  always @(negedge clk) if (rst_n) begin
    if (RegWriteW)
      $display("[C%0d] WB: x%0d <= 0x%08x @PC=0x%08x.",
               cycle, rdW, ResultW, PCW);

    if (dmem_WE)
      $display("[C%0d] MEM WRITE: A=0x%08x (idx=%0d)  BE=%b  WD=0x%08x.",
               cycle, dmem_Addr, dmem_word_idx, dmem_BE, dmem_WD);
  end

  // ===== Điều kiện PASS =====
  always @(negedge clk) if (rst_n) begin
    if (USE_PASS_RD && RegWriteW && (rdW == PASS_RD) &&
        ((~HAS_PASS_VAL) || (ResultW == PASS_VAL))) begin
      $display("[PASS] WB: rd=%0d, value=0x%08x, PC=0x%08x.", rdW, ResultW, PCW);
      $finish;
    end
    if (USE_PASS_STORE && dmem_WE && (dmem_Addr == PASS_ADDR) &&
        ((~HAS_PASS_DATA) || (dmem_WD == PASS_DATA))) begin
      $display("[PASS] STORE: A=0x%08x, WD=0x%08x (idx=%0d).",
               dmem_Addr, dmem_WD, dmem_word_idx);
      $finish;
    end
  end

  // ===== Timeout =====
  initial begin
    forever begin
      @(posedge clk);
      if (rst_n && cycle >= MAX_CYCLES) begin
        $display("[TIMEOUT] Het %0d chu ky.", MAX_CYCLES);
        $finish;
      end
    end
  end

endmodule

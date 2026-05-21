
//   IMEM_DEPTH/DMEM_DEPTH: số word 32-bit
//   IMEM_BASE/DMEM_BASE  : base address mapping (byte address)
//   IMEM_HEX             : file .hex để nạp chương trình cho IMEM 
module riscv_pipeline_5stages #(
    parameter integer IMEM_DEPTH = 256,
    parameter integer DMEM_DEPTH = 256,
    parameter [31:0]  IMEM_BASE  = 32'h0000_0000,
    parameter [31:0]  DMEM_BASE  = 32'h0000_1000,
    parameter         IMEM_HEX   = "memfile.hex"           
) (
    input  wire clk,
    input  wire rst_n
);
   
    // Bus IMEM (core <-> imem)
    wire [31:0] imem_Addr;
    wire [31:0] imem_ins;
    wire        imem_read;   
    wire        imem_ready;  // imem luôn 1'b1 (always-ready)

  
    // Bus DMEM (core <-> dmem)
  
    wire [31:0] dmem_Addr;
    wire [31:0] dmem_WD;
    wire  [3:0] dmem_BE;
    wire        dmem_WE;
    wire [31:0] dmem_read_data;

    // CORE

    pipeline_5stages_core u_pipeline_5stages_core (
        .clk        (clk),
        .rst_n      (rst_n),
        // IMEM
        .imem_A     (imem_Addr),
        .imem_read   (imem_read),
        .imem_ready (imem_ready),
        .imem_RD    (imem_ins),
        // DMEM
        .dmem_A     (dmem_Addr),
        .dmem_WD    (dmem_WD),
        .dmem_BE    (dmem_BE),
        .dmem_WE    (dmem_WE),
        .dmem_RD    (dmem_read_data)
    );


    // IMEM 
    imem #(
        .DEPTH_WORDS(IMEM_DEPTH),
        .BASE_ADDR  (IMEM_BASE),
        .INIT_HEX   (IMEM_HEX)
    ) u_imem (
        .Addr    (imem_Addr),
        .read  (imem_read),    // không bắt buộc, always-ready bên trong
        .ready(imem_ready),  // = 1'b1
        .ins   (imem_ins)
    );


    // DMEM 
    dmem #(
        .DEPTH_WORDS(DMEM_DEPTH),
        .BASE_ADDR  (DMEM_BASE)

    ) u_dmem (
        .clk  (clk),
        .Addr    (dmem_Addr),
        .WD   (dmem_WD),
        .BE   (dmem_BE),
        .WE   (dmem_WE),
        .read_data   (dmem_read_data)
    );

endmodule

module pipeline_5stages_core (
    input  wire        clk,
    input  wire        rst_n,
    // IMEM
    output wire [31:0] imem_A,
    output             imem_read,
    input              imem_ready,
    input  wire [31:0] imem_RD,
    // DMEM
    output wire [31:0] dmem_A,
    output wire [31:0] dmem_WD,
    output wire  [3:0] dmem_BE,
    output wire        dmem_WE,
    input  wire [31:0] dmem_RD
);
    // Control <=> Datapath
    wire        RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD;
    wire  [1:0] ResultSrcD;
    wire  [3:0] ALUControlD;
    wire [2:0] ImmSrcD;
    wire [1:0]  SrcASelD;
    wire [31:0] InstrD;

    // Hazard <=> Datapath
    wire        StallF, StallD, FlushE, FlushD;
    wire  [1:0] ForwardAE, ForwardBE;
    wire  [4:0] rs1D, rs2D, rs1E, rs2E, rdE, rdM, rdW;
    wire  [1:0] ResultSrcE;
    wire        PCSrcE;
    wire        RegWriteM, RegWriteW;

    // Datapath
    datapath u_datapath (
        .clk(clk), .rst_n(rst_n),

        .imem_A(imem_A), .imem_RD(imem_RD),
        .imem_ready(imem_ready),

        .dmem_A(dmem_A), .dmem_WD(dmem_WD), .dmem_BE(dmem_BE),
        .dmem_WE(dmem_WE), .dmem_RD(dmem_RD),

        .RegWriteD(RegWriteD), .ResultSrcD(ResultSrcD), .MemWriteD(MemWriteD),
        .JumpD(JumpD), .BranchD(BranchD), .ALUControlD(ALUControlD),
        .ALUSrcD(ALUSrcD), .ImmSrcD(ImmSrcD), .SrcASelD(SrcASelD), .InstrD(InstrD),

        .StallF(StallF), .StallD(StallD), .FlushE(FlushE), .FlushD(FlushD),
        .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),

        .rs1D(rs1D), .rs2D(rs2D), .rs1E(rs1E), .rs2E(rs2E), .rdE(rdE),
        .ResultSrcE(ResultSrcE), .PCSrcE(PCSrcE),
        .rdM(rdM), .rdW(rdW), .RegWriteM(RegWriteM), .RegWriteW(RegWriteW)
    );

    // Control
    Control_Unit u_Control_Unit (
        .instr      (InstrD),

        .imem_ready (imem_ready),
        .StallF     (StallF),
        .imem_read  (imem_read),
        
        .RegWriteD  (RegWriteD),
        .ResultSrcD (ResultSrcD),
        .MemWriteD  (MemWriteD),
        .JumpD      (JumpD),
        .BranchD    (BranchD),
        .ALUControlD(ALUControlD),
        .ALUSrcD    (ALUSrcD),
        .ImmSrcD    (ImmSrcD),
        .SrcASelD   (SrcASelD)
    );

    // Hazard 
    Hazard u_Hazard (
        .rs1D(rs1D), .rs2D(rs2D),
        .rdE(rdE), .ResultSrcE(ResultSrcE),

        .PCSrcE(PCSrcE),

        .rs1E(rs1E), .rs2E(rs2E),
        .rdM(rdM), .rdW(rdW),
        .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),

        .StallF(StallF), .StallD(StallD), .FlushE(FlushE), .FlushD(FlushD),
        .ForwardAE(ForwardAE), .ForwardBE(ForwardBE)
    );
endmodule

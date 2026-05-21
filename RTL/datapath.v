//   IMEM: imem_A -> imem_RD
//   DMEM: dmem_A/dmem_WD/dmem_BE/dmem_WE <-> dmem_RD
//
// Hazard/Control:
//   - Load-use: StallF, StallD, FlushE.
//   - Control hazard: PCSrcE=1 → FlushD (IF/ID) + FlushE.
//   - Forward: từ M (ALUResultM) hoặc W (ResultW) về EX.

// các lệnh :
// R-type : ADD, SUB, AND, OR, XOR, SLL, SLT
// I-type ALU : ADDI, ANDI, ORI, XORI, SLTI, SLLI
// LOAD (Imm I): LW, LB
// STORE (Imm S): SW, SB
// BRANCH (Imm B, signed compare): BEQ, BNE, BLT, BGE
// JUMP: JAL (Imm J; rd <= PC+4; target = PC + imm)
//       JALR 
// U: LUI, AUIPC
module datapath(
    input  wire        clk,
    input  wire        rst_n,

    // IMEM
    output wire [31:0] imem_A,    // PC (addr)
    input  wire [31:0] imem_RD,   // instruction read data
    input  wire        imem_ready,

    // DMEM
    output reg  [31:0] dmem_A,    // addr
    output reg  [31:0] dmem_WD,   // write data
    output reg   [3:0] dmem_BE,   // byte enable
    output reg         dmem_WE,   // write enable
    input  wire [31:0] dmem_RD,    // read data
    
    //Control Unit
    input  wire        RegWriteD,
    input  wire  [1:0] ResultSrcD,  // 00=ALU, 01=Mem, 10=PC+4
    input  wire        MemWriteD, 
    input  wire        JumpD,
    input  wire        BranchD,
    input  wire  [3:0] ALUControlD, // ALU
    input  wire        ALUSrcD,
    input  wire [2:0] ImmSrcD,
    input  wire [1:0] SrcASelD, // 00=RF, 01=PC, 10=ZERO
    output wire [31:0] InstrD,
    
    // Hazard outputs
    input  wire        StallF, //dừng PC
    input  wire        StallD, //giữ IF/ID(load-use)
    input  wire        FlushE,  // chèn bubble (NOP) vào ID/EX
    input  wire        FlushD,  // chèn bubble (NOP) vào IF/ID
    input  wire  [1:0] ForwardAE, 
    input  wire  [1:0] ForwardBE,  // chọn nguồn forward cho SrcA/SrcB ở EX

    // Hazard inputs
    output wire  [4:0] rs1D, rs2D,  // ID nguồn
    output wire  [4:0] rs1E, rs2E, rdE, // EX nguồn/đích
    output wire  [1:0] ResultSrcE,      // kiểm tra có phải load(=01)
    output wire        PCSrcE,          // quyết định mux(nhảy hay không)
    output reg  [4:0] rdM, rdW,        // MEM/WB dest
    output reg        RegWriteM, RegWriteW //cờ foward
);

    // define
    localparam [31:0] NOP32 = 32'h0000_0013; // addi x0,x0,0

    localparam [1:0]  RSRC_ALU=2'b00, RSRC_MEM=2'b01, RSRC_PC4=2'b10;

    localparam [3:0]  ALU_ADD=4'b0000, ALU_SUB=4'b0001, ALU_AND=4'b0010, ALU_OR=4'b0011,
                      ALU_XOR=4'b0100, ALU_SLT=4'b0101, ALU_SLL=4'b0110, ALU_SRA=4'b0111, ALU_SRL=4'b1000;

    localparam [6:0]  OP_BRANCH=7'b1100011, OP_JAL=7'b1101111,
                      OP_JALR=7'b1100111, OP_LOAD=7'b0000011, OP_STORE=7'b0100011;

    localparam [2:0] IMM_I=3'b000, IMM_S=3'b001, IMM_B=3'b010, IMM_J=3'b011, IMM_U=3'b100;


    // IF stage
    reg  [31:0] PCF;
    wire [31:0] PCPlus4F = PCF + 32'd4;
    wire [31:0] InstrF   = imem_RD;

    wire [31:0] PCTargetE;               // địa chỉ nhảy (branch/jump target) từ EX

    assign imem_A = PCF;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)       PCF <= 32'b0;
        else if (!StallF && imem_ready) PCF <= PCSrcE ? PCTargetE : PCPlus4F;
        //StallF = 1 => giữ nguyên PCF
    end

    // IF/ID  register
    reg  [31:0] PCD, PCPlus4D, InstrD_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            {PCD, PCPlus4D, InstrD_r} <= {32'b0, 32'b0, NOP32};
        else if (FlushD)
            {PCD, PCPlus4D, InstrD_r} <= {32'b0, 32'b0, NOP32}; // bubble
        else if (!StallD && imem_ready)
            {PCD, PCPlus4D, InstrD_r} <= {PCF, PCPlus4F, InstrF};
        // StallD=1 -> giữ nguyên
    end
    assign InstrD = InstrD_r;
    
 
    // ID stage: Decode + RF + Imm
    assign rs1D = InstrD_r[19:15];
    assign rs2D = InstrD_r[24:20];
    wire  [4:0] rdD  = InstrD_r[11:7];

    //Register file
    wire [31:0] RD1D, RD2D;
    wire [31:0] ResultW;

    RF u_rf(
        .clk   (clk),
        .rst_n (rst_n),
        .we    (RegWriteW),
        .rs1   (rs1D),
        .rs2   (rs2D),
        .rd    (rdW),
        .wdata (ResultW),
        .rdata1(RD1D),
        .rdata2(RD2D)
    );

    // ImmGen : InstrD + ImmSrcD → ImmExtD
    reg [31:0] ImmExtD;
    always @(ImmSrcD or InstrD_r) begin
        case (ImmSrcD)
            IMM_I: ImmExtD = {{20{InstrD_r[31]}}, InstrD_r[31:20]}; // I
            IMM_S: ImmExtD = {{20{InstrD_r[31]}}, InstrD_r[31:25], InstrD_r[11:7]}; // S
            IMM_B: ImmExtD = {{19{InstrD_r[31]}}, InstrD_r[31], InstrD_r[7], InstrD_r[30:25], InstrD_r[11:8], 1'b0}; // B (PC-rel, bit0=0)
            IMM_J: ImmExtD = {{11{InstrD_r[31]}}, InstrD_r[31], InstrD_r[19:12], InstrD_r[20], InstrD_r[30:21], 1'b0};    // J (PC-rel, bit0=0)
            IMM_U: ImmExtD = {InstrD_r[31:12], 12'b0};   //// U  (imm20 << 12)
            default: ImmExtD = 32'b0; 
        endcase
    end

    // ID/EX pipeline register (control/operand cho EX)
    localparam CTRLW = 13; // {RegWrite,MemWrite,ALUSrc,Branch,Jump,ResultSrc[1:0],ALUControl[3:0],SrcASelE}
    reg  [CTRLW-1:0] ctrlE;
    reg  [31:0] RD1E, RD2E, ImmExtE, PCE, PCPlus4E;
    reg  [4:0]  rs1E_r, rs2E_r, rdE_r;
    reg  [2:0]  funct3E;
    reg  [6:0]  funct7E, opE;

    wire RegWriteE, MemWriteE, ALUSrcE, BranchE, JumpE;
    wire [3:0] ALUControlE_w;
    wire  [1:0]  SrcASelE;
    assign {RegWriteE, MemWriteE, ALUSrcE, BranchE, JumpE, ResultSrcE, ALUControlE_w, SrcASelE} = ctrlE;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrlE <= {CTRLW{1'b0}};
            {RD1E,RD2E,ImmExtE,PCE,PCPlus4E} <= {5{32'b0}};
            {rs1E_r,rs2E_r,rdE_r} <= 15'b0;
            {funct3E,funct7E,opE} <= {3'b0,7'b0,7'b0};
        end else if (FlushE) begin
            // FlushE: chèn NOP vào EX (bubble) cho load-use/control hazard
            ctrlE <= {CTRLW{1'b0}};
            {RD1E,RD2E,ImmExtE,PCE,PCPlus4E} <= {5{32'b0}};
            {rs1E_r,rs2E_r,rdE_r} <= 15'b0;
            {funct3E,funct7E,opE} <= {3'b0,7'b0,7'b0};
        end else if (!StallD) begin
            ctrlE <= {RegWriteD, MemWriteD, ALUSrcD, BranchD, JumpD, ResultSrcD, ALUControlD, SrcASelD};
            {RD1E,RD2E,ImmExtE,PCE,PCPlus4E} <= {RD1D,RD2D,ImmExtD,PCD,PCPlus4D};
            {rs1E_r,rs2E_r,rdE_r} <= {rs1D, rs2D, rdD};
            {funct3E,funct7E,opE} <= {InstrD_r[14:12], InstrD_r[31:25], InstrD_r[6:0]};
        end
        // else: StallD=1 → giữ nguyên ID/EX
    end
    assign rs1E = rs1E_r; 
    assign rs2E = rs2E_r; 
    assign rdE = rdE_r;

    // Nhận biết LB/SB EX (để MEM chọn BE/SE đúng)
    wire LoadByteE  = (opE==OP_LOAD)  && (funct3E==3'b000); // LB
    wire StoreByteE = (opE==OP_STORE) && (funct3E==3'b000); // SB

    // EX : forward + ALU + quyết định nhánh/nhảy
    // Chọn nguồn đã forward: 2'b10 từ M, 2'b01 từ W, 2'b00 từ ID/EX
    reg  [31:0] ALUResultM;

    wire [31:0] srcA_fwd = (ForwardAE==2'b10) ? ALUResultM :
                           (ForwardAE==2'b01) ? ResultW : RD1E;
    wire [31:0] srcB_fwd = (ForwardBE==2'b10) ? ALUResultM :
                           (ForwardBE==2'b01) ? ResultW : RD2E;


    // 2'b01: PC ; 2'b10: ZERO ; 2'b00: RegFile (có forward)
    wire [31:0] SrcAE = (SrcASelE==2'b01) ? PCE    :
                        (SrcASelE==2'b10) ? 32'b0  :
                                            srcA_fwd;

    // chọn giữa Imm và RS2_fwd
    wire [31:0] SrcBE = ALUSrcE ? ImmExtE : srcB_fwd;

    // ALU
    reg  [31:0] ALUResultE;
    always @(ALUControlE_w or SrcAE or SrcBE) begin
        case (ALUControlE_w)
            ALU_ADD: ALUResultE = SrcAE + SrcBE;
            ALU_SUB: ALUResultE = SrcAE - SrcBE;
            ALU_AND: ALUResultE = SrcAE & SrcBE;
            ALU_OR : ALUResultE = SrcAE | SrcBE;
            ALU_XOR: ALUResultE = SrcAE ^ SrcBE;
            ALU_SLL: ALUResultE = SrcAE << SrcBE[4:0];
            ALU_SLT: ALUResultE = ($signed(SrcAE) < $signed(SrcBE)) ? 32'd1 : 32'd0;
            ALU_SRA: ALUResultE = ($signed(SrcAE)) >>> SrcBE[4:0];
            ALU_SRL: ALUResultE = SrcAE >> SrcBE[4:0];
            default: ALUResultE = 32'b0;
        endcase
    end

    // Dữ liệu ghi Store (đường RS2) sau forward
    wire [31:0] WriteDataE = srcB_fwd;

    // So sánh cho branch
    wire eq = (srcA_fwd == srcB_fwd);
    wire lt = ($signed(srcA_fwd) < $signed(srcB_fwd));
    wire ge = ~lt;

    // PCTarget: Branch/JAL = PC + imm; JALR = (RS1 + imm) & ~1
    wire [31:0] branch_target_E = PCE + ImmExtE;
    wire [31:0] jalr_target_E   = (srcA_fwd + ImmExtE) & 32'hFFFF_FFFE;

    // Quyết định nhánh theo funct3
    wire ZeroE = (opE==OP_BRANCH) && (
                        (funct3E==3'b000 &&  eq) || // BEQ
                        (funct3E==3'b001 && ~eq) || // BNE
                        (funct3E==3'b100 &&  lt) || // BLT
                        (funct3E==3'b101 &&  ge)    // BGE
                      );

    // Điều hướng PC tại EX
    assign PCSrcE    = JumpE | (BranchE & ZeroE);
    assign PCTargetE = (JumpE && (opE==OP_JALR)) ? jalr_target_E : branch_target_E;

    // EX/MEM pipeline register
    reg        MemWriteM, LoadByteM, StoreByteM;
    reg  [1:0] ResultSrcM;
    reg  [31:0] WriteDataM, PCPlus4M;



    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {RegWriteM,MemWriteM,ResultSrcM,LoadByteM,StoreByteM} <= {1'b0,1'b0,2'b00,1'b0,1'b0};
            {ALUResultM,WriteDataM,PCPlus4M} <= {32'b0,32'b0,32'b0};
            rdM <= 5'b0;
        end else begin
            {RegWriteM,MemWriteM,ResultSrcM,LoadByteM,StoreByteM} <=  {RegWriteE,  MemWriteE,  ResultSrcE,  LoadByteE, StoreByteE};
            {ALUResultM,WriteDataM,PCPlus4M} <= {ALUResultE,WriteDataE,PCPlus4E};
            rdM <= rdE;
        end
    end


    // MEM stage: truy cập DMEM (BE/SB/LB)
    always @(ALUResultM or MemWriteM or StoreByteM or WriteDataM) begin
        dmem_A  = ALUResultM;
        dmem_WE = MemWriteM;
        dmem_BE = StoreByteM ? (4'b0001 << ALUResultM[1:0]) : 4'b1111;
        dmem_WD = StoreByteM ? {4{WriteDataM[7:0]}} : WriteDataM;
    end

    wire [7:0] sel_byte = (ALUResultM[1:0]==2'b00) ? dmem_RD[7:0]  :
                          (ALUResultM[1:0]==2'b01) ? dmem_RD[15:8] :
                          (ALUResultM[1:0]==2'b10) ? dmem_RD[23:16]: dmem_RD[31:24];
    wire [31:0] ReadDataM = LoadByteM ? {{24{sel_byte[7]}}, sel_byte} : dmem_RD;

   
    // MEM/WB pipeline register
    reg  [1:0] ResultSrcW;
    reg  [31:0] ALUResultW, ReadDataW, PCPlus4W;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {RegWriteW, ResultSrcW} <= {1'b0, 2'b00};
            {ALUResultW, ReadDataW, PCPlus4W} <= {32'b0,32'b0,32'b0};
            rdW <= 5'b0;
        end else begin
            {RegWriteW, ResultSrcW} <= {RegWriteM, ResultSrcM};
            {ALUResultW, ReadDataW, PCPlus4W} <= {ALUResultM, ReadDataM, PCPlus4M};
            rdW <= rdM;
        end
    end

    // WB stage: chọn dữ liệu ghi về RF (ALU/MEM/PC+4)
    assign ResultW = (ResultSrcW==RSRC_MEM) ? ReadDataW :
                     (ResultSrcW==RSRC_PC4) ? PCPlus4W : ALUResultW;

endmodule

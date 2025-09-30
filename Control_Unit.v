module Control_Unit(
    input  wire [31:0] instr,       // lệnh tại ID

    // Handshake IMEM
    input  wire        imem_ready,  
    input  wire        StallF,      // không yêu cầu đọc khi stall
    output wire        imem_read,   // yêu cầu đọc IMEM

    output wire        RegWriteD,
    output wire  [1:0] ResultSrcD,  // 00=ALU, 01=MEM, 10=PC+4
    output wire        MemWriteD,
    output wire        JumpD,
    output wire        BranchD,
    output wire  [3:0] ALUControlD, // ADD/SUB/AND/OR/XOR/SLT/SLL/SRA/SRL
    output wire        ALUSrcD,
    output wire  [2:0] ImmSrcD,
    output wire  [1:0]  SrcASelD  // 00=RF, 01=PC, 10=ZERO
);

    // không stall thì cứ đọc 
    assign imem_read = ~StallF;

    // opcode/funct
    wire [6:0] op     = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    // opcode
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_JALR   = 7'b1100111;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_LOAD   = 7'b0000011;
    localparam [6:0] OP_STORE  = 7'b0100011;
    localparam [6:0] OP_IMM    = 7'b0010011; // I-type ALU imm
    localparam [6:0] OP_R     = 7'b0110011; // R-type
    localparam [6:0] OP_LUI   = 7'b0110111;
    localparam [6:0] OP_AUIPC = 7'b0010111;

    // ALU codes 
    localparam ALU_ADD=4'b0000, ALU_SUB=4'b0001, ALU_AND=4'b0010, ALU_OR=4'b0011,
               ALU_XOR=4'b0100, ALU_SLT=4'b0101, ALU_SLL=4'b0110, ALU_SRA=4'b0111, ALU_SRL=4'b1000;

    // ImmSrc 
    localparam [2:0] IMM_I = 3'b000;
    localparam [2:0] IMM_S = 3'b001;
    localparam [2:0] IMM_B = 3'b010;
    localparam [2:0] IMM_J = 3'b011;
    localparam [2:0] IMM_U = 3'b100;

    // mã SrcA
    localparam [1:0] SA_RF   = 2'b00; // lấy từ RegFile (RD1)
    localparam [1:0] SA_PC   = 2'b01; // lấy PC
    localparam [1:0] SA_ZERO = 2'b10; // hằng 0
    
    // bus concat
    localparam integer CTRLW = 16;
    reg [CTRLW-1:0] dec_bus;
    assign {RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD, ImmSrcD, SrcASelD} = dec_bus;

    always @(funct3 or funct7 or op) begin
        // Mặc định (NOP / illegal -> bubble)
        dec_bus = {1'b0, 2'b00, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, IMM_I, SA_RF};

        case (op)
            OP_JAL: begin
                // rd <- PC+4 ; PC <- PC + immJ
                dec_bus = {1'b1, 2'b10, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b1, IMM_J, SA_RF};
            end
            OP_JALR: begin
                // rd <- PC+4 ; PC <- (rs1 + immI) & ~1
                dec_bus = {1'b1, 2'b10, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b1, IMM_I, SA_RF};
            end
            OP_BRANCH: begin
                // so sánh tại EX, PC-relative B-imm
                dec_bus = {1'b0, 2'b00, 1'b0, 1'b0, 1'b1, ALU_ADD, 1'b0, IMM_B, SA_RF};
            end
            OP_LOAD: begin
                // rd <- MEM[rs1 + immI]
                dec_bus = {1'b1, 2'b01, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b1, IMM_I, SA_RF};
            end
            OP_STORE: begin
                // MEM[rs1 + immS] <- rs2
                dec_bus = {1'b0, 2'b00, 1'b1, 1'b0, 1'b0, ALU_ADD, 1'b1, IMM_S, SA_RF};
            end
            OP_IMM: begin
                // rd <- ALU(rs1, immI)
                // ALUControl theo funct3
                case (funct3)
                    3'b000: dec_bus = {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b1, IMM_I, SA_RF}; // ADDI
                    3'b111: dec_bus = {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b1, IMM_I, SA_RF}; // ANDI
                    3'b110: dec_bus = {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, ALU_OR , 1'b1, IMM_I, SA_RF}; // ORI
                    3'b100: dec_bus = {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, ALU_XOR, 1'b1, IMM_I, SA_RF}; // XORI
                    3'b010: dec_bus = {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, ALU_SLT, 1'b1, IMM_I, SA_RF}; // SLTI
                    3'b001: dec_bus = {1'b1, 2'b00, 1'b0, 1'b0, 1'b0, ALU_SLL, 1'b1, IMM_I, SA_RF}; // SLLI
                    3'b101: dec_bus = (funct7==7'b0100000) ?
                                      {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_SRA,1'b1,IMM_I,SA_RF} : // SRAI
                                      {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_SRL,1'b1,IMM_I,SA_RF};  // SRLI
                    default: dec_bus = {1'b0, 2'b00, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, IMM_I, SA_RF};
                endcase
            end
            OP_R: begin
                // rd <- ALU(rs1, rs2) (R-type)
                case (funct3)
                    3'b000: dec_bus = (funct7==7'b0100000) ?
                                      {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_SUB,1'b0,IMM_I,SA_RF} : // SUB
                                      {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_ADD,1'b0,IMM_I,SA_RF};  // ADD
                    3'b111: dec_bus = {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_AND,1'b0,IMM_I,SA_RF};
                    3'b110: dec_bus = {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_OR ,1'b0,IMM_I,SA_RF};
                    3'b100: dec_bus = {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_XOR,1'b0,IMM_I,SA_RF};
                    3'b010: dec_bus = {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_SLT,1'b0,IMM_I,SA_RF};
                    3'b001: dec_bus = {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_SLL,1'b0,IMM_I,SA_RF};
                    3'b101: dec_bus = (funct7==7'b0100000) ?
                                      {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_SRA,1'b0,IMM_I,SA_RF} : // SRA
                                      {1'b1, 2'b00,1'b0,1'b0,1'b0, ALU_SRL,1'b0,IMM_I,SA_RF};  // SRL
                    default:dec_bus = {1'b0, 2'b00, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, IMM_I, SA_RF};
                endcase
            end
            OP_LUI: begin
                // rd <- 0 + immU
                dec_bus = {1'b1, 2'b00, 1'b0,1'b0,1'b0, ALU_ADD, 1'b1, IMM_U, SA_ZERO};
            end
            OP_AUIPC: begin
                // rd <- PC + immU
                dec_bus = {1'b1, 2'b00, 1'b0,1'b0,1'b0, ALU_ADD, 1'b1, IMM_U, SA_PC};
            end
            default: begin
                dec_bus = {1'b0, 2'b00, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, IMM_I, SA_RF};
            end
        endcase
    end
endmodule

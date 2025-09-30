//   1) Load-use hazard (E là LOAD và rdE trùng rs1D/rs2D):
//      -> StallF=1, StallD=1 (giữ IF/ID), FlushE=1 (bubble vào EX)
//   2) Control hazard (branch/jump đúng ở EX): FlushE=1 ,FlushD=1
//   3) Forwarding cho EX từ M (2'b10) hoặc từ W (2'b01)

module Hazard(
    // Load-use (so giữa D và E)
    input  wire [4:0] rs1D,
    input  wire [4:0] rs2D,
    input  wire [4:0] rdE,
    input  wire [1:0] ResultSrcE, // 01 => kết quả từ MEM (LOAD)
    // Control hazard
    input  wire       PCSrcE,      // 1 khi branch/jump được chọn ở EX
    // Forwarding (so E với M/W, ưu tiên MEM)
    input  wire [4:0] rs1E,
    input  wire [4:0] rs2E,
    input  wire [4:0] rdM,
    input  wire [4:0] rdW,
    input  wire       RegWriteM,
    input  wire       RegWriteW,
    // Outputs
    output wire       StallF,
    output wire       StallD,
    output wire       FlushE,
    output wire       FlushD,
    output reg  [1:0] ForwardAE,
    output reg  [1:0] ForwardBE
);
    localparam [1:0] RSRC_MEM = 2'b01;

    //  Load-use stall
    wire lwStall = (ResultSrcE==RSRC_MEM) && (rdE!=0) && ((rdE==rs1D) || (rdE==rs2D));
    assign StallF = lwStall;
    assign StallD = lwStall;

    // Flush EX khi redirect hoặc load-use
    assign FlushD = PCSrcE;
    assign FlushE = lwStall | PCSrcE;

    // Forwarding
    always @(ForwardAE or ForwardBE or RegWriteM or RegWriteW or rdM or rdW or rs1E or rs2E) begin
        // A
        if (RegWriteM && (rdM!=0) && (rdM==rs1E))      ForwardAE = 2'b10;
        else if (RegWriteW && (rdW!=0) && (rdW==rs1E)) ForwardAE = 2'b01;
        else ForwardAE = 2'b00;
        // B
        if (RegWriteM && (rdM!=0) && (rdM==rs2E))      ForwardBE = 2'b10;
        else if (RegWriteW && (rdW!=0) && (rdW==rs2E)) ForwardBE = 2'b01;
        else ForwardBE = 2'b00;
    end
endmodule

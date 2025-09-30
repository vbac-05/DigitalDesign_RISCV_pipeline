

module RF(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,        // cho phép ghi
    input  wire  [4:0] rs1,
    input  wire  [4:0] rs2,
    input  wire  [4:0] rd,
    input  wire [31:0] wdata,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);
    reg [31:0] regs [0:31];
    integer i;

    // đọc cổng A và B
    assign rdata1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    assign rdata2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2];

    // ghi + reset
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // reset toàn bộ regs về 0
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else begin
            if (we && (rd != 5'd0))
                regs[rd] <= wdata;

            // đảm bảo x0 luôn 0
            regs[0] <= 32'b0;
        end
    end
endmodule



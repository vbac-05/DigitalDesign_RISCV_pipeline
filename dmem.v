
module dmem #(
    parameter integer DEPTH_WORDS = 256,            // số word 32-bit
    parameter [31:0]  BASE_ADDR   = 32'h0000_0000   // ánh xạ base (tuỳ chọn)
) (
    input  wire        clk,        // clock ghi

    input  wire [31:0] Addr,          // địa chỉ byte
    input  wire [31:0] WD,         // dữ liệu ghi
    input  wire  [3:0] BE,         // byte-enable (1 bit/1 byte)
    input  wire        WE,         // write enable

    output wire [31:0] read_data          // dữ liệu đọc (combinational)
);

    reg [31:0] dmem [0:DEPTH_WORDS-1];


    localparam integer ADDR_W = (DEPTH_WORDS <= 2) ? 1 : $clog2(DEPTH_WORDS);
    wire [31:0] byte_off = Addr - BASE_ADDR;
    wire [ADDR_W-1:0] dmem_idx = byte_off[ADDR_W+1:2];   // bỏ 2 bit thấp (byte offset)

    // đọc bất đồng bộ 
    assign read_data = dmem[dmem_idx];

    // ghi đồng bộ theo byte-enable 
    always @(posedge clk) begin
        if (WE) begin
            if (BE[0]) dmem[dmem_idx][ 7: 0] <= WD[ 7: 0];
            if (BE[1]) dmem[dmem_idx][15: 8] <= WD[15: 8];
            if (BE[2]) dmem[dmem_idx][23:16] <= WD[23:16];
            if (BE[3]) dmem[dmem_idx][31:24] <= WD[31:24];
        end
    end
endmodule

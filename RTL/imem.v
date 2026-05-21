
module imem #(
    parameter integer DEPTH_WORDS = 256,           // 256 words = 1KB
    parameter        INIT_HEX    = "memfile.hex",             
    parameter [31:0] BASE_ADDR   = 32'h0000_0000 // base address
)(
    input  wire [31:0] Addr,          // byte address (PC)
    input  wire        read,        // yêu cầu đọc
    output wire        ready,      // dữ liệu hợp lệ
    output wire [31:0] ins          // instruction
);
    //bộ nhớ theo word
    reg [31:0] imem [0:DEPTH_WORDS-1];
    localparam integer bit_addr = (DEPTH_WORDS <= 2) ? 1 : $clog2(DEPTH_WORDS);
    wire [31:0] byte_off = Addr - BASE_ADDR;
    wire [bit_addr-1:0] imem_idx = byte_off[bit_addr+1:2];

    //đọc bất đồng bộ
    assign ins = imem[imem_idx];

    assign ready = 1'b1;
endmodule

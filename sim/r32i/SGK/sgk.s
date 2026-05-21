    .data
# Dữ liệu thử nghiệm
mem:    .word 0x12345678       # memory word tại mem
        .half 0xABCD           # half-word
        .byte 0xEF             # byte

    .text
    .globl _start
_start:
    addi x0, x0, 0
    addi x1, x0, 0
    addi x2, x0, 0
    addi x3, x0, 0
    addi x4, x0, 0
    addi x5, x0, 0
    addi x6, x0, 0
    addi x7, x0, 0
    addi x8, x0, 0
    addi x9, x0, 0
    addi x10, x0, 0
    addi x11, x0, 0
    addi x12, x0, 0
    addi x13, x0, 0
    addi x14, x0, 0
    addi x15, x0, 0
    addi x16, x0, 0
    addi x17, x0, 0
    addi x18, x0, 0
    addi x19, x0, 0
    addi x20, x0, 0
    addi x21, x0, 0
    addi x22, x0, 0
    addi x23, x0, 0
    addi x24, x0, 0
    addi x25, x0, 0
    addi x26, x0, 0
    addi x27, x0, 0
    addi x28, x0, 0
    addi x29, x0, 0
    addi x30, x0, 0
    addi x31, x0, 0
    # --- Khai báo các register để test ---
    la t0, mem        # t0 = address của mem

    # --- STORE TESTS ---
    # Store byte (SB)
    li t1, 0xAA
    sb t1, 0(t0)      # ghi 0xAA vào byte 0

    # Store word (SW)
    li t3, 0xDEADBEEF
    sw t3, 4(t0)      # ghi toàn bộ word vào mem+4

    # --- LOAD TESTS ---
    # Load byte signed (LB)
    lb s0, 0(t0)      # đọc byte 0, sign extend

    # Load word (LW)
    lw s4, 4(t0)      # đọc toàn bộ word từ mem+4

    # --- STORE/LOAD mix tests ---
    # SB vào mem+5, LBU đọc lại
    li t4, 0x7F
    sb t4, 5(t0)

    # SH vào mem+6, LHU đọc lại
    li t5, 0xC0DE

    # SW vào mem+8, LW đọc lại
    li t6, 0xFEEDFACE
    sw t6, 8(t0)
    lw s7, 8(t0)
    
done:
    beq   x0, x0, done       # loop

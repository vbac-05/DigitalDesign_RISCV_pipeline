# DigitalDesign_RISCV_pipeline

Project implements a simplified **32-bit RISC-V processor** using a **5-stage pipeline** architecture, written in Verilog.

**Note:** Core supports a **subset** of the standard RV32I instruction set architecture (ISA) and does not support the full instruction set.

## Key Features
* **Architecture:** 5 stages (IF, ID, EX, MEM, WB).
* **Hazard Handling:**
    * **Forwarding:** Resolves Data Hazards (from MEM or WB stages back to EX).
    * **Stalling:** Automatically stalls the pipeline when a Load-Use Hazard is detected.
    * **Flushing:** Flushes incorrect instructions from the pipeline upon branch misprediction (Control Hazard).

## Supported Instructions
The current code supports the following basic instructions:

1.  **Arithmetic & Logic (R-Type & I-Type):**
    * `ADD`, `SUB`, `AND`, `OR`, `XOR`
    * `SLL`, `SRL`, `SRA` (Logical and Arithmetic shifts)
    * `SLT` (Signed comparison)
    * *Immediate versions:* `ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `SLTI`.
2.  **Memory Access (Load/Store):**
    * `LW` (Load Word), `SW` (Store Word)
    * `LB` (Load Byte - sign extended), `SB` (Store Byte).
3.  **Branch & Jump:**
    * **Branch:** `BEQ`, `BNE`, `BLT`, `BGE` (Equality and signed comparisons).
    * **Jump:** `JAL`, `JALR`.
4.  **Others:**
    * `LUI`, `AUIPC`.

## Limitations (Not Supported)
* **Unsigned Comparisons:** `SLTU`, `SLTIU`, `BLTU`, `BGEU` (The code currently only uses `$signed` for comparisons).
* **Half-word & Unsigned Load:** `LH`, `LHU`, `SH`, `LBU` (Logic for `funct3` to handle these is missing).
* **System Instructions:** `ECALL`, `EBREAK`, `CSRRW`, etc.

## File Structure

### Top-Level & Memories
* `riscv_pipeline_5stages.v`: The top-level module (SoC) that connects the **Processor Core** with **Instruction Memory** and **Data Memory**.
* `imem.v`: Instruction Memory (stores the machine code).
* `dmem.v`: Data Memory (RAM for Load/Store instructions).

### Processor Core (`pipeline_5stages_core.v`)
* `datapath.v`: Main datapath unit (contains the ALU, PC, Muxes, and instantiates `RF.v`).
* `Control_Unit.v`: Main Controller (decodes instructions to generate control signals).
* `Hazard.v`: Hazard Detection Unit (handles Forwarding, Stalling, and Flushing).
* `RF.v`: Register File (32 x 32-bit registers).

## Architecture Diagrams

### 1. RISC-V Datapath (Logical Flow)
<img width="1113" height="670" alt="Screenshot from 2026-01-10 14-09-34" src="https://github.com/user-attachments/assets/3b8214b8-1a7d-405a-a71b-4b5205f14d8a" />


### 2. RISC-V 5-Stage Pipeline (with Hazard Unit)
<img width="1173" height="723" alt="Screenshot from 2026-01-10 14-09-55" src="https://github.com/user-attachments/assets/12381171-7863-4c9a-b1ae-e806025c9030" />


### 3. Top-Level Architecture
<img width="1036" height="781" alt="Screenshot from 2026-01-10 14-10-29" src="https://github.com/user-attachments/assets/7342e4f4-e28a-4c4f-82eb-536598b40e08" />


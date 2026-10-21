# qstream-dma-pqc
SystemVerilog RTL and testbench for the Q-STREAM DMA engine in the PQC accelerator (Team C specification).
# Q-STREAM DMA Block — PQC Accelerator (Team C)

A SystemVerilog implementation of the **Q-STREAM Direct Memory Access (DMA)** engine for the Post-Quantum Cryptography (PQC) accelerator, designed per the **Team C Engineering Specification (Data Movement, Secure Memory & Host Interfaces)**.

---

## Overview

**Q-STREAM** serves as the dedicated data mover between external host memory and the on-chip **Secure Scratchpad**. It offloads data movement for cryptographic payloads—including public keys, ciphertexts, plaintexts, polynomials, and signatures—while keeping the host processor unburdened.

### Security Boundaries
- **Strict Key Vault Isolation:** Q-STREAM has no physical or logical interconnect routing to the Key Vault. It cannot read, write, or address root cryptographic keys.
- **Pre-Execution Validation:** Descriptors are validated combinationally prior to initiating bus transactions. Malformed descriptors are rejected with error code `0xC002` (`ERR_DMA_DESCRIPTOR_INVALID`).
- **Livelock Prevention:** Descriptors that fail validation immediately clear their `DESC_VALID` flag to prevent continuous re-evaluation loops.

---

## Architecture & Features

- **16-Entry Descriptor Table:** Stores up to 16 descriptors with a total entry width of 96 bits (`AXI_ADDR_WIDTH + 46 + 18`).
- **Lifecycle FSM:** Implements the three-state lifecycle: `EMPTY` $\rightarrow$ `PENDING` $\rightarrow$ `EXECUTING` $\rightarrow$ `EMPTY`.
- **Pre-Execution Checks:**
  - **Direction & Permissions Matching:** 
    - `DIRECTION = 0` (LOAD: Host $\rightarrow$ Scratchpad) strictly requires `PERMISSIONS = 2'b10` (WRITE).
    - `DIRECTION = 1` (STORE: Scratchpad $\rightarrow$ Host) strictly requires `PERMISSIONS = 2'b01` (READ).
  - **Bounds Verification:** Ensures `SCRATCHPAD_OFFSET + LENGTH <= BANK_CAPACITY_BYTES` and `LENGTH > 0`.
  - **Reserved Field Check:** Enforces that all 18 `RESERVED` bits are zero.
  - **Descriptor Chaining Bounds:** Ensures `NEXT_DESC_INDEX < 16` when `CHAIN_VALID = 1`.
- **Priority Controls:** 
  - `a2c_abort`: Cancels in-flight transfers and retires the active descriptor.
  - `a2c_zeroize`: Synchronously clears all active pipeline states and descriptor storage with top priority.

---

## Repository Structure

```text
├── qstream_pkg.sv         # SystemVerilog package: parameters, structs, error codes, and FSM states
├── qstream_validator.sv   # Pure combinational pre-execution validation engine
├── qstream_desc_table.sv  # 16-entry descriptor table with dual-port host/engine access
├── qstream_top.sv         # Top-level module: FSM, datapath routing, abort, and zeroize logic
└── tb_qstream_dma.sv      # Directed testbench verifying nominal transfers, rejections, and chaining

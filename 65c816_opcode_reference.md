# WDC 65C816 Opcode Reference

A working reference for 65C816 assembly programming. Covers all 91
mnemonics, their addressing modes, opcode bytes, and a minimal example
for each.

> **Note on immediate-mode byte counts:** The 65C816 has independent
> 8/16-bit control over the accumulator (M flag) and index registers
> (X flag). Immediate opcodes for A (`ADC #`, `LDA #`, etc.) are 2 bytes
> when M=1 (8-bit) and 3 bytes when M=0 (16-bit). Immediate opcodes for
> X/Y (`LDX #`, `CPY #`, etc.) follow the X flag the same way. This
> reference lists the base (8-bit) byte count and flags the variable
> ones.

---

## Table of Contents

**Quick Reference Table:** [Jump to table](#quick-reference-table)

**Instructions A-E:** [ADC](#adc--add-with-carry) · [AND](#and--and-accumulator-with-memory) · [ASL](#asl--arithmetic-shift-left) · [BCC](#bcc--branch-if-carry-clear) · [BCS](#bcs--branch-if-carry-set) · [BEQ](#beq--branch-if-equal) · [BIT](#bit--test-bits) · [BMI](#bmi--branch-if-minus) · [BNE](#bne--branch-if-not-equal) · [BPL](#bpl--branch-if-plus) · [BRA](#bra--branch-always) · [BRK](#brk--software-break) · [BRL](#brl--branch-long-always) · [BVC](#bvc--branch-if-overflow-clear) · [BVS](#bvs--branch-if-overflow-set) · [CLC](#clc--clear-carry) · [CLD](#cld--clear-decimal-mode) · [CLI](#cli--clear-interrupt-disable) · [CLV](#clv--clear-overflow) · [CMP](#cmp--compare-accumulator) · [COP](#cop--coprocessor-software-interrupt) · [CPX](#cpx--compare-x-register) · [CPY](#cpy--compare-y-register) · [DEC](#dec--decrement) · [DEX](#dex--decrement-x) · [DEY](#dey--decrement-y) · [EOR](#eor--exclusive-or-accumulator-with-memory)

**Instructions I-P:** [INC](#inc--increment) · [INX](#inx--increment-x) · [INY](#iny--increment-y) · [JML](#jml--jump-long) · [JMP](#jmp--jump) · [JSL](#jsl--jump-to-subroutine-long) · [JSR](#jsr--jump-to-subroutine) · [LDA](#lda--load-accumulator) · [LDX](#ldx--load-x-register) · [LDY](#ldy--load-y-register) · [LSR](#lsr--logical-shift-right) · [MVN](#mvn--block-move-negative) · [MVP](#mvp--block-move-positive) · [NOP](#nop--no-operation) · [ORA](#ora--or-accumulator-with-memory) · [PEA](#pea--push-effective-address) · [PEI](#pei--push-effective-indirect-address) · [PER](#per--push-effective-relative-address) · [PHA](#pha--push-accumulator) · [PHB](#phb--push-data-bank-register) · [PHD](#phd--push-direct-page-register) · [PHK](#phk--push-program-bank-register) · [PHP](#php--push-processor-status) · [PHX](#phx--push-x-register) · [PHY](#phy--push-y-register) · [PLA](#pla--pull-accumulator) · [PLB](#plb--pull-data-bank-register) · [PLD](#pld--pull-direct-page-register) · [PLP](#plp--pull-processor-status) · [PLX](#plx--pull-x-register) · [PLY](#ply--pull-y-register)

**Instructions R-Z:** [REP](#rep--reset-processor-status-bits) · [ROL](#rol--rotate-left) · [ROR](#ror--rotate-right) · [RTI](#rti--return-from-interrupt) · [RTL](#rtl--return-from-subroutine-long) · [RTS](#rts--return-from-subroutine) · [SBC](#sbc--subtract-with-borrow) · [SEC](#sec--set-carry) · [SED](#sed--set-decimal-mode) · [SEI](#sei--set-interrupt-disable) · [SEP](#sep--set-processor-status-bits) · [STA](#sta--store-accumulator) · [STP](#stp--stop-the-clock) · [STX](#stx--store-x-register) · [STY](#sty--store-y-register) · [STZ](#stz--store-zero) · [TAX](#tax--transfer-a-to-x) · [TAY](#tay--transfer-a-to-y) · [TCD](#tcd--transfer-c-to-direct-page-register) · [TCS](#tcs--transfer-c-to-stack-pointer) · [TDC](#tdc--transfer-direct-page-register-to-c) · [TRB](#trb--test-and-reset-bits) · [TSB](#tsb--test-and-set-bits) · [TSC](#tsc--transfer-stack-pointer-to-c) · [TSX](#tsx--transfer-stack-pointer-to-x) · [TXA](#txa--transfer-x-to-a) · [TXS](#txs--transfer-x-to-stack-pointer) · [TXY](#txy--transfer-x-to-y) · [TYA](#tya--transfer-y-to-a) · [TYX](#tyx--transfer-y-to-x) · [WAI](#wai--wait-for-interrupt) · [WDM](#wdm--reserved-william-d-mensch-instruction) · [XBA](#xba--exchange-b-and-a) · [XCE](#xce--exchange-carry-and-emulation-bits)

---

## Quick Reference Table

| Mnemonic | Full Name | Brief |
|---|---|---|
| [ADC](#adc--add-with-carry) | Add with Carry | A = A + M + C |
| [AND](#and--and-accumulator-with-memory) | AND Memory | A = A & M |
| [ASL](#asl--arithmetic-shift-left) | Arithmetic Shift Left | Shift left, bit 7/15 -> C |
| [BCC](#bcc--branch-if-carry-clear) | Branch if Carry Clear | Branch if C=0 |
| [BCS](#bcs--branch-if-carry-set) | Branch if Carry Set | Branch if C=1 |
| [BEQ](#beq--branch-if-equal) | Branch if Equal | Branch if Z=1 |
| [BIT](#bit--test-bits) | Test Bits | Test A & M, set flags |
| [BMI](#bmi--branch-if-minus) | Branch if Minus | Branch if N=1 |
| [BNE](#bne--branch-if-not-equal) | Branch if Not Equal | Branch if Z=0 |
| [BPL](#bpl--branch-if-plus) | Branch if Plus | Branch if N=0 |
| [BRA](#bra--branch-always) | Branch Always | Unconditional short branch |
| [BRK](#brk--software-break) | Software Break | Software interrupt |
| [BRL](#brl--branch-long-always) | Branch Long Always | Unconditional 16-bit branch |
| [BVC](#bvc--branch-if-overflow-clear) | Branch if Overflow Clear | Branch if V=0 |
| [BVS](#bvs--branch-if-overflow-set) | Branch if Overflow Set | Branch if V=1 |
| [CLC](#clc--clear-carry) | Clear Carry | C = 0 |
| [CLD](#cld--clear-decimal-mode) | Clear Decimal Mode | D = 0 |
| [CLI](#cli--clear-interrupt-disable) | Clear Interrupt Disable | I = 0 |
| [CLV](#clv--clear-overflow) | Clear Overflow | V = 0 |
| [CMP](#cmp--compare-accumulator) | Compare Accumulator | A - M, set flags |
| [COP](#cop--coprocessor-software-interrupt) | Coprocessor Interrupt | Software interrupt (coprocessor vector) |
| [CPX](#cpx--compare-x-register) | Compare X | X - M, set flags |
| [CPY](#cpy--compare-y-register) | Compare Y | Y - M, set flags |
| [DEC](#dec--decrement) | Decrement | M or A = M - 1 |
| [DEX](#dex--decrement-x) | Decrement X | X = X - 1 |
| [DEY](#dey--decrement-y) | Decrement Y | Y = Y - 1 |
| [EOR](#eor--exclusive-or-accumulator-with-memory) | Exclusive OR | A = A ^ M |
| [INC](#inc--increment) | Increment | M or A = M + 1 |
| [INX](#inx--increment-x) | Increment X | X = X + 1 |
| [INY](#iny--increment-y) | Increment Y | Y = Y + 1 |
| [JML](#jml--jump-long) | Jump Long | Jump, 24-bit address |
| [JMP](#jmp--jump) | Jump | Jump within bank |
| [JSL](#jsl--jump-to-subroutine-long) | Jump Subroutine Long | Call, 24-bit address |
| [JSR](#jsr--jump-to-subroutine) | Jump Subroutine | Call within bank |
| [LDA](#lda--load-accumulator) | Load Accumulator | A = M |
| [LDX](#ldx--load-x-register) | Load X | X = M |
| [LDY](#ldy--load-y-register) | Load Y | Y = M |
| [LSR](#lsr--logical-shift-right) | Logical Shift Right | Shift right, bit 0 -> C |
| [MVN](#mvn--block-move-negative) | Block Move Negative | Copy block, incrementing |
| [MVP](#mvp--block-move-positive) | Block Move Positive | Copy block, decrementing |
| [NOP](#nop--no-operation) | No Operation | Does nothing |
| [ORA](#ora--or-accumulator-with-memory) | OR Accumulator | A = A \| M |
| [PEA](#pea--push-effective-address) | Push Effective Address | Push immediate 16-bit value |
| [PEI](#pei--push-effective-indirect-address) | Push Effective Indirect Addr | Push word from dp pointer |
| [PER](#per--push-effective-relative-address) | Push Effective Relative Addr | Push PC-relative address |
| [PHA](#pha--push-accumulator) | Push Accumulator | Push A |
| [PHB](#phb--push-data-bank-register) | Push Data Bank | Push DBR |
| [PHD](#phd--push-direct-page-register) | Push Direct Page | Push D |
| [PHK](#phk--push-program-bank-register) | Push Program Bank | Push PBR |
| [PHP](#php--push-processor-status) | Push Processor Status | Push flags |
| [PHX](#phx--push-x-register) | Push X | Push X |
| [PHY](#phy--push-y-register) | Push Y | Push Y |
| [PLA](#pla--pull-accumulator) | Pull Accumulator | Pull A |
| [PLB](#plb--pull-data-bank-register) | Pull Data Bank | Pull DBR |
| [PLD](#pld--pull-direct-page-register) | Pull Direct Page | Pull D |
| [PLP](#plp--pull-processor-status) | Pull Processor Status | Pull flags |
| [PLX](#plx--pull-x-register) | Pull X | Pull X |
| [PLY](#ply--pull-y-register) | Pull Y | Pull Y |
| [REP](#rep--reset-processor-status-bits) | Reset Status Bits | Clear flag bits |
| [ROL](#rol--rotate-left) | Rotate Left | Rotate left through C |
| [ROR](#ror--rotate-right) | Rotate Right | Rotate right through C |
| [RTI](#rti--return-from-interrupt) | Return from Interrupt | Return, restore flags |
| [RTL](#rtl--return-from-subroutine-long) | Return from Subroutine Long | Return, 24-bit |
| [RTS](#rts--return-from-subroutine) | Return from Subroutine | Return within bank |
| [SBC](#sbc--subtract-with-borrow) | Subtract with Borrow | A = A - M - ~C |
| [SEC](#sec--set-carry) | Set Carry | C = 1 |
| [SED](#sed--set-decimal-mode) | Set Decimal Mode | D = 1 |
| [SEI](#sei--set-interrupt-disable) | Set Interrupt Disable | I = 1 |
| [SEP](#sep--set-processor-status-bits) | Set Status Bits | Set flag bits |
| [STA](#sta--store-accumulator) | Store Accumulator | M = A |
| [STP](#stp--stop-the-clock) | Stop the Clock | Halt until reset |
| [STX](#stx--store-x-register) | Store X | M = X |
| [STY](#sty--store-y-register) | Store Y | M = Y |
| [STZ](#stz--store-zero) | Store Zero | M = 0 |
| [TAX](#tax--transfer-a-to-x) | Transfer A to X | X = A |
| [TAY](#tay--transfer-a-to-y) | Transfer A to Y | Y = A |
| [TCD](#tcd--transfer-c-to-direct-page-register) | Transfer C to Direct Page | D = C (16-bit A) |
| [TCS](#tcs--transfer-c-to-stack-pointer) | Transfer C to Stack Pointer | S = C (16-bit A) |
| [TDC](#tdc--transfer-direct-page-register-to-c) | Transfer Direct Page to C | C = D |
| [TRB](#trb--test-and-reset-bits) | Test and Reset Bits | Clear bits in M using A as mask |
| [TSB](#tsb--test-and-set-bits) | Test and Set Bits | Set bits in M using A as mask |
| [TSC](#tsc--transfer-stack-pointer-to-c) | Transfer Stack Pointer to C | C = S |
| [TSX](#tsx--transfer-stack-pointer-to-x) | Transfer Stack Pointer to X | X = S |
| [TXA](#txa--transfer-x-to-a) | Transfer X to A | A = X |
| [TXS](#txs--transfer-x-to-stack-pointer) | Transfer X to Stack Pointer | S = X |
| [TXY](#txy--transfer-x-to-y) | Transfer X to Y | Y = X |
| [TYA](#tya--transfer-y-to-a) | Transfer Y to A | A = Y |
| [TYX](#tyx--transfer-y-to-x) | Transfer Y to X | X = Y |
| [WAI](#wai--wait-for-interrupt) | Wait for Interrupt | Halt until interrupt |
| [WDM](#wdm--reserved-william-d-mensch-instruction) | Reserved | Reserved for future expansion |
| [XBA](#xba--exchange-b-and-a) | Exchange B and A | Swap A's two bytes |
| [XCE](#xce--exchange-carry-and-emulation-bits) | Exchange Carry and Emulation | Swap C and E (mode switch) |

---

## ADC — Add with Carry

**Function:** `A = A + M + C`. Honors the D (decimal) flag for BCD math.
**Flags:** N, V, Z, C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `ADC #const` | `$69` | 2 (3 if M=0) |
| Direct Page | `ADC dp` | `$65` | 2 |
| Absolute | `ADC addr` | `$6D` | 3 |
| Absolute Long | `ADC long` | `$6F` | 4 |
| DP Indexed,X | `ADC dp,X` | `$75` | 2 |
| Absolute,X | `ADC addr,X` | `$7D` | 3 |
| Absolute,Y | `ADC addr,Y` | `$79` | 3 |
| Long,X | `ADC long,X` | `$7F` | 4 |
| (DP,X) | `ADC (dp,X)` | `$61` | 2 |
| (DP),Y | `ADC (dp),Y` | `$71` | 2 |
| (DP) | `ADC (dp)` | `$72` | 2 |
| [DP] | `ADC [dp]` | `$67` | 2 |
| [DP],Y | `ADC [dp],Y` | `$77` | 2 |
| Stack Relative | `ADC sr,S` | `$63` | 2 |
| (SR,S),Y | `ADC (sr,S),Y` | `$73` | 2 |

**Example:**
```asm
    CLC             ; clear carry before a fresh add
    LDA #$10
    ADC #$05        ; A = $15
```
[Back to top](#table-of-contents)

## AND — AND Accumulator with Memory

**Function:** `A = A & M`
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `AND #const` | `$29` | 2 (3 if M=0) |
| Direct Page | `AND dp` | `$25` | 2 |
| Absolute | `AND addr` | `$2D` | 3 |
| Absolute Long | `AND long` | `$2F` | 4 |
| DP Indexed,X | `AND dp,X` | `$35` | 2 |
| Absolute,X | `AND addr,X` | `$3D` | 3 |
| Absolute,Y | `AND addr,Y` | `$39` | 3 |
| Long,X | `AND long,X` | `$3F` | 4 |
| (DP,X) | `AND (dp,X)` | `$21` | 2 |
| (DP),Y | `AND (dp),Y` | `$31` | 2 |
| (DP) | `AND (dp)` | `$32` | 2 |
| [DP] | `AND [dp]` | `$27` | 2 |
| [DP],Y | `AND [dp],Y` | `$37` | 2 |
| Stack Relative | `AND sr,S` | `$23` | 2 |
| (SR,S),Y | `AND (sr,S),Y` | `$33` | 2 |

**Example:**
```asm
    LDA #$FF
    AND #$0F        ; A = $0F, mask off high nibble
```
[Back to top](#table-of-contents)

## ASL — Arithmetic Shift Left

**Function:** Shifts memory or A left one bit; bit 7 (or 15) moves into carry, 0 fills bit 0.
**Flags:** N, Z, C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Accumulator | `ASL A` | `$0A` | 1 |
| Direct Page | `ASL dp` | `$06` | 2 |
| Absolute | `ASL addr` | `$0E` | 3 |
| DP Indexed,X | `ASL dp,X` | `$16` | 2 |
| Absolute,X | `ASL addr,X` | `$1E` | 3 |

**Example:**
```asm
    LDA #$40
    ASL A           ; A = $80, C = 0
```
[Back to top](#table-of-contents)

## BCC — Branch if Carry Clear

**Function:** Branches (short, PC-relative) if C=0.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative | `BCC label` | `$90` | 2 |

**Example:**
```asm
    CMP #$10
    BCC below       ; branch taken if A < $10
```
[Back to top](#table-of-contents)

## BCS — Branch if Carry Set

**Function:** Branches (short, PC-relative) if C=1.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative | `BCS label` | `$B0` | 2 |

**Example:**
```asm
    CMP #$10
    BCS not_less    ; branch taken if A >= $10
```
[Back to top](#table-of-contents)

## BEQ — Branch if Equal

**Function:** Branches if Z=1 (typically after a CMP that found equality, or a result of zero).
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative | `BEQ label` | `$F0` | 2 |

**Example:**
```asm
    CMP #$00
    BEQ is_zero
```
[Back to top](#table-of-contents)

## BIT — Test Bits

**Function:** Computes `A & M` to set Z, and (for non-immediate modes) copies M's bit 7 into N and bit 6 into V, without altering A.
**Flags:** N, V, Z (immediate mode only sets Z)

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `BIT #const` | `$89` | 2 (3 if M=0) |
| Direct Page | `BIT dp` | `$24` | 2 |
| Absolute | `BIT addr` | `$2C` | 3 |
| DP Indexed,X | `BIT dp,X` | `$34` | 2 |
| Absolute,X | `BIT addr,X` | `$3C` | 3 |

**Example:**
```asm
    LDA status_reg
    BIT #%00000001  ; test bit 0 without modifying A
    BEQ bit_clear
```
[Back to top](#table-of-contents)

## BMI — Branch if Minus

**Function:** Branches if N=1 (result's sign bit set).
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative | `BMI label` | `$30` | 2 |

**Example:**
```asm
    LDA counter
    BMI negative
```
[Back to top](#table-of-contents)

## BNE — Branch if Not Equal

**Function:** Branches if Z=0.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative | `BNE label` | `$D0` | 2 |

**Example:**
```asm
    DEX
    BNE loop        ; classic countdown loop
```
[Back to top](#table-of-contents)

## BPL — Branch if Plus

**Function:** Branches if N=0.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative | `BPL label` | `$10` | 2 |

**Example:**
```asm
    LDA counter
    BPL positive
```
[Back to top](#table-of-contents)

## BRA — Branch Always

**Function:** Unconditional short (PC-relative, +/-127 byte range) branch. 65C816/65C02 addition over base 6502.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative | `BRA label` | `$80` | 2 |

**Example:**
```asm
    BRA skip
    NOP             ; never executed
skip:
    RTS
```
[Back to top](#table-of-contents)

## BRK — Software Break

**Function:** Software interrupt. Pushes PC+2 and status, sets I, jumps through the BRK/IRQ vector. In native mode also pushes PBR and uses the dedicated native BRK vector.
**Flags:** I set; D cleared on 65C816 (unlike base 6502)

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack/Interrupt | `BRK` | `$00` | 2 (signature byte follows, often used as a debug id) |

**Example:**
```asm
    BRK $01         ; trigger software interrupt with signature $01
```
[Back to top](#table-of-contents)

## BRL — Branch Long Always

**Function:** Unconditional branch with a 16-bit signed PC-relative displacement, reaching anywhere in the current bank.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative Long | `BRL label` | `$82` | 3 |

**Example:**
```asm
    BRL far_away    ; can jump further than BRA's +/-127 bytes
```
[Back to top](#table-of-contents)

## BVC — Branch if Overflow Clear

**Function:** Branches if V=0.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative | `BVC label` | `$50` | 2 |

**Example:**
```asm
    ADC #$01
    BVC no_overflow
```
[Back to top](#table-of-contents)

## BVS — Branch if Overflow Set

**Function:** Branches if V=1.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative | `BVS label` | `$70` | 2 |

**Example:**
```asm
    ADC #$01
    BVS overflowed
```
[Back to top](#table-of-contents)

## CLC — Clear Carry

**Function:** `C = 0`. Standard prerequisite before ADC.
**Flags:** C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `CLC` | `$18` | 1 |

**Example:**
```asm
    CLC
    ADC #$01
```
[Back to top](#table-of-contents)

## CLD — Clear Decimal Mode

**Function:** `D = 0`. Switches ADC/SBC back to binary math.
**Flags:** D

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `CLD` | `$D8` | 1 |

**Example:**
```asm
    CLD             ; make sure we're in binary mode, not BCD
```
[Back to top](#table-of-contents)

## CLI — Clear Interrupt Disable

**Function:** `I = 0`. Allows IRQs to be recognized.
**Flags:** I

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `CLI` | `$58` | 1 |

**Example:**
```asm
    CLI             ; enable IRQ handling after setting up vectors
```
[Back to top](#table-of-contents)

## CLV — Clear Overflow

**Function:** `V = 0`.
**Flags:** V

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `CLV` | `$B8` | 1 |

**Example:**
```asm
    CLV
```
[Back to top](#table-of-contents)

## CMP — Compare Accumulator

**Function:** Computes `A - M` (discarding the result) and sets flags: C=1 if A>=M, Z=1 if A=M, N reflects the sign of the difference.
**Flags:** N, Z, C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `CMP #const` | `$C9` | 2 (3 if M=0) |
| Direct Page | `CMP dp` | `$C5` | 2 |
| Absolute | `CMP addr` | `$CD` | 3 |
| Absolute Long | `CMP long` | `$CF` | 4 |
| DP Indexed,X | `CMP dp,X` | `$D5` | 2 |
| Absolute,X | `CMP addr,X` | `$DD` | 3 |
| Absolute,Y | `CMP addr,Y` | `$D9` | 3 |
| Long,X | `CMP long,X` | `$DF` | 4 |
| (DP,X) | `CMP (dp,X)` | `$C1` | 2 |
| (DP),Y | `CMP (dp),Y` | `$D1` | 2 |
| (DP) | `CMP (dp)` | `$D2` | 2 |
| [DP] | `CMP [dp]` | `$C7` | 2 |
| [DP],Y | `CMP [dp],Y` | `$D7` | 2 |
| Stack Relative | `CMP sr,S` | `$C3` | 2 |
| (SR,S),Y | `CMP (sr,S),Y` | `$D3` | 2 |

**Example:**
```asm
    LDA input_char
    CMP #'A'
    BEQ got_a
```
[Back to top](#table-of-contents)

## COP — Coprocessor Software Interrupt

**Function:** Like BRK, but vectors through the dedicated COP vector. Intended for coprocessor call-outs.
**Flags:** I set

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack/Interrupt | `COP #const` | `$02` | 2 |

**Example:**
```asm
    COP $00         ; invoke coprocessor handler with signature $00
```
[Back to top](#table-of-contents)

## CPX — Compare X Register

**Function:** `X - M`, sets flags. Width follows the X flag.
**Flags:** N, Z, C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `CPX #const` | `$E0` | 2 (3 if X=0) |
| Direct Page | `CPX dp` | `$E4` | 2 |
| Absolute | `CPX addr` | `$EC` | 3 |

**Example:**
```asm
    CPX #$08
    BEQ loop_done
```
[Back to top](#table-of-contents)

## CPY — Compare Y Register

**Function:** `Y - M`, sets flags. Width follows the X flag.
**Flags:** N, Z, C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `CPY #const` | `$C0` | 2 (3 if X=0) |
| Direct Page | `CPY dp` | `$C4` | 2 |
| Absolute | `CPY addr` | `$CC` | 3 |

**Example:**
```asm
    CPY #$00
    BEQ y_is_zero
```
[Back to top](#table-of-contents)

## DEC — Decrement

**Function:** `M = M - 1` (or `A = A - 1` in accumulator mode).
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Accumulator | `DEC A` | `$3A` | 1 |
| Direct Page | `DEC dp` | `$C6` | 2 |
| Absolute | `DEC addr` | `$CE` | 3 |
| DP Indexed,X | `DEC dp,X` | `$D6` | 2 |
| Absolute,X | `DEC addr,X` | `$DE` | 3 |

**Example:**
```asm
    DEC A           ; A = A - 1
```
[Back to top](#table-of-contents)

## DEX — Decrement X

**Function:** `X = X - 1`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `DEX` | `$CA` | 1 |

**Example:**
```asm
    LDX #$10
loop:
    DEX
    BNE loop
```
[Back to top](#table-of-contents)

## DEY — Decrement Y

**Function:** `Y = Y - 1`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `DEY` | `$88` | 1 |

**Example:**
```asm
    DEY
```
[Back to top](#table-of-contents)

## EOR — Exclusive OR Accumulator with Memory

**Function:** `A = A ^ M`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `EOR #const` | `$49` | 2 (3 if M=0) |
| Direct Page | `EOR dp` | `$45` | 2 |
| Absolute | `EOR addr` | `$4D` | 3 |
| Absolute Long | `EOR long` | `$4F` | 4 |
| DP Indexed,X | `EOR dp,X` | `$55` | 2 |
| Absolute,X | `EOR addr,X` | `$5D` | 3 |
| Absolute,Y | `EOR addr,Y` | `$59` | 3 |
| Long,X | `EOR long,X` | `$5F` | 4 |
| (DP,X) | `EOR (dp,X)` | `$41` | 2 |
| (DP),Y | `EOR (dp),Y` | `$51` | 2 |
| (DP) | `EOR (dp)` | `$52` | 2 |
| [DP] | `EOR [dp]` | `$47` | 2 |
| [DP],Y | `EOR [dp],Y` | `$57` | 2 |
| Stack Relative | `EOR sr,S` | `$43` | 2 |
| (SR,S),Y | `EOR (sr,S),Y` | `$53` | 2 |

**Example:**
```asm
    LDA #%11110000
    EOR #%11111111  ; A = %00001111, a bitwise NOT trick
```
[Back to top](#table-of-contents)

## INC — Increment

**Function:** `M = M + 1` (or `A = A + 1`).
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Accumulator | `INC A` | `$1A` | 1 |
| Direct Page | `INC dp` | `$E6` | 2 |
| Absolute | `INC addr` | `$EE` | 3 |
| DP Indexed,X | `INC dp,X` | `$F6` | 2 |
| Absolute,X | `INC addr,X` | `$FE` | 3 |

**Example:**
```asm
    INC A           ; A = A + 1
```
[Back to top](#table-of-contents)

## INX — Increment X

**Function:** `X = X + 1`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `INX` | `$E8` | 1 |

**Example:**
```asm
    INX
```
[Back to top](#table-of-contents)

## INY — Increment Y

**Function:** `Y = Y + 1`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `INY` | `$C8` | 1 |

**Example:**
```asm
    INY
```
[Back to top](#table-of-contents)

## JML — Jump Long

**Function:** Jump to a 24-bit address, changing the program bank register (PBR). Assemblers typically emit this for `JMP [addr]` (indirect long) or `JML long`.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Absolute Long | `JML long` | `$5C` | 4 |
| Absolute Indirect Long | `JML [addr]` | `$DC` | 3 |

**Example:**
```asm
    JML $018000     ; jump to bank $01, address $8000
```
[Back to top](#table-of-contents)

## JMP — Jump

**Function:** Unconditional jump within (or, via long forms, across) banks.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Absolute | `JMP addr` | `$4C` | 3 |
| Absolute Indirect | `JMP (addr)` | `$6C` | 3 |
| Absolute Indexed Indirect | `JMP (addr,X)` | `$7C` | 3 |
| Absolute Long | `JMP long` | `$5C` | 4 |
| Absolute Indirect Long | `JMP [addr]` | `$DC` | 3 |

**Example:**
```asm
    JMP main_loop
```
[Back to top](#table-of-contents)

## JSL — Jump to Subroutine Long

**Function:** Calls a subroutine in another bank. Pushes PBR and the 16-bit return address; must be paired with RTL.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Absolute Long | `JSL long` | `$22` | 4 |

**Example:**
```asm
    JSL $028000     ; call a routine living in bank $02
```
[Back to top](#table-of-contents)

## JSR — Jump to Subroutine

**Function:** Calls a subroutine within the current bank. Pushes the 16-bit return address; must be paired with RTS.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Absolute | `JSR addr` | `$20` | 3 |
| Absolute Indexed Indirect | `JSR (addr,X)` | `$FC` | 3 |

**Example:**
```asm
    JSR init_video
```
[Back to top](#table-of-contents)

## LDA — Load Accumulator

**Function:** `A = M`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `LDA #const` | `$A9` | 2 (3 if M=0) |
| Direct Page | `LDA dp` | `$A5` | 2 |
| Absolute | `LDA addr` | `$AD` | 3 |
| Absolute Long | `LDA long` | `$AF` | 4 |
| DP Indexed,X | `LDA dp,X` | `$B5` | 2 |
| Absolute,X | `LDA addr,X` | `$BD` | 3 |
| Absolute,Y | `LDA addr,Y` | `$B9` | 3 |
| Long,X | `LDA long,X` | `$BF` | 4 |
| (DP,X) | `LDA (dp,X)` | `$A1` | 2 |
| (DP),Y | `LDA (dp),Y` | `$B1` | 2 |
| (DP) | `LDA (dp)` | `$B2` | 2 |
| [DP] | `LDA [dp]` | `$A7` | 2 |
| [DP],Y | `LDA [dp],Y` | `$B7` | 2 |
| Stack Relative | `LDA sr,S` | `$A3` | 2 |
| (SR,S),Y | `LDA (sr,S),Y` | `$B3` | 2 |

**Example:**
```asm
    LDA #$42        ; A = $42
```
[Back to top](#table-of-contents)

## LDX — Load X Register

**Function:** `X = M`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `LDX #const` | `$A2` | 2 (3 if X=0) |
| Direct Page | `LDX dp` | `$A6` | 2 |
| Absolute | `LDX addr` | `$AE` | 3 |
| DP Indexed,Y | `LDX dp,Y` | `$B6` | 2 |
| Absolute,Y | `LDX addr,Y` | `$BE` | 3 |

**Example:**
```asm
    LDX #$00
```
[Back to top](#table-of-contents)

## LDY — Load Y Register

**Function:** `Y = M`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `LDY #const` | `$A0` | 2 (3 if X=0) |
| Direct Page | `LDY dp` | `$A4` | 2 |
| Absolute | `LDY addr` | `$AC` | 3 |
| DP Indexed,X | `LDY dp,X` | `$B4` | 2 |
| Absolute,X | `LDY addr,X` | `$BC` | 3 |

**Example:**
```asm
    LDY #$00
```
[Back to top](#table-of-contents)

## LSR — Logical Shift Right

**Function:** Shifts memory or A right one bit; bit 0 moves into carry, 0 fills the top bit.
**Flags:** N (always cleared), Z, C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Accumulator | `LSR A` | `$4A` | 1 |
| Direct Page | `LSR dp` | `$46` | 2 |
| Absolute | `LSR addr` | `$4E` | 3 |
| DP Indexed,X | `LSR dp,X` | `$56` | 2 |
| Absolute,X | `LSR addr,X` | `$5E` | 3 |

**Example:**
```asm
    LDA #$02
    LSR A           ; A = $01, C = 0
```
[Back to top](#table-of-contents)

## MVN — Block Move Negative

**Function:** Copies a block of memory from source bank to destination bank, incrementing X, Y, and decrementing the byte counter in A (16-bit) after each byte. Used for moving blocks upward in memory (low to high address).
**Flags:** none (except A/X/Y are updated)

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Block Move | `MVN dest,src` | `$54` | 3 |

**Example:**
```asm
    ; copy (A+1) bytes from bank $7E:X to bank $00:Y
    LDA #$00FF      ; 256 bytes to copy (count - 1)
    LDX #$0000      ; source offset
    LDY #$1000      ; destination offset
    MVN $00,$7E     ; dest bank $00, src bank $7E
```
[Back to top](#table-of-contents)

## MVP — Block Move Positive

**Function:** Same as MVN but decrements X and Y after each byte -- used for overlapping moves where the destination is higher than the source (copy from the end backward).
**Flags:** none (except A/X/Y are updated)

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Block Move | `MVP dest,src` | `$44` | 3 |

**Example:**
```asm
    LDA #$00FF
    LDX #$10FF      ; source end offset
    LDY #$20FF      ; destination end offset
    MVP $00,$00     ; same-bank overlapping move, backward
```
[Back to top](#table-of-contents)

## NOP — No Operation

**Function:** Does nothing except consume a cycle. Useful for timing padding or patching out code.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `NOP` | `$EA` | 1 |

**Example:**
```asm
    NOP
```
[Back to top](#table-of-contents)

## ORA — OR Accumulator with Memory

**Function:** `A = A | M`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `ORA #const` | `$09` | 2 (3 if M=0) |
| Direct Page | `ORA dp` | `$05` | 2 |
| Absolute | `ORA addr` | `$0D` | 3 |
| Absolute Long | `ORA long` | `$0F` | 4 |
| DP Indexed,X | `ORA dp,X` | `$15` | 2 |
| Absolute,X | `ORA addr,X` | `$1D` | 3 |
| Absolute,Y | `ORA addr,Y` | `$19` | 3 |
| Long,X | `ORA long,X` | `$1F` | 4 |
| (DP,X) | `ORA (dp,X)` | `$01` | 2 |
| (DP),Y | `ORA (dp),Y` | `$11` | 2 |
| (DP) | `ORA (dp)` | `$12` | 2 |
| [DP] | `ORA [dp]` | `$07` | 2 |
| [DP],Y | `ORA [dp],Y` | `$17` | 2 |
| Stack Relative | `ORA sr,S` | `$03` | 2 |
| (SR,S),Y | `ORA (sr,S),Y` | `$13` | 2 |

**Example:**
```asm
    LDA #%00001111
    ORA #%11110000  ; A = %11111111
```
[Back to top](#table-of-contents)

## PEA — Push Effective Address

**Function:** Pushes an immediate 16-bit value onto the stack. Useful for setting up a "return address" for RTL, or passing constants to subroutines.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate/Stack | `PEA addr` | `$F4` | 3 |

**Example:**
```asm
    PEA $1234       ; push the literal value $1234
```
[Back to top](#table-of-contents)

## PEI — Push Effective Indirect Address

**Function:** Pushes the 16-bit word stored at a direct-page pointer.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| DP Indirect/Stack | `PEI (dp)` | `$D4` | 2 |

**Example:**
```asm
    PEI ($10)       ; push the word pointed to by dp $10
```
[Back to top](#table-of-contents)

## PER — Push Effective Relative Address

**Function:** Computes `PC + displacement` and pushes the 16-bit result. Used for position-independent code and setting up jump tables.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Relative Long/Stack | `PER label` | `$62` | 3 |

**Example:**
```asm
    PER some_label  ; push PC-relative address of some_label
```
[Back to top](#table-of-contents)

## PHA — Push Accumulator

**Function:** Pushes A onto the stack.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PHA` | `$48` | 1 |

**Example:**
```asm
    PHA             ; save A before calling a routine that clobbers it
```
[Back to top](#table-of-contents)

## PHB — Push Data Bank Register

**Function:** Pushes DBR (8 bits) onto the stack.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PHB` | `$8B` | 1 |

**Example:**
```asm
    PHB             ; save current data bank
```
[Back to top](#table-of-contents)

## PHD — Push Direct Page Register

**Function:** Pushes D (16 bits) onto the stack.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PHD` | `$0B` | 1 |

**Example:**
```asm
    PHD             ; save current direct page register
```
[Back to top](#table-of-contents)

## PHK — Push Program Bank Register

**Function:** Pushes PBR (8 bits) onto the stack.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PHK` | `$4B` | 1 |

**Example:**
```asm
    PHK             ; common idiom before PLB to set DBR = PBR
    PLB
```
[Back to top](#table-of-contents)

## PHP — Push Processor Status

**Function:** Pushes the status register (flags byte) onto the stack.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PHP` | `$08` | 1 |

**Example:**
```asm
    PHP             ; save flags before modifying M/X width
```
[Back to top](#table-of-contents)

## PHX — Push X Register

**Function:** Pushes X onto the stack.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PHX` | `$DA` | 1 |

**Example:**
```asm
    PHX
```
[Back to top](#table-of-contents)

## PHY — Push Y Register

**Function:** Pushes Y onto the stack.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PHY` | `$5A` | 1 |

**Example:**
```asm
    PHY
```
[Back to top](#table-of-contents)

## PLA — Pull Accumulator

**Function:** Pulls a value off the stack into A.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PLA` | `$68` | 1 |

**Example:**
```asm
    PLA             ; restore A saved earlier with PHA
```
[Back to top](#table-of-contents)

## PLB — Pull Data Bank Register

**Function:** Pulls a byte off the stack into DBR.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PLB` | `$AB` | 1 |

**Example:**
```asm
    PLB             ; restore data bank register
```
[Back to top](#table-of-contents)

## PLD — Pull Direct Page Register

**Function:** Pulls a word off the stack into D.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PLD` | `$2B` | 1 |

**Example:**
```asm
    PLD             ; restore direct page register
```
[Back to top](#table-of-contents)

## PLP — Pull Processor Status

**Function:** Pulls a byte off the stack into the status register.
**Flags:** all (replaced wholesale)

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PLP` | `$28` | 1 |

**Example:**
```asm
    PLP             ; restore flags saved earlier with PHP
```
[Back to top](#table-of-contents)

## PLX — Pull X Register

**Function:** Pulls a value off the stack into X.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PLX` | `$FA` | 1 |

**Example:**
```asm
    PLX
```
[Back to top](#table-of-contents)

## PLY — Pull Y Register

**Function:** Pulls a value off the stack into Y.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `PLY` | `$7A` | 1 |

**Example:**
```asm
    PLY
```
[Back to top](#table-of-contents)

## REP — Reset Processor Status Bits

**Function:** Clears the status-register bits specified by an 8-bit immediate mask (bit=1 means "clear this flag"). The classic way to switch A/X/Y to 16-bit in native mode: `REP #$30` clears M and X.
**Flags:** whichever bits are specified in the mask

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `REP #const` | `$C2` | 2 |

**Example:**
```asm
    REP #$30        ; clear M and X flags -> 16-bit A, X, Y
```
[Back to top](#table-of-contents)

## ROL — Rotate Left

**Function:** Rotates memory or A left through carry: old carry becomes bit 0, old bit 7/15 becomes new carry.
**Flags:** N, Z, C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Accumulator | `ROL A` | `$2A` | 1 |
| Direct Page | `ROL dp` | `$26` | 2 |
| Absolute | `ROL addr` | `$2E` | 3 |
| DP Indexed,X | `ROL dp,X` | `$36` | 2 |
| Absolute,X | `ROL addr,X` | `$3E` | 3 |

**Example:**
```asm
    CLC
    LDA #$80
    ROL A           ; A = $00, C = 1
```
[Back to top](#table-of-contents)

## ROR — Rotate Right

**Function:** Rotates memory or A right through carry: old carry becomes bit 7/15, old bit 0 becomes new carry.
**Flags:** N, Z, C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Accumulator | `ROR A` | `$6A` | 1 |
| Direct Page | `ROR dp` | `$66` | 2 |
| Absolute | `ROR addr` | `$6E` | 3 |
| DP Indexed,X | `ROR dp,X` | `$76` | 2 |
| Absolute,X | `ROR addr,X` | `$7E` | 3 |

**Example:**
```asm
    CLC
    LDA #$01
    ROR A           ; A = $00, C = 1
```
[Back to top](#table-of-contents)

## RTI — Return from Interrupt

**Function:** Pulls flags, PC, and (in native mode) PBR off the stack, resuming execution where the interrupt occurred.
**Flags:** all (restored from stack)

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `RTI` | `$40` | 1 |

**Example:**
```asm
irq_handler:
    PHA
    ; ... handle interrupt ...
    PLA
    RTI
```
[Back to top](#table-of-contents)

## RTL — Return from Subroutine Long

**Function:** Pulls a 24-bit return address (16-bit address + bank) off the stack; pairs with JSL.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `RTL` | `$6B` | 1 |

**Example:**
```asm
far_routine:
    ; ... do work ...
    RTL             ; return to caller in a different bank
```
[Back to top](#table-of-contents)

## RTS — Return from Subroutine

**Function:** Pulls a 16-bit return address off the stack; pairs with JSR.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Stack | `RTS` | `$60` | 1 |

**Example:**
```asm
my_subroutine:
    ; ... do work ...
    RTS
```
[Back to top](#table-of-contents)

## SBC — Subtract with Borrow

**Function:** `A = A - M - (1 - C)`. Honors the D flag for BCD math. Remember to SEC before the first subtraction in a chain.
**Flags:** N, V, Z, C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `SBC #const` | `$E9` | 2 (3 if M=0) |
| Direct Page | `SBC dp` | `$E5` | 2 |
| Absolute | `SBC addr` | `$ED` | 3 |
| Absolute Long | `SBC long` | `$EF` | 4 |
| DP Indexed,X | `SBC dp,X` | `$F5` | 2 |
| Absolute,X | `SBC addr,X` | `$FD` | 3 |
| Absolute,Y | `SBC addr,Y` | `$F9` | 3 |
| Long,X | `SBC long,X` | `$FF` | 4 |
| (DP,X) | `SBC (dp,X)` | `$E1` | 2 |
| (DP),Y | `SBC (dp),Y` | `$F1` | 2 |
| (DP) | `SBC (dp)` | `$F2` | 2 |
| [DP] | `SBC [dp]` | `$E7` | 2 |
| [DP],Y | `SBC [dp],Y` | `$F7` | 2 |
| Stack Relative | `SBC sr,S` | `$E3` | 2 |
| (SR,S),Y | `SBC (sr,S),Y` | `$F3` | 2 |

**Example:**
```asm
    SEC             ; set carry before a fresh subtract
    LDA #$10
    SBC #$05        ; A = $0B
```
[Back to top](#table-of-contents)

## SEC — Set Carry

**Function:** `C = 1`. Standard prerequisite before SBC.
**Flags:** C

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `SEC` | `$38` | 1 |

**Example:**
```asm
    SEC
    SBC #$01
```
[Back to top](#table-of-contents)

## SED — Set Decimal Mode

**Function:** `D = 1`. Switches ADC/SBC to BCD math.
**Flags:** D

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `SED` | `$F8` | 1 |

**Example:**
```asm
    SED             ; enable BCD arithmetic for a decimal counter
```
[Back to top](#table-of-contents)

## SEI — Set Interrupt Disable

**Function:** `I = 1`. Masks IRQs (NMI is unaffected).
**Flags:** I

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `SEI` | `$78` | 1 |

**Example:**
```asm
    SEI             ; disable IRQs during a critical section
```
[Back to top](#table-of-contents)

## SEP — Set Processor Status Bits

**Function:** Sets the status-register bits specified by an 8-bit immediate mask. The classic way to switch A/X/Y to 8-bit: `SEP #$30` sets M and X.
**Flags:** whichever bits are specified in the mask

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Immediate | `SEP #const` | `$E2` | 2 |

**Example:**
```asm
    SEP #$20        ; set M flag -> 8-bit accumulator
```
[Back to top](#table-of-contents)

## STA — Store Accumulator

**Function:** `M = A`.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Direct Page | `STA dp` | `$85` | 2 |
| Absolute | `STA addr` | `$8D` | 3 |
| Absolute Long | `STA long` | `$8F` | 4 |
| DP Indexed,X | `STA dp,X` | `$95` | 2 |
| Absolute,X | `STA addr,X` | `$9D` | 3 |
| Absolute,Y | `STA addr,Y` | `$99` | 3 |
| Long,X | `STA long,X` | `$9F` | 4 |
| (DP,X) | `STA (dp,X)` | `$81` | 2 |
| (DP),Y | `STA (dp),Y` | `$91` | 2 |
| (DP) | `STA (dp)` | `$92` | 2 |
| [DP] | `STA [dp]` | `$87` | 2 |
| [DP],Y | `STA [dp],Y` | `$97` | 2 |
| Stack Relative | `STA sr,S` | `$83` | 2 |
| (SR,S),Y | `STA (sr,S),Y` | `$93` | 2 |

**Example:**
```asm
    LDA #$42
    STA $2000       ; write $42 to address $2000
```
[Back to top](#table-of-contents)

## STP — Stop the Clock

**Function:** Halts the processor entirely until a hardware reset. Lower power draw than WAI, but the only way out is /RESET.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `STP` | `$DB` | 1 |

**Example:**
```asm
    STP             ; halt until reset -- used for fatal error states
```
[Back to top](#table-of-contents)

## STX — Store X Register

**Function:** `M = X`.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Direct Page | `STX dp` | `$86` | 2 |
| Absolute | `STX addr` | `$8E` | 3 |
| DP Indexed,Y | `STX dp,Y` | `$96` | 2 |

**Example:**
```asm
    STX $10         ; store X to direct page address $10
```
[Back to top](#table-of-contents)

## STY — Store Y Register

**Function:** `M = Y`.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Direct Page | `STY dp` | `$84` | 2 |
| Absolute | `STY addr` | `$8C` | 3 |
| DP Indexed,X | `STY dp,X` | `$94` | 2 |

**Example:**
```asm
    STY $12         ; store Y to direct page address $12
```
[Back to top](#table-of-contents)

## STZ — Store Zero

**Function:** `M = 0`. 65C816/65C02 addition -- clears memory without needing A to hold zero first.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Direct Page | `STZ dp` | `$64` | 2 |
| Absolute | `STZ addr` | `$9C` | 3 |
| DP Indexed,X | `STZ dp,X` | `$74` | 2 |
| Absolute,X | `STZ addr,X` | `$9E` | 3 |

**Example:**
```asm
    STZ $2000       ; clear address $2000 to zero
```
[Back to top](#table-of-contents)

## TAX — Transfer A to X

**Function:** `X = A`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TAX` | `$AA` | 1 |

**Example:**
```asm
    LDA #$05
    TAX             ; X = $05
```
[Back to top](#table-of-contents)

## TAY — Transfer A to Y

**Function:** `Y = A`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TAY` | `$A8` | 1 |

**Example:**
```asm
    LDA #$05
    TAY             ; Y = $05
```
[Back to top](#table-of-contents)

## TCD — Transfer C to Direct Page Register

**Function:** `D = C` (the full 16-bit accumulator, regardless of M flag). Used to relocate the direct page.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TCD` | `$5B` | 1 |

**Example:**
```asm
    LDA #$2000
    TCD             ; direct page now starts at $2000
```
[Back to top](#table-of-contents)

## TCS — Transfer C to Stack Pointer

**Function:** `S = C` (full 16-bit accumulator). Used to set up the stack pointer, e.g. during a reset handler.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TCS` | `$1B` | 1 |

**Example:**
```asm
    LDA #$1FFF
    TCS             ; set stack pointer to $1FFF
```
[Back to top](#table-of-contents)

## TDC — Transfer Direct Page Register to C

**Function:** `C = D` (full 16-bit accumulator).
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TDC` | `$7B` | 1 |

**Example:**
```asm
    TDC             ; read current direct page value into A
```
[Back to top](#table-of-contents)

## TRB — Test and Reset Bits

**Function:** `Z = (A & M == 0)`, then `M = M & ~A` (clears the bits in M that are set in A), without changing A.
**Flags:** Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Direct Page | `TRB dp` | `$14` | 2 |
| Absolute | `TRB addr` | `$1C` | 3 |

**Example:**
```asm
    LDA #%00000001
    TRB flags_byte  ; clear bit 0 of flags_byte, test old value
```
[Back to top](#table-of-contents)

## TSB — Test and Set Bits

**Function:** `Z = (A & M == 0)`, then `M = M | A` (sets the bits in M that are set in A), without changing A.
**Flags:** Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Direct Page | `TSB dp` | `$04` | 2 |
| Absolute | `TSB addr` | `$0C` | 3 |

**Example:**
```asm
    LDA #%00000001
    TSB flags_byte  ; set bit 0 of flags_byte, test old value
```
[Back to top](#table-of-contents)

## TSC — Transfer Stack Pointer to C

**Function:** `C = S` (full 16-bit accumulator).
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TSC` | `$3B` | 1 |

**Example:**
```asm
    TSC             ; read current stack pointer into A
```
[Back to top](#table-of-contents)

## TSX — Transfer Stack Pointer to X

**Function:** `X = S`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TSX` | `$BA` | 1 |

**Example:**
```asm
    TSX             ; X now holds the current stack pointer value
```
[Back to top](#table-of-contents)

## TXA — Transfer X to A

**Function:** `A = X`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TXA` | `$8A` | 1 |

**Example:**
```asm
    TXA
```
[Back to top](#table-of-contents)

## TXS — Transfer X to Stack Pointer

**Function:** `S = X`.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TXS` | `$9A` | 1 |

**Example:**
```asm
    LDX #$1FFF
    TXS             ; set stack pointer via X
```
[Back to top](#table-of-contents)

## TXY — Transfer X to Y

**Function:** `Y = X`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TXY` | `$9B` | 1 |

**Example:**
```asm
    TXY
```
[Back to top](#table-of-contents)

## TYA — Transfer Y to A

**Function:** `A = Y`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TYA` | `$98` | 1 |

**Example:**
```asm
    TYA
```
[Back to top](#table-of-contents)

## TYX — Transfer Y to X

**Function:** `X = Y`.
**Flags:** N, Z

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `TYX` | `$BB` | 1 |

**Example:**
```asm
    TYX
```
[Back to top](#table-of-contents)

## WAI — Wait for Interrupt

**Function:** Suspends the CPU in a low-activity state until an interrupt (IRQ or NMI) occurs, then resumes at the instruction after WAI (after servicing the interrupt if unmasked).
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `WAI` | `$CB` | 1 |

**Example:**
```asm
main_loop:
    WAI             ; sleep the CPU until the next vblank IRQ
    JSR handle_frame
    BRA main_loop
```
[Back to top](#table-of-contents)

## WDM — Reserved (William D. Mensch instruction)

**Function:** Reserved for future expansion by WDC. Currently acts as a 2-byte NOP on real silicon, but should not be relied upon -- future chip revisions could assign it real behavior.
**Flags:** none

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Reserved | `WDM #const` | `$42` | 2 |

**Example:**
```asm
    ; Avoid using WDM in production code -- shown here for
    ; completeness only, since it appears in the opcode map.
    WDM $00
```
[Back to top](#table-of-contents)

## XBA — Exchange B and A

**Function:** Swaps the high and low bytes of the 16-bit accumulator (A <-> B, where B is the accumulator's normally-hidden high byte). Handy for byte-wise access to a 16-bit value.
**Flags:** N, Z (based on the new low byte)

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `XBA` | `$EB` | 1 |

**Example:**
```asm
    LDA #$1234
    XBA             ; A = $3412 (low/high bytes swapped)
```
[Back to top](#table-of-contents)

## XCE — Exchange Carry and Emulation Bits

**Function:** Swaps the Carry flag with the Emulation (E) flag. This is *the* mode-switch instruction: setting/clearing C then executing XCE moves the CPU between Emulation mode (6502-compatible) and Native mode.
**Flags:** C, E (swapped)

| Mode | Syntax | Opcode | Bytes |
|---|---|---|---|
| Implied | `XCE` | `$FB` | 1 |

**Example:**
```asm
    CLC             ; C = 0
    XCE             ; E = 0 -> enter Native mode
```
[Back to top](#table-of-contents)

---

## Sources and Further Reading

This reference was compiled from well-established 65C816 documentation
and cross-checked against the standard opcode map. For anything
safety-critical (timing analysis, exact cycle counts for wait-state
budgeting, or the full addressing-mode cycle penalty rules), verify
against the primary source:

- **W65C816S Datasheet** (Western Design Center) -- the authoritative
  reference for opcode encoding, cycle timing, and electrical
  characteristics.
- **Programming the 65816** by David Eyes and Ron Lichty -- excellent
  prose explanation of addressing modes and the M/X flag interactions.
- **Eyes & Lichty's opcode tables** and the **65816 Opcodes** page at
  wilsonminesco.com are good secondary cross-checks if you spot a
  discrepancy here.

If you find an error in this reference while coding against real
hardware, that's a good sign you're reading the datasheet's timing
diagrams carefully -- which is exactly the skill this reference is
meant to support, not replace.

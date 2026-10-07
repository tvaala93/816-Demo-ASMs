; =============================================================================
; thru_defs.inc -- shared constants for code using the through-hole computer
; (ASCII only. Edit ACIA_BASE / VIA_BASE here if your PLD map differs.)
;
; Board facts only. Per-driver constants live in lcd.inc / ps2KB.inc, and
; RAM for drivers is assigned by the linker (see rom.cfg), not by this file.
; =============================================================================

;------------------------------------------------------------------------------
; --- W65C22N VIA: 16-bit absolute addressing, uses Data Bank Register (=0) ---
;------------------------------------------------------------------------------
VIA_BASE = $4000
PORTB    = VIA_BASE + 0
PORTA    = VIA_BASE + 1
DDRB     = VIA_BASE + 2 ; Data Direction Register
DDRA     = VIA_BASE + 3
T1CL     = VIA_BASE + 4
T1CH     = VIA_BASE + 5
T1LL     = VIA_BASE + 6
T1LH     = VIA_BASE + 7
T2CL     = VIA_BASE + 8
T2CH     = VIA_BASE + 9
VIA_SR   = VIA_BASE + $A ; Shfit Register
ACR      = VIA_BASE + $B ; Auxilliary Control Register
PCR      = VIA_BASE + $C ; Peripheral Control Register
IFR      = VIA_BASE + $D ; Interrupt Flag Register
IER      = VIA_BASE + $E ; Interrupt Enable Register

;------------------------------------------------------------------------------
; --- W65C51N ACIA: value > $FFFF, so ca65 emits 24-bit LONG addressing ---
;------------------------------------------------------------------------------
ACIA_BASE   = $014000
ACIA_DATA   = ACIA_BASE + 0     ; RS1:RS0 = 00  (A1:A0)
ACIA_STATUS = ACIA_BASE + 1     ;           01  read = status, write = prog rst
ACIA_CMD    = ACIA_BASE + 2     ;           10
ACIA_CTRL   = ACIA_BASE + 3     ;           11

; --- ACIA status register bits ---
ST_IRQ  = %10000000             ; Interrupt requested
ST_RDRF = %00001000             ; Reciever Data Register Full bit
ST_OVRN = %00000100             ; overrun bit
ST_FE   = %00000010             ; frame error bit
ST_PE   = %00000001             ; parity error bit

; --- ACIA control register bits ---
; CTRL: SBN=0 (1 stop bit) | WL=00 (8 bits) | RCS=1 (baud gen clk) | SBR=0000
;       SBR=0000 means "XTAL1 / 16".  1.8432 MHz / 16 = 115200 baud.
CTRL_115200 = %00010000

; --- ACIA command register bits ---
; CMD:  PMC=000 no parity | REM=0 | TIC=10 (RTS low, TX irq off) |
;       IRD=1 (RX irq off) | DTR=1 (data term rdy)
CMD_POLLED  = %00001011

ACIA_BUF    = $0400     ; Input buffer (RAM)

; --- TX delay ---
; One frame = 10 bits = 160 CPU cycles at 1.8432 MHz (16 cycles/bit).
; W65C51N may add up to one more bit time of latency before shifting starts,
; so the transmitter can stay busy for up to ~176 cycles after a write.
; send_char total = 5*TX_DELAY_N + 25 cycles.  N=36 -> 205 cycles (111 us).
TX_DELAY_N = 36


; -----------------------------------------------------------------------------
; --- ASCII Reference ---
; -----------------------------------------------------------------------------
CR    = $0D                 ; Carriage Return in ascii
LF    = $0A                 ; Line Feed in ascii
ESC   = $1B                 ; Escape key in ascii
BKSP  = $08                 ; Backspace key in ascii

; -----------------------------------------------------------------------------
; --- PS/2 Reference ---
; -----------------------------------------------------------------------------
PS2_LF  = $5A
PS2_ESC = $76 


; --- Emulation-mode vectors. NMI and IRQ just RTI (ACIA /IRQ is wired to NMI!)
.macro STD_VECTORS
    .segment "CODE"
nmi_rti:
irq_rti:
    rti
    .segment "VECTORS"
    .word nmi_rti               ; $FFFA  NMI
    .word reset                 ; $FFFC  RESET
    .word irq_rti               ; $FFFE  IRQ/BRK
.endmacro
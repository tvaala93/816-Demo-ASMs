; ============================================================
; thruHoleUtils.s
;
; Board-specific hardware definitions and low-level init for
; the through-hole 65C816 breadboard build.
;
; Rule of thumb for what belongs in this file: if it would
; change because you rewired the VIA or swapped the CPU, it
; goes here. If it would change because you swapped out a
; peripheral (a different LCD controller, a different UART),
; it belongs in THAT peripheral's own lib file instead.
; ============================================================

  .setcpu "65816"
  .a8              ; tell assembler accumulator is 8-bit
  .i8              ; tell assembler index registers (X/Y) are 8-bit
  .smart           ; let ca65 auto-track register widths after rep/sep

; -- W65C22 VIA register addresses --
; Exported so any peripheral driver that talks to the VIA
; (lcd.s today, others later) imports the address map from
; a single place instead of hardcoding it in multiple files.
;.export PORTB := $4000
;.export PORTA := $4001
;.export DDRB  := $4002
;.export DDRA  := $4003

;.export viaInit

.segment "CODE"

; -------------------------------------
; viaInit
; Configures the VIA's data direction
; registers for this board's wiring.
; Call once at reset, before touching
; any peripheral that lives on the VIA.
; -------------------------------------
viaInit:
  lda #%11111111
  sta DDRB          ; Port B: all outputs (LCD data/control lines)
  lda #%00000000
  sta DDRA          ; Port A: all inputs (unused for now)
  rts
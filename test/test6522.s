; -- W65C816S specific directives --
  .setcpu "65816"
  .a8              ; tell assembler accumulator is 8-bit
  .i8              ; tell assembler index registers (X/Y) are 8-bit
  .smart           ; let ca65 auto-track register widths after rep/sep

PORTB = $4000
PORTA = $4001
DDRB = $4002
DDRA = $4003

.segment "CODE"

reset:
  sei  ; disable interrupts
  clc
  xce   ; ensure emulation mode (E=1) — this is the
        ; standard 65816 startup idiom, though on
        ; power-up/reset E is already 1 by hardware
  ldx #$ff          ; Setup stack to begin at 0x01ff
  txs

  ; -- VIA Setup --
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11111111 ; Set all pins on port A to output
  sta DDRA

  ldx #$00
cycle:
  lda #$aa
  sta PORTA
  lda #$55
  sta PORTA
  jmp cycle

done:
  jmp done


; Setup code from reset vector fffc, fffd
.segment "VECTORS"
  ;.org $fffc
  .word reset       ; NMI vector   ($FFFA/FFFB -> mirrors to $9FFA on this chip)
  .word reset       ; RESET vector ($FFFC/FFFD -> mirrors to $9FFC on this chip)
  .word $0000       ; IRQ/BRK vector ($FFFE/FFFF -> mirrors to $9FFE on this chip)
  ;.org $fffc
  ;.word reset
  ;.word $0000

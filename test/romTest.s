; -- W65C816S specific directives --
  .setcpu "65816"
  .a8              ; tell assembler accumulator is 8-bit
  .i8              ; tell assembler index registers (X/Y) are 8-bit
  .smart           ; let ca65 auto-track register widths after rep/sep


PORTB = $4000
;PORTA = $4001
DDRB = $4002
;DDRA = $4003

E  = %00000100 ; PB2
RW = %00000010 ; PB1
RS = %00000001 ; PB0

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
  
  ; -- LCD Setup --
  ; PB7 PB6 PB5 PB4 PB3 PB2 PB1 PB0
  ; NUL DB7 DB6 DB5 DB4 E   RW  RS

  ; Step 2 function set
  lda #%00010000 ; 
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB
  lda #E         ; Set E bit to send instruction
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB

  ; Step 3 function set
  lda #%00010000 ;
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB
  lda #E         ; Set E bit to send instruction
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB

  lda #$0
  sta PORTB
  lda #0
  sta PORTB
  lda #E
  sta PORTB
  lda #0
  sta PORTB

  ; Step 4 Display on/off control
  lda #%0
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB
  lda #E         ; Set E bit to send instruction
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB

  lda #%01110000
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB
  lda #E         ; Set E bit to send instruction
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB

  ; Step 5 entry mode set
    lda #%0
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB
  lda #E         ; Set E bit to send instruction
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB

  lda #%00110000
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB
  lda #E         ; Set E bit to send instruction
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB

  ; Step 6 write data ("H")
  lda #%00100001
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB
  lda #E         ; Set E bit to send instruction
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB

  lda #%01000001
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB
  lda #E         ; Set E bit to send instruction
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTB

; -- Attention Catcher --
sta $DEAD
sta $BEEF


done:
  lda #$67
  ; -- Attention Catcher --
  sta $DEAD
  lda #$89
  sta $BEEF
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
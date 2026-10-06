; -- W65C816S specific directives --
  .setcpu "65816"
  .a8              ; tell assembler accumulator is 8-bit
  .i8              ; tell assembler index registers (X/Y) are 8-bit
  .smart           ; let ca65 auto-track register widths after rep/sep

PORTB = $4000
PORTA = $4001
DDRB = $4002
DDRA = $4003

E =  %00000100      ; LCD enable signal -> PB2
RW = %00000010      ; LCD read/write signal -> PB1
RS = %00000001      ; LCD register select -> PB0

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

  lda #%11111111    ;
  sta DDRB          ; Cfg port B to be all outputs
  lda #%00000000    ; 
  sta DDRA          ; Cfg top 3 pins of port A to be output


  ; -- LCD Setup --
  ; PB7 PB6 PB5 PB4 PB3 PB2 PB1 PB0
  ; NUL DB7 DB6 DB5 DB4 E   RW  RS

  jsr lcdInit
  ;lda #%01000010 ; Set 4-bit model 2-line display; 5x8 font
  ; CORRECTION: USE BEN'S CODE HERE
  ; YOUR lcdCfgCmd TAKES CARE OF BIT_SHIFTING
  lda #%00101000
  jsr lcdCfgCmd
  ;lda #%01110000 ; Display on, cursor on, blink off
  lda #%00001110
  jsr lcdCfgCmd
  ;lda #%00110000 ; Increment cursor, don't scroll
  lda #%00000110
  jsr lcdCfgCmd
  ;lda #%00001000 ; Clear the display
  lda #%00000001
  jsr lcdCfgCmd
  

; -------------------------------------
; Main loop
; -------------------------------------
  ldx #0
writeHelloWorld:  
  lda message,x
  beq loop
  jsr lcdWriteChar
  inx
  jmp writeHelloWorld

loop:
  jmp loop

; Specialized subroutines go down here vvv

lcdInit:
  lda #%00010000 ; Set to 4-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%01111000
  sta PORTB
  rts

toggleE:  
  ora #E    ; Set E bit to send instruction
  sta PORTB
  eor #E    ; Clear E bit
  sta PORTB
  rts

; -------------------------------------
; Poll LCD busy flag instead of using
; a fixed delay
; -------------------------------------

; to check Busy flag need to set RS = 0, RW = 1
lcdWait:
  pha
  lda #%10000111    ; LCD data is input
  sta DDRB
lcdBusy:
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB ; Read high nibble
  pha       ; and put on stack since it has the busy flag
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB ; Read low nibble
  pla       ; Get high nibble off stack
  and #%01000000 ; Read DB7 for busy flag
  bne lcdBusy
  
  lda #RW
  sta PORTB
  lda #%11111111    ; Cfg PORTB to be output again
  sta DDRB
  pla
  rts


; -------------------------------------
; Send an instruction to the LCD
; -------------------------------------
lcdCfgCmd:          ; Send a configuration command to LCD
  jsr lcdWait
  pha  
  lsr               ; Shift high 4 bits to correct pins
  and #%01111000    ; Mask off other bits
  sta PORTB         
  jsr toggleE
  pla
  asl
  asl
  asl               ; Shift low 4 bits to fit in PB3-6
  and #%01111000    ; Mask off other bits
  sta PORTB
  jsr toggleE
  rts

; -------------------------------------
; Send a character to the LCD
; -------------------------------------
lcdWriteChar:  
  jsr lcdWait
  pha
  lsr               ; Shift 4 high bits
  and #%01111000    ; Mask off other bits
  ora #RS           ; Set RS bit
  sta PORTB
  jsr toggleE
  pla
  asl
  asl
  asl               ; Shift low 4 bits to fit in PB3-6
  and #%01111000    ; Mask off other bits
  ora #RS
  sta PORTB
  jsr toggleE
  rts


.segment "RODATA"
message: 
  .asciiz "Hello, world!"


; Setup code from reset vector fffc, fffd
.segment "VECTORS"
  ;.org $fffc
  .word reset       ; NMI vector   ($FFFA/FFFB -> mirrors to $9FFA on this chip)
  .word reset       ; RESET vector ($FFFC/FFFD -> mirrors to $9FFC on this chip)
  .word $0000       ; IRQ/BRK vector ($FFFE/FFFF -> mirrors to $9FFE on this chip)

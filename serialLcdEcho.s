; =============================================================================
; serialLcdEcho.s
; 
; Application to initialize LCD, ACIA and echo rec'd serial messages to LCD
;
; =============================================================================

  .setcpu "65816"
  .a8
  .i8
  .smart

;.import viaInit
;.import lcdInit
;.import lcdCfgCmd
;.import lcdWriteChar

PORTB := $4000
PORTA := $4001
DDRB  := $4002
DDRA  := $4003

E  = %00000100      ; LCD enable signal   -> PB2
RW = %00000010      ; LCD read/write sig  -> PB1
RS = %00000001      ; LCD register select -> PB0

ACIA_BUF    = $0300     ; Input buffer (RAM)

ACIA_DATA   = $014000
ACIA_STATUS = $014001
ACIA_CMD    = $014002
ACIA_CTRL   = $014003

.segment "CODE"

reset:
  sei               ; disable interrupts
  clc
  xce               ; ensure emulation mode (E=1) -- this is the
                    ; standard 65816 startup idiom, though on
                    ; power-up/reset E is already 1 by hardware
  ldx #$ff          ; Setup stack to begin at 0x01ff
  txs

  jsr viaInit

  ; -- LCD Setup --
  ; PB7 PB6 PB5 PB4 PB3 PB2 PB1 PB0
  ; NUL DB7 DB6 DB5 DB4 E   RW  RS

  jsr lcdInit
  lda #%00101000    ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcdCfgCmd
  lda #%00001110    ; Display on, cursor on, blink off
  jsr lcdCfgCmd
  lda #%00000110    ; Increment cursor, don't scroll
  jsr lcdCfgCmd
  lda #%00000001    ; Clear the display
  jsr lcdCfgCmd

  ; -- ACIA Setup --
  lda #$00
  sta ACIA_STATUS   ; soft reset
  lda #$10          ; 8-N-1 115200 Baud
  sta ACIA_CTRL
  lda #$0b          ; No parity, no echo, no interrupts.
  sta ACIA_CMD

  ldx #$00
sendLcdMessage:
  lda message, X
  beq done
  jsr lcdWriteChar
  inx
  jmp sendLcdMessage


  jmp rx_wait

  ldx #$00
sendSerialMsg:
  lda serMessage, X
  beq done
  jsr send_char
  inx
  jmp sendSerialMsg

done:

rx_wait:
  lda ACIA_STATUS
  and #$08          ; Check RX buffer flag
  beq rx_wait       ; Loop if empty
  lda ACIA_DATA
  jsr lcdWriteChar
  jsr send_char
  jsr lcdWriteChar
  jmp rx_wait



send_char:
  sta ACIA_DATA     ; Just Echoing right now
  pha
tx_wait:
  lda ACIA_STATUS   ;
  and #$10          ; Check TX buffer flag
  beq tx_wait       ; Loop if TX buffer full
  jsr tx_delay; 6 cycles
  pla
  rts

tx_delay:           ; Specific to 115200
  phx ; 3 clk cycles
  ldx #$1d ; 2 clk cycles
tx_delay_1:
  dex ; 2 clk cycles
  bne tx_delay_1 ; 3 clk cycles
  plx ; 4 cycles
  rts ; 6 cycles


viaInit:
  lda #%11111111
  sta DDRB          ; Port B: all outputs (LCD data/control lines)
  lda #%00000000
  sta DDRA          ; Port A: all inputs (unused for now)
  rts

lcdInit:
  
  jsr lcdWait  
  ; The LCD may have been left halfway through a byte by a warm
  ; reset.  Send the 8-bit-mode wake-up nibble three times so the
  ; controller is synchronized before selecting 4-bit mode.
  lda #%00011000 ; LCD nibble 0011 (DB4..DB7 on PB3..PB6)
  jsr lcdInitNibble
  jsr lcdInitDelay
  jsr lcdInitNibble
  jsr lcdInitDelay
  jsr lcdInitNibble
  jsr lcdInitDelay
  lda #%00010000 ; LCD nibble 0010: select 4-bit mode
  jsr lcdInitNibble
  rts

lcdInitNibble:
  sta PORTB
  ora #E
  sta PORTB
  and #%01111000
  sta PORTB
  rts

lcdInitDelay:
  ldy #$ff
lcdInitDelayLoop:
  ldx #$ff
lcdInitDelayInnerLoop:
  dex
  bne lcdInitDelayInnerLoop
  dey
  bne lcdInitDelayLoop
  rts

toggleE:
  ora #E            ; Set E bit to send instruction
  sta PORTB
  eor #E            ; Clear E bit
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
  lda PORTB         ; Read high nibble
  pha               ; and put on stack since it has the busy flag
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB         ; Read low nibble
  pla               ; Get high nibble off stack
  and #%01000000    ; Read DB7 for busy flag
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
  .asciiz "Hello, new world!"
serMessage:
  .asciiz "Hello, serial!"

.segment "KEYMAP"

; Setup code from reset vector fffc, fffd
.segment "VECTORS"
  ;.org $fffc
  .word reset       ; NMI vector   ($FFFA/FFFB -> mirrors to $9FFA on this chip)
  .word reset       ; RESET vector ($FFFC/FFFD -> mirrors to $9FFC on this chip)
  .word $0000       ; IRQ/BRK vector ($FFFE/FFFF -> mirrors to $9FFE on this chip)
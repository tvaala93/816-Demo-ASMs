; =============================================================================
; ps2Utils.s -- driver for interacting with a PS/2 keyboard
; =============================================================================
  .setcpu "65816"
  .a8
  .i8
  .smart
  .include "thru_defs.inc"

PCR      = VIA_BASE + $c
IFR      = VIA_BASE + $d
IER      = VIA_BASE + $e

; --- Keyboard tracking registers and flags ---
KB_WPTR = $0000
KB_RPTR = $0001
KB_FLAG = $0002

KB_BUFF = $0200 ; 256-byte keboard buffer 0200-02ff

KB_RELEASE  = %00000001
KB_SHIFT    = %00000010
KB_ENTER    = $0a
KB_ESCAPE   = $1b


E  = %00000100      ; LCD enable signal   -> PB2
RW = %00000010      ; LCD read/write sig  -> PB1
RS = %00000001      ; LCD register select -> PB0

.segment "CODE"

key_pressed:
  ldx kb_rptr
  lda kb_buffer, x
  cmp #$0a           ; enter - go to second line
  beq enter_pressed
  cmp #$1b           ; escape - clear display
  beq esc_pressed

  jsr lcdWriteChar

  inc kb_rptr
  jmp loop

enter_pressed:
  lda #%10101000 ; put cursor at position 40
  jsr lcdCfgCmd
  inc kb_rptr
  jmp loop

esc_pressed:
  lda #%00000001 ; Clear display
  jsr lcdCfgCmd
  inc kb_rptr
  jmp loop



lcdInit:
  lda #%00010000 ; Set to 4-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%01111000
  sta PORTB
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


; IRQ vector points here
keyboard_interrupt:
  pha
  txa
  pha

  ; Tedits
  lda #%00000001 ; Clear display
  jsr lcdCfgCmd
  ldx #$00
  jmp interruptMessage

  lda kb_flags
  and #RELEASE   ; check if we're releasing a key
  beq read_key   ; otherwise, read the key

  lda kb_flags
  eor #RELEASE   ; flip the releasing bit
  sta kb_flags
  lda PORTA      ; read key value that's being released
  cmp #$12       ; left shift
  beq shift_up
  cmp #$59       ; right shift
  beq shift_up
  jmp exit

shift_up:
  lda kb_flags
  eor #SHIFT  ; flip the shift bit
  sta kb_flags
  jmp exit

read_key:
  lda PORTA
  cmp #$f0        ; if releasing a key
  beq key_release ; set the releasing bit
  cmp #$12        ; left shift
  beq shift_down
  cmp #$59        ; right shift
  beq shift_down

  tax
  lda kb_flags
  and #SHIFT
  bne shifted_key

  lda keymap, x   ; map to character code
  jmp push_key

shifted_key:
  lda keymap_shifted, x   ; map to character code

push_key:
  ldx kb_wptr
  sta kb_buffer, x
  inc kb_wptr
  jmp exit

shift_down:
  lda kb_flags
  ora #SHIFT
  sta kb_flags
  jmp exit

key_release:
  lda kb_flags
  ora #RELEASE
  sta kb_flags

exit:
  pla
  tax
  pla
  rti

  ldx #0
interruptMessage:
  lda message,x
  beq do_return
  jsr lcdWriteChar
  inx
  jmp interruptMessage
do_return:
  rts


nmi:
  rti

.segment "RODATA"
message:
  .asciiz "Hello, keyboard!"
intMsg:
  .asciiz "INTERRUPT"

.segment "KEYMAP"
keymap:
  .byte "????????????? `?" ; 00-0F
  .byte "?????q1???zsaw2?" ; 10-1F
  .byte "?cxde43?? vftr5?" ; 20-2F
  .byte "?nbhgy6???mju78?" ; 30-3F
  .byte "?,kio09??./l;p-?" ; 40-4F
  .byte "??'?[=????",$0a,"]?\??" ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568",$1b,"??+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF

keymap_shifted:
  .byte "????????????? ~?" ; 00-0F
  .byte "?????Q!???ZSAW@?" ; 10-1F
  .byte "?CXDE#$?? VFTR%?" ; 20-2F
  .byte "?NBHGY^???MJU&*?" ; 30-3F
  .byte "?<KIO)(??>?L:P_?" ; 40-4F
  .byte "????{+?????}?|??" ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568???+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF


; Setup code from reset vector fffc, fffd
.segment "VECTORS"
  .word nmi       ; NMI vector   ($FFFA/FFFB -> mirrors to $9FFA on this chip)
  .word reset       ; RESET vector ($FFFC/FFFD -> mirrors to $9FFC on this chip)
  .word keyboard_interrupt       ; IRQ/BRK vector ($FFFE/FFFF -> mirrors to $9FFE on this chip)

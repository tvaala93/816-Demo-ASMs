; =============================================================================
; *** NOTE: Bit order is swapped in hardware. Fix for future hardware versions
; =============================================================================
    .setcpu "65816"
    .a8
    .i8
    .smart

    .include "thru_defs.inc"
    .import lcdSetup, lcdCfgCmd, lcdWriteChar, lcdCursU, lcdCursD, lcdCursL, lcdCursR, lcdNewline
REL_CODE    = $F0
EXTEND_CODE = $E0

LEFT_SHIFT  = $12
RIGHT_SHIFT = $59
KEY_CTRL    = $14
KEY_ALT     = $11

ARW_LT      = $6B
ARW_RT      = $74
ARW_UP      = $75
ARW_DN      = $72

KEY_BACK    = $66
KEY_DEL     = $71
KEY_TAB     = $0D

TEMP = $40

.segment "CODE"

; -------------------------------------
; Reset Block
; -------------------------------------
reset:
    sei               ; disable interrupts    
    ldx #$ff          ; Setup stack to begin at 0x01ff
    txs

    lda #$7f
    sta IER             ; Disable all VIA interrupt sources
    sta IFR             ; Clear pending VIA interrupt flags

    lda #%00000001
    sta PCR         ; Positive edge trigger for CA1
    lda #%11111111 ; Set all pins on port B to output
    sta DDRB
    lda #%00000000 ; Set all pins on port A to input
    sta DDRA

    ;lda #$00
    stz KB_FLAG
    stz KB_WPTR
    stz KB_RPTR
    
    jsr lcdSetup

    lda #$7f
    sta IFR             ; Discard any CA1 event during setup
    lda #%10000010  ; Port A peripheral control line active edge interrupt CA1
    sta IER
    cli    

    ldx #0
welcomeMessage:
    lda message,x
    beq loop
    jsr lcdWriteChar
    inx
    jmp welcomeMessage


; -------------------------------------
; Main Loop - Load Byte from Keybuffer
; -------------------------------------
loop:
    sei
    lda KB_RPTR
    cmp KB_WPTR
    cli
    bne proc_code
    jmp loop


; -------------------------------------
; Foreground Handlers - Key pressed
; Jump back to Loop
; -------------------------------------
enter_press:
    ; TODO - handle more rows ; Currently equivalent to arrow down    
    ;jsr lcdCursD
    jsr lcdNewline
    jmp loop

esc_press:    
    stz CURS_POSN
    stz LCD_OFFSET
    lda #LCD_CLEAR  ; Clear the screen
    jsr lcdCfgCmd    
    jmp loop

backspace_press:
    ; TODO - this just moves the cursor 1 posn left, not true backspace    
    jsr lcdCursL
    jmp loop

;tab_press:
;    jmp loop

; -------------------------------------
; Main Branch out of Loop
; Clobbers A. A contains KB_RPTR prior
; -------------------------------------
proc_code:
    ldx KB_RPTR         ; Preserves KB_RPTR
    lda KB_BUFF, x      ; Get the code from buffer
    inc KB_RPTR

    ; A now holds raw KB Buffer value (a PS/2 scan code)
    ; X now holds pointer to KB_RPTR value

    ; Handle prefixes $F0, $E0
    ; Does this code necessitate flag changes?
    cmp #REL_CODE       ; if releasing a key
    beq key_release     ; set the releasing bit  
    cmp #EXTEND_CODE
    beq key_extend      ; Handle an extension code

    ; Check oustanding flags
    tax    
    
    ; X now holds raw scan code
    ; A free to hold value of KB_FLAG

    ; Was the key just released?
    lda KB_FLAG
    and #KB_RELEASE
    bne on_release

    ; Is this an extended key?
    lda KB_FLAG
    and #KB_EXTENDED
    bne on_extend

    ; Is this key's held status tracked? (ie ctrl, alt, shift)
    ; NOTE - Right ctrl, right alt are extended codes
    lda KB_FLAG
    cpx #LEFT_SHIFT     ; left shift
    beq shift_press
    cpx #RIGHT_SHIFT    ; right shift
    beq shift_press
    cpx #KEY_CTRL
    beq ctrl_press
    ;cpx #KEY_ALT
    ;beq alt_press
    
    ; Does the key press necessitate an action?
    cpx #KEY_BACK           ; backspace
    beq backspace_press
    cpx #PS2_LF             ; enter - go to second line
    beq enter_press
    cpx #PS2_ESC            ; escape - clear display
    beq esc_press
    ;cpx #KEY_TAB           ; tab key
    ;beq tab_press
    
    ; Is shift active?
    and #KB_SHIFT
    bne shifted_key

    lda keymap, x
    jsr lcdWriteChar    
    jmp loop

key_release:    
    lda KB_FLAG
    ora #KB_RELEASE     ; Flag a release event is upcoming    
    sta KB_FLAG
    jmp loop

key_extend:
    lda KB_FLAG
    ora #KB_EXTENDED    ; Flag an extended key was pressed or released  
    sta KB_FLAG
    jmp loop

; Handle a newly released key
; Clear flags as applicable
on_release:

    lda KB_FLAG
    and #<~(KB_RELEASE | KB_EXTENDED)
    sta KB_FLAG    ; Ensure release bit is cleared in flags

    cpx #LEFT_SHIFT
    beq shift_up
    cpx #RIGHT_SHIFT
    beq shift_up
    cpx #KEY_CTRL
    beq ctrl_up
    
    ;cpx #KEY_ALT
    ;beq alt_up

    jmp loop
    
on_extend:

    ; we've made it to the extend code handler, so we no longer need the flag
    ; clear it
    lda KB_FLAG
    and #<~KB_EXTENDED
    sta KB_FLAG

    cpx #KEY_CTRL
    beq ctrl_press
    ;cpx #KEY_ALT
    ;beq alt_press
    cpx #ARW_UP
    beq up_press
    cpx #ARW_DN
    beq dn_press
    cpx #ARW_LT
    beq lt_press
    cpx #ARW_RT
    beq rt_press
    ;cpx #KEY_DEL        ; delete key
    ;beq del_press

    ; if none of the above, return to loop
    jmp loop

shift_press:
    lda KB_FLAG
    ora #KB_SHIFT
    sta KB_FLAG
    jmp loop

ctrl_press:
    lda KB_FLAG
    ora #KB_CTRL
    sta KB_FLAG
    jmp loop

;alt_press:
;    lda KB_FLAG
;    ora #KB_ALT
;    sta KB_FLAG
;    jmp loop

up_press:
    jsr lcdCursU  
    jmp loop

dn_press:    
    jsr lcdCursD    
    jmp loop

lt_press:
    jsr lcdCursL
    jmp loop

rt_press:    
    jsr lcdCursR
    jmp loop

shifted_key:
  lda keymap_shifted, x   ; map to character code
  jsr lcdWriteChar
  jmp loop

shift_up:
  lda KB_FLAG
  and #<~KB_SHIFT  ; clear the shift bit
  sta KB_FLAG
  jmp loop

ctrl_up:
  lda KB_FLAG
  and #<~KB_CTRL  ; clear the ctrl bit
  sta KB_FLAG
  jmp loop

;alt_up:
;  lda KB_FLAG
;  and #<~KB_ALT  ; clear the alt bit
;  sta KB_FLAG
;  jmp exit


; IRQ vector points here - Bits get reversed on input to buffer
keyboard_interrupt:
  pha
  phx

  lda PORTA         ; read key code (reading PORTA also clears the interrupt)
  jsr bitReversal
  ldx KB_WPTR       ; push it into key code buffer
  sta KB_BUFF, x
  inc KB_WPTR

  plx
  pla
  rti

bitReversal:
    sta TEMP
    lda #$00
    ldx #$08
@n:
    lsr TEMP
    rol A
    dex
    bne @n
    rts

nmi:
  rti

.segment "RODATA"
message:
  .asciiz "Hello!"


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
  .byte "??",$22,"?{+????",$0a,"}?|??" ; 50-5F
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

.segment "VECTORS"
    .word nmi
    .word reset
    .word keyboard_interrupt
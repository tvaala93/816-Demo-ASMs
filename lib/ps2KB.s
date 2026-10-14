; =============================================================================
; ps2KB.s -- driver for a PS/2 keyboard on the W65C22 VIA
;
; Hardware: the keyboard clock/data go through the shift register chain to
; VIA port A, and CA1 interrupts once per complete scan code.
; *** NOTE: Bit order is swapped in hardware. Fix for future hardware versions
;
; Public interface (the only labels other files should use):
;   kbInit     - set up the VIA and clear driver state. Does NOT enable
;                interrupts: call this, then cli.   Clobbers A.
;   kbIRQ      - interrupt handler. Point the IRQ vector at it, or from your
;                own dispatcher do "jmp kbIRQ". Ends with rti.
;   kbGetKey   - non-blocking. C=1 and A=key if a key press is waiting,
;                C=0 if not. Clobbers A, X.
;   kbWaitKey  - blocking version of kbGetKey (returns with A=key).
;
; What kbGetKey returns is described in ps2KB.inc (ASCII, plus KEY_UP etc.).
; Releases, shift/ctrl and unmapped keys are consumed internally and never
; returned. Modifier state lives in kbFlags.
;
; Assumes 8-bit A/X/Y (emulation mode, or .a8/.i8 native), since the IRQ
; handler pushes with pha/phx.
; =============================================================================
    .setcpu "65816"
    .a8
    .i8
    .smart
    .include "thru_defs.inc"
; this file defines the routines ps2KB.inc would import
PS2KB_IMPL = 1
    .include "ps2KB.inc"
    .export kbInit, kbIRQ, kbGetKey, kbWaitKey
    .exportzp kbFlags

; Variables: the linker assigns the addresses (see ZEROPAGE and BSS in rom.cfg)
    .segment "ZEROPAGE" : zeropage
kbWptr:     .res 1      ; ring buffer write index (only IRQ handler writes it)
kbRptr:     .res 1      ; ring buffer read index  (only kbGetKey writes it)
kbFlags:    .res 1      ; modifier / decoder state, see the KB_* bits
kbTemp:     .res 1      ; scratch for bitReversal

    .segment "BSS"
kbBuffer:   .res 256    ; raw scan codes. A full 256 entries, so the 8-bit
                        ; indexes wrap by themselves
; --- bits in kbFlags (KB_SHIFT and KB_CTRL are public, in ps2KB.inc) ---
KB_RELEASE  = %00000001 ; next code is a key release
KB_EXTENDED = %00010000 ; next code is an extended (E0) key

; --- PS/2 set 2 scan codes (private to this file) ---
REL_CODE    = $F0       ; prefix: next code is a key release
EXTEND_CODE = $E0       ; prefix: next code is an extended key
SC_LSHIFT   = $12
SC_RSHIFT   = $59
SC_CTRL     = $14       ; left ctrl; right ctrl is E0 14
SC_SLASH    = $4A       ; shift+/ really is '?', see kbGetKey
SC_LEFT     = $6B       ; arrows and delete only arrive as E0-prefixed codes
SC_RIGHT    = $74
SC_UP       = $75
SC_DOWN     = $72
SC_DEL      = $71

.segment "CODE"

; -------------------------------------
; Setup the VIA for the keyboard & clear driver state
; -------------------------------------
kbInit:
    stz kbFlags
    stz kbWptr
    stz kbRptr
    stz DDRA            ; port A is all input
    lda PCR
    ora #%00000001      ; CA1 interrupts on the positive edge
    sta PCR
    lda #%01111111
    sta IFR             ; discard any CA1 event from before now
    lda #%10000010
    sta IER             ; enable the CA1 interrupt (other sources untouched)
    rts

; -------------------------------------
; IRQ handler: grab the scan code, fix its bit order, push it in the buffer.
; Only writes kbWptr; kbGetKey only writes kbRptr, so no locking is needed.
; -------------------------------------
kbIRQ:
    pha
    phx
    lda PORTA           ; read key code (reading PORTA also clears interrupt)
    jsr bitReversal
    ldx kbWptr
    sta kbBuffer,x
    inc kbWptr
    plx
    pla
    rti

bitReversal:            ; A = bit-reversed A. Clobbers X.
    sta kbTemp
    lda #$00
    ldx #$08
@n:
    lsr kbTemp
    rol a
    dex
    bne @n
    rts

; -------------------------------------
; Get one decoded key press, if there is one.
; Eats scan codes from the buffer until a key press comes out or the buffer
; runs dry. Clobbers A, X.
; -------------------------------------
kbGetKey:
    lda kbRptr
    cmp kbWptr
    beq @none           ; buffer empty

    ldx kbRptr
    lda kbBuffer,x
    inc kbRptr

    cmp #REL_CODE
    beq @prefix_release
    cmp #EXTEND_CODE
    beq @prefix_extend
    tax                 ; X = scan code from here on

    lda kbFlags
    and #KB_RELEASE
    bne @released
    lda kbFlags
    and #KB_EXTENDED
    bne @extended

    ; ---- ordinary key press ----
    cpx #SC_LSHIFT
    beq @shift_down
    cpx #SC_RSHIFT
    beq @shift_down
    cpx #SC_CTRL
    beq @ctrl_down

    lda kbFlags
    and #KB_SHIFT
    bne @shifted
    lda keymap,x
    bra @mapped
@shifted:
    lda keymap_shifted,x
@mapped:
    ; Unmapped keys (F-keys, caps lock, self-test code ...) are '?' in the
    ; tables. Skip those, except the one place where '?' is a real character.
    cmp #'?'
    bne @got_key
    cpx #SC_SLASH
    bne @next
@got_key:
    sec
    rts

@none:
    clc
    rts

@next:
    jmp kbGetKey

@prefix_release:
    lda kbFlags
    ora #KB_RELEASE     ; the next code is a release
    sta kbFlags
    bra @next

@prefix_extend:
    lda kbFlags
    ora #KB_EXTENDED    ; the next code is an extended key
    sta kbFlags
    bra @next

@released:
    lda kbFlags
    ; E0 F0 xx: the release ends the extended sequence too
    and #<~(KB_RELEASE | KB_EXTENDED)
    sta kbFlags
    cpx #SC_LSHIFT
    beq @shift_up
    cpx #SC_RSHIFT
    beq @shift_up
    cpx #SC_CTRL
    beq @ctrl_up
    bra @next

@extended:
    lda kbFlags
    and #<~KB_EXTENDED  ; the prefix has done its job
    sta kbFlags
    cpx #SC_CTRL
    beq @ctrl_down      ; right ctrl
    lda #KEY_UP
    cpx #SC_UP
    beq @got_key
    lda #KEY_DOWN
    cpx #SC_DOWN
    beq @got_key
    lda #KEY_LEFT
    cpx #SC_LEFT
    beq @got_key
    lda #KEY_RIGHT
    cpx #SC_RIGHT
    beq @got_key
    lda #KEY_DEL
    cpx #SC_DEL
    beq @got_key
    bra @next

@shift_down:
    lda kbFlags
    ora #KB_SHIFT
    sta kbFlags
    bra @next

@shift_up:
    lda kbFlags
    and #<~KB_SHIFT
    sta kbFlags
    bra @next

@ctrl_down:
    lda kbFlags
    ora #KB_CTRL
    sta kbFlags
    bra @next

@ctrl_up:
    lda kbFlags
    and #<~KB_CTRL
    sta kbFlags
    bra @next


; -------------------------------------
; Wait for a key press. Returns with A = key.
; -------------------------------------
kbWaitKey:
    jsr kbGetKey
    bcc kbWaitKey
    rts


.segment "KEYMAP"

keymap:
    .byte "????????????? `?" ; 00-0F
    .byte "?????q1???zsaw2?" ; 10-1F
    .byte "?cxde43?? vftr5?" ; 20-2F
    .byte "?nbhgy6???mju78?" ; 30-3F
    .byte "?,kio09??./l;p-?" ; 40-4F
    .byte "??'?[=????",$0A,"]?\??" ; 50-5F
    .byte "?????????1?47???" ; 60-6F
    .byte "0.2568",$1B,"??+3-*9??" ; 70-7F
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
    .byte "??",$22,"?{+????",$0A,"}?|??" ; 50-5F
    .byte "?????????1?47???" ; 60-6F
    .byte "0.2568",$1B,"??+3-*9??" ; 70-7F
    .byte "????????????????" ; 80-8F
    .byte "????????????????" ; 90-9F
    .byte "????????????????" ; A0-AF
    .byte "????????????????" ; B0-BF
    .byte "????????????????" ; C0-CF
    .byte "????????????????" ; D0-DF
    .byte "????????????????" ; E0-EF
    .byte "????????????????" ; F0-FF

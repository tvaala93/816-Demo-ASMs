; =============================================================================
; ps2KB.inc -- public interface of the PS/2 keyboard driver (ps2KB.s)
;
; Include this in any file that uses the keyboard; the routines are imported
; for you. See the header of ps2KB.s for what each one does:
;   kbInit, kbIRQ, kbGetKey, kbWaitKey
;
; RAM: the driver's variables (and its 256-byte scan code buffer) are allocated
; by the linker. The only one a caller may look at is the modifier byte:
;     lda kbFlags
;     and #KB_SHIFT          ; or KB_CTRL
; =============================================================================
.ifndef PS2KB_INC
PS2KB_INC = 1

.ifndef PS2KB_IMPL          ; ps2KB.s defines these itself
    .import kbInit, kbIRQ, kbGetKey, kbWaitKey
    .importzp kbFlags
.endif

; Values returned by kbGetKey / kbWaitKey in A.
; $20-$7E are plain ASCII characters (already shift-adjusted).
KEY_BACK   = $08        ; Backspace
KEY_ENTER  = $0A        ; Enter (LF)
KEY_ESC    = $1B        ; Escape
KEY_DEL    = $7F        ; Delete
KEY_UP     = $80        ; Arrow keys
KEY_DOWN   = $81
KEY_LEFT   = $82
KEY_RIGHT  = $83

; Bits in kbFlags that callers can test
KB_SHIFT   = %00000010
KB_CTRL    = %00000100

.endif
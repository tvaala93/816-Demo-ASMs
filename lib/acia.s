; ============================================================
; acia.s
;
; Driver for serial comms via the 65C51 ACIA chip
;
; ----------------------
; Status Register (ST_*)
; ----------------------
;
; 7654 3210
; |||| ||||
; |||| |||+> Parity Error (PE)
; |||| ||+-> Framing Error (FE)
; |||| |+--> Overrun (OVRN)
; |||| +---> Rcvr Data Reg Full (RDRF)
; |||+-----> Transmit Data Reg Empty* (TDRE); **Never 0 during transmission**
; ||+------> Data Carrier Detect (DCDB); 0=Detected, 1=Not (active low)
; |+-------> Data Set Ready (DSRB); 0=Ready, 1=Not (active low)
; +--------> Interrupt (IRQ); 0=No Interrupt
;
; ------------------------
; Command Register (CMD_*)
; ------------------------
;
; 7654 3210
; |||| ||||
; |||| |||+> Data Terminal Ready (DTR); 0=F, 1=T
; |||| ||+-> Rcvr Interrupt Rqst Disabled; 0=Enabled, 1=Disabled
; |||| ++--> Transmitter Interrupt CTRL (TIC)
; |||+-----> Rcvr Echo Mode (REM); 0=Normal, 1=Ech0 (TIC must be 0)
; ||+------> Parity Mode Enabled (PME); 0=F, 1=T
; ++-------> Parity Mode Ctrl (PMC)
;
; -------------------------
; Control Register (CTRL_*)
; -------------------------
;
; 7654 3210
; |||| ||||
; |||| ++++> Selected Baud Rate (SBR)
; |||+-----> Rcvr Clock Source (RCS); 0=External, 1=Baud Rate
; |++------> Word Length (WL) No. Bits
; +--------> Stop Bit Number (SBN)
; ============================================================




.export aciaReset, aciaSendChar, txDelay

aciaReset:
  lda #$00
  sta ACIA_STATUS ; soft reset
  rts

rxWait:
  lda ACIA_STATUS
  and #$08          ; Check RX buffer flag
  beq rxWait       ; Loop if empty
  lda ACIA_DATA
  jsr lcdWriteChar
  jsr aciaSendChar
  jmp rxWait

txWait:
  lda ACIA_STATUS   ;
  and #$10          ; Check TX buffer flag
  beq txWait       ; Loop if TX buffer full
  jsr txDelay; 6 cycles
  pla
  rts


; A = byte to send. Preserves A, X, Y.
; We do NOT poll TDRE: the W65C51N loads TDR and TSR together, so the flag
; cannot be trusted. We wait a fixed time instead.
aciaSendChar:
    sta ACIA_DATA   ; 5 clk cycles (long store)
txDelay:            ; Specific to 115200 Baud
    phx             ; 3 clk cycles
    ldx #TX_DELAY_N ; 2 clk cycles
@l:
    dex             ; 2 clk cycles
    bne @l          ; 3 clk cycles (2 on final)
    plx             ; 4 cycles
    rts             ; 6 cycles


; --- Control Character Handlers ---
aciaESC:

aciaBack:

aciaEnter:
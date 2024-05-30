; Script used to display the title screen.
; Author: Egar Garcia
; Last Revision 2024-05-29

  lda #$00
  sta u
  sta v
  sta COLUBK
  sta COLUPF
  sta CTRLPF

NextFrame
  ; Disable output (enable VBLANK)
  lda #2
  sta VBLANK

  ; VERTICAL SYNC
  sta VSYNC
  sta WSYNC
  sta WSYNC
  sta WSYNC
  ; Turning VSYNC off
  lda #0
  sta VSYNC

  ; VERTICAL BLANK
  ldy #37
LVBlank
  sta WSYNC
  dey
  bne LVBlank
  ; Re-enable output (disable VBLANK)
  lda #0
  sta VBLANK

  ; VISIBLE FRAME (192 lines)
  ldx u
  ldy #191
LVScan
  txa
  and ColorMasks,y
  ora ColorExpressions,y
  sta WSYNC
  sta COLUPF
  lda MapPF0,y
  sta PF0
  lda MapPF1,y
  sta PF1
  lda MapPF2,y
  sta PF2
  nop
  nop
  lda MapPF3,y
  sta PF0
  lda MapPF4,y
  sta PF1
  lda MapPF5,y
  sta PF2
  dex
  dey
  bne LVScan

  ; Line 192
  sta WSYNC

  ; Clean playfield
  lda #0
  sta PF0
  sta PF1
  sta PF2

  ; Disable output (enable VBLANK again)
  lda #2
  sta VBLANK
  ; OVERSCAN
  ldy #30
LVOver
  sta WSYNC
  dey
  bne LVOver

  ; Check if START is pressed
  lda #$01
  bit SWCHB
  beq EndTitle
  ; Check if SELECT is pressed
  lda #$02
  bit SWCHB
  beq EndTitle
  ; Check if PLAYER 1'S BUTTON is pressed
  lda INPT4
  bpl EndTitle
  ; Check if PLAYER 2'S BUTTON is pressed
  lda INPT5
  bpl EndTitle

  inc v
  lda v
  cmp #8
  bne SkipCountIncrease
  lda #0
  sta v
  inc u
SkipCountIncrease
  jmp NextFrame


EndTitle
  lda #1
  sta CTRLPF

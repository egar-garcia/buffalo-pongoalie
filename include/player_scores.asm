; This minikernel displays two digit scores for each one of the two players.
; Author: Egar Garcia
; Last Revision 2024-04-14

; Variables to replace the lives minikernel variables.
player0score = $f2 ; BCD
player1score = $f3 ; BCD
player0scorecolor = $f4
player1scorecolor = $f5

; Assigning alternate names to temp variables (for more descriptive names in coding).
player0digit1Ptr = temp1
player0digit2Ptr = temp3
player1digit1Ptr = temp5
player1digit2Ptr = stack1

minikernel

  ; Setting up pointers to the digits (count cycles)
  clc                       ; 2  (02)
  ldx #>scoretable          ; 2  (04) X := score-graphics-high-byte

  ; player0score first digit
  lda player0score          ; 3  (07) A := player0score
  and #$F0                  ; 2  (09) A := A & 0xF0 (stripping off low digit)
  lsr                       ; 2  (11) A := A >> 1, A = player0score-first-digit * 8
  adc <#scoretable          ; 2  (13) A := A + score-graphics-low-byte, A = score-graphics-low-byte + player0score-first-digit * 8
  sta player0digit1Ptr      ; 3  (16) player0digit1Ptr-low-byte := score-graphics-low-byte + player0score-first-digit * 8
  stx player0digit1Ptr+1    ; 3  (19) player0digit1Ptr-high-byte := score-graphics-high-byte

  ; player0score second digit
  lda player0score          ; 3  (22) A := player0score
  and #$0F                  ; 2  (24) A := A & 0x0F (stripping off high digit)
  asl                       ; 2  (26) A := A << 1
  asl                       ; 2  (28) A := A << 1
  asl                       ; 2  (30) A := A << 1, A = player0score-second-digit * 8
  adc <#scoretable          ; 2  (32) A := A + score-graphics-low-byte, A = score-graphics-low-byte + player0score-second-digit * 8
  sta player0digit2Ptr      ; 3  (35) player0digit2Ptr-low-byte := score-graphics-low-byte + player0score-second-digit * 8
  stx player0digit2Ptr+1    ; 3  (38) player0digit2Ptr-high-byte := score-graphics-high-byte

  ; player1score first digit
  lda player1score          ; 3  (41) A := player1score
  and #$F0                  ; 2  (43) A := A & 0xF0 (stripping off low digit)
  lsr                       ; 2  (45) A := A >> 1, A = player1score-first-digit * 8
  adc <#scoretable          ; 2  (47) A := A + score-graphics-low-byte, A = score-graphics-low-byte + player1score-first-digit * 8
  sta player1digit1Ptr      ; 3  (50) player1digit1Ptr-low-byte := score-graphics-low-byte + player1score-first-digit * 8
  stx player1digit1Ptr+1    ; 3  (53) player1digit2Ptr-high-byte := score-graphics-high-byte

  ; player1score second digit
  lda player1score          ; 3  (56) A := player1score
  and #$0F                  ; 2  (58) A := A & 0x0F (stripping off high digit)
  asl                       ; 2  (60) A := A << 1
  asl                       ; 2  (62) A := A << 1
  asl                       ; 2  (64) A := A << 1, A = player1score-second-digit * 8
  adc <#scoretable          ; 2  (66) A := A + score-graphics-low-byte, A = score-graphics-low-byte + player1score-second-digit * 8
  sta player1digit2Ptr      ; 3  (69) player1digit2Ptr-low-byte := score-graphics-low-byte + player1score-second-digit * 8
  stx player1digit2Ptr+1    ; 3  (72) player1digit2Ptr-high-byte := score-graphics-high-byte
  ;this took close to a full scan line

  ; Setting up the players' positions
  sta WSYNC                 ; waiting for the beginning of a new line
  lda #$02                  ; 2  (02) two copies - medium size for players
  sta NUSIZ0                ; 3  (05)  
  sta NUSIZ1                ; 3  (08) 
  lda player0scorecolor     ; 3  (11)  
  sta COLUP0                ; 3  (14)
  lda player1scorecolor     ; 3  (17)  
  sta COLUP1                ; 3  (20)

  sleep 20                  ;20  (40)
  sta RESP0                 ; 3  (43) reset position for player0 
  sta RESP1                 ; 3  (46) reset position for player1
  lda #$E0                  ; 2  (48) moving 2 machine cycles (6 color clocks) right 
  sta HMP0                  ; 3  (51) set horizontal motion of player0
  lda #$00                  ; 2  (53) A := 0 to turn off vertical delay
  sta HMP1                  ; 3  (56) no horizontal motion for player1
  sta VDELP0                ; 3  (59) display player0
  sta VDELP1                ; 3  (62) display player1
  sleep 4                   ; 2  (66) 
  ldy #7                    ; 2  (68) 8 lines to display per digits 
  sty temp7                 ; 3  (71) temp7 := 7
  sta HMOVE                 ; 3  (74) horizontal movement has to be done during horizontal blank

minikernelloop
  ; Displaying the digits (through the players)
  sta WSYNC                 ; waiting for the beginning of a new line

  lda (player0digit1Ptr),y  ; 5  (05) getting the sprite of the first digit of player0's score
  sta GRP0                  ; 3  (08) setting sprite of the first digit of player0's score as graphics bitmap for player0
  ldx player0scorecolor     ; 3  (11) X := player0-score-color
  stx COLUP0                ; 3  (14) setting player0-score-color for first digit of player0's score
  lda (player0digit2Ptr),y  ; 5  (19) getting the sprite of the second digit of player0's score
  sta GRP1                  ; 3  (22) setting sprite of the second digit of player0's score as graphics bitmap for player1
  stx COLUP1                ; 3  (25) setting player0-score-color for second digit of player0's score

  lda (player1digit2Ptr),y  ; 5  (30) getting the sprite of the first digit of player1's score
  tax                       ; 2  (32) X := first-digit-player1-score
  lda (player1digit1Ptr),y  ; 5  (37) getting the sprite of the second digit of player1's score
  ldy player1scorecolor     ; 3  (40) Y := player1-score-color
  nop                       ; 2  (42) synchronizing color clocks to setup and display second copy of players
  sty COLUP0                ; 3  (45) setting player1-score-color for first digit of player1's score
  sta GRP0                  ; 3  (48) setting sprite of the first digit of player1's score as graphics bitmap for player0
  sty COLUP1                ; 3  (51) setting player1-score-color for second digit of player1's score
  stx GRP1                  ; 3  (54) setting sprite of the second digit of player1's score as graphics bitmap for player1

  dec temp7                 ; 2  (56)
  ldy temp7                 ; 3  (59)
  bpl minikernelloop        ; 2+ (60-61) 8 loops for the 8 sprite lines per digit (15 cycles free)

endminikernel
  sta WSYNC                 ; waiting for the beginning of a new line
  iny
  sty GRP0                  ; clear player0
  sty GRP1                  ; clear player1
  rts

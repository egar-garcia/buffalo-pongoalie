;PlayerScores MiniKernal
;9 Sept 2007 - Curtis F Kaylor
;displays two digit score for each of two players
;
;Copyright 2007 Curtis F Kaylor
;Permission is hereby granted to distribute this code with the bAtari Basic
;compiler, under the terms of the bAtari Basic license.

;these variables replace the lives minikernel variables
player0score = $f2 ; BCD
player1score = $f3 ; BCD
player0scorecolor = $f4
player1scorecolor = $f5

;assign alternate names for easier coding
player0digit1 = temp1
player0digit2 = temp3
player1digit1 = temp5
player1digit2 = stack1

minikernel ;this is where the kernel JSRs

  ;first, set up pointers to the digits (count cycles)
  clc                    ; 2  (02) for the ADCs coming up
  ldx #>scoretable       ; 2  (04) score graphics high byte
  ;player0score first digit
  lda player0score       ; 3  (07) get score
  and #$F0               ; 2  (09) strip off low digit
  lsr                    ; 2  (11) divide by two = digit * 8
  adc <#scoretable       ; 2  (13) add to base address 
  sta player0digit1      ; 3  (16) store address low byte
  stx player0digit1+1    ; 3  (19) and high byte
  ;player0score second digit
  lda player0score       ; 3  (22) get score again
  and #$0F               ; 2  (24) strip off high digit
  asl                    ; 2  (26) multiply by eight
  asl                    ; 2  (28)
  asl                    ; 2  (30)
  adc <#scoretable       ; 2  (32) add to base address  
  sta player0digit2      ; 3  (35) store address low byte
  stx player0digit2+1    ; 3  (38) and high byte
  ;player1score first digit
  lda player1score       ; 3  (41) get score
  and #$F0               ; 2  (43) strip off low digit
  lsr                    ; 2  (45) divide by two = digit * 8
  adc <#scoretable       ; 2  (47) add to base address 
  sta player1digit1      ; 3  (50) store address low byte
  stx player1digit1+1    ; 3  (53) and high byte
  ;player1score second digit
  lda player1score       ; 3  (56) get score again
  and #$0F               ; 2  (58) strip off high digit
  asl                    ; 2  (60) multiply by eight
  asl                    ; 2  (62)
  asl                    ; 2  (64)
  adc <#scoretable       ; 2  (66) add to base address  
  sta player1digit2      ; 3  (69) store address low byte
  stx player1digit2+1    ; 3  (72) and high byte
  ;this took close to a full scan line

  ;set up the player positions
  sta WSYNC              ;wait till the end of the line (count cycles)
  lda #$02               ;2  (02) two copies medium - normal sized
  sta NUSIZ0             ;3  (05)  
  sta NUSIZ1             ;3  (08) 
  lda player0scorecolor  ;3  (11)  
  sta COLUP0             ;3  (14)
  lda player1scorecolor  ;3  (17)  
  sta COLUP1             ;3  (20)

  sleep 20               ;20  (40)
  sta RESP0              ; 3  (43) Position Player0 
  sta RESP1              ; 3  (46) Position Player1
  lda #$E0               ; 2  (48) Move Two Clocks Right 
  sta HMP0               ; 3  (51) Set Player 1
  lda #$00               ; 2  (53) Turning Off Vertical Delay
  sta HMP1               ; 3  (56) No Movement
  sta VDELP0             ; 3  (59) Displays Player0
  sta VDELP1             ; 3  (62) and Player1
  sleep 4                ; 2  (66)
  ldy #7                 ; 2  (68) 8 lines in the digits 
  sty temp7              ; 3  (71)
  sta HMOVE              ; 3  (74) have to do during horizontal blank
                         ; 2 cycles to spare
minikernelloop
  ;now to draw the players
  sta WSYNC              ;wait till line starts (count cycles)
  lda (player0digit1),y  ; 5  (05) get the graphic
  sta GRP0               ; 3  (08)
  ldx player0scorecolor  ; 3  (11) left player score color
  stx COLUP0             ; 3  (14) goes in both digits
  lda (player0digit2),y  ; 5  (19) get the graphic
  sta GRP1               ; 3  (22)
  stx COLUP1             ; 3  (25) 
  lda (player1digit2),y  ; 5  (30) get graphic
  tax                    ; 2  (32) store in X
  lda (player1digit1),y  ; 5  (37) get the graphic
  ldy player1scorecolor  ; 3  (40) right player score color
  nop                    ; 2  (42)  there's about 1 cycle leeway here 
  sty COLUP0             ; 3  (45) player 0 color
  sta GRP0               ; 3  (48) player 0 data
  sty COLUP1             ; 3  (51) player 1 color
  stx GRP1               ; 3  (54) player 1 data

  dec temp7              ; 2  (56)
  ldy temp7              ; 3  (59)
  bpl minikernelloop     ; 2+ (60-61) leaves 15 cycles free

endminikernel
  sta WSYNC              ;score routine expects to be at the beginning of a line
  iny
  sty GRP0               ;clear player0
  sty GRP1               ;clear player1
  rts                    ;return to the kernel

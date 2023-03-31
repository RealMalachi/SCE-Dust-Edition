; https://plutiedev.com/controllers
; https://segaretro.org/Six_Button_Control_Pad_(Mega_Drive)
; Note: all code here expects an outside source to stop Z80 when running it, and preferably resume it directly after
; ---------------------------------------------------------------------------
; Subroutine to initialise joypads
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Init_Controllers:
	stopZ80
	stopZ802
	moveq	#$40,d3
	lea	(HW_Port_1_Control).l,a0			; first joypad port
	move.b	d3,HW_Port_1_Control-HW_Port_1_Control(a0)	; init port 1 (joypad 1)
	move.b	d3,HW_Port_2_Control-HW_Port_1_Control(a0)	; init port 2 (joypad 2)
	move.b	d3,HW_Expansion_Control-HW_Port_1_Control(a0)	; init port 3 (expansion/extra)
	startZ802
	startZ80
	rts
; End of function Init_Controllers

; ---------------------------------------------------------------------------
; Subroutine to determine what joypad you have, read joypad input, and send it to the RAM
; note: when requesting data from HW_Port_X_Data, an 8 cycle delay is mandatory
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Poll_Controllers:
	moveq	#$40,d3			; do first request
	lea	(Ctrl1).w,a0		; address where joypad states are written
	lea	(HW_Port_1_Data).l,a1	; first joypad port
	lea	(Ctrl1State).w,a2	; first joypad state
  if Joypad_2PSupport=1
	bsr.s	+			; do the first joypad
	addq.w	#HW_Port_2_Data-HW_Port_1_Data,a1	; second joypad port
+
  endif
  if Joypad_6BSupport=0	; simple 3pad controller code. Note how much simpler this code is.
	move.b	d3,(a1)		; request controller data
	moveq	#%00111111,d1	; DT (4) ; set the positions of B,C,Joypads as active
	moveq	#0,d2		; DT (4) ; Prepare for next request
	and.b	(a1),d1		; AND data with pressed B,C,Joypads

	move.b	d2,(a1)		; request controller data
	moveq	#%00110000,d0	; DT (4) ; set the positions of A and Start as active
	moveq	#0,d4		; DT (4) ; clear controller type (for a future where seq isn't enough)
	and.b	(a1),d0		; AND data with pressed A and Start
	lsl.b	#2,d0		; push data to the last two bits
	or.b	d1,d0		; combine them together
	move.b	d4,(a2)+	; set CtrlXState to whatever d4 has, increment to next controller
; copy final input data
	not.b	d0		; reverse bits (Only the 3pad inputs)
	move.w	(a0),d1		; Get previous held inputs
	move.w	d0,(a0)+	; Set new held inputs
	eor.w	d0,d1		;
	and.w	d0,d1		; mask held button inputs
	move.w	d1,(a0)+	; set pressed inputs
	rts

  elseif Joypad_6BSupport=1
	move.b	d3,(a1)		; request no.1
	moveq	#%00111111,d1	; DT (4) ; set the positions of B,C,Joypads as active
	moveq	#0,d2		; DT (4) ; Prepare for next request
	and.b	(a1),d1		; AND data with pressed B,C,Joypads

	move.b	d2,(a1)		; request no.2
	moveq	#%00110000,d0	; DT (4) ; set the positions of A and Start as active
	moveq	#0,d4		; DT (4) ; clear controller type
	and.b	(a1),d0		; AND data with pressed A and Start
; during all this downtime, sort out combining the main controller inputs
; functionally the same as the one on 3pad controls, just spread out across the downtime
	move.b	d3,(a1)		; request no.3
    if HardwareSafety=0
	lsl.b	#1,d0		; DT (8) ; push data to the last two bits
	move.b	d2,(a1)		; request no.4
	lsl.b	#1,d0		; DT (8) ; push data to the last two bits
	move.b	d3,(a1)		; request no.5
	or.b	d1,d0		; DT (4) ; combine the controller inputs
	moveq	#%00001111,d1	; DT (4) ; Prepare for 6 button controller check
	move.b	d2,(a1)		; request no.6
	nop		; DT (4)
	nop		; DT (4)
    else    ; fix bug when pressing up and down (impossible on regular joypads)
	lsl.b	#2,d0		; DT (10,2 bled) ; push data to the last two bits
	move.b	d2,(a1)		; request no.4
	or.b	d1,d0		; DT (4) ; combine the controller inputs
	move.w	d0,d5		; DT (4) ; copy 3pad input to d5
	move.b	d3,(a1)		; request no.5
	moveq	#%00000011,d1	; DT (4) ; Prepare for 3 button illegal input check
	and.w	d1,d5		; DT (4) ; and 3pad inputs to only have up and down
	move.b	d2,(a1)		; request no.6
; safety check: pressing up and down confuses the 6b check, it's best to default to 3b
	tst.b	d5		; DT (4) ; is up and down both being pressed?
	beq.s	+		; DT (8,4 bled) ; if so, branch (d4 should be 0)
    endif
; check the controller type
	move.b	(a1),d5		; copy no.6
	moveq	#%00001111,d1	; Prepare for 6 button controller check
	and.b	d1,d5		; only keep the first 4 bits
	seq	d4		; if d5 is 0, set d4 to -1 (6 button). Otherwise, set to 0 (3 button)
+
	move.b	d4,(a2)+	; set CtrlXState to whatever d4 has, increment to next controller
	beq.s	.handle3button	; if we're on a 3 button controller, branch

.handle6button
	move.b	d3,(a1)		; request controller data (no.7)
	moveq	#%00001111,d1	; DT (4) ; set the positions of X,Y,Z,Mode
	nop			; DT (4) ;
	and.b	(a1),d1		; AND data with pressed X,Y,Z,Mode
	lsl.w	#8,d1		; move to next byte
	or.w	d1,d0		; combine with other inputs
; copy final input data
	not.w	d0		; reverse bits
;.h3bcont:
	move.w	(a0),d1		; Get previous held inputs
	move.w	d0,(a0)+	; Set new held inputs
	eor.w	d0,d1		;
	and.w	d0,d1		; mask old inputs with new ones
	move.w	d1,(a0)+	; set pressed inputs
	rts

.handle3button
; copy final input data
	move.b	d3,(a1)		; request controller data (no.7) just in case
	not.b	d0		; reverse bits (Only the 3pad inputs)
;	bra.s	.h3bcont
	move.w	(a0),d1		; Get previous held inputs
	move.w	d0,(a0)+	; Set new held inputs
	eor.w	d0,d1		;
	and.w	d0,d1		; mask held button inputs
	move.w	d1,(a0)+	; set pressed inputs
	rts
  endif
; End of function Poll_Controllers
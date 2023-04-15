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
; note: when requesting controller data, an 8 cycle delay is mandatory
; USES:
; a0 = Final input RAM
; a1 = HW_Port_X_Data
; a2 = CtrlXState (Joypad_StateSupport)
; d0 = controller inputs 1, final    held inputs
; d1 = controller inputs 2, final pressed inputs
; d2 = control request type 1, controller type (3pad, Joypad_StateSupport)
; d3 = control request type 2
; d4 = misc (Joypad_6BSupport)
; d5 = controller type (6pad, Joypad_StateSupport)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Poll_Controllers:
	moveq	#$40,d3			; do first request
	lea	(Ctrl1).w,a0		; address where joypad states are written
	lea	(HW_Port_1_Data).l,a1	; first joypad port
  if Joypad_StateSupport=1
	lea	(Ctrl1State).w,a2	; first joypad state
  endif
  if Joypad_2PSupport=1
	bsr.s	+			; do the first joypad
	addq.w	#HW_Port_2_Data-HW_Port_1_Data,a1	; second joypad port
+
  endif
  if Joypad_6BSupport<>1	; simple 3pad controller code. Note how much simpler this code is.
	move.b	d3,(a1)			; request no.1
	moveq	#%00111111,d1		; DT (4) ; set the positions of B,C,Joypads as active
	moveq	#0,d2			; DT (4) ; Prepare for next request
	and.b	(a1),d1			; AND data with pressed B,C,Joypads

	move.b	d2,(a1)			; request no.2
	moveq	#%00110000,d0		; DT (4) ; set the positions of A and Start as active
;  if Joypad_StateSupport=1	; uncomment if 3pad isn't defined as 0
;	moveq	#0,d2			; DT (4) ; clear controller type (d2 gets reset every loop)
;  else
	nop				; DT (4)
;  endif
	and.b	(a1),d0			; AND data with pressed A and Start
	lsl.b	#2,d0			; push data to the last two bits
	or.b	d1,d0			; combine them together
  if Joypad_StateSupport=1
	move.b	d2,(a2)+		; set CtrlXState to whatever d2 has, increment to next controller
  endif
; copy final input data
	not.b	d0			; reverse bits (Only the 3pad inputs)
	move.w	(a0),d1			; Get previous held inputs
	move.w	d0,(a0)+		; Set new held inputs
	eor.w	d0,d1			;
	and.w	d0,d1			; mask held button inputs
	move.w	d1,(a0)+		; set pressed inputs
	rts

  elseif Joypad_6BSupport=1
	move.b	d3,(a1)			; request no.1
	moveq	#%00111111,d1		; DT (4) ; set the positions of B,C,Joypads as active
	moveq	#0,d2			; DT (4) ; Prepare for next request
	and.b	(a1),d1			; AND data with pressed B,C,Joypads

	move.b	d2,(a1)			; request no.2
	moveq	#%00110000,d0		; DT (4) ; set the positions of A and Start as active
    if Joypad_StateSupport=1
	moveq	#0,d5			; DT (4) ; clear controller type
    else
	nop				; DT (4)
    endif
	and.b	(a1),d0			; AND data with pressed A and Start
; during all this downtime, sort out combining the main controller inputs
; functionally the same as the one on 3pad controls, just spread out across the downtime
	move.b	d3,(a1)			; request no.3
    if HardwareSafety<>1
	lsl.b	#1,d0			; DT (8) ; push data to the last two bits
	move.b	d2,(a1)			; request no.4
	lsl.b	#1,d0			; DT (8) ; push data to the last two bits
	move.b	d3,(a1)			; request no.5
	or.b	d1,d0			; DT (4) ; combine the controller inputs
	moveq	#%00001111,d1		; DT (4) ; Prepare for 6pad check and positions of X,Y,Z,Mode
	move.b	d2,(a1)			; request no.6
;	nop2			; DT (8)
	or.l	d0,d0			; DT (8) ; stall time
    else
	lsl.b	#2,d0			; DT (10,2 bled) ; push data to the last two bits
	move.b	d2,(a1)			; request no.4
	or.b	d1,d0			; DT (4) ; combine the controller inputs
	moveq	#%00000011,d1		; DT (4) ; Prepare for 3 button illegal input check
	move.b	d3,(a1)			; request no.5
; safety check: pressing up and down confuses the 6pad check (impossible on regular joypads)
	move.b	d0,d4			; DT (4) ; copy 3pad inputs to d4
	and.b	d1,d4			; DT (4) ;  and 3pad inputs to only have up and down
	move.b	d2,(a1)			; request no.6
	tst.b	d4			; DT (4) ; is up and down both being pressed?
	beq.s	.handle6berror		; DT (8,4 bled) ; if so, branch
	moveq	#%00001111,d1		; Prepare for 6pad check and positions of X,Y,Z,Mode
    endif	; HardwareSafety
; check the controller type
	move.b	(a1),d4			; copy no.6
	and.b	d1,d4			; only keep the first 4 bits (%xxxx0000)
    if Joypad_StateSupport=1
	seq	d5			; if d4 is 0, set d5 to -1 (6 button). Otherwise, set to 0 (3 button)
	move.b	d5,(a2)+		; set CtrlXState to whatever d5 has, increment to next controller
	beq.s	.handle3button		; if we're on a 3 button controller, branch
    else
	bne.s	.handle3button		; if we're not on a 6 button controller, branch
    endif

.handle6button
	move.b	d3,(a1)			; request no.7
;	nop2			; DT (8)
	or.l	d0,d0			; DT (8) ; stall time
;	moveq	#%00001111,d1		; DT (4) ; set the positions of X,Y,Z,Mode
;	nop				; DT (4) ;
	and.b	(a1),d1			; AND data with pressed X,Y,Z,Mode
	lsl.w	#8,d1			; move to next byte
	or.w	d1,d0			; combine with other inputs
; copy final input data
	not.w	d0			; reverse bits
.h3padcont:
	move.w	(a0),d1			; Get previous held inputs
	move.w	d0,(a0)+		; Set new held inputs
	eor.w	d0,d1			;
	and.w	d0,d1			; mask old inputs with new ones
	move.w	d1,(a0)+		; set pressed inputs
	rts

  if HardwareSafety=1
.handle6berror
    if Joypad_StateSupport<>1	; this creates a pseudo-6pad mode
;	move.b	#-1,(a2)+		; set CtrlXState to 6pad, increment to next controller
	addq.w	#1,a2			; don't set CtrlXState, increment to next controller
    endif
  endif
.handle3button
; copy final input data
	move.b	d3,(a1)			; request no.7 (just in case)
	not.b	d0			; reverse bits (Only the 3pad inputs, high byte should be 0)
	bra.s	.h3padcont		; save a bit of space
;	move.w	(a0),d1			; Get previous held inputs
;	move.w	d0,(a0)+		; Set new held inputs
;	eor.w	d0,d1			;
;	and.w	d0,d1			; mask held button inputs
;	move.w	d1,(a0)+		; set pressed inputs
;	rts

  endif	; Joypad_6BSupport
; End of function Poll_Controllers

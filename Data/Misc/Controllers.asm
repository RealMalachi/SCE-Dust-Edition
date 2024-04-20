; https://plutiedev.com/controllers
; https://segaretro.org/Six_Button_Control_Pad_(Mega_Drive)
; Note: all code here expects an outside source to stop Z80 when running it, and preferably resume it directly after
; ---------------------------------------------------------------------------
; Subroutine to initialise joypads
; ---------------------------------------------------------------------------

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
; ---------------------------------------------------------------------------
; Subroutine to determine what joypad you have, read joypad input, and send it to the RAM
; note: when requesting controller data, an 8 cycle delay is mandatory
; USES:
; a0 = Final input RAM
; a1 = HW_Port_X_Data
; a2 = CtrlXState (Joypad_StateSupport)
; d0 = controller inputs 1, final    held inputs
; d1 = controller inputs 2, final pressed inputs
; d2 = control request type 1
; d3 = control request type 2
; d4 = misc (Joypad_6BSupport)
; d5 = controller type (6pad, Joypad_StateSupport)
; ---------------------------------------------------------------------------

Poll_Controllers:
	moveq	#0,d2			; do second
	moveq	#$40,d3			; do first request
	lea	(Ctrl1).w,a0		; address where joypad states are written
	lea	(HW_Port_1_Data).l,a1	; first joypad port
  if Joypad_StateSupport=1
	lea	(Ctrl1State).w,a2	; first joypad state
  endif
  if Joypad_MultiSupport
	bsr.w	TestMultiTap
;	moveq	#$40,d3
	move.b	d3,(HW_Port_1_Control).l	; init port 1 (joypad 1)
	move.b	d3,(HW_Port_1_Control).l	; init port 2 (joypad 2)
  endif
  if Joypad_2PSupport=1
	bsr.s	+			; do the first joypad
	addq.w	#HW_Port_2_Data-HW_Port_1_Data,a1	; second joypad port
+
  endif
  if Joypad_6BSupport<>1	; simple 3pad controller code. Note how much simpler this code is.
	move.b	d2,(a1)			; request no.1
	moveq	#%00111111,d1		; DT (4) ; set the positions of B,C,Joypads as active
	moveq	#%00110000,d0		; DT (4) ; set the positions of A and Start as active
	and.b	(a1),d0			; AND data with pressed A and Start

	move.b	d3,(a1)			; request no.3
	lsl.b	#2,d0			; DT (10, 2 bled) ; push data to the last two bits
	and.b	(a1),d1			; AND data with pressed B,C,Joypads
	or.b	d1,d0			; combine them together
  if Joypad_StateSupport=1
	moveq	#0,d5			; clear controller type
	move.b	d5,(a2)+		; set CtrlXState to whatever d5 has, increment to next controller
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
	moveq	#%00110000,d0		; DT (4) ; set the positions of A and Start as active
	and.b	(a1),d1			; AND data with pressed B,C,Joypads

	move.b	d2,(a1)			; request no.2
    if Joypad_StateSupport=1
	moveq	#0,d5			; DT (4) ; clear controller type
	nop				; DT (4)
    else
	nop2				; DT (8)
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
	nop2				; DT (8)
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
	moveq	#%00001111,d1		; Prepare for 6pad check
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
	moveq	#%00001111,d1		; DT (4) ; set the positions of X,Y,Z,Mode
	nop				; DT (4) ;
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
; if no ability to figure out if it was a 6pad, just use 3pad
    if Joypad_StateSupport=1	; this creates a pseudo-6pad mode
;	move.b	#-1,(a2)+		; set CtrlXState to 6pad, increment to next controller
;	addq.w	#1,a2			; don't set CtrlXState, increment to next controller
	tst.b	(a2)+			; use previous frames CtrlXState to determine if the controller was a 3pad or not
	bne.s	.handle6button		; if 0, 3pad. Otherwise, 6pad
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
	if Joypad_MultiSupport=1
; ---------------------------------------------------------------------------
; Subroutine to handle EA MultiTap
; TODO: 6pad is broken. Find (or better yet, make) proper documentation and solve this issue
EAMULTI_1P =		$0C ; Controller #1
EAMULTI_2P =		$1C ; Controller #2
EAMULTI_3P =		$2C ; Controller #3
EAMULTI_4P =		$3C ; Controller #4
EAMULTI_ID =		$7C ; Multitap ID
Multi6padStall macro
	move.b	#EAMULTI_1P,(a3)
	nop2
	nop2
	move.b	#EAMULTI_2P,(a3)
	nop2
	nop2
	move.b	#EAMULTI_3P,(a3)
	nop2
	nop2
	move.b	#EAMULTI_4P,(a3)
	nop2
	nop2
	endm

TestMultiTap:
;	moveq	#0,d2			; do second
;	moveq	#$40,d3			; do first request
;	lea	(Ctrl1).w,a0		; address where joypad states are written
;	lea	(HW_Port_1_Data).l,a1	; first joypad port
;  if Joypad_StateSupport=1
;	lea	(Ctrl1State).w,a2	; first joypad state
;  endif
; Set up ports to check for EA multitap
	move.b	d3,HW_Port_1_Control-HW_Port_1_Data(a1)
	move.b	#$7F,HW_Port_2_Control-HW_Port_1_Data(a1)
	move.b	d3,(a1)
; Read from multitap ID
	move.b	#EAMULTI_ID,HW_Port_2_Data-HW_Port_1_Data(a1)
	moveq	#%0000011,d0
	moveq	#%0000011,d1
	and.b	(a1),d0
; Read from controller #1
	move.b	#EAMULTI_1P,HW_Port_2_Data-HW_Port_1_Data(a1)
	nop2
	and.b	(a1),d1
	tst.b	d0		; check ID result
	bne	.notEA		; if not 0, branch
	tst.b	d1		; check joypad input
	beq	.notEA		; if 0, branch
; EA multitap present...
	addq.w	#4,sp		; don't return to regular 3pad and 6pad input
	lea	HW_Port_2_Data-HW_Port_1_Data(a1),a3

	moveq	#$40,d7
	move.b	d7,(a1)		; 1, $40
	move.b	#EAMULTI_1P,(a3)
	swap	d7			; DT (4) ; 0
	moveq	#%00111111,d0		; DT (4) ; set the positions of B,C,Joypads as active
	moveq	#%00111111,d1		; DT (4) ; set the positions of B,C,Joypads as active
	and.b	(a1),d0
	move.b	#EAMULTI_2P,(a3)
	moveq	#%00111111,d2		; DT (4) ; set the positions of B,C,Joypads as active
	nop2
	and.b	(a1),d1
	move.b	#EAMULTI_3P,(a3)
	moveq	#%00111111,d3		; DT (4) ; set the positions of B,C,Joypads as active
	nop2
	and.b	(a1),d2
	move.b	#EAMULTI_4P,(a3)
	moveq	#%00110000,d4		; DT (4) ; set the positions of A and Start as active
	moveq	#%00110000,d5		; DT (4) ; set the positions of A and Start as active
	moveq	#%00110000,d6		; DT (4) ; set the positions of A and Start as active
	and.b	(a1),d3

	move.b	d7,(a1)		; 2, 0
	move.b	#EAMULTI_1P,(a3)
	swap	d7			; DT (4) ; $40
	nop2
	and.b	(a1),d4
	move.b	#EAMULTI_2P,(a3)
	lsl.b	#2,d4
	or.b	d4,d0
	and.b	(a1),d5
	move.b	#EAMULTI_3P,(a3)
	lsl.b	#2,d5
	or.b	d5,d1
	and.b	(a1),d6
	move.b	#EAMULTI_4P,(a3)
	lsl.b	#2,d6
	moveq	#%00110000,d4		; DT (4) ; set the positions of A and Start as active
	and.b	(a1),d4
	or.b	d6,d2
;  if Joypad_6BSupport=0
  if Joypad_6BSupport<>77
	lsl.b	#2,d4
	or.b	d4,d3

	not.b	d0			; reverse bits (Only the 3pad inputs, high byte should be 0)
	move.w	(a0),d4			; Get previous held inputs
	move.w	d0,(a0)+		; Set new held inputs
	eor.w	d0,d4			;
	and.w	d0,d4			; mask old inputs with new ones
	move.w	d4,(a0)+		; set pressed inputs

	not.b	d1			; reverse bits (Only the 3pad inputs, high byte should be 0)
	move.w	(a0),d4			; Get previous held inputs
	move.w	d1,(a0)+		; Set new held inputs
	eor.w	d1,d4			;
	and.w	d1,d4			; mask old inputs with new ones
	move.w	d4,(a0)+		; set pressed inputs

	not.b	d2			; reverse bits (Only the 3pad inputs, high byte should be 0)
	move.w	(a0),d4			; Get previous held inputs
	move.w	d2,(a0)+		; Set new held inputs
	eor.w	d2,d4			;
	and.w	d2,d4			; mask old inputs with new ones
	move.w	d4,(a0)+		; set pressed inputs

	not.b	d3			; reverse bits (Only the 3pad inputs, high byte should be 0)
	move.w	(a0),d4			; Get previous held inputs
	move.w	d3,(a0)+		; Set new held inputs
	eor.w	d3,d4			;
	and.w	d3,d4			; mask old inputs with new ones
	move.w	d4,(a0)+		; set pressed inputs
  else
	move.b	d7,(a1)		; 3, $40
	Multi6padStall
	swap	d7			; DT (4) ; 0
	lsl.b	#2,d4
	or.b	d4,d3
	move.b	d7,(a1)		; 4, 0
	Multi6padStall
	swap	d7			; DT (4) ; $40
	moveq	#%00001111,d4		; DT (4) ; Prepare for 6pad check and positions of X,Y,Z,Mode
	nop
	move.b	d7,(a1)		; 5, $40
	Multi6padStall
	swap	d7			; DT (4) ; 0
	nop2
	move.b	d7,(a1)		; 6, 0
	Multi6padStall
	swap	d7			; DT (4) ; $40
	nop2

	move.b	d7,(a1)		; 7, $40		; after this, we can now use d7 for checks
	move.b	#EAMULTI_1P,(a3)
	moveq	#%00001111,d5		; DT (4) ; Prepare for 6pad check and positions of X,Y,Z,Mode
	moveq	#%00001111,d6		; DT (4) ; Prepare for 6pad check and positions of X,Y,Z,Mode
	moveq	#%00001111,d7		; DT (4) ; Prepare for 6pad check and positions of X,Y,Z,Mode
	and.b	(a1),d4

	move.b	#EAMULTI_2P,(a3)
	nop3
	and.b	(a1),d5

	move.b	#EAMULTI_3P,(a3)
	nop3
	and.b	(a1),d6

	move.b	#EAMULTI_4P,(a3)
	nop3
	and.b	(a1),d7

	lsl.w	#8,d4
	or.w	d4,d0
	lsl.w	#8,d5
	or.w	d5,d1
	lsl.w	#8,d6
	or.w	d6,d2
	lsl.w	#8,d7
	or.w	d7,d3

	not.w	d0			; reverse bits (Only the 3pad inputs, high byte should be 0)
	move.w	(a0),d4			; Get previous held inputs
	move.w	d0,(a0)+		; Set new held inputs
	eor.w	d0,d4			;
	and.w	d0,d4			; mask old inputs with new ones
	move.w	d4,(a0)+		; set pressed inputs

	not.w	d1			; reverse bits (Only the 3pad inputs, high byte should be 0)
	move.w	(a0),d4			; Get previous held inputs
	move.w	d1,(a0)+		; Set new held inputs
	eor.w	d1,d4			;
	and.w	d1,d4			; mask old inputs with new ones
	move.w	d4,(a0)+		; set pressed inputs

	not.w	d2			; reverse bits (Only the 3pad inputs, high byte should be 0)
	move.w	(a0),d4			; Get previous held inputs
	move.w	d2,(a0)+		; Set new held inputs
	eor.w	d2,d4			;
	and.w	d2,d4			; mask old inputs with new ones
	move.w	d4,(a0)+		; set pressed inputs

	not.w	d3			; reverse bits (Only the 3pad inputs, high byte should be 0)
	move.w	(a0),d4			; Get previous held inputs
	move.w	d3,(a0)+		; Set new held inputs
	eor.w	d3,d4			;
	and.w	d3,d4			; mask old inputs with new ones
	move.w	d4,(a0)+		; set pressed inputs

;	moveq	#0,d7
;	move.b	d7,(a1)		; 8, 0
;	Multi6padStall
  endif		; Joypad_6BSupport

.notEA
	rts
	endif	; Joypad_MultiSupport

; ---------------------------------------------------------------------------
; Subroutine to calculate a square root, originates from Sonic 1 REV00 (unused)

; input
;	d0 = number
; output
;	d0 = square root of number
; ---------------------------------------------------------------------------
SquareRootUnroll = 0

CalcSqrt:
Get_SquareRoot:
; init
	move.w	d0,d1
	swap	d1
	moveq	#0,d0
	move.w	d0,d1

	if SquareRootUnroll = 0
	moveq	#8-1,d2
.loop
	rol.l	#2,d1
	add.w	d0,d0
	addq.w	#1,d0
	sub.w	d0,d1
	bcc.s	+
	add.w	d0,d1
	subq.w	#1,d0
	dbf	d2,.loop
	lsr.w	#1,d0
	rts
+
	addq.w	#1,d0
	dbf	d2,.loop
	lsr.w	#1,d0
	rts

	else
	rept 8
	rol.l	#2,d1
	add.w	d0,d0
	addq.w	#1,d0
	sub.w	d0,d1
	bcc.s	+
	add.w	d0,d1
	subq.w	#1+1,d0
+	addq.w	#1,d0
	endr

	lsr.w	#1,d0
	rts

	endif
; End of function CalcSqrt

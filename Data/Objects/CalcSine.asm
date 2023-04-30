; ---------------------------------------------------------------------------
; Calculates the sine and cosine of the angle in d0 (360 degrees = 256)
; Returns the sine in d0 and the cosine in d1 (both multiplied by $100)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

CalcSine:
GetSineCosine:
; the two before the uncommented addq are basically a makeshift andi.w #$FF,d0, but moving d0 to d1
; this allows cosine to be handled last, and opens an optional unsafe call which can save 4 cycles
		clr.w	d1
CalcSine.unsafe:
GetSineCosine.unsafe:
		move.b	d0,d1
; assumes d1 is angle, and the high byte is already clear
CalcSine.angd1:
GetSineCosine.angd1:
;		addq.w	#8/2,d1				; add 8 (4x2) so cosine can reach further
		add.w	d1,d1				; double because we're handling words
		move.w	SineTable(pc,d1.w),d0		; sin
		addq.w	#8,d1				; add 8 so cosine can reach further
		move.w	SineTable+($40*2)-8(pc,d1.w),d1	; cos ; $40 = 90 degrees, sin(x+90) = cos(x)
		rts
; ---------------------------------------------------------------------------

SineTable:	binclude "Misc Data/Sine.bin"
	even
; ---------------------------------------------------------------------------
; if calc = 0 or nothing, get sine in d0 and cosine in d1
; if 1, get   sine in d0
; if 2, get cosine in d1
; if 3, get cosine in d0
calcsine_macro macro reg,calc,unsafe
	if ("calc"="0") || ("calc"="")
	    if ("unsafe"="0") || ("unsafe"="")
		clr.w	d1
	    endif
		move.b	d0,d1
		add.w	d1,d1				; double because we're handling words
		lea	(SineTable).w,reg
		add.w	d1,reg				; add angle to sine table
		move.w	(reg),d0			; sin
		move.w	$40*2(reg),d1			; cos ; $40 = 90 degrees, sin(x+90) = cos(x)
	elseif calc=1
		andi.w	#$FF,d0
		add.w	d0,d0				; double because we're handling words
		lea	(SineTable).w,reg
		move.w	(reg,d0.w),d0			; sin
	elseif calc=2
	    if ("unsafe"="0") || ("unsafe"="")
		clr.w	d1
	    endif
		move.b	d0,d1
		add.w	d1,d1				; double because we're handling words
		lea	(SineTable+($40*2)).w,reg	; $40 = 90 degrees, sin(x+90) = cos(x)
		move.w	(reg,d1.w),d1			; cos
	elseif calc=3
		andi.w	#$FF,d0
		add.w	d0,d0				; double because we're handling words
		lea	(SineTable+($40*2)).w,reg	; $40 = 90 degrees, sin(x+90) = cos(x)
		move.w	(reg,d0.w),d0			; cos
	else
	fatal "CalcSine macro type not defined"
	endif
	endm

;	calcsine_macro a1
;	calcsine_macro a1,0
;	calcsine_macro a1,1
;	calcsine_macro a1,2
;	calcsine_macro a1,3
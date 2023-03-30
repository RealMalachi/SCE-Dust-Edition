; ===========================================================================
; MoveSprite routines
; Macro by Malachi (you can tell because it's shit)
; MoveSprite variant by flamewing, uses d1 as opposed to original example of d2. Adjust if needed
; original code: https://forums.sonicretro.org/index.php?threads/some-changes-and-fixes-for-sonic-2.29029/page-14
; if fall = 0, don't update gravity
; if fall = anything but 0, add gravity to y_vel to apply velocity. Downwards by default
; if upw  = 1, move upward
; if reg  = 1, also use a register to set velocity
; if regupw = 1, same as upw for register velocity
; if rev = 1, reverse gravity if flag is 1
; if rev = 2, reverse gravity if flag is 0
; if rev = 3, always apply reverse gravity
; TODO: Find a way to use a1 for objects
MoveSprite_macro macro fall,rev,reg,upw,regupw
	movem.w	x_vel(a0),d0-d1	; Does sign extension (ext) for free
  if ReverseGravity = 1	; if ReverseGravity isn't 1, ignore dynamic checks
    if ("rev"="0") || ("rev"="")
    elseif rev=1	; if rev = 1, check for reverse gravity. If so, reverse d0 (which is storing y velocity)
	tst.b	(Reverse_gravity_flag).w; is reverse gravity active?
	beq.s	.norevgrav	; if not, branch
	neg.w	d1		; reverse
	ext.l	d1	; extend again
.norevgrav:
    elseif rev=2	; if rev = 2, check for reverse gravity. If so, reverse d0 (which is storing y velocity)
	tst.b	(Reverse_gravity_flag).w; is reverse gravity active?
	bne.s	.norevgrav	; if so, branch
	neg.w	d1		; reverse
	ext.l	d1		; extend again
.norevgrav:
    endif	; rev
  endif	; ReverseGravity
  if ("rev"="0") || ("rev"="")	; this is so it's separate from the dynamic reversing
  elseif rev=3	; if rev = 3, always apply reverse gravity to calculation
	neg.w	d1		; reverse
	ext.l	d1		; extend again
  endif
	asl.l	#8,d0		; shift velocity to line up with the middle 16 bits of the 32-bit position
	asl.l	#8,d1		; shift velocity to line up with the middle 16 bits of the 32-bit position
	add.l	d0,x_pos(a0)	; add X speed to X position ; note this affects x_sub
	add.l	d1,y_pos(a0)	; add Y speed to Y position ; note this affects y_sub
  if ("reg"="0") || ("reg"="")	; if reg = 1, handle velocity with a register
  else
    if ("regupw"="0") || ("regupw"="")
	add.w	reg,y_vel(a0)	; increase vertical speed (apply downward gravity)
    else  ; regupw
	sub.w	reg,y_vel(a0)	; increase vertical speed (apply upward gravity)
    endif ; regupw
  endif ; reg
  if ("fall"="0") || ("fall"="")	; if fall = anything but 0, it has gravity
  else
    if ("upw"="0") || ("upw"="")	; if upw = 1, subi instead of addi (fall up)
	add.w	#fall,y_vel(a0)	; increase vertical speed (apply downward gravity)
    else  ; upw
	sub.w	#fall,y_vel(a0)	; increase vertical speed (apply upward gravity)
    endif
  endif ; fall
	endm

; =============== S U B R O U T I N E =======================================

ObjectFall:
MoveSprite:
	MoveSprite_macro $38
	rts

; =============== S U B R O U T I N E =======================================

SpeedToPos:
MoveSprite2:
	MoveSprite_macro
	rts

; =============== S U B R O U T I N E =======================================

MoveSprite_TestGravity:
	tst.b	(Reverse_gravity_flag).w
	beq.s	MoveSprite

MoveSprite_ReverseGravity:
	MoveSprite_macro $38,3
	rts

; =============== S U B R O U T I N E =======================================

MoveSprite2_TestGravity:
	tst.b	(Reverse_gravity_flag).w
	beq.s	MoveSprite2

MoveSprite2_ReverseGravity:
	MoveSprite_macro 0,3
	rts

; =============== S U B R O U T I N E =======================================

MoveSprite_LightGravity:
	moveq	#$20,d2

MoveSprite_CustomGravity:
	MoveSprite_macro 0,0,d2
	rts

; =============== S U B R O U T I N E =======================================

MoveSprite_NormGravity:	; -____-
	moveq	#$38,d2

MoveSprite_CustomGravity2:
	movem.w	x_vel(a1),d0-d1	; load xy speed
;	ext.l	d0
	asl.l	#8,d0
	add.l	d0,x_pos(a1)
;	ext.l	d1
	asl.l	#8,d1
	add.l	d1,y_pos(a1)
	add.w	d2,y_vel(a1)
	rts

; =============== S U B R O U T I N E =======================================

MoveSprite_Reserve:
	movem.w	x_vel(a0),d0-d1	; load xy speed
;	ext.l	d0
	asl.l	#8,d0
	add.l	d0,objoff_30(a0)
;	ext.l	d1
	asl.l	#8,d1
	add.l	d1,objoff_34(a0)
	addi.w	#$38,y_vel(a0)
	rts

; =============== S U B R O U T I N E =======================================

MoveSprite2_Reserve:
	movem.w	x_vel(a0),d0-d1	; load xy speed
;	ext.l	d0
	asl.l	#8,d0
	add.l	d0,objoff_30(a0)
;	ext.l	d1
	asl.l	#8,d1
	add.l	d1,objoff_34(a0)
	rts

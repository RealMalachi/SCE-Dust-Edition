; ---------------------------------------------------------------------------
; Subroutine to display	a sprite/object, when a0 is the object RAM
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

DrawSpriteUnsafe_cus_macro macro prid,obj,reg
	if ("prid"=="")
	movea.w	priority(obj),reg
	elseif ("prid"=="set") || ("prid"=="s")
;  if ErrorChecks<>0	; make sure it's set.
;	cmpa.w	#Sprite_table_input,reg	; is it in the table input?
;	blo.s	+			; if not, branch
;	cmpa.w	#Sprite_table_input+(next_priority*priority_queue),reg	; is it in the table input?
;	blo.s	++			; if not, branch
;+
;	RaiseError "Object render priority not set:", Debug_Priority
;	rts
;+
;  endif
	elseif prid <= priority_queue	; prid >=0 &&
	movea.w	#make_priority(prid),reg
	else
	fatal "Priority exceeds the intended amount of queue (prid)"
	endif
	move.w	(reg),d0		; get the amount of objects in the queue
	addq.w	#2,d0		; add to the queue amount
	move.w	d0,(reg)		; copy the addition to the queue amount
	move.w	obj,(reg,d0.w)	; copy the objects address to the queue
	endm

DrawSpriteUnsafe_macro macro prid
	DrawSpriteUnsafe_cus_macro prid,a0,a1
	endm
DrawOtherSpriteUnsafe_macro macro prid
	DrawSpriteUnsafe_cus_macro prid,a1,a2
	endm
; originally made by lavagaming1
Draw_Sprite:
DisplaySprite:
	movea.w	priority(a0),a1
Draw_Sprite.set:
DisplaySprite.set:
  if ErrorChecks<>0
	cmpa.w	#Sprite_table_input,a1	; is it in the table input?
	blo.s	.error			; if not, branch
	cmpa.w	#Sprite_table_input+(next_priority*priority_queue),a1	; is it in the table input?
	bhi.s	.error			; if not, branch
  endif
	move.w	(a1),d0			; get the amount of objects in the queue
	cmp.w	#next_priority-2,d0	; is it full?
;	blo.s	.queue		; if you want to save space over speed
	bhs.s	.loop			; if so, branch
	addq.w	#2,d0			; add to the queue amount
	move.w	d0,(a1)			; copy the addition to the queue amount
	move.w	a0,(a1,d0.w)		; copy the objects address to the queue
	rts
.loop:
	cmpa.w	#Sprite_table_input+(next_priority*priority_queue),a1	; have we exceeded the rendering queue RAM?
	bhs.s	.rts			; if so, branch
	lea	next_object(a1),a1	; check next priority queue
	move.w	(a1),d0
	cmp.w	#next_priority-2,d0
	bhs.s	.loop
;.queue:
	addq.w	#2,d0
	move.w	d0,(a1)
	move.w	a0,(a1,d0.w)
.rts:
	rts
  if ErrorChecks<>0
.error:
	RaiseError "Object render priority not set:", Debug_Priority
	rts
  endif

; =============== S U B R O U T I N E =======================================

Draw_And_Touch_Sprite:
		bsr.w	Add_SpriteToCollisionResponseList
		bra.w	Draw_Sprite
; ---------------------------------------------------------------------------

Child_Draw_Sprite:
		movea.w	parent3(a0),a1
		btst	#7,status(a1)
		bne.w	Go_Delete_Sprite
		bra.w	Draw_Sprite
; ---------------------------------------------------------------------------

Child_DrawTouch_Sprite:
		movea.w	parent3(a0),a1
		btst	#7,status(a1)
		bne.w	Go_Delete_Sprite
		bsr.w	Add_SpriteToCollisionResponseList
		bra.w	Draw_Sprite
; ---------------------------------------------------------------------------

Child_CheckParent:
		movea.w	parent3(a0),a1
		btst	#7,status(a1)
		bne.w	Go_Delete_Sprite
		rts
; ---------------------------------------------------------------------------

Child_AddToTouchList:
		movea.w	parent3(a0),a1
		btst	#7,status(a1)
		bne.w	Go_Delete_Sprite
		bra.w	Add_SpriteToCollisionResponseList
; ---------------------------------------------------------------------------

Child_Remember_Draw_Sprite:
		movea.w	parent3(a0),a1
		btst	#7,status(a1)
		bne.s	loc_84984
		bra.w	Draw_Sprite
; ---------------------------------------------------------------------------

loc_84984:
		bsr.w	Remove_From_TrackingSlot
		bra.w	Go_Delete_Sprite
; ---------------------------------------------------------------------------

Child_Draw_Sprite2:
		movea.w	parent3(a0),a1
		btst	#4,objoff_38(a1)
		bne.s	loc_8499E
		bra.w	Draw_Sprite
; ---------------------------------------------------------------------------

loc_8499E:
		bra.w	Go_Delete_Sprite_2
; ---------------------------------------------------------------------------

Child_DrawTouch_Sprite2:
		movea.w	parent3(a0),a1
		btst	#4,objoff_38(a1)
		bne.s	loc_8499E
		btst	#7,status(a1)
		bne.s	loc_849BC
		bsr.w	Add_SpriteToCollisionResponseList

loc_849BC:
		bra.w	Draw_Sprite
; ---------------------------------------------------------------------------

Child_Draw_Sprite_FlickerMove:
		movea.w	parent3(a0),a1
		btst	#7,status(a1)
		bne.s	loc_849D8
		bra.w	Draw_Sprite
; ---------------------------------------------------------------------------

loc_849D8:
		bset	#7,status(a0)
		move.l	#Obj_FlickerMove,address(a0)
		clr.b	collision_flags(a0)
		bsr.w	Set_IndexedVelocity
		bra.w	Draw_Sprite
; ---------------------------------------------------------------------------

Child_Draw_Sprite2_FlickerMove:
		movea.w	parent3(a0),a1
		btst	#4,objoff_38(a1)
		bne.s	loc_849D8
		bra.w	Draw_Sprite
; ---------------------------------------------------------------------------

Child_DrawTouch_Sprite_FlickerMove:
		movea.w	parent3(a0),a1
		btst	#7,status(a1)
		bne.s	loc_849D8

loc_84A3C:
		bsr.w	Add_SpriteToCollisionResponseList
		bra.w	Draw_Sprite
; ---------------------------------------------------------------------------

Child_DrawTouch_Sprite2_FlickerMove:
		movea.w	parent3(a0),a1
		btst	#4,objoff_38(a1)
		bne.s	loc_849D8
		btst	#7,status(a1)
		beq.s	loc_84A3C
		bset	#7,status(a0)
		bra.w	Draw_Sprite

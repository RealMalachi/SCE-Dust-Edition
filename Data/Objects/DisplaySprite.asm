; ---------------------------------------------------------------------------
; Subroutine to display	a sprite/object, when a0 is the object RAM
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================
DrawSpriteUnsafe_macro macro prid
	if ("prid"=="")
	movea.w	priority(a0),a1
	else
	movea.w	#make_priority(prid),a1
	endif
;	lea	(Sprite_table_input).w,a1
;	adda.w	priority(a0),a1
	move.w	(a1),d0		; get the amount of objects in the queue
	addq.w	#2,d0		; add to the queue amount
	move.w	d0,(a1)		; copy the addition to the queue amount
	move.w	a0,(a1,d0.w)	; copy the objects address to the queue
	endm

DrawOtherSpriteUnsafe_macro macro prid
	if ("prid"=="")
	movea.w	priority(a1),a2
	else
	movea.w	#make_priority(prid),a2
	endif
;	lea	(Sprite_table_input).w,a2
;	adda.w	priority(a1),a2
	move.w	(a2),d0		; get the amount of objects in the queue
	addq.w	#2,d0		; add to the queue amount
	move.w	d0,(a2)		; copy the addition to the queue amount
	move.w	a1,(a2,d0.w)	; copy the objects address to the queue
	endm
; originally made by lavagaming1
Draw_Sprite:
DisplaySprite:
	movea.w	priority(a0),a1
;	lea	(Sprite_table_input).w,a1
;	adda.w	priority(a0),a1
  if GameDebug=1
	cmpa.w	#make_priority(0),a1	; is it in the table input?
	blo.s	.error			; if not, branch
	cmpa.w	#make_priority(7)+next_priority,a1	; is it in the table input?
	bhs.s	.error			; if not, branch
  endif
	move.w	(a1),d0			; get the amount of objects in the queue
	cmp.w	#next_priority-2,d0	; is it full?
;	blo.s	.queue			; if you want to save space over speed
	bhs.s	.loop			; if so, branch
	addq.w	#2,d0			; add to the queue amount
	move.w	d0,(a1)			; copy the addition to the queue amount
	move.w	a0,(a1,d0.w)		; copy the objects address to the queue
	rts
.loop:
	cmpa.w	#Sprite_table_input+(next_priority*7),a1	; have we exceeded the rendering queue RAM?
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
  if GameDebug=1
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

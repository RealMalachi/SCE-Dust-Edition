
; set beforehand
; a6 = offset address
; d6 = offset frame
; d0 = player x_pos
; d1 = player y_pos
; creates
; d2 = offsettled x
; d3 = offsettled y
Invinc_RotateAnim_OffRead macro unsafe
;    if ("unsafe"=="")
	andi.w	#$7F,d6
;    endif
	move.w	(a6,d6.w),d2	; put offset into d2...
	move.w	2(a6,d6.w),d3	; ...and d3
	add.w	d0,d2		; then add the x_pos of player to it...
	add.w	d1,d3		; ...ditto for y_pos. this is the new invincibility position
	endm

; =============== S U B R O U T I N E =======================================
; the object now makes use of the parent sprite rendering
Invinc_RotateOffset		= x_sub			; byte
Invinc_AnimFrame		= Invinc_RotateOffset+1	; byte
; for multidrawn sprites
; sub 9 is off limits
Invinc_Subs_RotateOffset	= sub2_mapframe-1
Invinc_Sub_AnimFrame		= (sub3_mapframe-1)-sub3_x_pos	; 3,5,7
Invinc_Sub_ParentFrameOffset	= (sub4_mapframe-1)-sub3_x_pos	; 4,6,8
Invinc_sub3animbuffer		= routine ; sub3_mapframe-1 is mapping_frame, so we have to do some funky shit

Obj_Invincibility_Delete:
	move.l	LastLoadedShield(a0),a1
	move.l	a1,address(a0)	
	jmp	(a1)	; reload shield

Obj_Invincibility:
	QueueStaticDMA ArtUnc_Invincibility,tiles_to_bytes(29),tiles_to_bytes(ArtTile_Shield)	; load art
	move.b	#ren_camerapos|objflag_continue|ren_multidraw,render_flags(a0)
	move.w	#bytes_to_word(32/2,32/2),height_pixels(a0)			; set height and width
	move.w	#make_priority(1),priority(a0)
	move.w	#make_art_tile(ArtTile_Shield,0,1),art_tile(a0)
	move.l	#Map_Invincibility,mappings(a0)

	clr.b	Invinc_Subs_RotateOffset(a0)
; set up (actual) subsprites
	lea	off_187DE(pc),a2
	lea	sub3_x_pos(a0),a5
	moveq	#3-1,d1	; set loop amount
-
	clr.b	Invinc_Sub_AnimFrame(a5)
	move.b	(a2)+,Invinc_Sub_ParentFrameOffset(a5)
	lea	sub5_x_pos-sub3_x_pos(a5),a5
	dbf	d1,-
	move.w	#7,mainspr_childsprites(a0)	; set child sprite amount
	move.l	#.main,address(a0)
.main:
	movea.w	Shield_PlayerAddr(a0),a1
	tst.b	invincibility_timer(a1)		; is the timer still going?
;	btst	#Status_Invincible,status_secondary(a1)	; are we still invincible?
	beq.w	Obj_Invincibility_Delete	; if not, branch
	andi.w	#drawing_mask,art_tile(a0)
	tst.w	art_tile(a1)
	bpl.s	+
	ori.w	#high_priority,art_tile(a0)
+
; load addresses you'll be using a lot
	lea	Invincibility_AnimationAddress(pc),a3	; animation address
; a4 is used for temporary addresses
	lea	sub2_x_pos(a0),a5		; get multidraw area
	lea	Invincibility_PreCalcRotation(pc),a6	; Invinc_RotateAnim_OffRead
; load base position
	move.w	x_pos(a1),d0			; Copy player x_pos
	move.w	y_pos(a1),d1			; ditto
; animation
	moveq	#0,d2
	movea.l	(a3)+,a4
	move.b	Invinc_AnimFrame(a0),d2		; copy animation timer to d2
	move.b	(a4,d2.w),d5			; use it to get new frame, put that to d5
	bpl.s	+				; if its not $FF, branch
	moveq	#0,d2				; if it is, reset frame timer...
	move.b	d2,Invinc_AnimFrame(a0)
	move.b	(a4),d5				; ...then set d5 to the first frame
+
	addq.b	#1,Invinc_AnimFrame(a0)		; increment for next frame
	add.b	#byte_189E0.child-byte_189E0,d2	; add offset to animation timer
	move.b	(a4,d2.w),d4			; get child frame
; rotation
;	moveq	#7,d4	; debug
;	moveq	#7,d5
;	moveq	#0,d6
	move.b	Invinc_RotateOffset(a0),d6	; prepare rotation offset
	Invinc_RotateAnim_OffRead 0
	move.w	d2,x_pos(a0)			; set x_pos
	move.w	d3,y_pos(a0)			; set y_pos
;	move.b	d5,mapping_frame(a0)		; set mapping frame
	move.w	d5,-(sp)	; save mapping frame for later
	addi.b	#16*4,d6			; move up by halfway into the rotation
	Invinc_RotateAnim_OffRead
	move.w	d2,(a5)+			; set x_pos
	move.w	d3,(a5)+			; set y_pos
	addq.w	#1,a5		; skip Invinc_Subs_RotateOffset
	move.b	d4,(a5)+			; set mapping frame
	moveq	#(9*4),d5			;
	btst	#Status_Facing,status(a1)	; is player facing left?
	beq.s	+				; if not, branch
	moveq	#-(9*4),d5			; reverse
+
	add.b	d5,Invinc_RotateOffset(a0)	; add rotation for next frame
	bsr.w	Draw_Sprite			; render before setting up all the other stars.
; init offset stars
	moveq	#(1*4),d5			;
	btst	#Status_Facing,status(a1)	; is player facing left?
	beq.s	+				; if not, branch
	moveq	#-(1*4),d5			; reverse
+
;	moveq	#0,d6
	move.b	Invinc_Subs_RotateOffset(a0),d6	; prepare rotation offset
	add.b	d5,Invinc_Subs_RotateOffset(a0) ; add rotation for next frame
	lea	(Pos_table).w,a2		; load position table from player object
	move.w	(Pos_table_index).w,d7	; a1 is free.
; handle offset stars
	move.b	Invinc_sub3animbuffer(a0),mapping_frame(a0)
	bsr.s	+
	move.b	mapping_frame(a0),Invinc_sub3animbuffer(a0)
	move.w	(sp)+,d5
	move.b	d5,mapping_frame(a0)
	bsr.w	+	; second to last loop needs to be .w due to range overflow
+
;Obj_Invincibility_HandleSubs:
; load base position
	sub.b	#4*3,d7				; decrement to next offset (two words*3 offset)
	move.w	d7,d0				; copy number in Pos_table_index to d0
	lea	(a2,d0.w),a4			; use that to figure out which saved position to use, send address of that to a2
	move.w	(a4)+,d0			; use this for x_pos...
	move.w	(a4)+,d1			; ...and this for y_pos
; animation
;	moveq	#0,d4
;	moveq	#0,d5
	movea.l	(a3)+,a4
	moveq	#0,d2
	move.b	Invinc_Sub_AnimFrame(a5),d2	; copy animation timer to d2
	move.b	(a4,d2.w),d5			; use it to get new frame, put that to d5
	bpl.s	+				; if its not $FF, branch
	moveq	#0,d2				; if it is, reset frame timer...
	move.b	d2,Invinc_Sub_AnimFrame(a5)
	move.b	(a4),d5				; ...then set d5 to the first frame
+
	addq.b	#1,Invinc_Sub_AnimFrame(a5)	; increment for next time
	add.b	Invinc_Sub_ParentFrameOffset(a5),d2	; add offset to animation timer
	move.b	(a4,d2.w),d4			; get child frame
; rotation
;	moveq	#7,d4	; debug
;	moveq	#7,d5
	Invinc_RotateAnim_OffRead
	move.w	d2,(a5)+			; set x_pos
	move.w	d3,(a5)+			; set y_pos
	addq.w	#1,a5		; skip Invinc_Sub_AnimFrame
	move.b	d5,(a5)+			; set mapping frame
	addi.b	#16*4,d6			; move up by halfway into the rotation
	Invinc_RotateAnim_OffRead
	move.w	d2,(a5)+			; set x_pos
	move.w	d3,(a5)+			; set y_pos
	addq.w	#1,a5		; skip Invinc_Sub_ParentFrameOffset
	move.b	d4,(a5)+			; set mapping frame
	addi.b	#(16+11)*4,d6			; go back to top, and move onto next star offset
	rts
; ---------------------------------------------------------------------------

off_187DE:
;	dc.b byte_189E0.child-byte_189E0
	dc.b byte_189ED.child-byte_189ED
	dc.b byte_18A02.child-byte_18A02
	dc.b byte_18A1B.child-byte_18A1B
	even

Invincibility_AnimationAddress:
	dc.l byte_189E0
	dc.l byte_189ED
	dc.l byte_18A02
	dc.l byte_18A1B

Invincibility_PreCalcRotation:
;	rept 2
	dc.w	 15,  0
	dc.w	 15,  3
	dc.w	 14,  6
	dc.w	 13,  8
	dc.w	 11, 11
	dc.w	  8, 13
	dc.w	  6, 14
	dc.w	  3, 15
	dc.w	  0, 16
	dc.w	 -4, 15
	dc.w	 -9, 14
	dc.w	 -9, 13
	dc.w	-12, 11
	dc.w	-14,  8
	dc.w	-15,  6
	dc.w	-16,  3
	dc.w	-16,  0
	dc.w	-16, -4
	dc.w	-15, -7
	dc.w	-14, -9
	dc.w	-12,-12
	dc.w	 -9,-14
	dc.w	 -7,-15
	dc.w	 -4,-16
	dc.w	 -1,-16
	dc.w	  3,-16
	dc.w	  6,-15
	dc.w	  8,-14
	dc.w	 11,-12
	dc.w	 13, -9
	dc.w	 14, -7
	dc.w	 15, -4
;	endm
byte_189E0:
	dc.b	8, 5, 7, 6, 6, 7, 5, 8, 6, 7, 7, 6, $FF
.child:
	dc.b	5, 7, 6, 6, 7, 5, 8, 6, 7, 7, 6, 8

byte_189ED:
	dc.b    8, 7, 6, 5, 4, 3, 4, 5, 6, 7, $FF
.child:
	dc.b	3, 4, 5, 6, 7, 8, 7, 6, 5, 4

byte_18A02:
	dc.b    8, 7, 6, 5, 4, 3, 2, 3, 4, 5, 6, 7, $FF
.child:
	dc.b	2, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3

byte_18A1B:
	dc.b    7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6, $FF
.child:
	dc.b	1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2
	even
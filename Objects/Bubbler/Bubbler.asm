; ---------------------------------------------------------------------------
; Bubbler (Object)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_Bubbler:
		moveq	#0,d0
		move.b	routine(a0),d0
		move.w	off_2F946(pc,d0.w),d1
		jmp	off_2F946(pc,d1.w)
; ---------------------------------------------------------------------------

off_2F946: offsetTable
		offsetTableEntry.w loc_2F952	; 0
		offsetTableEntry.w loc_2F9B0	; 2
		offsetTableEntry.w loc_2F9CA	; 4
		offsetTableEntry.w loc_2FA2C	; 6
		offsetTableEntry.w loc_2FB8A	; 8
	;	offsetTableEntry.w loc_2FA50	; A
; ---------------------------------------------------------------------------

loc_2F952:
		addq.b	#2,routine(a0)
		move.l	#Map_Bubbler,mappings(a0)
		move.w	#$570,art_tile(a0)
		move.b	#$84,render_flags(a0)
		move.w	#bytes_to_word(32/2,32/2),height_pixels(a0)
		move.w	#make_priority(1),priority(a0)
		move.b	subtype(a0),d0
		bpl.s	loc_2F996
	;	addq.b	#8,routine(a0)
		andi.w	#$7F,d0
		move.b	d0,$32(a0)
		move.b	d0,$33(a0)
		move.b	#8,anim(a0)
		move.l	#loc_2FA50,address(a0)
		bra.w	loc_2FA50
; ---------------------------------------------------------------------------

loc_2F996:
		move.b	d0,anim(a0)
		move.w	x_pos(a0),$30(a0)
		move.w	#-$88,y_vel(a0)
		jsr	(Random_Number).w
		move.b	d0,$26(a0)

loc_2F9B0:
		lea	Ani_Bubbler(pc),a1
		jsr	(Animate_Sprite).w
		cmpi.b	#6,mapping_frame(a0)
		bne.s	loc_2F9CA
		move.b	#1,$2E(a0)

loc_2F9CA:
		move.w	(Water_level).w,d0
		cmp.w	y_pos(a0),d0
		blo.s	loc_2F9E2
		move.b	#6,routine(a0)
		addq.b	#4,anim(a0)
		bra.s	loc_2FA2C
; ---------------------------------------------------------------------------

loc_2F9E2:
		move.b	$26(a0),d0
		addq.b	#1,$26(a0)
		andi.w	#$7F,d0
		lea	AirCountdown_WobbleData(pc),a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	$30(a0),d0
		move.w	d0,x_pos(a0)
		tst.b	$2E(a0)
		beq.s	loc_2FA14
		bsr.w	sub_2FBA8
		cmpi.b	#6,routine(a0)
		beq.s	loc_2FA2C

loc_2FA14:
		jsr	(MoveSprite2).w
		tst.b	render_flags(a0)
		bpl.w	loc_2FB8A
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

loc_2FA2C:
		lea	Ani_Bubbler(pc),a1
		jsr	(Animate_Sprite).w
		tst.b	render_flags(a0)
		bpl.w	loc_2FB8A
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

loc_2FA50:
		tst.w	$36(a0)
		bne.s	loc_2FAB2
		move.w	(Water_level).w,d0
		cmp.w	y_pos(a0),d0
		bhs.w	loc_2FB5C
		tst.b	render_flags(a0)
		bpl.w	loc_2FB5C
		subq.w	#1,$38(a0)
		bpl.w	loc_2FB50
		move.w	#1,$36(a0)

-		jsr	(Random_Number).w
		move.w	d0,d1
		andi.w	#7,d0
		cmpi.w	#6,d0
		bhs.s	-
		move.b	d0,$34(a0)
		andi.w	#$C,d1
		lea	Bub_BblTypes(pc),a1
		adda.w	d1,a1
		move.l	a1,$3C(a0)
		subq.b	#1,$32(a0)
		bpl.s	+
		move.b	$33(a0),$32(a0)
		bset	#7,$36(a0)
+		bra.s	loc_2FABA
; ---------------------------------------------------------------------------

loc_2FAB2:
		subq.w	#1,$38(a0)
		bpl.w	loc_2FB50

loc_2FABA:
		jsr	(Random_Number).w
		andi.w	#$1F,d0
		move.w	d0,$38(a0)
		jsr	(Create_New_Sprite).w
		bne.s	.end
		move.l	#Obj_Bubbler,address(a1)
		move.w	x_pos(a0),x_pos(a1)
		jsr	(Random_Number).w
		andi.w	#$F,d0
		subq.w	#8,d0
		add.w	d0,x_pos(a1)
		move.w	y_pos(a0),y_pos(a1)
		moveq	#0,d0
		move.b	$34(a0),d0
		movea.l	$3C(a0),a2
		move.b	(a2,d0.w),$2C(a1)
		btst	#7,$36(a0)
		beq.s	.end
		jsr	(Random_Number).w
		andi.w	#3,d0
		bne.s	+
		bset	#6,$36(a0)
		bne.s	.end
		move.b	#2,$2C(a1)

+		tst.b	$34(a0)
		bne.s	.end
		bset	#6,$36(a0)
		bne.s	.end
		move.b	#2,$2C(a1)
.end
		subq.b	#1,$34(a0)
		bpl.s	loc_2FB50
		jsr	(Random_Number).w
		andi.w	#$7F,d0
		addi.w	#$80,d0
		add.w	d0,$38(a0)
		clr.w	$36(a0)

loc_2FB50:
		lea	Ani_Bubbler(pc),a1
		jsr	(Animate_Sprite).w

loc_2FB5C:
		out_of_xrange.s	loc_2FB7E
		move.w	(Water_level).w,d0
		cmp.w	y_pos(a0),d0
		bhs.s	+
		jmp	(Draw_Sprite).w
+		rts
; ---------------------------------------------------------------------------

loc_2FB7E:
		move.w	respawn_addr(a0),d0
		beq.s	+
		movea.w	d0,a2
		bclr	#7,(a2)
+
loc_2FB8A:
		jmp	(Delete_Current_Sprite).w
; ---------------------------------------------------------------------------
; bubble production sequence

; 0 = small bubble, 1 =	large bubble

Bub_BblTypes:	dc.b 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0
	even

; =============== S U B R O U T I N E =======================================

sub_2FBA8:
		lea	(Player_1).w,a1
		bsr.s	+
		lea	(Player_2).w,a1
+
		tst.b	object_control(a1)
		bmi.w	.rts
		btst	#Status_BublShield,shield_reaction(a1)
		bne.w	.rts
		move.w	x_pos(a1),d0
		move.w	x_pos(a0),d1
		subi.w	#$10,d1
		cmp.w	d0,d1
		bhs.w	.rts
		addi.w	#$20,d1
		cmp.w	d0,d1
		blo.w	.rts
		move.w	y_pos(a1),d0
		move.w	y_pos(a0),d1
		cmp.w	d0,d1
		bhs.s	.rts
		addi.w	#$10,d1
		cmp.w	d0,d1
		blo.s	.rts
		bsr.w	Player_ResetAirTimer
		sfx	sfx_Bubble
		clr.l	x_vel(a1)
		clr.w	ground_vel(a1)
		move.b	#id_GetAir,anim(a1)
		move.w	#$23,move_lock(a1)
		clr.b	jumping(a1)
		bclr	#Status_Push,status(a1)
		bclr	#Status_RollJump,status(a1)
		bclr	#Status_Roll,status(a1)
		beq.s	.notroll	; if we weren't rolling, branch
		move.b	y_radius(a0),d1
		sub.b	default_y_radius(a0),d1
;	if ReverseGravity = 1
;		tst.b	(Reverse_gravity_flag).w
;		beq.s	+
;		neg.b	d1
;+
;	endif
		ext.w	d1
		add.w	d1,d0		; adjust position to different hitbox to prevent clipping issues
		move.w	default_y_radius(a1),y_radius(a1)	; set y_radius and x_radius
.notroll:
	;	addq.w	#4,sp	; don't do the other players
		cmpi.b	#6,routine(a0)
		beq.s	.rts
		move.b	#6,routine(a0)
		addq.b	#4,anim(a0)
.rts:
		rts
; ---------------------------------------------------------------------------

		include "Objects/Bubbler/Object Data/Anim - Bubbler.asm"
		include "Objects/Bubbler/Object Data/Map - Bubbler.asm"
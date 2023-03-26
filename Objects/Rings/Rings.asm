; ---------------------------------------------------------------------------
; Ring (Object)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_RingAnimate		= Sprite_OnScreen_Test_Collision
Obj_Ring:
Obj_RingInit:
		move.l	#StMap_Ring,mappings(a0)
		move.w	#make_art_tile(ArtTile_Ring,1,1),art_tile(a0)
		move.w	#make_priority(2),priority(a0)	; note: lower priority to the level rings, which render above everything except the HUD
		move.b	#ren_camerapos|ren_static,render_flags(a0)
		move.w	#bytes_to_word(16/2,16/2),height_pixels(a0)
	;	move.w	#bytes_to_word(16/2,16/2),y_radius(a0)		; set y_radius and x_radius
		move.b	#7|$40,collision_flags(a0)	; when collected, set address to Obj_RingCollect
		move.l	#Obj_RingAnimate,address(a0)
;Obj_RingAnimate:
		jmp	(Sprite_OnScreen_Test_Collision).w
; ---------------------------------------------------------------------------

Obj_RingCollect:
		jsr	(GiveRing).w

Obj_RingSparkle:
		move.l	#Map_RingSparkle,mappings(a0)
		move.w	#make_art_tile(ArtTile_Ring,1,1),art_tile(a0)
		move.w	#make_priority(1),priority(a0)
		move.b	#ren_camerapos,render_flags(a0)
		move.w	#bytes_to_word(16/2,16/2),height_pixels(a0)
		clr.b	routine(a0)	; clear it just in case
		move.l	#.main,address(a0)
.main:
		tst.b	routine(a0)
		bne.s	.delete
		lea	Ani_RingSparkle(pc),a1
		jsr	(Animate_Sprite).w
		jmp	(Draw_Sprite).w
.delete:
		jmp	(Delete_Current_Sprite).w
; ---------------------------------------------------------------------------
; Bouncing ring (Object)
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Ring Spawn Array. Thanks RHS
; https://info.sonicretro.org/SCHG_How-to:Speed_Up_Ring_Loss_Process_(With_Underwater)
; ---------------------------------------------------------------------------
SpillRingData:
	dc.w  $0C4,-$3EC
	dc.w -$0C4,-$3EC
	dc.w  $238,-$350
	dc.w -$238,-$350
	dc.w  $350,-$238
	dc.w -$350,-$238
	dc.w  $3EC,-$0C4
	dc.w -$3EC,-$0C4
	dc.w  $3EC, $0C4
	dc.w -$3EC, $0C4
	dc.w  $350, $238
	dc.w -$350, $238
	dc.w  $238, $350
	dc.w -$238, $350
	dc.w  $0C4, $3EC
	dc.w -$0C4, $3EC
	dc.w  $062,-$1F6
	dc.w -$062,-$1F6
	dc.w  $11C,-$1A8
	dc.w -$11C,-$1A8
	dc.w  $1A8,-$11C
	dc.w -$1A8,-$11C
	dc.w  $1F6,-$062
	dc.w -$1F6,-$062
	dc.w  $1F6, $062
	dc.w -$1F6, $062
	dc.w  $1A8, $11C
	dc.w -$1A8, $11C
	dc.w  $11C, $1A8
	dc.w -$11C, $1A8
	dc.w  $062, $1F6
	dc.w -$062, $1F6
	even

; =============== S U B R O U T I N E =======================================

RingRecoilTimer		= subtype	; used as a substitute for d7 spreading out the level collision checks

Obj_Bouncing_Ring_Singular:
		move.l	#Obj_Bouncing_Ring_Main,d6
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		move.l	#Obj_Bouncing_Ring_MainRev,d6
+
		move.l	d6,address(a0)
		move.l	#StMap_Ring,mappings(a0)
		move.w	#make_art_tile(ArtTile_Ring,1,1),art_tile(a0)
		move.w	#make_priority(3),priority(a0)
		move.b	#ren_camerapos|ren_static|ren_onscreen,render_flags(a0)
		move.b	#7|$40,collision_flags(a0)
		move.w	#bytes_to_word(16/2,16/2),height_pixels(a0)
		move.w	#bytes_to_word(16/2,16/2),y_radius(a0)	; set y_radius and x_radius
		movea.l	d6,a1
		jmp	(a1)		; run code

Obj_Bouncing_Ring:
		move.l	#Obj_Bouncing_Ring_Main,d6
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		move.l	#Obj_Bouncing_Ring_MainRev,d6
+	;	moveq	#0,d5
		move.w	(Ring_count).w,d5
		moveq	#32,d0		; max rings
		cmp.w	d0,d5		; is the ring count the same or below the ring cap?
		ble.s	+		; if so, branch
		move.w	d0,d5		; cap it at 32
+		subq.w	#1,d5
		lea	SpillRingData(pc),a3	; load the velocity array in a3
		movea.w	a0,a1
		bra.s	.firstring
.loop:
		jsr	(Create_New_Sprite4).w
		bne.s	.endloop
		move.w	x_pos(a0),x_pos(a1)
		move.w	y_pos(a0),y_pos(a1)
.firstring:
		move.l	d6,address(a1)
		move.l	#StMap_Ring,mappings(a1)
		move.w	#make_art_tile(ArtTile_Ring,1,1),art_tile(a1)
		move.w	#make_priority(3),priority(a1)
		move.b	#ren_camerapos|ren_static|ren_onscreen,render_flags(a1)
		move.b	#7|$40,collision_flags(a1)
		move.w	#bytes_to_word(16/2,16/2),height_pixels(a1)
		move.w	#bytes_to_word(16/2,16/2),y_radius(a1)	; set y_radius and x_radius
		move.l	(a3)+,x_vel(a1)		; move the pre-calculated velocity to x_vel and y_vel, increment a3 for next ring
		move.b	d5,RingRecoilTimer(a1)	; copy the current loop number here
		dbf	d5,.loop
.endloop:
		st	(Ring_spill_anim_counter).w
		sfx	sfx_RingLoss		; play ring loss sound
		clr.w	(Ring_count).w
		move.b	#$80,(Update_HUD_ring_count).w
		tst.b	(Reverse_gravity_flag).w
		bne.s	Obj_Bouncing_Ring_MainRev

Obj_Bouncing_Ring_Main:
		jsr	(MoveSprite2).w
		addi.w	#$18,y_vel(a0)
		bmi.s	loc_1A7B0
	;	move.b	(V_int_run_count+3).w,d0
	;	add.b	d7,d0
	;	andi.b	#3,d0
		addq.b	#1,RingRecoilTimer(a0)	; increase by 1
		andi.b	#3,RingRecoilTimer(a0)	; limit recoil timer to every 4th frame
		bne.s	loc_1A7B0		; if not 0, don't process collision this frame
		tst.b	render_flags(a0)
		bpl.s	loc_1A79C
		jsr	(RingCheckFloorDist).l
		tst.w	d1
		bpl.s	loc_1A79C
		add.w	d1,y_pos(a0)
		move.w	y_vel(a0),d0	; copy y_vel
		move.w	d0,d1
		asr.w	#2,d0
		sub.w	d0,d1
		neg.w	d1
		move.w	d1,y_vel(a0)

loc_1A79C:
		tst.b	(Ring_spill_anim_counter).w
		beq.s	loc_1A7E4
		move.w	(Camera_max_Y_pos).w,d0
		addi.w	#224,d0
		cmp.w	y_pos(a0),d0
		blo.s	loc_1A7E4

loc_1A7B0:
		jsr	(Add_SpriteToCollisionResponseList).w
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------
loc_1A7E4:
		jmp	(Delete_Current_Sprite).w
; ---------------------------------------------------------------------------

Obj_Bouncing_Ring_MainRev:
		jsr	(MoveSprite2_TestGravity).w
		addi.w	#$18,y_vel(a0)
		bmi.s	loc_1A83C
	;	move.b	(V_int_run_count+3).w,d0
	;	add.b	d7,d0
	;	andi.b	#3,d0
		addq.b	#1,RingRecoilTimer(a0)	; increase by 1
		andi.b	#3,RingRecoilTimer(a0)	; limit recoil timer to every 4th frame
		bne.s	loc_1A83C		; if not 0, don't process collision this frame
		tst.b	render_flags(a0)
		bpl.s	loc_1A828
		jsr	(sub_FCA0).w
		tst.w	d1
		bpl.s	loc_1A828
		sub.w	d1,y_pos(a0)
		move.w	y_vel(a0),d0	; copy y_vel
		move.w	d0,d1
		asr.w	#2,d0
		sub.w	d0,d1
		neg.w	d1
		move.w	d1,y_vel(a0)

loc_1A828:
		tst.b	(Ring_spill_anim_counter).w
		beq.s	loc_1A7E4
		move.w	(Camera_max_Y_pos).w,d0
		addi.w	#224,d0
		cmp.w	y_pos(a0),d0
		blo.s	loc_1A7E4

loc_1A83C:
		jsr	(Add_SpriteToCollisionResponseList).w
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------
; Attracted ring (Object)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_Attracted_Ring:
		; init
		move.l	#StMap_Ring,mappings(a0)
		move.w	#make_art_tile(ArtTile_Ring,1,1),art_tile(a0)
		move.w	#make_priority(2),priority(a0)
		move.b	#ren_camerapos|ren_static,render_flags(a0)
		move.b	#7|$40,collision_flags(a0)
		move.w	#bytes_to_word(16/2,16/2),height_pixels(a0)	; set height and width
		move.w	#bytes_to_word(16/2,16/2),y_radius(a0)		; set y_radius and x_radius
		move.l	#loc_1A88C,address(a0)

loc_1A88C:
;		tst.b	routine(a0)
;		bne.s	Obj_RingCollect
		bsr.w	AttractedRing_Move
		btst	#Status_LtngShield,(Player_1+status_secondary).w	; Does player still have a lightning shield?
		bne.s	loc_1A8C6
		move.l	#Obj_Bouncing_Ring_Singular,address(a0)		; If not, change object
		st	(Ring_spill_anim_counter).w
loc_1A8C6:
		out_of_xrange.s	loc_1A8E4
		out_of_yrange.s	loc_1A8E4
		jsr	(Add_SpriteToCollisionResponseList).w
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

loc_1A8E4:
		move.w	respawn_addr(a0),d0
		beq.s	+
		movea.w	d0,a2
		bclr	#7,(a2)
+
		move.w	objoff_30(a0),d0
		beq.s	+
		movea.w	d0,a2
		clr.w	(a2)
+
		jmp	(Delete_Current_Sprite).w

; =============== S U B R O U T I N E =======================================

AttractedRing_Move:
		; Move on X axis
		move.w	#$30,d1
		move.w	(Player_1+x_pos).w,d0
		cmp.w	x_pos(a0),d0
		bhs.s	AttractedRing_MoveRight	; If ring is to the left of the player, branch

;AttractedRing_MoveLeft:
		neg.w	d1
		tst.w	x_vel(a0)
		bmi.s	AttractedRing_ApplyMovementX
		add.w	d1,d1
		add.w	d1,d1
		bra.s	AttractedRing_ApplyMovementX
; ---------------------------------------------------------------------------

AttractedRing_MoveRight:
		tst.w	x_vel(a0)
		bpl.s	AttractedRing_ApplyMovementX
		add.w	d1,d1
		add.w	d1,d1

AttractedRing_ApplyMovementX:
		add.w	d1,x_vel(a0)
		; Move on Y axis
		move.w	#$30,d1
		move.w	(Player_1+y_pos).w,d0
		cmp.w	y_pos(a0),d0
		bhs.s	AttractedRing_MoveUp	; If ring is below the player, branch

;AttractedRing_MoveDown:
		neg.w	d1
		tst.w	y_vel(a0)
		bmi.s	AttractedRing_ApplyMovementY
		add.w	d1,d1
		add.w	d1,d1
		bra.s	AttractedRing_ApplyMovementY
; ---------------------------------------------------------------------------

AttractedRing_MoveUp:
		tst.w	y_vel(a0)
		bpl.s	AttractedRing_ApplyMovementY
		add.w	d1,d1
		add.w	d1,d1

AttractedRing_ApplyMovementY:
		add.w	d1,y_vel(a0)
		jmp	(MoveSprite2).w
; ---------------------------------------------------------------------------
StMap_Ring:
	spritePiece -8,-8,2,2,0,0,0,0,0

Map_RingSparkle:
	include	"Objects/Rings/Object Data/Map - Rings.asm"

	include	"Objects/Rings/Object Data/Anim - Rings.asm"

SuperStars_Flag1	= $34	; set when player moves fast
SuperStars_Flag2	= SuperStars_Flag1+1	; set when animation ends

Obj_SuperStars:
	lea	(ArtKosM_SuperStars).l,a1
	move.w	#tiles_to_bytes(ArtTile_Shield),d2
	jsr	(Queue_Kos_Module).l

	SetRendering_Macro Render_CameraPos_Mask+Render_Excessive_Mask,0,48/2,48/2	
	SetPriorityAndArtTile_Macro priority_1,make_art_tile(ArtTile_Shield,0,1)
	move.l	#Map_SuperStars,mappings(a0)
	btst	#7,(Player_1+art_tile).w
	beq.s	+
	bset	#7,art_tile(a0)
+
	clr.b	mapping_frame(a0)
	clr.b	anim_frame_timer(a0)	; reset the frame timer
	clr.w	SuperStars_Flag1(a0)	; clear flag 1 and 2
	move.l	#.main,address(a0)
.main:
	lea	(Player_1).w,a1
	btst	#Status_Invincible,status_secondary(a1)	; are we still invincible?
;	tst.b	(Super_Sonic_Knux_flag).w
	bne.s	+
	move.l	LastLoadedShield(a0),a1
	move.l	a1,address(a0)	
	jmp	(a1)	; reload shield
+
	tst.b	SuperStars_Flag1(a0)
	beq.s	.flag1notset
	subq.b	#1,anim_frame_timer(a0)
	bpl.s	+
	move.b	#2-1,anim_frame_timer(a0)
	addq.b	#1,mapping_frame(a0)
	cmpi.b	#6,mapping_frame(a0)
	blo.s	+
	clr.b	mapping_frame(a0)
;	move.b	#0,SuperStars_Flag1(a0)
	clr.b	SuperStars_Flag1(a0)
	move.b	#1,SuperStars_Flag2(a0)
	rts
+
	tst.b	SuperStars_Flag2(a0)
	bne.s	.dontsetpositions
.render:
	move.w	x_pos(a1),x_pos(a0)
	move.w	y_pos(a1),y_pos(a0)
.dontsetpositions:
	jmp	(Draw_Sprite).l

; checks player speed
.flag1notset:
	tst.b	object_control(a1)
	bne.s	+
	mvabs.w	ground_vel(a1),d0
	cmpi.b	#$800,d0	; is speed $800?
	blo.s	+
	clr.b	mapping_frame(a0)
	move.b	#1,SuperStars_Flag1(a0)
	bra.s	.render
+
;	move.b	#0,SuperStars_Flag2(a0)
	clr.b	SuperStars_Flag2(a0)
	rts
; ---------------------------------------------------------------------------

Map_SuperStars:
	include "Objects/Shields/Object Data/Map - Super Stars.asm"
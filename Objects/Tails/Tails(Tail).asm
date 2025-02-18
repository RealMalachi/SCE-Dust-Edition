
; =============== S U B R O U T I N E =======================================

Obj_Tails_Tail:
		; init
		move.l	#Map_Tails_Tail,mappings(a0)
		move.w	#ArtTile_Player_2_Tail,art_tile(a0)
;		move.w	#make_priority(2),priority(a0)
		move.w	#bytes_to_word($18,$18),height_pixels(a0)
;		move.w	#bytes_to_word(ren_camerapos,objflag_continue),render_flags(a0)
		move.l	#byte_tri_to_long(2,Obj_Tails_Tail_Main),address(a0)	; mark that we've loaded additional object

Obj_Tails_Tail_Main:
		; Here, several SSTs are inheritied from the parent, normally Tails
		movea.w	playadd_parent(a0),a2
		move.b	angle(a2),angle(a0)
		move.b	status(a2),status(a0)
		move.w	x_pos(a2),x_pos(a0)
		move.w	y_pos(a2),y_pos(a0)
		move.w	priority(a2),priority(a0)
		move.w	render_flags(a2),d0
		andi.w	#bytes_to_word(~(ren_xflip|ren_yflip),$FF),d0
		andi.w	#bytes_to_word((ren_xflip|ren_yflip),0),render_flags(a0)
		or.w	d0,render_flags(a0)	; copy over all of render_flags, aside for flipped rendering flags
		andi.w	#drawing_mask,art_tile(a0)
		tst.w	art_tile(a2)
		bpl.s	+
		ori.w	#high_priority,art_tile(a0)
+
		moveq	#0,d0
		move.b	anim(a2),d0
		btst	#5,status(a2)
		beq.s	.skipedgecases
		tst.b	(WindTunnel_flag_P2).w
		bne.s	.skipedgecases
		; This is checking if parent (Tails) is in its pushing animation
		cmpi.b	#$A9,mapping_frame(a2)
		blo.s	+
		cmpi.b	#$AC,mapping_frame(a2)
		bhi.s	+
		moveq	#4,d0
+
.skipedgecases
		cmp.b	playadd_animchange(a0),d0	; Has the input parent anim changed since last check?
		beq.s	+				; If not, branch and skip setting a matching Tails' Tails anim
		move.b	d0,playadd_animchange(a0)	; Store d0 for the above comparision
		move.b	Obj_Tails_Tail_AniSelection(pc,d0.w),anim(a0)	; Load anim relative to parent's
+		lea	(AniTails_Tail).l,a1
		bsr.w	Animate_Tails_Part2
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		cmpi.b	#3,anim(a0)		; Is this the Directional animation?
		beq.s	+			; If so, skip the gravity flip
		eori.b	#2,render_flags(a0)	; Reverse the vertical mirror render_flag bit (On if Off beforehand and vice versa)
+		tst.b	playadd_renderflag(a0)
		bne.s	+
		jsr	(Draw_Sprite).w		; main tails object renders it to fix layering bugs
+		bra.w	Tails_Tail_Load_PLC
; ---------------------------------------------------------------------------
; animation master script table for the tails
; chooses which animation script to run depending on what Tails is doing

Obj_Tails_Tail_AniSelection:
		dc.b 0,0	; TailsAni_Walk,Run	->
		dc.b 3		; TailsAni_Roll		-> Directional
		dc.b 3		; TailsAni_Roll2	-> Directional
		dc.b 9		; TailsAni_Push		-> Pushing
		dc.b 1		; TailsAni_Wait		-> Swish
		dc.b 0		; TailsAni_Balance	-> Blank
		dc.b 2		; TailsAni_LookUp	-> Flick
		dc.b 1		; TailsAni_Duck		-> Swish
		dc.b 7		; TailsAni_Spindash	-> Spindash
		dc.b 0,0,0	; TailsAni_Dummy1,2,3	->
		dc.b 8		; TailsAni_Stop		-> Skidding
		dc.b 0,0	; TailsAni_Float,2	->
		dc.b 0		; TailsAni_Spring	->
		dc.b 0		; TailsAni_Hang		->
		dc.b 0		;
		dc.b 0		; TailsAni_Victory	->
		dc.b $A		; TailsAni_Hang2	-> Hanging
		dc.b 0		; TailsAni_Bubble	->
		dc.b 0,0,0	; TailsAni_Death,2,3	->
		dc.b 0		; TailsAni_Slide2?	->
		dc.b 0,0	; TailsAni_Hurt,Slide	->
		dc.b 0		; TailsAni_Blank	->
		dc.b 0,0	; TailsAni_Dummy4,5	->
		dc.b 0		; TailsAni_HaulAss	->
		dc.b $B,$C	; TailsAni_Fly,2	-> Fly1,2
		dc.b $B		; TailsAni_Carry	-> Fly1
		dc.b $C		; TailsAni_Ascend	-> Fly2
		dc.b $B		; TailsAni_Tired	-> Fly1
		dc.b 0,0	; TailsAni_Swim,2	->
		dc.b 0		; TailsAni_Tired2	->
		dc.b 0		; TailsAni_Tired3	->
		dc.b 0
		dc.b 0
		dc.b 0
		dc.b 0
		dc.b 0
		dc.b 0
		dc.b 0
		dc.b 0
		dc.b 0

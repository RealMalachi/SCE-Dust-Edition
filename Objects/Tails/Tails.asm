
; =============== S U B R O U T I N E =======================================

Obj_Tails:
		lea	(Max_speed_P2).w,a4
		lea	(Distance_from_top_P2).w,a5
		lea	(v_Dust_P2).w,a6

		cmpi.w	#2,(Player_mode).w
		bne.s	Tails_Normal
	;	lea	(Max_speed_P2).w,a4
		lea	(Distance_from_top).w,a5
	;	lea	(v_Dust_P2).w,a6

		tst.w	(Debug_placement_mode).w
		beq.s	Tails_Normal
		cmpi.b	#1,(Debug_placement_type).w
		beq.s	loc_136A8
		btst	#4,(Ctrl_1_pressed).w
		beq.s	loc_1368C
		move.w	#0,(Debug_placement_mode).w

loc_1368C:
		addq.b	#1,mapping_frame(a0)
		cmpi.b	#$FB,mapping_frame(a0)
		blo.s	loc_1369E
		move.b	#0,mapping_frame(a0)

loc_1369E:
		bsr.w	Tails_Load_PLC
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

loc_136A8:
		jmp	(DebugMode).l
; ---------------------------------------------------------------------------

Tails_Normal:
		moveq	#0,d0
		move.b	routine(a0),d0
		move.w	Tails_Index(pc,d0.w),d1
		jmp	Tails_Index(pc,d1.w)
; ---------------------------------------------------------------------------

Tails_Index:
		dc.w Tails_Init-Tails_Index
		dc.w Tails_Control-Tails_Index
		dc.w loc_1569C-Tails_Index
		dc.w loc_1578E-Tails_Index
		dc.w loc_157E0-Tails_Index
		dc.w loc_157F4-Tails_Index
		dc.w loc_15810-Tails_Index
; ---------------------------------------------------------------------------

Tails_Init:
		addq.b	#2,routine(a0)
		move.b	#$F,y_radius(a0)
		move.b	#9,x_radius(a0)
		move.b	#$F,default_y_radius(a0)
		move.b	#9,default_x_radius(a0)
		move.l	#Map_Tails,mappings(a0)
		move.w	#make_priority(2),priority(a0)
		move.b	#$18,width_pixels(a0)
		move.b	#$18,height_pixels(a0)
		move.b	#ren_camerapos|objflag_continue,render_flags(a0)
		move.b	#1,character_id(a0)
		bsr.w	Player_SetSpeed
		cmpi.w	#2,(Player_mode).w
		bne.s	loc_1375E
		tst.b	(Last_star_post_hit).w
		bne.s	Tails_Init_Continued

		; only happens when not starting at a checkpoint:
		move.w	#make_art_tile(ArtTile_Player_2,0,0),art_tile(a0)
		move.w	#bytes_to_word($C,$D),top_solid_bit(a0)

		; only happens when not starting at a Special Stage ring:
		move.w	x_pos(a0),(Saved_X_pos).w
		move.w	y_pos(a0),(Saved_Y_pos).w
		move.w	art_tile(a0),(Saved_art_tile).w
		move.w	top_solid_bit(a0),(Saved_solid_bits).w
		bra.s	Tails_Init_Continued
; ---------------------------------------------------------------------------

loc_1375E:
		move.w	#make_art_tile(ArtTile_Player_2,0,0),art_tile(a0)
		move.w	(Player_1+top_solid_bit).w,top_solid_bit(a0)
		tst.w	(Player_1+art_tile).w
		bpl.s	Tails_Init_Continued
		ori.w	#$8000,art_tile(a0)

Tails_Init_Continued:
		move.b	#0,flips_remaining(a0)
		move.b	#4,flip_speed(a0)
		move.b	#$1E,air_left(a0)
		cmpi.w	#$20,(Tails_CPU_routine).w
		beq.s	loc_137A4
		cmpi.w	#$12,(Tails_CPU_routine).w
		beq.s	loc_137A4
		move.w	#0,(Tails_CPU_routine).w

loc_137A4:
		move.w	#0,(Tails_CPU_idle_timer).w
		move.w	#0,(Tails_CPU_flight_timer).w
		lea	(v_Tails_tails).w,a1		; load tails' tails object
		move.l	#Obj_Tails_Tail,address(a1)
		move.w	a0,playeradd_parent(a1)
		move.b	#1,playerchild_renderflag(a1)	; tails renders for it
		move.b	(Last_star_post_hit).w,(Tails_CPU_star_post_flag).w
		rts
; ---------------------------------------------------------------------------

Tails_Control:
		cmpi.w	#2,(Player_mode).w
		bne.s	loc_13808
		tst.b	(Debug_mode_flag).w
		beq.s	loc_13808
		bclr	#6,(Ctrl_1_pressed).w
		beq.s	loc_137E0
		eori.b	#1,(Reverse_gravity_flag).w

loc_137E0:
		btst	#4,(Ctrl_1_pressed).w
		beq.s	loc_13808
		move.w	#1,(Debug_placement_mode).w
		clr.b	(Ctrl_1_locked).w
		btst	#5,(Ctrl_1).w
		beq.s	locret_13806
		move.w	#2,(Debug_placement_mode).w
		move.b	#0,anim(a0)

locret_13806:
		rts
; ---------------------------------------------------------------------------

loc_13808:
		cmpa.w	#Player_1,a0
		bne.s	loc_13830
		move.l	(Ctrl1_Player).w,(Ctrl2_Player).w
		tst.b	(Ctrl_1_locked).w
		bne.s	loc_1384A
		move.l	(Ctrl1).w,(Ctrl2_Player).w
		move.l	(Ctrl1).w,(Ctrl1_Player).w
		cmpi.w	#$1A,(Tails_CPU_routine).w
		bhs.s	loc_13840
		bra.s	loc_1384A
; ---------------------------------------------------------------------------

loc_13830:
		tst.b	(Ctrl_2_locked).w
		beq.s	loc_1383A
		bpl.s	loc_13840
		bra.s	loc_1384A
; ---------------------------------------------------------------------------

loc_1383A:
		move.l	(Ctrl2).w,(Ctrl2_Player).w

loc_13840:
		bsr.w	Tails_CPU_Control

loc_1384A:
		btst	#0,object_control(a0)
		beq.s	loc_13872
		move.b	#0,double_jump_flag(a0)
		tst.b	(Flying_carrying_Sonic_flag).w
		beq.s	loc_1388C
		lea	(Player_1).w,a1
		clr.b	object_control(a1)
		bset	#Status_InAir,status(a1)
		clr.w	(Flying_carrying_Sonic_flag).w
		bra.s	loc_1388C
; ---------------------------------------------------------------------------

loc_13872:
		movem.l	a4-a6,-(sp)
		moveq	#0,d0
		move.b	status(a0),d0
		andi.w	#6,d0
		move.w	Tails_Modes(pc,d0.w),d1
		jsr	Tails_Modes(pc,d1.w)
		movem.l	(sp)+,a4-a6

loc_1388C:
		cmpi.w	#-$100,(Camera_min_Y_pos).w
		bne.s	loc_1389C
		move.w	(Screen_Y_wrap_value).w,d0
		and.w	d0,y_pos(a0)

loc_1389C:
		bsr.s	Tails_Display
		bsr.w	Sonic_RecordPos
		bsr.w	Tails_Water
		move.b	(Primary_Angle).w,next_tilt(a0)
		move.b	(Secondary_Angle).w,tilt(a0)
		tst.b	(WindTunnel_flag_P2).w
		beq.s	loc_138C8
		tst.b	anim(a0)
		bne.s	loc_138C8
		move.b	prev_anim(a0),anim(a0)

loc_138C8:
		btst	#1,object_control(a0)
		bne.s	loc_138E4
		bsr.w	Animate_Tails
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_138E0
		eori.b	#2,render_flags(a0)

loc_138E0:
		bsr.w	Tails_Load_PLC

loc_138E4:
		move.b	object_control(a0),d0
		andi.b	#$A0,d0
		bne.s	locret_138F4
		jsr	(TouchResponse).l

locret_138F4:
		rts
; ---------------------------------------------------------------------------
Tails_Modes:	dc.w Tails_Stand_Path-Tails_Modes
		dc.w Tails_Stand_Freespace-Tails_Modes
		dc.w Tails_Spin_Path-Tails_Modes
		dc.w Tails_Spin_Freespace-Tails_Modes
; ---------------------------------------------------------------------------

Tails_Display:
		move.b	invulnerability_timer(a0),d0
		beq.s	loc_1390C
		subq.b	#1,invulnerability_timer(a0)
		lsr.b	#3,d0
		bcc.s	loc_13912

loc_1390C:
		DrawSpriteUnsafe_macro		; it's either the first thing to render or the second
		lea	(v_Tails_tails).w,a1
		DrawOtherSpriteUnsafe_macro	; render Tails' tails directly after the main body to fix rendering bugs

loc_13912:
		btst	#1,status_secondary(a0)
		beq.s	loc_1394E
		tst.b	invincibility_timer(a0)
		beq.s	loc_1394E
		move.b	(Level_frame_counter+1).w,d0
		andi.b	#7,d0
		bne.s	loc_1394E
		subq.b	#1,invincibility_timer(a0)
		bne.s	loc_1394E
		tst.b	(Level_end_flag).w						; don't change music if level is end
		bne.s	loc_13948
		tst.b	(Boss_flag).w
		bne.s	loc_13948
		cmpi.b	#$C,air_left(a0)
		blo.s	loc_13948
		move.w	(Current_music).w,d0
		music					; stop playing invincibility theme and resume normal level music

loc_13948:
		bclr	#1,status_secondary(a0)

loc_1394E:
		btst	#2,status_secondary(a0)
		beq.s	locret_139A6
		tst.b	speed_shoes_timer(a0)
		beq.s	locret_139A6
		move.b	(Level_frame_counter+1).w,d0
		andi.b	#7,d0
		bne.s	locret_139A6
		subq.b	#1,speed_shoes_timer(a0)
		bne.s	locret_139A6
		bclr	#2,status_secondary(a0)
		music	mus_Slowdown						; run music at normal speed
		bra.w	Player_SetSpeed
locret_139A6:
		rts

; =============== S U B R O U T I N E =======================================

Tails_CPU_Control:
		move.b	(Ctrl_2_logical).w,d0
		andi.b	#$7F,d0
		beq.s	loc_139DC
		move.w	#600,(Tails_CPU_idle_timer).w

loc_139DC:
		lea	(Player_1).w,a1
		move.w	(Tails_CPU_routine).w,d0
		move.w	off_139EC(pc,d0.w),d0
		jmp	off_139EC(pc,d0.w)
; ---------------------------------------------------------------------------

off_139EC:
		dc.w loc_13A10-off_139EC
		dc.w Tails_Catch_Up_Flying-off_139EC
		dc.w Tails_FlySwim_Unknown-off_139EC
		dc.w loc_13D4A-off_139EC
		dc.w loc_13F40-off_139EC
		dc.w locret_13FC0-off_139EC
		dc.w loc_13FC2-off_139EC
		dc.w loc_13FFA-off_139EC
		dc.w loc_1408A-off_139EC
		dc.w loc_140C6-off_139EC
		dc.w loc_140CE-off_139EC
		dc.w loc_14106-off_139EC
		dc.w loc_1414C-off_139EC
		dc.w loc_141F2-off_139EC
		dc.w loc_1421C-off_139EC
		dc.w loc_14254-off_139EC
		dc.w loc_1425C-off_139EC
		dc.w loc_14286-off_139EC
; ---------------------------------------------------------------------------

loc_13A10:
	;	tst.b	(Tails_CPU_star_post_flag).w
	;	bne.s	+
	;	nop
	;	nop
	;	nop
+
		move.b	#0,anim(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.w	#0,ground_vel(a0)
		move.b	#0,status(a0)

loc_13B12:
		move.b	#0,object_control(a0)

loc_13B18:
		move.w	#6,(Tails_CPU_routine).w
		move.w	#0,(Tails_CPU_flight_timer).w
		rts
; ---------------------------------------------------------------------------

Tails_Catch_Up_Flying:
		move.b	(Ctrl_2_logical).w,d0
		andi.b	#$F0,d0
		bne.s	loc_13B50
		move.w	(Level_frame_counter).w,d0
		andi.w	#$3F,d0
		bne.w	locret_13BF6
		tst.b	object_control(a1)
		bmi.w	locret_13BF6
		move.b	status(a1),d0
		andi.b	#$80,d0
		bne.w	locret_13BF6

loc_13B50:
		move.w	#4,(Tails_CPU_routine).w
		move.w	x_pos(a1),d0
		move.w	d0,x_pos(a0)
		move.w	d0,(Tails_CPU_target_X).w
		move.w	y_pos(a1),d0
		move.w	d0,(Tails_CPU_target_Y).w
		subi.w	#$C0,d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_13B78
		addi.w	#$180,d0

loc_13B78:
		move.w	d0,y_pos(a0)
		ori.w	#$8000,art_tile(a0)
		move.w	#make_priority(2),priority(a0)
		moveq	#0,d0
		move.w	d0,x_vel(a0)
		move.w	d0,y_vel(a0)
		move.w	d0,ground_vel(a0)
		move.b	d0,flip_type(a0)
		move.b	d0,double_jump_flag(a0)
		move.b	#1<<Status_InAir,status(a0)
		move.b	#$1E,air_left(a0)
		move.b	#$81,object_control(a0)
		move.b	d0,flips_remaining(a0)
		move.b	d0,flip_speed(a0)
		move.w	d0,move_lock(a0)
		move.b	d0,invulnerability_timer(a0)
		move.b	d0,invincibility_timer(a0)
		move.b	d0,speed_shoes_timer(a0)
		move.b	d0,status_tertiary(a0)
		move.b	d0,scroll_delay_counter(a0)
		move.w	d0,next_tilt(a0)	; clear next_tilt and tilt
		move.b	d0,stick_to_convex(a0)
		move.b	d0,spin_dash_flag(a0)
		move.w	d0,spin_dash_counter(a0)
		move.b	d0,jumping(a0)
;		move.b	d0,$41(a0)		; unused
		move.b	#$F0,double_jump_property(a0)
		bsr.w	Tails_Set_Flying_Animation

locret_13BF6:
		rts
; ---------------------------------------------------------------------------

Tails_FlySwim_Unknown:
		tst.b	render_flags(a0)
		bmi.s	loc_13C3A
		addq.w	#1,(Tails_CPU_flight_timer).w
		cmpi.w	#300,(Tails_CPU_flight_timer).w
		blo.s	loc_13C50
		move.w	#0,(Tails_CPU_flight_timer).w
		move.w	#2,(Tails_CPU_routine).w
		move.b	#$81,object_control(a0)
		move.b	#1<<Status_InAir,status(a0)
		move.w	#0,x_pos(a0)
		move.w	#0,y_pos(a0)
		move.b	#$F0,double_jump_property(a0)
		bsr.w	Tails_Set_Flying_Animation
		rts
; ---------------------------------------------------------------------------

loc_13C3A:
		move.b	#$F0,double_jump_property(a0)
		ori.b	#1<<Status_InAir,status(a0)
		bsr.w	Tails_Set_Flying_Animation
		move.w	#0,(Tails_CPU_flight_timer).w

loc_13C50:
		lea	(Pos_table).w,a2
		move.w	#$10,d2
		lsl.b	#2,d2
		addq.b	#4,d2
		move.w	(Pos_table_index).w,d3
		sub.b	d2,d3
		move.w	(a2,d3.w),(Tails_CPU_target_X).w
		move.w	2(a2,d3.w),(Tails_CPU_target_Y).w
		move.w	x_pos(a0),d0
		sub.w	(Tails_CPU_target_X).w,d0
		beq.s	loc_13CBE
		move.w	d0,d2
		bpl.s	loc_13C7E
		neg.w	d2

loc_13C7E:
		lsr.w	#4,d2
		cmpi.w	#$C,d2
		blo.s	loc_13C88
		moveq	#$C,d2

loc_13C88:
		move.b	x_vel(a1),d1
		bpl.s	loc_13C90
		neg.b	d1

loc_13C90:
		add.b	d1,d2
		addq.w	#1,d2
		tst.w	d0
		bmi.s	loc_13CAA
		bset	#Status_Facing,status(a0)
		cmp.w	d0,d2
		blo.s	loc_13CA6
		move.w	d0,d2
		moveq	#0,d0

loc_13CA6:
		neg.w	d2
		bra.s	loc_13CBA
; ---------------------------------------------------------------------------

loc_13CAA:
		bclr	#Status_Facing,status(a0)
		neg.w	d0
		cmp.w	d0,d2
		blo.s	loc_13CBA
		move.b	d0,d2
		moveq	#0,d0

loc_13CBA:
		add.w	d2,x_pos(a0)

loc_13CBE:
		moveq	#1,d2
		move.w	y_pos(a0),d1
		sub.w	(Tails_CPU_target_Y).w,d1
		beq.s	loc_13CD2
		bmi.s	loc_13CCE
		neg.w	d2

loc_13CCE:
		add.w	d2,y_pos(a0)

loc_13CD2:
		lea	(Stat_table).w,a2
		move.b	2(a2,d3.w),d2
		andi.b	#$80,d2
		bne.s	loc_13D42
		or.w	d0,d1
		bne.s	loc_13D42
		cmpi.b	#6,(Player_1+routine).w
		bhs.s	loc_13D42
		move.w	#6,(Tails_CPU_routine).w
		move.b	#0,object_control(a0)
		move.b	#0,anim(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.w	#0,ground_vel(a0)
		andi.b	#1<<Status_Underwater,status(a0)	; only keep underwater flag
		ori.b	#1<<Status_InAir,status(a0)		; set in-air flag
		move.w	#0,move_lock(a0)
		andi.w	#$7FFF,art_tile(a0)
		tst.b	art_tile(a1)
		bpl.s	+
		ori.w	#$8000,art_tile(a0)
+
		move.b	top_solid_bit(a1),top_solid_bit(a0)
		move.b	lrb_solid_bit(a1),lrb_solid_bit(a0)
		rts
; ---------------------------------------------------------------------------

loc_13D42:
		move.b	#$81,object_control(a0)
		rts
; ---------------------------------------------------------------------------

loc_13D4A:
		cmpi.b	#6,(Player_1+routine).w
		blo.s	loc_13D78
		move.w	#4,(Tails_CPU_routine).w
		move.b	#0,spin_dash_flag(a0)
		move.w	#0,spin_dash_counter(a0)
		move.b	#$81,object_control(a0)
		move.b	#1<<Status_InAir,status(a0)
		move.b	#$20,anim(a0)
		rts
; ---------------------------------------------------------------------------

loc_13D78:
		bsr.w	sub_13EFC
		tst.w	(Tails_CPU_idle_timer).w
		bne.w	loc_13EBE
		tst.b	object_control(a0)
		bmi.w	loc_13EBE
		tst.b	status_tertiary(a1)
		bmi.w	loc_13EBE
		tst.w	move_lock(a0)
		beq.s	+
		tst.w	ground_vel(a0)
		bne.s	+
		move.w	#8,(Tails_CPU_routine).w
+
		lea	(Pos_table).w,a2
		move.w	#$10,d1
		lsl.b	#2,d1
		addq.b	#4,d1
		move.w	(Pos_table_index).w,d0
		sub.b	d1,d0
		move.w	(a2,d0.w),d2
		btst	#Status_OnObj,status(a1)
		bne.s	+
		cmpi.w	#$400,ground_vel(a1)
		bge.s	+
		subi.w	#$20,d2
+
		move.w	2(a2,d0.w),d3
		lea	(Stat_table).w,a2
		move.w	(a2,d0.w),d1
		move.b	2(a2,d0.w),d4
		move.w	d1,d0
		btst	#Status_Push,status(a0)
		beq.s	+
		btst	#5,d4
		beq.w	loc_13E9C
+
		sub.w	x_pos(a0),d2
		beq.s	.null
		bpl.s	.right
;.left
		neg.w	d2
		cmpi.w	#$30,d2
		blo.s	+
		andi.w	#$F3F3,d1	; 11110011
		ori.w	#(button_left_mask)<<8|button_left_mask,d1
+
		tst.w	ground_vel(a0)
		beq.s	loc_13E64
		btst	#Status_Facing,status(a0)
		beq.s	loc_13E64
		btst	#0,object_control(a0)
		bne.s	loc_13E64
		subq.w	#1,x_pos(a0)
		bra.s	loc_13E64
; ---------------------------------------------------------------------------

.right:
		cmpi.w	#$30,d2
		blo.s	+
		andi.w	#$F3F3,d1
		ori.w	#(button_right_mask)<<8|button_right_mask,d1
+
		tst.w	ground_vel(a0)
		beq.s	loc_13E64
		btst	#Status_Facing,status(a0)
		bne.s	loc_13E64
		btst	#0,object_control(a0)
		bne.s	loc_13E64
		addq.w	#1,x_pos(a0)
		bra.s	loc_13E64
; ---------------------------------------------------------------------------

.null:
		bclr	#Status_Facing,status(a0)
		move.b	d4,d0
		andi.b	#1,d0
		beq.s	+
		bset	#Status_Facing,status(a0)
+
loc_13E64:
		tst.b	(Tails_CPU_auto_jump_flag).w
		beq.s	+
		ori.w	#(button_ABC_mask)<<8,d1
		btst	#Status_InAir,status(a0)
		bne.s	loc_13EB8
		move.b	#0,(Tails_CPU_auto_jump_flag).w
+
		move.w	(Level_frame_counter).w,d0
		andi.w	#$FF,d0
		beq.s	+
		cmpi.w	#$40,d2
		bhs.s	loc_13EB8
+
		sub.w	y_pos(a0),d3
		beq.s	loc_13EB8
		bpl.s	loc_13EB8
		neg.w	d3
		cmpi.w	#$20,d3
		blo.s	loc_13EB8

loc_13E9C:
		move.b	(Level_frame_counter+1).w,d0
		andi.b	#$3F,d0
		bne.s	loc_13EB8
		cmpi.b	#8,anim(a0)
		beq.s	loc_13EB8
		ori.w	#(button_ABC_mask)<<8|button_ABC_mask,d1
		move.b	#1,(Tails_CPU_auto_jump_flag).w

loc_13EB8:
; HHHHHHHH PPPPPPP
		move.b	d1,(Ctrl_2_pressed_logical).w
		lsr.w	#8,d1
		move.b	d1,(Ctrl_2_held_logical).w
		rts
; ---------------------------------------------------------------------------

loc_13EBE:
		tst.w	(Tails_CPU_idle_timer).w
		beq.s	+
		subq.w	#1,(Tails_CPU_idle_timer).w
+
		rts

; =============== S U B R O U T I N E =======================================

sub_13EFC:
		tst.b	render_flags(a0)
		bmi.s	loc_13F28
		btst	#Status_OnObj,status(a0)
		beq.s	loc_13F18
		moveq	#0,d0
		movea.w	interact(a0),a3
		move.w	(Tails_CPU_interact).w,d0
		cmp.w	(a3),d0
		bne.s	loc_13F24

loc_13F18:
		addq.w	#1,(Tails_CPU_flight_timer).w
		cmpi.w	#300,(Tails_CPU_flight_timer).w
		blo.s	loc_13F2E

loc_13F24:
;		bra.w	sub_13ECA
sub_13ECA:
		move.w	#0,(Tails_CPU_idle_timer).w
		move.w	#0,(Tails_CPU_flight_timer).w
		move.w	#2,(Tails_CPU_routine).w
		move.b	#$81,object_control(a0)
		move.b	#1<<Status_InAir,status(a0)
		move.w	#$7F00,x_pos(a0)
		move.w	#0,y_pos(a0)
		move.b	#0,double_jump_flag(a0)
		rts
; ---------------------------------------------------------------------------

loc_13F28:
		move.w	#0,(Tails_CPU_flight_timer).w

loc_13F2E:
		btst	#Status_OnObj,status(a0)
		beq.s	+
		movea.w	interact(a0),a3
		move.w	(a3),(Tails_CPU_interact).w
+
locret_13FBE:
locret_13FC0:
		rts
; ---------------------------------------------------------------------------

loc_13F40:
		bsr.w	sub_13EFC
		tst.w	(Tails_CPU_idle_timer).w
		bne.s	locret_13FBE
		tst.w	move_lock(a0)
		bne.s	locret_13FBE
		tst.b	spin_dash_flag(a0)
		bne.s	loc_13F94
		tst.w	ground_vel(a0)
		bne.s	locret_13FBE
		bclr	#Status_Facing,status(a0)
		move.w	x_pos(a0),d0
		sub.w	x_pos(a1),d0
		bcs.s	+
		bset	#Status_Facing,status(a0)
+
		move.l	#(button_down_mask)<<16|button_down_mask,d0
		move.b	(Level_frame_counter+1).w,d1
		andi.b	#$7F,d1
		beq.s	loc_13FA4
		cmpi.b	#8,anim(a0)
		bne.s	+
		move.l	#(button_ABC_mask+button_down_mask)<<16|button_ABC_mask+button_down_mask,d0
+
		move.l	d0,(Ctrl2_Player).w
		rts
; ---------------------------------------------------------------------------

loc_13F94:
		move.l	#(button_down_mask)<<16|button_down_mask,d0
		move.b	(Level_frame_counter+1).w,d1
		andi.b	#$7F,d1
		bne.s	loc_13FB2

loc_13FA4:
		move.w	#6,(Tails_CPU_routine).w
		moveq	#0,d0
		move.l	d0,(Ctrl2_Player).w
		rts
; ---------------------------------------------------------------------------

loc_13FB2:
		andi.b	#$1F,d1
		bne.s	+
		ori.l	#(button_ABC_mask)<<16|button_ABC_mask,d0
+
		move.l	d0,(Ctrl2_Player).w
		rts
; ---------------------------------------------------------------------------

loc_13FC2:
		move.b	#1,double_jump_flag(a0)
		move.b	#$F0,double_jump_property(a0)
		move.b	#1<<Status_InAir,status(a0)
		move.w	#$100,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.w	#0,ground_vel(a0)
		lea	(Player_1).w,a1
		bsr.w	sub_1459E
		move.b	#1,(Flying_carrying_Sonic_flag).w
		move.w	#$E,(Tails_CPU_routine).w

loc_13FFA:
		moveq	#0,d0
		move.w	d0,(Tails_CPU_idle_timer).w
	;	move.l	d0,(Ctrl2_Player).w	;
		move.b	(Level_frame_counter+1).w,d1
		andi.b	#$1F,d1
		bne.s	+
		move.l	#(button_right_mask<<16)+button_right_mask,d0
+
		move.l	d0,(Ctrl2_Player).w
		lea	(Flying_carrying_Sonic_flag).w,a2
		lea	(Player_1).w,a1
		btst	#Status_InAir,status(a1)
		bne.s	loc_14082
		move.w	#6,(Tails_CPU_routine).w
		move.b	#0,object_control(a0)
		move.b	#0,anim(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.w	#0,ground_vel(a0)
		move.w	#0,move_lock(a0)
		move.b	#1<<Status_InAir,status(a0)
		andi.w	#$7FFF,art_tile(a0)
		tst.b	art_tile(a1)
		bpl.s	loc_14068
		ori.w	#$8000,art_tile(a0)

loc_14068:
		move.b	top_solid_bit(a1),top_solid_bit(a0)
		move.b	lrb_solid_bit(a1),lrb_solid_bit(a0)
		cmpi.w	#1,(Player_mode).w
		bne.s	loc_14082
		move.w	#$10,(Tails_CPU_routine).w

loc_14082:
	;	move.w	(Ctrl_1).w,d0
		bra.w	Tails_Carry_Sonic
; ---------------------------------------------------------------------------

loc_1408A:
		move.b	#$F0,double_jump_property(a0)
		moveq	#0,d0
		tst.b	render_flags(a0)
		bmi.s	+
		move.l	d0,(a0)
		move.w	d0,x_pos(a0)
		move.w	d0,y_pos(a0)
		move.w	#$A,(Tails_CPU_routine).w
+
		move.w	d0,(Tails_CPU_idle_timer).w
	;	move.l	d0,(Ctrl2_Player).w
		move.b	(Level_frame_counter+1).w,d1
		andi.b	#$F,d1
		bne.s	+
		move.l	#(button_right_mask+button_ABC_mask)<<16|button_right_mask+button_ABC_mask,d0
+
		move.l	d0,(Ctrl2_Player).w
		rts
; ---------------------------------------------------------------------------

loc_140C6:
		moveq	#0,d0
		move.l	d0,(Ctrl2_Player).w
		rts
; ---------------------------------------------------------------------------

loc_140CE:
		move.b	#1,double_jump_flag(a0)
		move.b	#$F0,double_jump_property(a0)
		move.b	#1<<Status_InAir,status(a0)
		moveq	#0,d0
		move.l	d0,x_vel(a0)	; clear x_vel and y_vel
		move.w	d0,ground_vel(a0)
		lea	(Player_1).w,a1
		bsr.w	sub_1459E
		move.b	#1,(Flying_carrying_Sonic_flag).w
		move.w	#$16,(Tails_CPU_routine).w

loc_14106:
		move.w	#0,(Tails_CPU_idle_timer).w
		move.b	#$F0,double_jump_property(a0)
		moveq	#0,d0
	;	move.l	d0,(Ctrl2_Player).w
		move.b	(Level_frame_counter+1).w,d1
		andi.b	#7,d1
		bne.s	+
		move.l	#(button_ABC_mask)<<16|button_ABC_mask,d0
+
		move.l	d0,(Ctrl2_Player).w

		move.w	(Camera_Y_pos).w,d0
		addi.w	#$90,d0
		cmp.w	y_pos(a0),d0
		blo.s	loc_1413C
		move.w	#$18,(Tails_CPU_routine).w

loc_1413C:
		lea	(Flying_carrying_Sonic_flag).w,a2
		lea	(Player_1).w,a1
	;	move.w	(Ctrl_1).w,d0
		bra.w	Tails_Carry_Sonic
; ---------------------------------------------------------------------------

loc_1414C:
		move.b	#$F0,double_jump_property(a0)
		tst.w	(Tails_CPU_idle_timer).w
		beq.s	loc_14164
		tst.b	(Flying_carrying_Sonic_flag).w
		bne.w	loc_141E2
		bra.w	loc_142E2
; ---------------------------------------------------------------------------

loc_14164:
		clr.l	(Ctrl2_Player).w
		tst.b	(Flying_carrying_Sonic_flag).w
		beq.w	loc_142E2
		clr.b	(_unkFAAC).w
		btst	#1,(Ctrl_1).w
		beq.s	loc_14198
		addq.b	#1,(Tails_CPU_auto_fly_timer).w
		cmpi.b	#$C0,(Tails_CPU_auto_fly_timer).w
		blo.s	loc_141D2
		move.b	#0,(Tails_CPU_auto_fly_timer).w
		ori.l	#(button_ABC_mask)<<16|button_ABC_mask,(Ctrl2_Player).w
		bra.s	loc_141D2
; ---------------------------------------------------------------------------

loc_14198:
		btst	#0,(Ctrl_1).w
		beq.s	loc_141BA
		addq.b	#1,(Tails_CPU_auto_fly_timer).w
		cmpi.b	#$20,(Tails_CPU_auto_fly_timer).w
		blo.s	loc_141D2
		move.b	#0,(Tails_CPU_auto_fly_timer).w
		ori.l	#(button_ABC_mask)<<16|button_ABC_mask,(Ctrl2_Player).w
		bra.s	loc_141D2
; ---------------------------------------------------------------------------

loc_141BA:
		addq.b	#1,(Tails_CPU_auto_fly_timer).w
		cmpi.b	#$58,(Tails_CPU_auto_fly_timer).w
		blo.s	loc_141D2
		move.b	#0,(Tails_CPU_auto_fly_timer).w
		ori.l	#(button_ABC_mask)<<16|button_ABC_mask,(Ctrl2_Player).w

loc_141D2:
		move.b	(Ctrl_1).w,d0
		andi.b	#$C,d0
		or.b	(Ctrl_2_logical).w,d0
		move.b	d0,(Ctrl_2_logical).w

loc_141E2:
		lea	(Flying_carrying_Sonic_flag).w,a2
		lea	(Player_1).w,a1
	;	move.w	(Ctrl_1).w,d0
		bra.w	Tails_Carry_Sonic
; ---------------------------------------------------------------------------

loc_141F2:
		move.b	#1,double_jump_flag(a0)
		move.b	#$F0,double_jump_property(a0)
		move.b	#1<<Status_InAir,status(a0)
		moveq	#0,d0
		move.l	d0,x_vel(a0)	; clear x_vel and y_vel
		move.w	d0,ground_vel(a0)
		move.w	#$1C,(Tails_CPU_routine).w

loc_1421C:
		move.w	#0,(Tails_CPU_idle_timer).w
		move.b	#$F0,double_jump_property(a0)
		moveq	#0,d0
		move.b	(Level_frame_counter+1).w,d1
		andi.b	#7,d1
		bne.s	+
		move.l	#(button_ABC_mask)<<16|button_ABC_mask,d0
+
		move.l	d0,(Ctrl2_Player).w

		move.w	(Camera_Y_pos).w,d0
		addi.w	#$90,d0
		cmp.w	y_pos(a0),d0
		blo.s	locret_14252
		move.w	#$1E,(Tails_CPU_routine).w

locret_14252:
		rts
; ---------------------------------------------------------------------------

loc_14254:
		move.b	#$F0,double_jump_property(a0)
		rts
; ---------------------------------------------------------------------------

loc_1425C:
		move.b	#1,double_jump_flag(a0)
		move.b	#$F0,double_jump_property(a0)
		move.b	#1<<Status_InAir,status(a0)
		move.w	#$100,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.w	#0,ground_vel(a0)
		move.w	#$22,(Tails_CPU_routine).w

loc_14286:
		move.w	#0,(Tails_CPU_idle_timer).w
		moveq	#0,d0
		move.b	(Level_frame_counter+1).w,d1
		andi.b	#$1F,d1
		bne.s	+
		move.l	#(button_right_mask)<<16|button_right_mask,d0
+
		move.l	d0,(Ctrl2_Player).w
		btst	#Status_InAir,status(a0)
		bne.s	locret_142E0
		move.w	#6,(Tails_CPU_routine).w
		move.b	#0,object_control(a0)
		move.b	#0,anim(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.w	#0,ground_vel(a0)
		move.b	#1<<Status_InAir,status(a0)
		move.w	#0,move_lock(a0)
		andi.w	#$7FFF,art_tile(a0)

locret_142E0:
		rts
; ---------------------------------------------------------------------------

loc_142E2:
		tst.b	(_unkFAAC).w
		bne.s	loc_14362
		lea	(Player_1).w,a1
		tst.b	render_flags(a1)
		bpl.s	loc_14330
		tst.w	(Tails_CPU_idle_timer).w
		bne.w	loc_143AA
		cmpi.w	#$300,y_vel(a1)
		bge.s	loc_14330
		move.w	#0,x_vel(a0)
		clr.l	(Ctrl2_Player).w
		cmpi.w	#$200,y_vel(a0)
		bge.s	+
		addq.b	#1,(Tails_CPU_auto_fly_timer).w
		cmpi.b	#$58,(Tails_CPU_auto_fly_timer).w
		blo.s	loc_1432E
		move.b	#0,(Tails_CPU_auto_fly_timer).w
+
		ori.l	#(button_ABC_mask)<<16|button_ABC_mask,(Ctrl2_Player).w

loc_1432E:
		bra.s	loc_143AA
; ---------------------------------------------------------------------------

loc_14330:
		st	(_unkFAAC).w
		move.w	y_pos(a1),d1
		sub.w	y_pos(a0),d1
		bpl.s	loc_14340
		neg.w	d1

loc_14340:
		lsr.w	#2,d1
		move.w	d1,d2
		lsr.w	#1,d2
		add.w	d2,d1
		move.w	d1,(Camera_stored_min_X_pos).w
		move.w	x_pos(a1),d1
		sub.w	x_pos(a0),d1
		bpl.s	loc_14358
		neg.w	d1

loc_14358:
		lsr.w	#2,d1
		move.w	d1,(Camera_stored_max_X_pos).w
		bra.w	loc_143AA
; ---------------------------------------------------------------------------

loc_14362:
		clr.l	(Ctrl2_Player).w	; clear
		lea	(Player_1).w,a1
		move.w	x_pos(a0),d0
		move.w	y_pos(a0),d1
		subi.w	#$10,d1
		move.w	(Camera_stored_max_X_pos).w,d2
		bclr	#Status_Facing,status(a0)
		cmp.w	x_pos(a1),d0
		blo.s	loc_14390
		bset	#Status_Facing,status(a0)
		neg.w	d2

loc_14390:
		add.w	d2,x_vel(a0)
		cmp.w	y_pos(a1),d1
		bhs.s	loc_143AA
		move.w	(Camera_stored_min_X_pos).w,d2
		cmp.w	y_pos(a1),d1
		blo.s	loc_143A6
		neg.w	d2

loc_143A6:
		add.w	d2,y_vel(a0)

loc_143AA:
		lea	(Flying_carrying_Sonic_flag).w,a2
		lea	(Player_1).w,a1
	;	move.w	(Ctrl_1).w,d0
		bra.w	Tails_Carry_Sonic

; =============== S U B R O U T I N E =======================================


Tails_Carry_Sonic:
		move.b	(Ctrl_1_held).w,d0
		lsl.w	#8,d0
		move.b	(Ctrl_1_pressed).w,d0

		tst.b	(a2)
		beq.w	loc_14534
		cmpi.b	#4,routine(a1)
		bhs.w	loc_14466
		btst	#Status_InAir,status(a1)
		beq.w	loc_1445A
		move.w	(_unkF744).w,d1
		cmp.w	x_vel(a1),d1
		bne.s	loc_1445A
		move.w	(_unkF74C).w,d1
		cmp.w	y_vel(a1),d1
		bne.s	loc_14460
		tst.b	object_control(a1)
		bmi.s	loc_1446A
		andi.b	#$70,d0
		beq.w	loc_14474
		clr.b	object_control(a1)
		clr.b	(a2)
		move.b	#$12,1(a2)
		andi.w	#$F00,d0
		beq.w	loc_14410
		move.b	#$3C,1(a2)

loc_14410:
		btst	#$A,d0
		beq.s	loc_1441C
		move.w	#-$200,x_vel(a1)

loc_1441C:
		btst	#$B,d0
		beq.s	loc_14428
		move.w	#$200,x_vel(a1)

loc_14428:
		move.w	#-$380,y_vel(a1)
		bset	#Status_InAir,status(a1)
		move.b	#1,jumping(a1)
		move.b	#$E,y_radius(a1)
		move.b	#7,x_radius(a1)
		move.b	#id_Roll,anim(a1)
		bset	#Status_Roll,status(a1)
		bclr	#Status_RollJump,status(a1)
		rts
; ---------------------------------------------------------------------------

loc_1445A:
		move.w	#-$100,y_vel(a1)

loc_14460:
		move.b	#0,jumping(a1)

loc_14466:
		clr.b	object_control(a1)

loc_1446A:
		clr.b	(a2)
		move.b	#$3C,1(a2)
		rts
; ---------------------------------------------------------------------------

loc_14474:
		move.w	x_pos(a0),x_pos(a1)
		move.w	y_pos(a0),y_pos(a1)
		addi.w	#$1C,y_pos(a1)
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_14492
		subi.w	#$38,y_pos(a1)

loc_14492:
		andi.b	#-4,render_flags(a1)
		andi.b	#~(1<<Status_Facing),status(a1)
		move.b	status(a0),d0
		andi.b	#1<<Status_Facing,d0
		or.b	d0,render_flags(a1)
		or.b	d0,status(a1)
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_144BA
		eori.b	#2,render_flags(a1)

loc_144BA:
		subq.b	#1,anim_frame_timer(a1)
		bpl.s	loc_144F8
		move.b	#$B,anim_frame_timer(a1)
		moveq	#0,d1
		move.b	anim_frame(a1),d1
		addq.b	#1,anim_frame(a1)
		move.b	AniRaw_Tails_Carry(pc,d1.w),d0
		cmpi.b	#-1,d0
		bne.s	loc_144E4
		move.b	#0,anim_frame(a1)
		move.b	AniRaw_Tails_Carry(pc),d0

loc_144E4:
		move.b	d0,mapping_frame(a1)
		moveq	#0,d0
		move.b	mapping_frame(a1),d0
		move.l	a2,-(sp)
		jsr	(Perform_Player_DPLC).l
		movea.l	(sp)+,a2

loc_144F8:
		move.w	x_vel(a0),(Player_1+x_vel).w
		move.w	x_vel(a0),(_unkF744).w
		move.w	y_vel(a0),(Player_1+y_vel).w
		move.w	y_vel(a0),(_unkF74C).w
		movem.l	d0-a6,-(sp)
		lea	(Player_1).w,a0
		bsr.w	Player_DoLevelCollision
		movem.l	(sp)+,d0-a6
		rts
; ---------------------------------------------------------------------------

AniRaw_Tails_Carry:	dc.b  $91, $91, $90, $90, $90, $90, $90, $90, $92, $92, $92, $92, $92, $92, $91, $91, $FF
	even
; ---------------------------------------------------------------------------

loc_14534:
		tst.b	1(a2)
		beq.s	loc_14542
		subq.b	#1,1(a2)
		bne.w	locret_1459C

loc_14542:
		move.w	x_pos(a1),d0
		sub.w	x_pos(a0),d0
		addi.w	#$10,d0
		cmpi.w	#$20,d0
		bhs.w	locret_1459C
		move.w	y_pos(a1),d1
		sub.w	y_pos(a0),d1
		subi.w	#$20,d1
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_1456C
		addi.w	#$50,d1

loc_1456C:
		cmpi.w	#$10,d1
		bhs.w	locret_1459C
		tst.b	object_control(a1)
		bne.s	locret_1459C
		cmpi.b	#4,routine(a1)
		bhs.s	locret_1459C
		tst.w	(Debug_placement_mode).w
		bne.s	locret_1459C
		tst.b	spin_dash_flag(a1)
		bne.s	locret_1459C
		bsr.s	sub_1459E
		sfx	sfx_Grab
		move.b	#1,(a2)

locret_1459C:
		rts

; =============== S U B R O U T I N E =======================================

sub_1459E:
		clr.w	x_vel(a1)
		clr.w	y_vel(a1)
		clr.w	ground_vel(a1)
		clr.w	angle(a1)
		move.w	x_pos(a0),x_pos(a1)
		move.w	y_pos(a0),y_pos(a1)
		addi.w	#$1C,y_pos(a1)
		move.w	#bytes_to_word(id_Carry,id_Walk),anim(a1)
		clr.b	anim_frame_timer(a1)
		clr.b	anim_frame(a1)
		move.b	#3,object_control(a1)
		bset	#Status_InAir,status(a1)
		bclr	#Status_RollJump,status(a1)
		move.b	#0,spin_dash_flag(a1)
		andi.b	#-4,render_flags(a1)
		andi.b	#~(1<<Status_Facing),status(a1)
		move.b	status(a0),d0
		andi.b	#1<<Status_Facing,d0
		or.b	d0,render_flags(a1)
		or.b	d0,status(a1)
		move.w	x_vel(a0),(_unkF744).w
		move.w	x_vel(a0),x_vel(a1)
		move.w	y_vel(a0),(_unkF74C).w
		move.w	y_vel(a0),y_vel(a1)
		tst.b	(Reverse_gravity_flag).w
		beq.s	locret_14630
		subi.w	#$38,y_pos(a1)
		eori.b	#2,render_flags(a1)

locret_14630:
		rts

; =============== S U B R O U T I N E =======================================

Tails_Water:
		tst.b	(Water_flag).w
		bne.s	loc_1463A

locret_14638:
		rts
; ---------------------------------------------------------------------------

loc_1463A:
		move.w	(Water_level).w,d0
		cmp.w	y_pos(a0),d0
		bge.s	loc_146BA
		bset	#Status_Underwater,status(a0)
		bne.s	locret_14638
		addq.b	#1,(Water_entered_counter).w
		movea.l	a0,a1
		bsr.w	Player_ResetAirTimer
		move.l	#Obj_AirCountdown,(v_Breathing_bubbles_P2).w
		move.b	#$81,(v_Breathing_bubbles_P2+subtype).w
		move.w	a0,(v_Breathing_bubbles_P2+parent).w
		bsr.w	Player_SetSpeed
		cmpi.w	#4,(Tails_CPU_routine).w
		beq.s	loc_1469C
		tst.b	object_control(a0)
		bne.s	locret_14638

loc_1469C:
		asr	x_vel(a0)
		asr	y_vel(a0)
		asr	y_vel(a0)
		beq.s	locret_14638
		move.w	#$100,anim(a6)
		sfx	sfx_Splash,1				; splash sound
; ---------------------------------------------------------------------------

loc_146BA:
		bclr	#Status_Underwater,status(a0)
		beq.w	locret_14638
		addq.b	#1,(Water_entered_counter).w
		movea.l	a0,a1
		bsr.w	Player_ResetAirTimer
		bsr.w	Player_SetSpeed
		cmpi.b	#4,routine(a0)
		beq.s	loc_14718
		cmpi.w	#4,(Tails_CPU_routine).w
		beq.s	loc_1470A
		tst.b	object_control(a0)
		bne.s	loc_14718

loc_1470A:
		move.w	y_vel(a0),d0
		cmpi.w	#-$400,d0
		blt.s	loc_14718
		asl	y_vel(a0)

loc_14718:
		cmpi.b	#$1C,anim(a0)
		beq.w	locret_14638
		tst.w	y_vel(a0)
		beq.w	locret_14638
		move.w	#$100,anim(a6)
		cmpi.w	#-$1000,y_vel(a0)
		bgt.s	loc_1473E
		move.w	#-$1000,y_vel(a0)

loc_1473E:
		sfx	sfx_Splash,1				; splash sound
; ---------------------------------------------------------------------------

Tails_Stand_Path:
		tst.b	(Flying_carrying_Sonic_flag).w
		beq.s	loc_14760
		lea	(Player_1).w,a1
		clr.b	object_control(a1)
		bset	#Status_InAir,status(a1)
		clr.w	(Flying_carrying_Sonic_flag).w

loc_14760:
		bsr.w	Tails_Spindash
		bsr.w	Tails_Jump
		bsr.w	Player_SlopeResist
		bsr.w	Tails_InputAcceleration_Path
		bsr.w	Tails_Roll
		bsr.w	Tails_Check_Screen_Boundaries
		jsr	(MoveSprite2_TestGravity).w
		bsr.w	Call_Player_AnglePos
		bra.w	Player_SlopeRepel
; ---------------------------------------------------------------------------

Tails_Stand_Freespace:
		tst.b	double_jump_flag(a0)
		bne.s	Tails_FlyingSwimming
	if RollInAir
		bsr.w	Sonic_ChgFallAnim
	endif
		bsr.w	Tails_JumpHeight
		bsr.w	Tails_InputAcceleration_Freespace
		bsr.w	Tails_Check_Screen_Boundaries
		jsr	(MoveSprite_TestGravity).w
		btst	#Status_Underwater,status(a0)
		beq.s	+
		subi.w	#$28,y_vel(a0)
+
		bsr.w	Player_JumpAngle
		bra.w	Tails_DoLevelCollision
; ---------------------------------------------------------------------------

Tails_FlyingSwimming:
		bsr.w	Tails_Move_FlySwim
		bsr.w	Tails_InputAcceleration_Freespace
		bsr.w	Tails_Check_Screen_Boundaries
		jsr	(MoveSprite2_TestGravity).w
		bsr.w	Player_JumpAngle
		movem.l	a4-a6,-(sp)
		bsr.w	Tails_DoLevelCollision
		movem.l	(sp)+,a4-a6
		tst.w	(Player_mode).w
		bne.s	locret_14820
		lea	(Flying_carrying_Sonic_flag).w,a2
		lea	(Player_1).w,a1
	;	move.w	(Ctrl_1).w,d0
		bra.w	Tails_Carry_Sonic

locret_14820:
		rts

; =============== S U B R O U T I N E =======================================


Tails_Move_FlySwim:
		move.b	(Level_frame_counter+1).w,d0
		andi.b	#1,d0
		beq.s	loc_14836
		tst.b	double_jump_property(a0)
		beq.s	loc_14836
		subq.b	#1,double_jump_property(a0)

loc_14836:
		cmpi.b	#1,double_jump_flag(a0)
		beq.s	loc_14860
		cmpi.w	#-$100,y_vel(a0)
		blt.s	loc_14858
		subi.w	#$20,y_vel(a0)
		addq.b	#1,double_jump_flag(a0)
		cmpi.b	#$20,double_jump_flag(a0)
		bne.s	loc_1485E

loc_14858:
		move.b	#1,double_jump_flag(a0)

loc_1485E:
		bra.s	loc_14892
; ---------------------------------------------------------------------------

loc_14860:
		move.b	(Ctrl_2_pressed_logical).w,d0
		andi.b	#$70,d0
		beq.s	loc_1488C
		cmpi.w	#-$100,y_vel(a0)
		blt.s	loc_1488C
		tst.b	double_jump_property(a0)
		beq.s	loc_1488C
		btst	#Status_Underwater,status(a0)
		beq.s	loc_14886
		tst.b	(Flying_carrying_Sonic_flag).w
		bne.s	loc_1488C

loc_14886:
		move.b	#2,double_jump_flag(a0)

loc_1488C:
		addi.w	#8,y_vel(a0)

loc_14892:
		move.w	(Camera_min_Y_pos).w,d0
		addi.w	#$10,d0
		cmp.w	y_pos(a0),d0
		blt.s	Tails_Set_Flying_Animation
		tst.w	y_vel(a0)
		bpl.s	Tails_Set_Flying_Animation
		move.w	#0,y_vel(a0)

; =============== S U B R O U T I N E =======================================

Tails_Set_Flying_Animation:
		btst	#Status_Underwater,status(a0)
		bne.s	loc_14914
		moveq	#$20,d0
		tst.w	y_vel(a0)
		bpl.s	loc_148C4
		moveq	#$21,d0

loc_148C4:
		tst.b	(Flying_carrying_Sonic_flag).w
		beq.s	loc_148CC
		addq.b	#2,d0

loc_148CC:
		tst.b	double_jump_property(a0)
		bne.s	loc_148F4
		moveq	#$24,d0
		move.b	d0,anim(a0)
		tst.b	render_flags(a0)
		bpl.s	locret_148F2
		move.b	(Level_frame_counter+1).w,d0
		addq.b	#8,d0
		andi.b	#$F,d0
		bne.s	locret_148F2
		sfx	sfx_FlyTired

locret_148F2:
		rts
; ---------------------------------------------------------------------------

loc_148F4:
		move.b	d0,anim(a0)
		tst.b	render_flags(a0)
		bpl.s	locret_14912
		move.b	(Level_frame_counter+1).w,d0
		addq.b	#8,d0
		andi.b	#$F,d0
		bne.s	locret_14912
		sfx	sfx_Flying

locret_14912:
		rts
; ---------------------------------------------------------------------------

loc_14914:
		moveq	#$25,d0
		tst.w	y_vel(a0)
		bpl.s	loc_1491E
		moveq	#$26,d0

loc_1491E:
		tst.b	(Flying_carrying_Sonic_flag).w
		beq.s	loc_14926
		moveq	#$27,d0

loc_14926:
		tst.b	double_jump_property(a0)
		bne.s	loc_1492E
		moveq	#$28,d0

loc_1492E:
		move.b	d0,anim(a0)
		rts
; ---------------------------------------------------------------------------

Tails_Spin_Path:
		tst.b	(Flying_carrying_Sonic_flag).w
		beq.s	loc_1494C
		lea	(Player_1).w,a1
		clr.b	object_control(a1)
		bset	#Status_InAir,status(a1)
		clr.w	(Flying_carrying_Sonic_flag).w

loc_1494C:
		tst.b	spin_dash_flag(a0)
		bne.s	loc_14956
		bsr.w	Tails_Jump

loc_14956:
		bsr.w	Player_RollRepel
		bsr.w	Tails_RollSpeed
		bsr.w	Tails_Check_Screen_Boundaries
		jsr	(MoveSprite2_TestGravity).w
		bsr.w	Call_Player_AnglePos
		bra.w	Player_SlopeRepel
; ---------------------------------------------------------------------------

Tails_Spin_Freespace:
		tst.b	(Flying_carrying_Sonic_flag).w
		beq.s	loc_149BA
		lea	(Player_1).w,a1
		clr.b	object_control(a1)
		bset	#Status_InAir,status(a1)
		clr.w	(Flying_carrying_Sonic_flag).w

loc_149BA:
		bsr.w	Tails_JumpHeight
		bsr.w	Tails_InputAcceleration_Freespace
		bsr.w	Tails_Check_Screen_Boundaries
		jsr	(MoveSprite_TestGravity).w
		btst	#Status_Underwater,status(a0)
		beq.s	+
		subi.w	#$28,y_vel(a0)
+
		bsr.w	Player_JumpAngle
		bra.w	Tails_DoLevelCollision

; =============== S U B R O U T I N E =======================================


Tails_InputAcceleration_Path:
		move.w	Max_speed_P2-Max_speed_P2(a4),d6
		move.w	Acceleration_P2-Max_speed_P2(a4),d5
		move.w	Deceleration_P2-Max_speed_P2(a4),d4
		tst.b	status_secondary(a0)
		bmi.w	loc_14B5C
		tst.w	move_lock(a0)
		bne.w	loc_14B14
		btst	#2,(Ctrl_2_logical).w
		beq.s	loc_14A0A
		bsr.w	sub_14C20

loc_14A0A:
		btst	#3,(Ctrl_2_logical).w
		beq.s	loc_14A16
		bsr.w	sub_14CAC

loc_14A16:
		move.b	angle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.w	loc_14B14
		tst.w	ground_vel(a0)
		bne.w	loc_14B14
		bclr	#Status_Push,status(a0)
		move.b	#5,anim(a0)
		btst	#Status_OnObj,status(a0)
		beq.s	loc_14A6C
		movea.w	interact(a0),a1
		tst.b	status(a1)
		bmi.s	loc_14AA0
		moveq	#0,d1
		move.b	7(a1),d1
		move.w	d1,d2
		add.w	d2,d2
		subq.w	#4,d2
		add.w	x_pos(a0),d1
		sub.w	x_pos(a1),d1
		cmpi.w	#4,d1
		blt.s	loc_14A92
		cmp.w	d2,d1
		bge.s	loc_14A82
		bra.s	loc_14AA0
; ---------------------------------------------------------------------------

loc_14A6C:
		move.w	x_pos(a0),d3
		bsr.w	ChooseChkFloorEdge
		cmpi.w	#$C,d1
		blt.s	loc_14AA0
		cmpi.b	#3,next_tilt(a0)
		bne.s	loc_14A8A

loc_14A82:
		bclr	#Status_Facing,status(a0)
		bra.s	loc_14A98
; ---------------------------------------------------------------------------

loc_14A8A:
		cmpi.b	#3,tilt(a0)
		bne.s	loc_14AA0

loc_14A92:
		bset	#Status_Facing,status(a0)

loc_14A98:
		move.b	#6,anim(a0)
		bra.s	loc_14B14
; ---------------------------------------------------------------------------

loc_14AA0:
		btst	#1,(Ctrl_2_logical).w
		beq.s	loc_14ADA
		move.b	#8,anim(a0)
		addq.b	#1,scroll_delay_counter(a0)
		cmpi.b	#$78,scroll_delay_counter(a0)
		blo.s	loc_14B1A
		move.b	#$78,scroll_delay_counter(a0)
		tst.b	(Reverse_gravity_flag).w
		bne.s	loc_14AD0
		cmpi.w	#8,(a5)
		beq.s	loc_14B26
		subq.w	#2,(a5)
		bra.s	loc_14B26
; ---------------------------------------------------------------------------

loc_14AD0:
		cmpi.w	#$D8,(a5)
		beq.s	loc_14B26
		addq.w	#2,(a5)
		bra.s	loc_14B26
; ---------------------------------------------------------------------------

loc_14ADA:
		btst	#0,(Ctrl_2_logical).w
		beq.s	loc_14B14
		move.b	#7,anim(a0)
		addq.b	#1,scroll_delay_counter(a0)
		cmpi.b	#$78,scroll_delay_counter(a0)
		blo.s	loc_14B1A
		move.b	#$78,scroll_delay_counter(a0)
		tst.b	(Reverse_gravity_flag).w
		bne.s	loc_14B0A
		cmpi.w	#$C8,(a5)
		beq.s	loc_14B26
		addq.w	#2,(a5)
		bra.s	loc_14B26
; ---------------------------------------------------------------------------

loc_14B0A:
		cmpi.w	#$18,(a5)
		beq.s	loc_14B26
		subq.w	#2,(a5)
		bra.s	loc_14B26
; ---------------------------------------------------------------------------

loc_14B14:
		move.b	#0,scroll_delay_counter(a0)

loc_14B1A:
	resetlookcamerapos (a5)

loc_14B26:
		move.b	(Ctrl_2_logical).w,d0
		andi.b	#$C,d0
		bne.s	loc_14B5C
		move.w	ground_vel(a0),d0
		beq.s	loc_14B5C
		bmi.s	loc_14B50
		sub.w	d5,d0
		bcc.s	loc_14B4A
		move.w	#0,d0

loc_14B4A:
		move.w	d0,ground_vel(a0)
		bra.s	loc_14B5C
; ---------------------------------------------------------------------------

loc_14B50:
		add.w	d5,d0
		bcc.s	loc_14B58
		move.w	#0,d0

loc_14B58:
		move.w	d0,ground_vel(a0)

loc_14B5C:
		move.b	angle(a0),d0
		jsr	(GetSineCosine).w
		muls.w	ground_vel(a0),d1
		asr.l	#8,d1
		move.w	d1,x_vel(a0)
		muls.w	ground_vel(a0),d0
		asr.l	#8,d0
		move.w	d0,y_vel(a0)

loc_14B7A:
		btst	#6,object_control(a0)
		bne.w	locret_14C1E
		move.b	angle(a0),d0
		andi.b	#$3F,d0
		beq.s	loc_14B9A
		move.b	angle(a0),d0
		addi.b	#$40,d0
		bmi.w	locret_14C1E

loc_14B9A:
		move.b	#$40,d1
		tst.w	ground_vel(a0)
		beq.s	locret_14C1E
		bmi.s	loc_14BA8
		neg.w	d1

loc_14BA8:
		move.b	angle(a0),d0
		add.b	d1,d0
		move.w	d0,-(sp)
		bsr.w	CalcRoomInFront
		move.w	(sp)+,d0
		tst.w	d1
		bpl.s	locret_14C1E
		asl.w	#8,d1
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.s	loc_14C1A
		cmpi.b	#$40,d0
		beq.s	loc_14C00
		cmpi.b	#$80,d0
		beq.s	loc_14BFA
		add.w	d1,x_vel(a0)
		move.w	#0,ground_vel(a0)
		btst	#Status_Facing,status(a0)
		bne.s	locret_14BF8
		bset	#Status_Push,status(a0)

locret_14BF8:
		rts
; ---------------------------------------------------------------------------

loc_14BFA:
		sub.w	d1,y_vel(a0)
		rts
; ---------------------------------------------------------------------------

loc_14C00:
		sub.w	d1,x_vel(a0)
		move.w	#0,ground_vel(a0)
		btst	#Status_Facing,status(a0)
		beq.s	locret_14BF8
		bset	#Status_Push,status(a0)
		rts
; ---------------------------------------------------------------------------

loc_14C1A:
		add.w	d1,y_vel(a0)

locret_14C1E:
		rts

; =============== S U B R O U T I N E =======================================

sub_14C20:
		move.w	ground_vel(a0),d0
		beq.s	loc_14C28
		bpl.s	loc_14C5A

loc_14C28:
		bset	#Status_Facing,status(a0)
		bne.s	loc_14C3C
		bclr	#Status_Push,status(a0)
		move.b	#1,prev_anim(a0)

loc_14C3C:
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_14C4E
		add.w	d5,d0
		cmp.w	d1,d0
		ble.s	loc_14C4E
		move.w	d1,d0

loc_14C4E:
		move.w	d0,ground_vel(a0)
		move.b	#0,anim(a0)
		rts
; ---------------------------------------------------------------------------

loc_14C5A:
		sub.w	d4,d0
		bcc.s	loc_14C62
		move.w	#-$80,d0

loc_14C62:
		move.w	d0,ground_vel(a0)
		move.b	angle(a0),d1
		addi.b	#$20,d1
		andi.b	#$C0,d1
		bne.s	locret_14CAA
		cmpi.w	#$400,d0
		blt.s	locret_14CAA
		tst.b	flip_type(a0)
		bmi.s	locret_14CAA
		sfx	sfx_Skid
		move.b	#$D,anim(a0)
		bclr	#Status_Facing,status(a0)
		cmpi.b	#$C,air_left(a0)
		blo.s	locret_14CAA
		move.b	#6,routine(a6)
		move.b	#$15,mapping_frame(a6)

locret_14CAA:
		rts

; =============== S U B R O U T I N E =======================================

sub_14CAC:
		move.w	ground_vel(a0),d0
		bmi.s	loc_14CE0
		bclr	#Status_Facing,status(a0)
		beq.s	loc_14CC6
		bclr	#Status_Push,status(a0)
		move.b	#1,prev_anim(a0)

loc_14CC6:
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_14CD4
		sub.w	d5,d0
		cmp.w	d6,d0
		bge.s	loc_14CD4
		move.w	d6,d0

loc_14CD4:
		move.w	d0,ground_vel(a0)
		move.b	#0,anim(a0)
		rts
; ---------------------------------------------------------------------------

loc_14CE0:
		add.w	d4,d0
		bcc.s	loc_14CE8
		move.w	#$80,d0

loc_14CE8:
		move.w	d0,ground_vel(a0)
		move.b	angle(a0),d1
		addi.b	#$20,d1
		andi.b	#$C0,d1
		bne.s	locret_14D30
		cmpi.w	#-$400,d0
		bgt.s	locret_14D30
		tst.b	flip_type(a0)
		bmi.s	locret_14D30
		sfx	sfx_Skid
		move.b	#$D,anim(a0)
		bset	#Status_Facing,status(a0)
		cmpi.b	#$C,air_left(a0)
		blo.s	locret_14D30
		move.b	#6,routine(a6)
		move.b	#$15,mapping_frame(a6)

locret_14D30:
		rts

; =============== S U B R O U T I N E =======================================

Tails_RollSpeed:
		move.w	Max_speed_P2-Max_speed_P2(a4),d6
		asl.w	#1,d6
		move.w	Acceleration_P2-Max_speed_P2(a4),d5
		asr.w	#1,d5
		move.w	#$20,d4
		tst.b	spin_dash_flag(a0)
		bmi.w	loc_14DF0
		tst.b	status_secondary(a0)
		bmi.w	loc_14DF0
		tst.w	move_lock(a0)
		bne.s	loc_14D78
		btst	#2,(Ctrl_2_logical).w
		beq.s	loc_14D6C
		bsr.w	sub_14E32

loc_14D6C:
		btst	#3,(Ctrl_2_logical).w
		beq.s	loc_14D78
		bsr.w	sub_14E56

loc_14D78:
		move.w	ground_vel(a0),d0
		beq.s	loc_14D9A
		bmi.s	loc_14D8E
		sub.w	d5,d0
		bcc.s	loc_14D88
		move.w	#0,d0

loc_14D88:
		move.w	d0,ground_vel(a0)
		bra.s	loc_14D9A
; ---------------------------------------------------------------------------

loc_14D8E:
		add.w	d5,d0
		bcc.s	loc_14D96
		move.w	#0,d0

loc_14D96:
		move.w	d0,ground_vel(a0)

loc_14D9A:
		move.w	ground_vel(a0),d0
		bpl.s	loc_14DA2
		neg.w	d0

loc_14DA2:
		cmpi.w	#$80,d0
		bhs.s	loc_14DF0
		tst.b	spin_dash_flag(a0)
		bne.s	loc_14DDE
		bclr	#Status_Roll,status(a0)
		move.b	y_radius(a0),d0
		move.b	default_y_radius(a0),y_radius(a0)
		move.b	default_x_radius(a0),x_radius(a0)
		move.b	#5,anim(a0)
		sub.b	default_y_radius(a0),d0
		ext.w	d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_14DD8
		neg.w	d0

loc_14DD8:
		add.w	d0,y_pos(a0)
		bra.s	loc_14DF0
; ---------------------------------------------------------------------------

loc_14DDE:
		move.w	#$400,ground_vel(a0)
		btst	#Status_Facing,status(a0)
		beq.s	loc_14DF0
		neg.w	ground_vel(a0)

loc_14DF0:
	resetlookcamerapos (a5)
		move.b	angle(a0),d0
		jsr	(GetSineCosine).w
		muls.w	ground_vel(a0),d0
		asr.l	#8,d0
		move.w	d0,y_vel(a0)
		muls.w	ground_vel(a0),d1
		asr.l	#8,d1
		cmpi.w	#$1000,d1
		ble.s	loc_14E20
		move.w	#$1000,d1

loc_14E20:
		cmpi.w	#-$1000,d1
		bge.s	loc_14E2A
		move.w	#-$1000,d1

loc_14E2A:
		move.w	d1,x_vel(a0)
		bra.w	loc_14B7A

; =============== S U B R O U T I N E =======================================

sub_14E32:
		move.w	ground_vel(a0),d0
		beq.s	loc_14E3A
		bpl.s	loc_14E48

loc_14E3A:
		bset	#Status_Facing,status(a0)
		move.b	#2,anim(a0)
		rts
; ---------------------------------------------------------------------------

loc_14E48:
		sub.w	d4,d0
		bcc.s	loc_14E50
		move.w	#-$80,d0

loc_14E50:
		move.w	d0,ground_vel(a0)
		rts

; =============== S U B R O U T I N E =======================================

sub_14E56:
		move.w	ground_vel(a0),d0
		bmi.s	loc_14E6A
		bclr	#Status_Facing,status(a0)
		move.b	#2,anim(a0)
		rts
; ---------------------------------------------------------------------------

loc_14E6A:
		add.w	d4,d0
		bcc.s	loc_14E72
		move.w	#$80,d0

loc_14E72:
		move.w	d0,ground_vel(a0)
		rts

; =============== S U B R O U T I N E =======================================

Tails_InputAcceleration_Freespace:
		move.w	Max_speed_P2-Max_speed_P2(a4),d6
		move.w	Acceleration_P2-Max_speed_P2(a4),d5
		asl.w	#1,d5
		btst	#Status_RollJump,status(a0)
		bne.s	loc_14ECC
		move.w	x_vel(a0),d0
		btst	#2,(Ctrl_2_logical).w
		beq.s	loc_14EAC
		bset	#Status_Facing,status(a0)
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_14EAC
		add.w	d5,d0
		cmp.w	d1,d0
		ble.s	loc_14EAC
		move.w	d1,d0

loc_14EAC:
		btst	#3,(Ctrl_2_logical).w
		beq.s	loc_14EC8
		bclr	#Status_Facing,status(a0)
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_14EC8
		sub.w	d5,d0
		cmp.w	d6,d0
		bge.s	loc_14EC8
		move.w	d6,d0

loc_14EC8:
		move.w	d0,x_vel(a0)

loc_14ECC:
	resetlookcamerapos (a5)
		cmpi.w	#-$400,y_vel(a0)
		blo.s	locret_14F06
		move.w	x_vel(a0),d0
		move.w	d0,d1
		asr.w	#5,d1
		beq.s	locret_14F06
		bmi.s	loc_14EFA
		sub.w	d1,d0
		bcc.s	loc_14EF4
		move.w	#0,d0

loc_14EF4:
		move.w	d0,x_vel(a0)
		rts
; ---------------------------------------------------------------------------

loc_14EFA:
		sub.w	d1,d0
		bcs.s	loc_14F02
		move.w	#0,d0

loc_14F02:
		move.w	d0,x_vel(a0)

locret_14F06:
		rts

; =============== S U B R O U T I N E =======================================

Tails_Check_Screen_Boundaries:
		move.l	x_pos(a0),d1
		move.w	x_vel(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d1
		swap	d1
		move.w	(Camera_min_X_pos).w,d0
		addi.w	#$10,d0
		cmp.w	d1,d0
		bhi.s	loc_14F5C
		move.w	(Camera_max_X_pos).w,d0
		addi.w	#$128,d0
		cmp.w	d1,d0
		blo.s	loc_14F5C

loc_14F30:
		tst.b	(Disable_death_plane).w
		bne.s	locret_14F4A
		tst.b	(Reverse_gravity_flag).w
		bne.s	loc_14F4C
		move.w	(Camera_max_Y_pos).w,d0
		addi.w	#$E0,d0
		cmp.w	y_pos(a0),d0
		blt.s	loc_14F56

locret_14F4A:
		rts
; ---------------------------------------------------------------------------

loc_14F4C:
		move.w	(Camera_min_Y_pos).w,d0
		cmp.w	y_pos(a0),d0
		blt.s	locret_14F4A

loc_14F56:
		jmp	(Kill_Character).l
; ---------------------------------------------------------------------------

loc_14F5C:
		move.w	d0,x_pos(a0)
		move.w	#0,x_sub(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,ground_vel(a0)
		bra.s	loc_14F30

; =============== S U B R O U T I N E =======================================

Tails_Roll:
		tst.b	status_secondary(a0)
		bmi.s	locret_14FA8
		move.b	(Ctrl_2_logical).w,d0
		andi.b	#$C,d0
		bne.s	locret_14FA8
		btst	#1,(Ctrl_2_logical).w
		beq.s	loc_14FAA
		move.w	ground_vel(a0),d0
		bpl.s	loc_14F94
		neg.w	d0

loc_14F94:
		cmpi.w	#$100,d0
		bhs.s	loc_14FBA
		btst	#Status_OnObj,status(a0)
		bne.s	locret_14FA8
		move.b	#8,anim(a0)

locret_14FA8:
		rts
; ---------------------------------------------------------------------------

loc_14FAA:
		cmpi.b	#8,anim(a0)
		bne.s	locret_14FA8
		move.b	#0,anim(a0)
		rts
; ---------------------------------------------------------------------------

loc_14FBA:
		btst	#Status_Roll,status(a0)
		beq.s	loc_14FC4
		rts
; ---------------------------------------------------------------------------

loc_14FC4:
		bset	#Status_Roll,status(a0)
		move.b	#$E,y_radius(a0)
		move.b	#7,x_radius(a0)
		move.b	#2,anim(a0)
		addq.w	#1,y_pos(a0)
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_14FEA
		subq.w	#2,y_pos(a0)

loc_14FEA:
		sfx	sfx_Roll
		tst.w	ground_vel(a0)
		bne.s	locret_15000
		move.w	#$200,ground_vel(a0)

locret_15000:
		rts

; =============== S U B R O U T I N E =======================================

Tails_Jump:
		move.b	(Ctrl_2_pressed_logical).w,d0
		andi.b	#$70,d0
		beq.w	locret_150D0
		moveq	#0,d0
		move.b	angle(a0),d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_15024
		addi.b	#$40,d0
		neg.b	d0
		subi.b	#$40,d0

loc_15024:
		addi.b	#$80,d0
		movem.l	a4-a6,-(sp)
		bsr.w	CalcRoomOverHead
		movem.l	(sp)+,a4-a6
		cmpi.w	#6,d1
		blt.w	locret_150D0
		moveq	#0,d0
		move.b	angle(a0),d0
		subi.b	#$40,d0
		jsr	(GetSineCosine).w
		move.w	Jump_height_P2-Max_speed_P2(a4),d2
		muls.w	d2,d1
		asr.l	#8,d1
		add.w	d1,x_vel(a0)
		muls.w	d2,d0
		asr.l	#8,d0
		add.w	d0,y_vel(a0)
		bset	#Status_InAir,status(a0)
		bclr	#Status_Push,status(a0)
		addq.l	#4,sp
		move.b	#1,jumping(a0)
		clr.b	stick_to_convex(a0)
		sfx	sfx_Jump
		move.b	default_y_radius(a0),y_radius(a0)
		move.b	default_x_radius(a0),x_radius(a0)
		btst	#Status_Roll,status(a0)
		bne.s	loc_150D2
		move.b	#$E,y_radius(a0)
		move.b	#7,x_radius(a0)
		move.b	#2,anim(a0)
		bset	#Status_Roll,status(a0)
		move.b	y_radius(a0),d0
		sub.b	default_y_radius(a0),d0
		ext.w	d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_150CC
		neg.w	d0

loc_150CC:
		sub.w	d0,y_pos(a0)

locret_150D0:
		rts
; ---------------------------------------------------------------------------

loc_150D2:
		bset	#Status_RollJump,status(a0)
		rts

; =============== S U B R O U T I N E =======================================

Tails_JumpHeight:
		tst.b	jumping(a0)
		beq.s	loc_15106
		move.w	#-$400,d1
		btst	#Status_Underwater,status(a0)
		beq.s	+
		move.w	#-$200,d1
+
		cmp.w	y_vel(a0),d1
		ble.s	Tails_Test_For_Flight
		move.b	(Ctrl_2_logical).w,d0
		andi.b	#$70,d0
		bne.s	locret_15104
		move.w	d1,y_vel(a0)

locret_15104:
		rts
; ---------------------------------------------------------------------------

loc_15106:
		tst.b	spin_dash_flag(a0)
		bne.s	locret_1511A
		cmpi.w	#-$FC0,y_vel(a0)
		bge.s	locret_1511A
		move.w	#-$FC0,y_vel(a0)

locret_1511A:
		rts
; ---------------------------------------------------------------------------

Tails_Test_For_Flight:
		tst.b	double_jump_flag(a0)
		bne.w	locret_151A2
		move.b	(Ctrl_2_pressed_logical).w,d0
		andi.b	#$70,d0
		beq.w	locret_151A2
		cmpi.w	#2,(Player_mode).w
		bne.s	loc_15156
		bra.s	loc_1515C
; ---------------------------------------------------------------------------

loc_15156:
		tst.w	(Tails_CPU_idle_timer).w
		beq.s	locret_151A2

loc_1515C:
		btst	#Status_Roll,status(a0)
		beq.s	loc_1518C
		bclr	#Status_Roll,status(a0)
		move.b	y_radius(a0),d1
		move.b	default_y_radius(a0),y_radius(a0)
		move.b	default_x_radius(a0),x_radius(a0)
		sub.b	default_y_radius(a0),d1
		ext.w	d1
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_15188
		neg.w	d0

loc_15188:
		add.w	d1,y_pos(a0)

loc_1518C:
		bclr	#Status_RollJump,status(a0)
		move.b	#1,double_jump_flag(a0)
		move.b	#-$10,double_jump_property(a0)
		bsr.w	Tails_Set_Flying_Animation

locret_151A2:
		rts

; =============== S U B R O U T I N E =======================================

Tails_Spindash:
		tst.b	spin_dash_flag(a0)
		bne.s	loc_1527C
		cmpi.b	#8,anim(a0)
		bne.s	locret_1527A
		move.b	(Ctrl_2_pressed_logical).w,d0
		andi.b	#$70,d0
		beq.w	locret_1527A
		move.b	#9,anim(a0)
		sfx	sfx_SpinDash
		addq.l	#4,sp
		move.b	#1,spin_dash_flag(a0)
		move.w	#0,spin_dash_counter(a0)
		cmpi.b	#$C,air_left(a0)
		blo.s		loc_15242
		move.b	#2,anim(a6)

loc_15242:
		bsr.w	Tails_Check_Screen_Boundaries
		bra.w	Call_Player_AnglePos
; ---------------------------------------------------------------------------

locret_1527A:
		rts
; ---------------------------------------------------------------------------
; Tails_UpdateSpindash:
loc_1527C:
		move.b	(Ctrl_2_logical).w,d0
		btst	#1,d0
		bne.w	loc_15332
		move.b	#$E,y_radius(a0)
		move.b	#7,x_radius(a0)
		move.b	#2,anim(a0)
		addq.w	#1,y_pos(a0)
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_152A8
		subq.w	#2,y_pos(a0)

loc_152A8:
		move.b	#0,spin_dash_flag(a0)
		moveq	#0,d0
		move.b	spin_dash_counter(a0),d0
		add.w	d0,d0
		move.w	word_1530E(pc,d0.w),ground_vel(a0)
		move.w	ground_vel(a0),d0
		subi.w	#$800,d0
	; To fix a bug in 'MoveCameraX', we need an extra variable, so this
	; code has been modified to make the delay value only a single byte.
	; The lower byte has been repurposed to hold a copy of the position
	; array index at the time that the spin dash was released.
	; This is used by the fixed 'MoveCameraX'.
		lsr.w	#7,d0
;		andi.w	#$1F,d0	 ; none of these removed bits are ever set
		neg.w	d0
		addi.w	#$20,d0
		lea	(H_scroll_frame_offset).w,a1
		cmpa.w	#Player_1,a0
		beq.s	+
		lea	(H_scroll_frame_offset_P2).w,a1
+
		move.b	d0,(a1)+			; H_scroll_frame_offset
		move.b	(Pos_table_byte).w,(a1)+	; H_scroll_frame_copy ; Back up the position array index for later.

		btst	#Status_Facing,status(a0)
		beq.s	loc_152F8
		neg.w	ground_vel(a0)
loc_152F8:
		bset	#Status_Roll,status(a0)
		move.b	#0,anim(a6)
		sfx	sfx_Dash
		bra.s	loc_1537A
; ---------------------------------------------------------------------------
word_1530E:	dc.w $800
		dc.w $880
		dc.w $900
		dc.w $980
		dc.w $A00
		dc.w $A80
		dc.w $B00
		dc.w $B80
		dc.w $C00
word_15320:	dc.w $A00
		dc.w $A80
		dc.w $B00
		dc.w $B80
		dc.w $C00
		dc.w $C80
		dc.w $D00
		dc.w $D80
		dc.w $E00
; ---------------------------------------------------------------------------

loc_15332:
		tst.w	spin_dash_counter(a0)
		beq.s	loc_1534A
		move.w	spin_dash_counter(a0),d0
		lsr.w	#5,d0
		sub.w	d0,spin_dash_counter(a0)
		bcc.s	loc_1534A
		move.w	#0,spin_dash_counter(a0)

loc_1534A:
		move.b	(Ctrl_2_pressed_logical).w,d0
		andi.b	#$70,d0
		beq.w	loc_1537A
		move.w	#$900,anim(a0)
		sfx	sfx_SpinDash
		addi.w	#$200,spin_dash_counter(a0)
		cmpi.w	#$800,spin_dash_counter(a0)
		blo.s	loc_1537A
		move.w	#$800,spin_dash_counter(a0)

loc_1537A:
		addq.l	#4,sp
	resetlookcamerapos (a5)
		bsr.w	Tails_Check_Screen_Boundaries
		bra.w	Call_Player_AnglePos

; =============== S U B R O U T I N E =======================================

Tails_DoLevelCollision:
		SetCollAddrPlane_macro
		move.b	lrb_solid_bit(a0),d5
		move.w	x_vel(a0),d1
		move.w	y_vel(a0),d2
		jsr	(GetArcTan).w
		subi.b	#$20,d0
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	loc_154AC
		cmpi.b	#$80,d0
		beq.w	loc_15538
		cmpi.b	#$C0,d0
		beq.w	loc_1559C
		bsr.w	CheckLeftWallDist
		tst.w	d1
		bpl.s	loc_1541A
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)

loc_1541A:
		bsr.w	CheckRightWallDist
		tst.w	d1
		bpl.s	loc_1542C
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)

loc_1542C:
		bsr.w	sub_11FD6
		tst.w	d1
		bpl.s	locret_154AA
		move.b	y_vel(a0),d2
		addq.b	#8,d2
		neg.b	d2
		cmp.b	d2,d1
		bge.s	loc_15444
		cmp.b	d2,d0
		blt.s	locret_154AA

loc_15444:
		move.b	d3,angle(a0)
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_15450
		neg.w	d1

loc_15450:
		add.w	d1,y_pos(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.s	loc_15484
		move.b	d3,d0
		addi.b	#$10,d0
		andi.b	#$20,d0
		beq.s	loc_15472
		asr	y_vel(a0)
		bra.s	loc_15498
; ---------------------------------------------------------------------------

loc_15472:
		move.w	#0,y_vel(a0)
		move.w	x_vel(a0),ground_vel(a0)
		bsr.w	Tails_TouchFloor_Check_Spindash
		rts
; ---------------------------------------------------------------------------

loc_15484:
		move.w	#0,x_vel(a0)
		cmpi.w	#$FC0,y_vel(a0)
		ble.s	loc_15498
		move.w	#$FC0,y_vel(a0)

loc_15498:
		bsr.w	Tails_TouchFloor_Check_Spindash
		move.w	y_vel(a0),ground_vel(a0)
		tst.b	d3
		bpl.s	locret_154AA
		neg.w	ground_vel(a0)

locret_154AA:
		rts
; ---------------------------------------------------------------------------

loc_154AC:
		bsr.w	CheckLeftWallDist
		tst.w	d1
		bpl.s	loc_154C4
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		move.w	y_vel(a0),ground_vel(a0)

loc_154C4:
		bsr.w	sub_11FEE
		tst.w	d1
		bpl.s	loc_15502
		neg.w	d1
		cmpi.w	#$14,d1
		bhs.s	loc_154EE
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_154DC
		neg.w	d1

loc_154DC:
		add.w	d1,y_pos(a0)
		tst.w	y_vel(a0)
		bpl.s	locret_154EC
		move.w	#0,y_vel(a0)

locret_154EC:
		rts
; ---------------------------------------------------------------------------

loc_154EE:
		bsr.w	CheckRightWallDist
		tst.w	d1
		bpl.s	locret_15500
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)

locret_15500:
		rts
; ---------------------------------------------------------------------------

loc_15502:
		tst.b	(WindTunnel_flag_P2).w
		bne.s	loc_1550E
		tst.w	y_vel(a0)
		bmi.s	locret_15536

loc_1550E:
		bsr.w	sub_11FD6
		tst.w	d1
		bpl.s	locret_15536
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_1551E
		neg.w	d1

loc_1551E:
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		move.w	#0,y_vel(a0)
		move.w	x_vel(a0),ground_vel(a0)
		bsr.w	Tails_TouchFloor_Check_Spindash

locret_15536:
		rts
; ---------------------------------------------------------------------------

loc_15538:
		bsr.w	CheckLeftWallDist
		tst.w	d1
		bpl.s	loc_1554A
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)

loc_1554A:
		bsr.w	CheckRightWallDist
		tst.w	d1
		bpl.s	loc_1555C
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)

loc_1555C:
		bsr.w	sub_11FEE
		tst.w	d1
		bpl.s	locret_1559A
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_1556C
		neg.w	d1

loc_1556C:
		sub.w	d1,y_pos(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.s	loc_15584
		move.w	#0,y_vel(a0)
		rts
; ---------------------------------------------------------------------------

loc_15584:
		move.b	d3,angle(a0)
		bsr.w	Tails_TouchFloor_Check_Spindash
		move.w	y_vel(a0),ground_vel(a0)
		tst.b	d3
		bpl.s	locret_1559A
		neg.w	ground_vel(a0)

locret_1559A:
		rts
; ---------------------------------------------------------------------------

loc_1559C:
		bsr.w	CheckRightWallDist
		tst.w	d1
		bpl.s	loc_155B4
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		move.w	y_vel(a0),ground_vel(a0)

loc_155B4:
		bsr.w	sub_11FEE
		tst.w	d1
		bpl.s	loc_155D6
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_155C4
		neg.w	d1

loc_155C4:
		sub.w	d1,y_pos(a0)
		tst.w	y_vel(a0)
		bpl.s	locret_155D4
		move.w	#0,y_vel(a0)

locret_155D4:
		rts
; ---------------------------------------------------------------------------

loc_155D6:
		tst.b	(WindTunnel_flag_P2).w
		bne.s	loc_155E2
		tst.w	y_vel(a0)
		bmi.s	locret_1560A

loc_155E2:
		bsr.w	sub_11FD6
		tst.w	d1
		bpl.s	locret_1560A
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_155F2
		neg.w	d1

loc_155F2:
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		move.w	#0,y_vel(a0)
		move.w	x_vel(a0),ground_vel(a0)
		bsr.w	Tails_TouchFloor_Check_Spindash

locret_1560A:
		rts

; =============== S U B R O U T I N E =======================================

Tails_TouchFloor_Check_Spindash:
		tst.b	spin_dash_flag(a0)
		bne.s	loc_1565E
		move.b	#0,anim(a0)

; =============== S U B R O U T I N E =======================================

Tails_TouchFloor:
		move.b	y_radius(a0),d0
		move.b	default_y_radius(a0),y_radius(a0)
		move.b	default_x_radius(a0),x_radius(a0)
		btst	#Status_Roll,status(a0)
		beq.s	loc_1565E
		bclr	#Status_Roll,status(a0)
		move.b	#0,anim(a0)
		sub.b	default_y_radius(a0),d0
		ext.w	d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_1564A
		neg.w	d0

loc_1564A:
		move.w	d0,-(sp)
		move.b	angle(a0),d0
		addi.b	#$40,d0
		bpl.s	loc_15658
		neg.w	(sp)

loc_15658:
		move.w	(sp)+,d0
		add.w	d0,y_pos(a0)

loc_1565E:
		bclr	#Status_InAir,status(a0)
		bclr	#Status_Push,status(a0)
		bclr	#Status_RollJump,status(a0)
		move.b	#0,jumping(a0)
		moveq	#0,d0
		move.b	d0,(Chain_bonus_counter).w
		move.b	d0,flip_angle(a0)
		move.b	d0,flip_type(a0)
		move.b	d0,flips_remaining(a0)
		move.b	d0,scroll_delay_counter(a0)
		move.b	d0,double_jump_flag(a0)
		rts
; ---------------------------------------------------------------------------

loc_1569C:
		cmpi.w	#2,(Player_mode).w
		bne.s	loc_156BE
		tst.b	(Debug_mode_flag).w
		beq.s	loc_156BE
		btst	#4,(Ctrl_1_pressed).w
		beq.s	loc_156BE
		move.w	#1,(Debug_placement_mode).w
		clr.b	(Ctrl_1_locked).w
		rts
; ---------------------------------------------------------------------------

loc_156BE:
		tst.b	(Flying_carrying_Sonic_flag).w
		beq.s	loc_156D6
		lea	(Player_1).w,a1
		clr.b	object_control(a1)
		bset	#Status_InAir,status(a1)
		clr.w	(Flying_carrying_Sonic_flag).w

loc_156D6:
		jsr	(MoveSprite2_TestGravity).w
		addi.w	#$30,y_vel(a0)
		btst	#Status_Underwater,status(a0)
		beq.s	+
		subi.w	#$20,y_vel(a0)
+
		cmpi.w	#-$100,(Camera_min_Y_pos).w
		bne.s	loc_15700
		move.w	(Screen_Y_wrap_value).w,d0
		and.w	d0,y_pos(a0)

loc_15700:
		bsr.w	sub_15716
		bsr.w	Tails_Check_Screen_Boundaries
		bsr.w	Sonic_RecordPos
		bsr.w	sub_15842
		jmp	(Draw_Sprite).w

; =============== S U B R O U T I N E =======================================


sub_15716:
		tst.b	(Disable_death_plane).w
		bne.s	loc_15742
		tst.b	(Reverse_gravity_flag).w
		bne.s	loc_15734
		move.w	(Camera_max_Y_pos).w,d0
		addi.w	#$E0,d0
		cmp.w	y_pos(a0),d0
		blt.w	loc_15788
		bra.s	loc_15742
; ---------------------------------------------------------------------------

loc_15734:
		move.w	(Camera_min_Y_pos).w,d0
		cmp.w	y_pos(a0),d0
		blt.s	loc_15742
		bra.w	loc_15788
; ---------------------------------------------------------------------------

loc_15742:
		movem.l	a4-a6,-(sp)
		bsr.w	Tails_DoLevelCollision
		movem.l	(sp)+,a4-a6
		btst	#Status_InAir,status(a0)
		bne.s	locret_15786
		moveq	#0,d0
		move.w	d0,y_vel(a0)
		move.w	d0,x_vel(a0)
		move.w	d0,ground_vel(a0)
		move.b	d0,object_control(a0)
		move.b	#0,anim(a0)
		move.w	#make_priority(2),priority(a0)
		move.b	#2,routine(a0)
		move.b	#$78,invulnerability_timer(a0)
		move.b	#0,spin_dash_flag(a0)

locret_15786:
		rts
; ---------------------------------------------------------------------------

loc_15788:
		jmp	(Kill_Character).l
; ---------------------------------------------------------------------------

loc_1578E:
		cmpi.w	#2,(Player_mode).w
		bne.s	loc_157B0
		tst.b	(Debug_mode_flag).w
		beq.s	loc_157B0
		btst	#4,(Ctrl_1_pressed).w
		beq.s	loc_157B0
		move.w	#1,(Debug_placement_mode).w
		clr.b	(Ctrl_1_locked).w
		rts
; ---------------------------------------------------------------------------

loc_157B0:
		tst.b	(Flying_carrying_Sonic_flag).w
		beq.s	loc_157C8
		lea	(Player_1).w,a1
		clr.b	object_control(a1)
		bset	#Status_InAir,status(a1)
		clr.w	(Flying_carrying_Sonic_flag).w

loc_157C8:
		bsr.w	sub_123C2
		jsr	(MoveSprite_TestGravity).w
		bsr.w	Sonic_RecordPos
		bsr.w	sub_15842
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

loc_157E0:
		tst.w	restart_timer(a0)
		beq.s	locret_157F2
		subq.w	#1,restart_timer(a0)
		bne.s	locret_157F2
		st	(Restart_level_flag).w

locret_157F2:
		rts
; ---------------------------------------------------------------------------

loc_157F4:
		tst.w	(H_scroll_amount_P2).w
		bne.s	loc_15806
		tst.w	(V_scroll_amount_P2).w
		bne.s	loc_15806
		move.b	#2,routine(a0)

loc_15806:
		bsr.w	sub_15842
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

loc_15810:
		tst.b	(Flying_carrying_Sonic_flag).w
		beq.s	loc_15828
		lea	(Player_1).w,a1
		clr.b	object_control(a1)
		bset	#Status_InAir,status(a1)
		clr.w	(Flying_carrying_Sonic_flag).w

loc_15828:
		jsr	(MoveSprite2_TestGravity).w
		addi.w	#$10,y_vel(a0)
		bsr.w	Sonic_RecordPos
		bsr.w	sub_15842
		jmp	(Draw_Sprite).w

; =============== S U B R O U T I N E =======================================

sub_15842:
		bsr.s	Animate_Tails
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_15856
		eori.b	#2,render_flags(a0)

loc_15856:
		bra.w	Tails_Load_PLC

; =============== S U B R O U T I N E =======================================

Animate_Tails:
		lea	(AniTails).l,a1

Animate_Tails_Part2:
		moveq	#0,d0
		move.b	anim(a0),d0
		cmp.b	prev_anim(a0),d0
		beq.s	loc_1588A
		move.b	d0,prev_anim(a0)
		move.b	#0,anim_frame(a0)
		move.b	#0,anim_frame_timer(a0)
		bclr	#Status_Push,status(a0)

loc_1588A:
		add.w	d0,d0
		adda.w	(a1,d0.w),a1
		move.b	(a1),d0
		bmi.s	loc_158FA
		move.b	status(a0),d1
		andi.b	#1,d1
		andi.b	#-4,render_flags(a0)
		or.b	d1,render_flags(a0)
		subq.b	#1,anim_frame_timer(a0)
		bpl.s	locret_158C8
		move.b	d0,anim_frame_timer(a0)

; =============== S U B R O U T I N E =======================================

sub_158B0:
		moveq	#0,d1
		move.b	anim_frame(a0),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#-4,d0
		bhs.s	loc_158CA

loc_158C0:
		move.b	d0,mapping_frame(a0)
		addq.b	#1,anim_frame(a0)

locret_158C8:
		rts
; ---------------------------------------------------------------------------

loc_158CA:
		addq.b	#1,d0
		bne.s	loc_158DA
		move.b	#0,anim_frame(a0)
		move.b	1(a1),d0
		bra.s	loc_158C0
; ---------------------------------------------------------------------------

loc_158DA:
		addq.b	#1,d0
		bne.s	loc_158EE
		move.b	2(a1,d1.w),d0
		sub.b	d0,anim_frame(a0)
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0
		bra.s	loc_158C0
; ---------------------------------------------------------------------------

loc_158EE:
		addq.b	#1,d0
		bne.s	locret_158F8
		move.b	2(a1,d1.w),anim(a0)

locret_158F8:
		rts
; ---------------------------------------------------------------------------

loc_158FA:
		addq.b	#1,d0
		bne.w	loc_159C8
		moveq	#0,d0
		tst.b	flip_type(a0)
		bmi.w	loc_127C0
		move.b	$27(a0),d0
		bne.w	loc_127C0
		moveq	#0,d1
		move.b	angle(a0),d0
		bmi.s	loc_1591E
		beq.s	loc_1591E
		subq.b	#1,d0

loc_1591E:
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_1592A
		not.b	d0

loc_1592A:
		addi.b	#$10,d0
		bpl.s	loc_15932
		moveq	#3,d1

loc_15932:
		andi.b	#-4,render_flags(a0)
		eor.b	d1,d2
		or.b	d2,render_flags(a0)
		btst	#Status_Push,status(a0)
		bne.w	loc_15A14
		lsr.b	#4,d0
		andi.b	#6,d0
		move.w	ground_vel(a0),d2
		bpl.s	loc_15956
		neg.w	d2

loc_15956:
		tst.b	status_secondary(a0)
		bpl.w	loc_15960
		add.w	d2,d2

loc_15960:
		move.b	d0,d3
		add.b	d3,d3
		add.b	d3,d3
		lea	(AniTails00).l,a1
		cmpi.w	#$600,d2
		blo.s	loc_1598A
		lea	(AniTails01).l,a1
		move.b	d0,d3
		add.b	d3,d3
		cmpi.w	#$700,d2
		blo.s	loc_1598A
		lea	(AniTails1F).l,a1
		move.b	d0,d3

loc_1598A:
		moveq	#0,d1
		move.b	anim_frame(a0),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#-1,d0
		bne.s	loc_159A4
		move.b	#0,anim_frame(a0)
		move.b	1(a1),d0

loc_159A4:
		move.b	d0,mapping_frame(a0)
		add.b	d3,mapping_frame(a0)
		subq.b	#1,anim_frame_timer(a0)
		bpl.s	locret_159C6
		neg.w	d2
		addi.w	#$800,d2
		bpl.s	loc_159BC
		moveq	#0,d2

loc_159BC:
		lsr.w	#8,d2
		move.b	d2,anim_frame_timer(a0)
		addq.b	#1,anim_frame(a0)

locret_159C6:
		rts
; ---------------------------------------------------------------------------

loc_159C8:
		addq.b	#1,d0
		bne.s	loc_15A3C
		move.b	status(a0),d1
		andi.b	#1,d1
		andi.b	#-4,render_flags(a0)
		or.b	d1,render_flags(a0)
		subq.b	#1,anim_frame_timer(a0)
		bpl.w	locret_158C8
		move.w	ground_vel(a0),d2
		bpl.s	loc_159EE
		neg.w	d2

loc_159EE:
		lea	(AniTails03).l,a1
		cmpi.w	#$600,d2
		bhs.s	loc_15A00
		lea	(AniTails02).l,a1

loc_15A00:
		neg.w	d2
		addi.w	#$400,d2
		bpl.s	loc_15A0A
		moveq	#0,d2

loc_15A0A:
		lsr.w	#8,d2
		move.b	d2,anim_frame_timer(a0)
		bra.w	sub_158B0
; ---------------------------------------------------------------------------

loc_15A14:
		subq.b	#1,anim_frame_timer(a0)
		bpl.w	locret_158C8
		move.w	ground_vel(a0),d2
		bmi.s	loc_15A24
		neg.w	d2

loc_15A24:
		addi.w	#$800,d2
		bpl.s	loc_15A2C
		moveq	#0,d2

loc_15A2C:
		lsr.w	#6,d2
		move.b	d2,anim_frame_timer(a0)
		lea	(AniTails04).l,a1
		bra.w	sub_158B0
; ---------------------------------------------------------------------------

loc_15A3C:
		subq.b	#1,anim_frame_timer(a0)
		bpl.w	locret_158C8
		move.w	x_vel(a2),d1
		move.w	y_vel(a2),d2
		jsr	(GetArcTan).w
		moveq	#0,d1
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_15A6E
		not.b	d0
		bra.s	loc_15A72
; ---------------------------------------------------------------------------

loc_15A6E:
		addi.b	#$80,d0

loc_15A72:
		addi.b	#$10,d0
		bpl.s	loc_15A7A
		moveq	#3,d1

loc_15A7A:
		andi.b	#-4,render_flags(a0)
		eor.b	d1,d2
		or.b	d2,render_flags(a0)
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_15A92
		eori.b	#2,render_flags(a0)

loc_15A92:
		lsr.b	#3,d0
		andi.b	#$C,d0
		move.b	d0,d3
		lea	(AniTails_Tail03).l,a1
		move.b	#3,anim_frame_timer(a0)
		bsr.w	sub_158B0
		add.b	d3,mapping_frame(a0)
-		rts
; ---------------------------------------------------------------------------

Tails_Tail_Load_PLC:
		lea	(a0),a1
		moveq	#0,d0
		move.b	mapping_frame(a1),d0

Tails_Tail_Load_PLC2:
		cmp.b	mapping_frame_copy(a1),d0
		beq.s	-	; rts
		move.b	d0,mapping_frame_copy(a1)
		lea	(DPLC_Tails_Tail).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d5
		subq.w	#1,d5
		bmi.s	-	; rts
		move.w	#tiles_to_bytes(ArtTile_Player_2_Tail),d4
		move.l	#dmaSource(ArtUnc_Tails_Tail),d6
		bra.s	loc_15CA6

; =============== S U B R O U T I N E =======================================

Tails_Load_PLC:
		lea	(a0),a1
		moveq	#0,d0
		move.b	mapping_frame(a0),d0

Tails_Load_PLC2:
		cmp.b	mapping_frame_copy(a1),d0
		beq.s	locret_15CCE
		move.b	d0,mapping_frame_copy(a1)
		lea	(DPLC_Tails).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d5
		subq.w	#1,d5
		bmi.s	locret_15CCE
		move.w	#tiles_to_bytes(ArtTile_Player_2),d4
		move.l	#dmaSource(ArtUnc_Tails),d6
		cmpi.w	#$D1*2,d0
		blo.s	loc_15CA6
		move.l	#dmaSource(ArtUnc_Tails_Extra),d6

loc_15CA6:
		moveq	#0,d1
		move.w	(a2)+,d1
		move.w	d1,d3
		lsr.w	#8,d3
		andi.w	#$F0,d3
		addi.w	#$10,d3
		andi.w	#$FFF,d1
		lsl.l	#4,d1
		add.l	d6,d1
		move.w	d4,d2
		add.w	d3,d4
		add.w	d3,d4
		jsr	(Add_To_DMA_Queue).w
		dbf	d5,loc_15CA6

locret_15CCE:
		rts

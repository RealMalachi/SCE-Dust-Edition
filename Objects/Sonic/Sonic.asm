
; =============== S U B R O U T I N E =======================================

Obj_Sonic:
		; Load some addresses into registers
		; This is done to allow some subroutines to be
		; shared with Tails/Knuckles.
		lea	(Max_speed).w,a4
		lea	(Distance_from_top).w,a5
		lea	(v_Dust).w,a6

	if GameDebug
		tst.w	(Debug_placement_mode).w
		beq.s	Sonic_Normal

; Debug only code
		cmpi.b	#1,(Debug_placement_type).w	; Are Sonic in debug object placement mode?
		beq.s	JmpTo_DebugMode			; If so, skip to debug mode routine
		; By this point, we're assuming you're in frame cycling mode
		btst	#button_B,(Ctrl_1_pressed).w
		beq.s	+
		clr.w	(Debug_placement_mode).w	; Leave debug mode
+		addq.b	#1,mapping_frame(a0)		; Next frame
		cmpi.b	#((Map_Sonic_End-Map_Sonic)/2)-1,mapping_frame(a0)	; Have we reached the end of Sonic's frames?
		blo.s		+
		clr.b	mapping_frame(a0)	; If so, reset to Sonic's first frame
+		bsr.w	Sonic_Load_PLC
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

JmpTo_DebugMode:
		jmp	(DebugMode).l
; ---------------------------------------------------------------------------

Sonic_Normal:
	endif
		moveq	#0,d0
		move.b	routine(a0),d0
		move.w	Sonic_Index(pc,d0.w),d1
		jmp	Sonic_Index(pc,d1.w)
; ---------------------------------------------------------------------------

Sonic_Index: offsetTable
ptr_Sonic_Init:		offsetTableEntry.w Sonic_Init		; 0
ptr_Sonic_Control:	offsetTableEntry.w Sonic_Control	; 2
ptr_Sonic_Hurt:		offsetTableEntry.w Sonic_Hurt		; 4
ptr_Sonic_Death:		offsetTableEntry.w Sonic_Death		; 6
ptr_Sonic_Restart:	offsetTableEntry.w Sonic_Restart	; 8
					offsetTableEntry.w loc_12590		; A
ptr_Sonic_Drown:	offsetTableEntry.w Sonic_Drown	; C
; ---------------------------------------------------------------------------

Sonic_Init:	; Routine 0
		addq.b	#2,routine(a0)				; => Obj01_Control
		move.w	#bytes_to_word(38/2,18/2),y_radius(a0)	; set y_radius and x_radius	; this sets Sonic's collision height (2*pixels)
		move.w	#bytes_to_word(38/2,18/2),default_y_radius(a0)	; set default_y_radius and default_x_radius
		move.l	#Map_Sonic,mappings(a0)
		move.w	#make_priority(2),priority(a0)
		move.w	#bytes_to_word(48/2,48/2),height_pixels(a0)		; set height and width
		move.b	#ren_camerapos|objflag_continue,render_flags(a0)
		clr.b	character_id(a0)
		bsr.w	Player_SetSpeed
		tst.b	(Last_star_post_hit).w
		bne.s	Sonic_Init_Continued

		; only happens when not starting at a checkpoint:
		move.w	#make_art_tile(ArtTile_Player_1,0,0),art_tile(a0)
		move.w	#bytes_to_word($C,$D),top_solid_bit(a0)

		; only happens when not starting at a Special Stage ring:
		move.w	x_pos(a0),(Saved_X_pos).w
		move.w	y_pos(a0),(Saved_Y_pos).w
		move.w	art_tile(a0),(Saved_art_tile).w
		move.w	top_solid_bit(a0),(Saved_solid_bits).w

Sonic_Init_Continued:
		clr.b	flips_remaining(a0)
		move.b	#4,flip_speed(a0)
		move.b	#30,air_left(a0)
		subi.w	#$20,x_pos(a0)
		addi.w	#4,y_pos(a0)
		bsr.w	Reset_Player_Position_Array
		addi.w	#$20,x_pos(a0)
		subi.w	#4,y_pos(a0)
		rts

; ---------------------------------------------------------------------------
; Normal state for Sonic
; ---------------------------------------------------------------------------

Sonic_Control:								; Routine 2
	if GameDebug
		tst.b	(Debug_mode_flag).w				; is debug cheat enabled?
		beq.s	loc_10BF0					; if not, branch
		bclr	#button_A,(Ctrl_1_pressed).w		; is button A pressed?
		beq.s	loc_10BCE					; if not, branch
		eori.b	#1,(Reverse_gravity_flag).w		; toggle reverse gravity

loc_10BCE:
		btst	#button_B,(Ctrl_1_pressed).w		; is button B pressed?
		beq.s	loc_10BF0					; if not, branch
		move.w	#1,(Debug_placement_mode).w	; change Sonic into a ring/item
		clr.b	(Ctrl_1_locked).w					; unlock control
		btst	#button_C,(Ctrl_1_held).w			; was button C held before pressing B?
		beq.s	locret_10BEE					; if not, branch
		move.w	#2,(Debug_placement_mode).w	; enter animation cycle mode

locret_10BEE:
		rts
; ---------------------------------------------------------------------------

loc_10BF0:
	endif
		tst.b	(Ctrl_1_locked).w					; are controls locked?
		bne.s	loc_10BFC					; if yes, branch
		move.l	(Ctrl1).w,(Ctrl1_Player).w	; copy new held buttons, to enable joypad control
loc_10BFC:
		btst	#0,object_control(a0)				; is Sonic interacting with another object that holds him in place or controls his movement somehow?
		beq.s	loc_10C0C					; if yes, branch to skip Sonic's control
		clr.b	double_jump_flag(a0)				; enable double jump
		bra.s	loc_10C26
; ---------------------------------------------------------------------------

loc_10C0C:
		movem.l	a4-a6,-(sp)
		moveq	#0,d0
		move.b	status(a0),d0
		andi.w	#6,d0
		move.w	Sonic_Modes(pc,d0.w),d1
		jsr	Sonic_Modes(pc,d1.w)	; run Sonic's movement control code
		movem.l	(sp)+,a4-a6

loc_10C26:
		cmpi.w	#-$100,(Camera_min_Y_pos).w		; is vertical wrapping enabled?
		bne.s	+								; if not, branch
		move.w	(Screen_Y_wrap_value).w,d0
		and.w	d0,y_pos(a0)						; perform wrapping of Sonic's y position
+		bsr.s	Sonic_Display
		bsr.w	Sonic_RecordPos
		bsr.w	Sonic_Water
		move.b	(Primary_Angle).w,next_tilt(a0)
		move.b	(Secondary_Angle).w,tilt(a0)
		tst.b	(WindTunnel_flag).w
		beq.s	+
		tst.b	anim(a0)
		bne.s	+
		move.b	prev_anim(a0),anim(a0)
+		btst	#1,object_control(a0)
		bne.s	++
		bsr.w	Animate_Sonic
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		eori.b	#2,render_flags(a0)
+		bsr.w	Sonic_Load_PLC
+		move.b	object_control(a0),d0
		andi.b	#$A0,d0
		bne.s	+
		jsr	TouchResponse(pc)
+		rts
; ---------------------------------------------------------------------------
; secondary states under state Sonic_Control

Sonic_Modes: offsetTable
		offsetTableEntry.w Sonic_MdNormal		; 0
		offsetTableEntry.w Sonic_MdAir			; 2
		offsetTableEntry.w Sonic_MdRoll		; 4
		offsetTableEntry.w Sonic_MdJump		; 6

; =============== S U B R O U T I N E =======================================

Sonic_Display:
		move.b	invulnerability_timer(a0),d0
		beq.s	loc_10CA6
		subq.b	#1,invulnerability_timer(a0)
		lsr.b	#3,d0
		bcc.s	Sonic_ChkInvin

loc_10CA6:
		DrawSpriteUnsafe_macro		; it's the first thing to render

Sonic_ChkInvin:										; checks if invincibility has expired and disables it if it has.
		btst	#Status_Invincible,status_secondary(a0)
		beq.s	Sonic_ChkShoes
		tst.b	invincibility_timer(a0)
		beq.s	Sonic_ChkShoes						; if there wasn't any time left, that means we're in Super/Hyper mode
		move.b	(Level_frame_counter+1).w,d0
		andi.b	#7,d0
		bne.s	Sonic_ChkShoes
		subq.b	#1,invincibility_timer(a0)				; reduce invincibility_timer only on every 8th frame
		bne.s	Sonic_ChkShoes						; if time is still left, branch
		tst.b	(Level_end_flag).w						; don't change music if level is end
		bne.s	Sonic_RmvInvin
		tst.b	(Boss_flag).w								; don't change music if in a boss fight
		bne.s	Sonic_RmvInvin
		cmpi.b	#12,air_left(a0)						; don't change music if drowning
		blo.s	Sonic_RmvInvin
		move.w	(Current_music).w,d0
		music					; stop playing invincibility theme and resume normal level music

Sonic_RmvInvin:
		bclr	#Status_Invincible,status_secondary(a0)

Sonic_ChkShoes:										; checks if Speed Shoes have expired and disables them if they have.
		btst	#Status_SpeedShoes,status_secondary(a0)	; does Sonic have speed shoes?
		beq.s	Sonic_ExitChk						; if so, branch
		tst.b	speed_shoes_timer(a0)
		beq.s	Sonic_ExitChk
		move.b	(Level_frame_counter+1).w,d0
		andi.b	#7,d0
		bne.s	Sonic_ExitChk
		subq.b	#1,speed_shoes_timer(a0)				; reduce speed_shoes_timer only on every 8th frame
		bne.s	Sonic_ExitChk
		bclr	#Status_SpeedShoes,status_secondary(a0)
		music	mus_Slowdown						; run music at normal speed
		bra.w	Player_SetSpeed
Sonic_ExitChk:
		rts
; ---------------------------------------------------------------------------
; Subroutine to record Sonic's previous positions for invincibility stars
; and input/status flags for Tails' AI to follow
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Sonic_RecordPos:
		cmpa.w	#Player_1,a0				; is Sonic the sidekick?
		bne.s	.return					; if so, branch

		move.w	(Pos_table_index).w,d0
		lea	(Pos_table).w,a1
		lea	(a1,d0.w),a1
		move.w	x_pos(a0),(a1)+			; write location to pos_table
		move.w	y_pos(a0),(a1)+
		addq.b	#4,(Pos_table_byte).w		; increment index as the post-increments did a1
		lea	(Stat_table).w,a1
		lea	(a1,d0.w),a1
	;	move.w	(Ctrl_1_logical).w,(a1)+
		move.b	(Ctrl_1_held_logical).w,(a1)+
		move.b	(Ctrl_1_pressed_logical).w,(a1)+
		move.b	status(a0),(a1)+
		move.b	art_tile(a0),(a1)+

.return
		rts

; =============== S U B R O U T I N E =======================================
; resets all pos_table and stat_table slots with current data
; the init is rather slow, but makes up for it in the loop
Reset_Player_Position_Array:
		cmpa.w	#Player_1,a0		; is object player 1?
		bne.s	.return			; if not, branch
		move.w	x_pos(a0),d1
		moveq	#16,d2
		lsl.l	d2,d1
		move.w	y_pos(a0),d1

		move.b	(Ctrl_1_held_logical).w,d2
		lsl.w	#8,d2
		move.b	(Ctrl_1_pressed_logical).w,d2
		lsl.l	#8,d2
		move.b	status(a0),d2
		lsl.l	#8,d2
		move.b	art_tile(a0),d2

		lea	(Pos_table).w,a1
		lea	(Stat_table).w,a2
		moveq	#64-1,d0
.loop
		move.l	d1,(a1)+		; write x and y pos
		move.l	d2,(a2)+		; write stat data
		dbf	d0,.loop
		clr.w	(Pos_table_index).w
.return
		rts

; ---------------------------------------------------------------------------
; Subroutine for Sonic when he's underwater
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Sonic_Water:
		tst.b	(Water_flag).w		; does level have water?
		beq.s	.end			; if not, branch
;Sonic_InWater:
		move.w	(Water_level).w,d0
		cmp.w	y_pos(a0),d0					; is Sonic above the water?
		bge.s	.outofwater					; if yes, branch
		bset	#Status_Underwater,status(a0)			; set underwater flag
		bne.s	.end						; if already underwater, branch
		addq.b	#1,(Water_entered_counter).w
		movea.w	a0,a1
		jsr	(Player_ResetAirTimer).l
		move.l	#Obj_AirCountdown,(v_Breathing_bubbles).w	; load Sonic's breathing bubbles
		move.b	#$81,(v_Breathing_bubbles+subtype).w
		move.w	a0,(v_Breathing_bubbles+parent).w
		bsr.w	Player_SetSpeed
		tst.b	object_control(a0)
		bne.s	.end
		asr	x_vel(a0)
		asr	y_vel(a0)				; memory operands can only be shifted one bit at a time
		asr	y_vel(a0)
		beq.s	.end
		move.w	#bytes_to_word(1,0),anim(a6)		; splash animation, write 1 to anim and clear prev_anim
		sfx	sfx_Splash,2				; splash sound
.end:
		rts
; ---------------------------------------------------------------------------

.outofwater:
		bclr	#Status_Underwater,status(a0)	; unset underwater flag
		beq.s	.end				; if already above water, branch
		addq.b	#1,(Water_entered_counter).w
		movea.w	a0,a1
		jsr	(Player_ResetAirTimer).l
		bsr.w	Player_SetSpeed
		cmpi.b	#id_SonicHurt,routine(a0)	; is Sonic falling back from getting hurt?
		beq.s	+				; if yes, branch
		tst.b	object_control(a0)
		bne.s	+
		cmpi.w	#-$400,y_vel(a0)
		blt.s	+
		asl	y_vel(a0)
+
		cmpi.b	#id_Null,anim(a0)		; is Sonic in his 'blank' animation
		beq.s	.end				; if so, branch
		tst.w	y_vel(a0)
		beq.s	.end
		move.w	#-$1000,d0
		cmp.w	y_vel(a0),d0
		ble.s	+
		move.w	d0,y_vel(a0)			; limit upward y velocity exiting the water
+
		move.w	#bytes_to_word(1,0),anim(a6)	; splash animation, write 1 to anim and clear prev_anim
		sfx	sfx_Splash,1			; splash sound

; =============== S U B R O U T I N E =======================================

Sonic_MdNormal:
		bsr.w	SonicKnux_Spindash
		bsr.w	Sonic_Jump
		bsr.w	Player_SlopeResist
		bsr.w	Sonic_Move
		bsr.w	SonicKnux_Roll
		bsr.w	Player_LevelBound
		jsr	(MoveSprite2_TestGravity).w
		bsr.s	Call_Player_AnglePos
		bra.w	Player_SlopeRepel

; =============== S U B R O U T I N E =======================================

Call_Player_AnglePos:
		tst.b	(Reverse_gravity_flag).w
		beq.w	Player_AnglePos
		move.b	angle(a0),d0
		addi.b	#$40,d0
		neg.b	d0
		subi.b	#$40,d0
		move.b	d0,angle(a0)
		bsr.w	Player_AnglePos
		move.b	angle(a0),d0
		addi.b	#$40,d0
		neg.b	d0
		subi.b	#$40,d0
		move.b	d0,angle(a0)
		rts
; ---------------------------------------------------------------------------
; Start of subroutine Sonic_MdAir
; Called if Sonic is airborne, but not in a ball (thus, probably not jumping)
; Sonic_Stand_Freespace:
Sonic_MdAir:
	if RollInAir
		bsr.w	Sonic_ChgFallAnim
	endif
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_ChgJumpDir
		bsr.w	Player_LevelBound
		jsr	(MoveSprite_TestGravity).w
		btst	#Status_Underwater,status(a0)	; is Sonic underwater?
		beq.s	loc_10FD6				; if not, branch
		subi.w	#$28,y_vel(a0)			; reduce gravity by $28 ($38-$28=$10)

loc_10FD6:
		bsr.w	Player_JumpAngle
		bra.w	Player_DoLevelCollision
; ---------------------------------------------------------------------------
; Start of subroutine Sonic_MdRoll
; Called if Sonic is in a ball, but not airborne (thus, probably rolling)
; Sonic_Spin_Path:
Sonic_MdRoll:
		tst.b	spin_dash_flag(a0)
		bne.s	loc_10FEA
		bsr.w	Sonic_Jump

loc_10FEA:
		bsr.w	Player_RollRepel
		bsr.w	Sonic_RollSpeed
		bsr.w	Player_LevelBound
		jsr	(MoveSprite2_TestGravity).w
		bsr.w	Call_Player_AnglePos
		bra.w	Player_SlopeRepel
; ---------------------------------------------------------------------------
; Start of subroutine Sonic_MdJump
; Called if Sonic is in a ball and airborne (he could be jumping but not necessarily)
; Notes: This is identical to Sonic_MdAir, at least at this outer level.
; Why they gave it a separate copy of the code, I don't know.
; Sonic_Spin_Freespace:
Sonic_MdJump:
		bsr.w	Sonic_JumpHeight
.firstframe
		bsr.w	Sonic_ChgJumpDir
		bsr.w	Player_LevelBound
		jsr	(MoveSprite_TestGravity).w
		btst	#Status_Underwater,status(a0)		; is Sonic underwater?
		beq.s	loc_11056					; if not, branch
		subi.w	#$28,y_vel(a0)				; reduce gravity by $28 ($38-$28=$10)

loc_11056:
		bsr.w	Player_JumpAngle
		bra.w	Player_DoLevelCollision

	if RollInAir

; ---------------------------------------------------------------------------
; Subroutine to make Sonic roll
; ---------------------------------------------------------------------------

Sonic_ChgFallAnim:
		btst	#Status_Roll,status(a0)			; is Sonic rolling?
		bne.s	.return					 	; if yes, branch
		btst	#Status_OnObj,status(a0)			; is Sonic standing on an object?
		bne.s	.return 						; if yes, branch
		tst.b	flip_angle(a0)					; flip angle?
		bne.s	.return 						; if yes, branch
		tst.b	anim(a0)						; walk animation?
		bne.s	.return 						; if not, branch
		moveq	#btnABC,d0					; read only A/B/C buttons
		and.b	(Ctrl_1_pressed_logical).w,d0	; get button presses
		beq.s	.return
		bset	#Status_Roll,status(a0)
		move.w	#bytes_to_word(28/2,14/2),y_radius(a0)	; set y_radius and x_radius
		move.b	#id_Roll,anim(a0)				; use "rolling"	animation
		addq.w	#5,y_pos(a0)
		tst.b	(Reverse_gravity_flag).w
		beq.s	.return
		subi.w	#5+5,y_pos(a0)

.return
		rts

	endif

; ---------------------------------------------------------------------------
; Subroutine to make Sonic walk/run
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Sonic_Move:
		move.w	Max_speed-Max_speed(a4),d6		; set Max_speed
		move.w	Acceleration-Max_speed(a4),d5		; set Acceleration
		move.w	Deceleration-Max_speed(a4),d4		; set Deceleration
		tst.b	status_secondary(a0)			; is bit 7 set? (Infinite inertia)
		bmi.w	loc_11332				; if so, branch
		tst.w	move_lock(a0)
		bne.w	loc_112EA
		btst	#button_left,(Ctrl_1_logical).w		; is left being pressed?
		beq.s	Sonic_NotLeft				; if not, branch
		bsr.w	sub_113F6

Sonic_NotLeft:
		btst	#button_right,(Ctrl_1_logical).w	; is right being pressed?
		beq.s	Sonic_NotRight				; if not, branch
		bsr.w	sub_11482

Sonic_NotRight:
		move.w	(HScroll_Shift).w,d1
		beq.s	+
		bclr	#Status_Facing,status(a0)
		tst.w	d1
		bpl.s	+
		bset	#Status_Facing,status(a0)
+		move.b	angle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0					; is Sonic on a slope?
		bne.w	loc_112EA				; if yes, branch
		tst.w	ground_vel(a0)				; is Sonic moving?
		bne.w	loc_112EA				; if yes, branch
		tst.w	d1
		bne.w	loc_112EA
		bclr	#Status_Push,status(a0)
		move.b	#id_Wait,anim(a0)			; use standing animation
		btst	#Status_OnObj,status(a0)
		beq.w	Sonic_Balance
		movea.w	interact(a0),a1				; load interacting object's RAM space
		tst.b	status(a1)				; is status bit 7 set? (Balance anim off)
		bmi.w	loc_11276				; if so, branch

		; Calculations to determine where on the object Sonic is, and make him balance accordingly
		moveq	#0,d1					; Clear d1
		move.b	width_pixels(a1),d1			; Load interacting object's width into d1
		move.w	d1,d2					; Move to d2 for seperate calculations
		add.w	d2,d2					; Double object width, converting it to X pos' units of measurement
		subq.w	#2,d2					; Subtract 2: This is the margin for 'on edge'
		add.w	x_pos(a0),d1				; Add Sonic's X position to object width
		sub.w	x_pos(a1),d1				; Subtract object's X position from width+Sonic's X pos, giving you Sonic's distance from left edge of object
		cmpi.w	#2,d1					; is Sonic within two units of object's left edge?
		blt.s	Sonic_BalanceOnObjLeft			; if so, branch
		cmp.w	d2,d1
		bge.s	Sonic_BalanceOnObjRight			; if Sonic is within two units of object's right edge, branch (Realistically, it checks this, and BEYOND the right edge of the object)
		bra.w	loc_11276				; if Sonic is more than 2 units from both edges, branch
; ---------------------------------------------------------------------------
; balancing checks for when you're on the right edge of an object

Sonic_BalanceOnObjRight:
		btst	#Status_Facing,status(a0)	; is Sonic facing right?
		bne.s	loc_11128			; if so, branch
		move.b	#id_Balance,anim(a0)		; Balance animation 1
		addq.w	#6,d2				; extend balance range
		cmp.w	d2,d1				; is Sonic within (two units before and) four units past the right edge?
		blt.w	loc_112EA			; if so branch
		move.b	#id_Balance2,anim(a0)		; if REALLY close to the edge, use different animation (Balance animation 2)
		bra.w	loc_112EA
loc_11128:	; +
		; Somewhat dummied out/redundant code from Sonic 2
		; Originally, Sonic displayed different animations for each direction faced
		; But now, Sonic uses only the one set of animations no matter what, making the check pointless, and the code redundant
		bclr	#Status_Facing,status(a0)
		move.b	#id_Balance,anim(a0)		; Balance animation 1
		addq.w	#6,d2				; extend balance range
		cmp.w	d2,d1				; is Sonic within (two units before and) four units past the right edge?
		blt.w	loc_112EA			; if so branch
		move.b	#id_Balance2,anim(a0)		; if REALLY close to the edge, use different animation (Balance animation 2)
		bra.w	loc_112EA
; ---------------------------------------------------------------------------

Sonic_BalanceOnObjLeft:
		btst	#Status_Facing,status(a0)	; is Sonic facing right?
		beq.s	loc_11166
		move.b	#id_Balance,anim(a0)		; Balance animation 1
		cmpi.w	#-4,d1		; is Sonic within (two units before and) four units past the left edge?
		bge.w	loc_112EA	; if so branch (instruction signed to match)
		move.b	#id_Balance2,anim(a0)		; if REALLY close to the edge, use different animation (Balance animation 2)
		bra.w	loc_112EA
loc_11166:	; +
		; Somewhat dummied out/redundant code from Sonic 2
		; Originally, Sonic displayed different animations for each direction faced
		; But now, Sonic uses only the one set of animations no matter what, making the check pointless, and the code redundant
		bset	#Status_Facing,status(a0)	; is Sonic facing right?
		move.b	#id_Balance,anim(a0)	; Balance animation 1
		cmpi.w	#-4,d1		; is Sonic within (two units before and) four units past the left edge?
		bge.w	loc_112EA	; if so branch (instruction signed to match)
		move.b	#id_Balance2,anim(a0)	; if REALLY close to the edge, use different animation (Balance animation 2)
		bra.w	loc_112EA
; ---------------------------------------------------------------------------
; balancing checks for when you're on the edge of part of the level
Sonic_Balance:
		move.w	x_pos(a0),d3
		bsr.w	ChooseChkFloorEdge
		cmpi.w	#$C,d1
		blt.w	loc_11276
		cmpi.b	#3,next_tilt(a0)
		bne.s	loc_111F6
		btst	#Status_Facing,status(a0)
		bne.s	loc_111CE
		move.b	#id_Balance,anim(a0)
		move.w	x_pos(a0),d3
		subq.w	#6,d3
		bsr.w	ChooseChkFloorEdge
		cmpi.w	#$C,d1
		blt.w	loc_112EA
		move.b	#id_Balance2,anim(a0)
		bra.w	loc_112EA
		; on right edge but facing left:
loc_111CE:	; +
		; Somewhat dummied out/redundant code from Sonic 2
		; Originally, Sonic displayed different animations for each direction faced
		; But now, Sonic uses only the one set of animations no matter what, making the check pointless, and the code redundant
		bclr	#Status_Facing,status(a0)
		move.b	#id_Balance,anim(a0)
		move.w	x_pos(a0),d3
		subq.w	#6,d3
		bsr.w	ChooseChkFloorEdge
		cmpi.w	#$C,d1
		blt.w	loc_112EA
		move.b	#id_Balance2,anim(a0)
		bra.w	loc_112EA
; ---------------------------------------------------------------------------

loc_111F6:
		cmpi.b	#3,tilt(a0)
		bne.s	loc_11276
		btst	#Status_Facing,status(a0)
		beq.s	loc_11228
		move.b	#id_Balance,anim(a0)
		move.w	x_pos(a0),d3
		addq.w	#6,d3
		bsr.w	ChooseChkFloorEdge
		cmpi.w	#$C,d1
		blt.w	loc_112EA
		move.b	#id_Balance2,anim(a0)
		bra.w	loc_112EA
; ---------------------------------------------------------------------------

loc_11228:
		bset	#Status_Facing,status(a0)
		move.b	#id_Balance,anim(a0)
		move.w	x_pos(a0),d3
		addq.w	#6,d3
		bsr.w	ChooseChkFloorEdge
		cmpi.w	#$C,d1
		blt.w	loc_112EA
		move.b	#id_Balance2,anim(a0)
		bra.w	loc_112EA
; ---------------------------------------------------------------------------

loc_11276:
		tst.w	(HScroll_Shift).w
		bne.s	loc_112B0
		btst	#button_down,(Ctrl_1_logical).w
		beq.s	loc_112B0
		move.b	#id_Duck,anim(a0)
		addq.b	#1,scroll_delay_counter(a0)
		cmpi.b	#2*60,scroll_delay_counter(a0)
		bcs.s	loc_112F0
		move.b	#2*60,scroll_delay_counter(a0)
		tst.b	(Reverse_gravity_flag).w
		bne.s	loc_112A6
		cmpi.w	#8,(a5)
		beq.s	loc_112FC
		subq.w	#2,(a5)
		bra.s	loc_112FC
; ---------------------------------------------------------------------------

loc_112A6:
		cmpi.w	#$D8,(a5)
		beq.s	loc_112FC
		addq.w	#2,(a5)
		bra.s	loc_112FC
; ---------------------------------------------------------------------------

loc_112B0:
		btst	#button_up,(Ctrl_1_logical).w
		beq.s	loc_112EA
		move.b	#id_LookUp,anim(a0)
		addq.b	#1,scroll_delay_counter(a0)
		cmpi.b	#2*60,scroll_delay_counter(a0)
		bcs.s	loc_112F0
		move.b	#2*60,scroll_delay_counter(a0)
		tst.b	(Reverse_gravity_flag).w
		bne.s	loc_112E0
		cmpi.w	#$C8,(a5)
		beq.s	loc_112FC
		addq.w	#2,(a5)
		bra.s	loc_112FC
; ---------------------------------------------------------------------------

loc_112E0:
		cmpi.w	#$18,(a5)
		beq.s	loc_112FC
		subq.w	#2,(a5)
		bra.s	loc_112FC
; ---------------------------------------------------------------------------

loc_112EA:
		clr.b	scroll_delay_counter(a0)

loc_112F0:
		cmpi.w	#$60,(a5)
		beq.s	loc_112FC
		bcc.s	loc_112FA
		addq.w	#4,(a5)

loc_112FA:
		subq.w	#2,(a5)

loc_112FC:
		move.b	(Ctrl_1_logical).w,d0
		andi.b	#btnL+btnR,d0
		bne.s	loc_11332
		move.w	ground_vel(a0),d0
		beq.s	loc_11332
		bmi.s	loc_11326
		sub.w	d5,d0
		bcc.s	loc_11320
		moveq	#0,d0

loc_11320:
		move.w	d0,ground_vel(a0)
		bra.s	loc_11332
; ---------------------------------------------------------------------------

loc_11326:
		add.w	d5,d0
		bcc.s	loc_1132E
		moveq	#0,d0

loc_1132E:
		move.w	d0,ground_vel(a0)

loc_11332:
		move.b	angle(a0),d0
		jsr	(GetSineCosine).w
		move.w	ground_vel(a0),d2
		muls.w	d2,d1
		asr.l	#8,d1
		move.w	d1,x_vel(a0)
		muls.w	d2,d0
		asr.l	#8,d0
		move.w	d0,y_vel(a0)

loc_11350:
		btst	#6,object_control(a0)
		bne.s	locret_113CE
		move.b	angle(a0),d0
		move.b	d0,d1
		andi.b	#$3F,d0
		beq.s	+
		addi.b	#$40,d1
		bmi.s	locret_113CE
+
		moveq	#$40,d1
		tst.w	ground_vel(a0)
		beq.s	locret_113CE
		bmi.s	+
		neg.w	d1
+
		move.b	angle(a0),d0
		add.b	d1,d0
		move.w	d0,-(sp)
		bsr.w	CalcRoomInFront
		move.w	(sp)+,d0
		tst.w	d1
		bpl.s	locret_113CE
		asl.w	#8,d1
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.s	loc_113F0
		cmpi.b	#$40,d0
		beq.s	loc_113D6
		cmpi.b	#$80,d0
		beq.s	loc_113D0
		add.w	d1,x_vel(a0)
		clr.w	ground_vel(a0)
		btst	#Status_Facing,status(a0)
		bne.s	locret_113CE
		bset	#Status_Push,status(a0)

locret_113CE:
		rts
; ---------------------------------------------------------------------------

loc_113D0:
		sub.w	d1,y_vel(a0)
		rts
; ---------------------------------------------------------------------------

loc_113D6:
		sub.w	d1,x_vel(a0)
		clr.w	ground_vel(a0)
		btst	#Status_Facing,status(a0)
		beq.s	locret_113CE
		bset	#Status_Push,status(a0)
		rts
; ---------------------------------------------------------------------------

loc_113F0:
		add.w	d1,y_vel(a0)
		rts

; =============== S U B R O U T I N E =======================================

sub_113F6:
		move.w	ground_vel(a0),d0
		beq.s	loc_113FE
		bpl.s	loc_11430

loc_113FE:
		tst.w	(HScroll_Shift).w
		bne.s	loc_11412
		bset	#Status_Facing,status(a0)
		bne.s	loc_11412
		bclr	#Status_Push,status(a0)
		move.b	#id_Run,prev_anim(a0)

loc_11412:
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_11424
		add.w	d5,d0
		cmp.w	d1,d0
		ble.s		loc_11424
		move.w	d1,d0

loc_11424:
		move.w	d0,ground_vel(a0)
		clr.b	anim(a0)	; id_Walk
		rts
; ---------------------------------------------------------------------------

loc_11430:
		sub.w	d4,d0
		bcc.s	loc_11438
		move.w	#-$80,d0

loc_11438:
		move.w	d0,ground_vel(a0)
		move.b	angle(a0),d1
		addi.b	#$20,d1
		andi.b	#$C0,d1
		bne.s	locret_11480
		cmpi.w	#$400,d0
		blt.s		locret_11480
		tst.b	flip_type(a0)
		bmi.s	locret_11480
		sfx	sfx_Skid
		move.b	#id_Stop,anim(a0)
		bclr	#Status_Facing,status(a0)
		cmpi.b	#12,air_left(a0)
		bcs.s	locret_11480
		move.b	#6,routine(a6)			; v_Dust
		move.b	#$15,mapping_frame(a6)	; v_Dust

locret_11480:
		rts

; =============== S U B R O U T I N E =======================================

sub_11482:
		move.w	ground_vel(a0),d0
		bmi.s	loc_114B6
		bclr	#Status_Facing,status(a0)
		beq.s	loc_1149C
		bclr	#Status_Push,status(a0)
		move.b	#id_Run,prev_anim(a0)

loc_1149C:
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s		loc_114AA
		sub.w	d5,d0
		cmp.w	d6,d0
		bge.s	loc_114AA
		move.w	d6,d0

loc_114AA:
		move.w	d0,ground_vel(a0)
		clr.b	anim(a0)	; id_Walk
		rts
; ---------------------------------------------------------------------------

loc_114B6:
		add.w	d4,d0
		bcc.s	loc_114BE
		move.w	#$80,d0

loc_114BE:
		move.w	d0,ground_vel(a0)
		move.b	angle(a0),d1
		addi.b	#$20,d1
		andi.b	#$C0,d1
		bne.s	locret_11506
		cmpi.w	#-$400,d0
		bgt.s	locret_11506
		tst.b	flip_type(a0)
		bmi.s	locret_11506
		sfx	sfx_Skid
		move.b	#id_Stop,anim(a0)
		bset	#Status_Facing,status(a0)
		cmpi.b	#12,air_left(a0)
		bcs.s	locret_11506
		move.b	#6,routine(a6)			; v_Dust
		move.b	#$15,mapping_frame(a6)	; v_Dust

locret_11506:
		rts

; =============== S U B R O U T I N E =======================================

Sonic_RollSpeed:
		move.w	Max_speed-Max_speed(a4),d6
		asl.w	#1,d6
		move.w	Acceleration-Max_speed(a4),d5
		asr.w	#1,d5
		move.w	#$20,d4
		tst.b	spin_dash_flag(a0)
		bmi.w	loc_115C6
		tst.b	status_secondary(a0)
		bmi.w	loc_115C6
		tst.w	move_lock(a0)
		bne.s	loc_1154E
		btst	#button_left,(Ctrl_1_logical).w
		beq.s	loc_11542
		bsr.w	sub_11608

loc_11542:
		btst	#button_right,(Ctrl_1_logical).w
		beq.s	loc_1154E
		bsr.w	sub_1162C

loc_1154E:
		move.w	ground_vel(a0),d0
		beq.s	loc_11570
		bmi.s	loc_11564
		sub.w	d5,d0
		bcc.s	loc_1155E
		moveq	#0,d0

loc_1155E:
		move.w	d0,ground_vel(a0)
		bra.s	loc_11570
; ---------------------------------------------------------------------------

loc_11564:
		add.w	d5,d0
		bcc.s	loc_1156C
		moveq	#0,d0

loc_1156C:
		move.w	d0,ground_vel(a0)

loc_11570:
		move.w	ground_vel(a0),d0
		bpl.s	loc_11578
		neg.w	d0

loc_11578:
		cmpi.w	#$80,d0
		bcc.s	loc_115C6
		tst.b	spin_dash_flag(a0)
		bne.s	loc_115B4
		bclr	#Status_Roll,status(a0)
		move.b	y_radius(a0),d0
		move.b	default_y_radius(a0),y_radius(a0)
		move.b	default_x_radius(a0),x_radius(a0)
		move.b	#id_Wait,anim(a0)
		sub.b	default_y_radius(a0),d0
		ext.w	d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_115AE
		neg.w	d0

loc_115AE:
		add.w	d0,y_pos(a0)
		bra.s	loc_115C6
; ---------------------------------------------------------------------------

loc_115B4:
		move.w	#$400,ground_vel(a0)
		btst	#Status_Facing,status(a0)
		beq.s	loc_115C6
		neg.w	ground_vel(a0)

loc_115C6:
		cmpi.w	#$60,(a5)
		beq.s	loc_115D2
		bcc.s	loc_115D0
		addq.w	#4,(a5)

loc_115D0:
		subq.w	#2,(a5)

loc_115D2:
		move.b	angle(a0),d0
		jsr	(GetSineCosine).w
		move.w	ground_vel(a0),d2
		muls.w	d2,d0
		asr.l	#8,d0
		move.w	d0,y_vel(a0)
		muls.w	d2,d1
		asr.l	#8,d1
		cmpi.w	#$1000,d1
		ble.s	+
		move.w	#$1000,d1
+
		cmpi.w	#-$1000,d1
		bge.s	+
		move.w	#-$1000,d1
+
		move.w	d1,x_vel(a0)
		bra.w	loc_11350

; =============== S U B R O U T I N E =======================================

sub_11608:
		move.w	ground_vel(a0),d0
		beq.s	loc_11610
		bpl.s	loc_1161E

loc_11610:
		bset	#Status_Facing,status(a0)
		move.b	#id_Roll,anim(a0)
		rts
; ---------------------------------------------------------------------------

loc_1161E:
		sub.w	d4,d0
		bcc.s	loc_11626
		move.w	#-$80,d0

loc_11626:
		move.w	d0,ground_vel(a0)
		rts

; =============== S U B R O U T I N E =======================================

sub_1162C:
		move.w	ground_vel(a0),d0
		bmi.s	loc_11640
		bclr	#Status_Facing,status(a0)
		move.b	#id_Roll,anim(a0)
		rts
; ---------------------------------------------------------------------------

loc_11640:
		add.w	d4,d0
		bcc.s	loc_11648
		move.w	#$80,d0

loc_11648:
		move.w	d0,ground_vel(a0)
		rts
; ---------------------------------------------------------------------------
; Subroutine for moving Sonic left or right when he's in the air
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Sonic_ChgJumpDir:
		btst	#Status_RollJump,status(a0)
		bne.s	loc_116A2
		move.w	Max_speed-Max_speed(a4),d6
		move.w	Acceleration-Max_speed(a4),d5
		asl.w	#1,d5
		move.w	x_vel(a0),d0
		btst	#button_left,(Ctrl_1_logical).w
		beq.s	loc_11682
		bset	#Status_Facing,status(a0)
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_11682
		add.w	d5,d0
		cmp.w	d1,d0
		ble.s		loc_11682
		move.w	d1,d0

loc_11682:
		btst	#button_right,(Ctrl_1_logical).w
		beq.s	loc_1169E
		bclr	#Status_Facing,status(a0)
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s		loc_1169E
		sub.w	d5,d0
		cmp.w	d6,d0
		bge.s	loc_1169E
		move.w	d6,d0

loc_1169E:
		move.w	d0,x_vel(a0)

loc_116A2:
		cmpi.w	#$60,(a5)
		beq.s	loc_116AE
		bcc.s	loc_116AC
		addq.w	#4,(a5)

loc_116AC:
		subq.w	#2,(a5)

loc_116AE:
		cmpi.w	#-$400,y_vel(a0)
		bcs.s	locret_116DC
		move.w	x_vel(a0),d0
		move.w	d0,d1
		asr.w	#5,d1
		beq.s	locret_116DC
		bmi.s	loc_116D0
		sub.w	d1,d0
		bcc.s	loc_116CA
		moveq	#0,d0

loc_116CA:
		move.w	d0,x_vel(a0)
		rts
; ---------------------------------------------------------------------------

loc_116D0:
		sub.w	d1,d0
		bcs.s	loc_116D8
		moveq	#0,d0

loc_116D8:
		move.w	d0,x_vel(a0)

locret_116DC:
		rts

; =============== S U B R O U T I N E =======================================

Player_LevelBound:
		move.l	x_pos(a0),d1
		move.w	x_vel(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d1
		swap	d1
		move.w	(Camera_min_X_pos).w,d0
		addi.w	#$10,d0
		cmp.w	d1,d0
		bhi.s	loc_11732
		move.w	(Camera_max_X_pos).w,d0
		addi.w	#$128,d0
		cmp.w	d1,d0
		bcs.s	loc_11732

Player_Boundary_CheckBottom:
		tst.b	(Disable_death_plane).w
		bne.s	locret_11720
		tst.b	(Reverse_gravity_flag).w
		bne.s	loc_11722
		move.w	(Camera_max_Y_pos).w,d0
		cmp.w	(Camera_target_max_Y_pos).w,d0
		blt.s		locret_11720
		addi.w	#224,d0
		cmp.w	y_pos(a0),d0
		blt.s		Player_Boundary_Bottom

locret_11720:
		rts
; ---------------------------------------------------------------------------

loc_11722:
		move.w	(Camera_min_Y_pos).w,d0
		cmp.w	y_pos(a0),d0
		blt.s		locret_11720

Player_Boundary_Bottom:
		jmp	Kill_Character(pc)
; ---------------------------------------------------------------------------

loc_11732:
		move.w	d0,x_pos(a0)
		clr.w	2+x_pos(a0)
		clr.w	x_vel(a0)
		clr.w	ground_vel(a0)
		bra.s	Player_Boundary_CheckBottom

; =============== S U B R O U T I N E =======================================

SonicKnux_Roll:
		tst.b	status_secondary(a0)
		bmi.s	locret_1177E
		tst.w	(HScroll_Shift).w
		bne.s	locret_1177E
		move.b	(Ctrl_1_logical).w,d0
		andi.b	#btnL+btnR,d0
		bne.s	locret_1177E
		btst	#button_down,(Ctrl_1_logical).w
		beq.s	loc_11780
		move.w	ground_vel(a0),d0
		bpl.s	loc_1176A
		neg.w	d0

loc_1176A:
		cmpi.w	#$100,d0
		bcc.s	loc_11790
		btst	#Status_OnObj,status(a0)
		bne.s	locret_1177E
		move.b	#id_Duck,anim(a0)

locret_1177E:
		rts
; ---------------------------------------------------------------------------

loc_11780:
		cmpi.b	#id_Duck,anim(a0)
		bne.s	locret_1177E
		clr.b	anim(a0)	; id_Walk
		rts
; ---------------------------------------------------------------------------

loc_11790:
		btst	#Status_Roll,status(a0)
		beq.s	loc_1179A
		rts
; ---------------------------------------------------------------------------

loc_1179A:
		bset	#Status_Roll,status(a0)
		move.w	#bytes_to_word(28/2,14/2),y_radius(a0)	; set y_radius and x_radius
		move.b	#id_Roll,anim(a0)
		addq.w	#5,y_pos(a0)
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_117C2
		subi.w	#$A,y_pos(a0)

loc_117C2:
		sfx	sfx_Roll
		tst.w	ground_vel(a0)
		bne.s	locret_117D8
		move.w	#$200,ground_vel(a0)

locret_117D8:
		rts
; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to jump
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Sonic_Jump:
		move.b	(Ctrl_1_pressed_logical).w,d0
		andi.b	#btnA+btnB+btnC,d0
		beq.s	locret_117D8
		moveq	#0,d0
		move.b	angle(a0),d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		addi.b	#$40,d0
		neg.b	d0
		subi.b	#$40,d0
+
		addi.b	#$80,d0
		movem.l	d1/a4-a6,-(sp)
		bsr.w	CalcRoomOverHead
		movem.l	(sp)+,d1/a4-a6
		cmpi.w	#6,d1
		blt.s	locret_117D8

		moveq	#0,d1
		move.b	angle(a0),d1
		subi.b	#$40,d1
		jsr	(GetSineCosine.angd1).w
		move.w	Jump_height-Max_speed(a4),d2
		muls.w	d2,d1
		asr.l	#8,d1
		add.w	d1,x_vel(a0)
		muls.w	d2,d0
		asr.l	#8,d0
		add.w	d0,y_vel(a0)
		addq.l	#4,sp		; skip the rest of Sonic_MdNormal
		move.b	#1,jumping(a0)
		bset	#Status_InAir,status(a0)
		bclr	#Status_Push,status(a0)
		clr.b	stick_to_convex(a0)
		move.w	default_y_radius(a0),y_radius(a0)
	;	move.b	default_x_radius(a0),x_radius(a0)
		btst	#Status_Roll,status(a0)
		bne.s	.rolljump
		move.w	#bytes_to_word(28/2,14/2),y_radius(a0)	; set y_radius and x_radius
		move.b	#id_Roll,anim(a0)
		bset	#Status_Roll,status(a0)
		move.b	y_radius(a0),d0
		sub.b	default_y_radius(a0),d0
		ext.w	d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		neg.w	d0
+
		sub.w	d0,y_pos(a0)
.rolljump
		sfx	sfx_Jump,1
	;	bra.w	Sonic_MdJump.firstframe	; this fixes the one frame delay when jumping, but is character specific


; =============== S U B R O U T I N E =======================================

Sonic_JumpHeight:
		tst.b	jumping(a0)			; is Sonic jumping?
		beq.s	Sonic_UpVelCap			; if not, branch

		move.w	#-$400,d1
		btst	#Status_Underwater,status(a0)			; is Sonic underwater?
		beq.s	+						; if not, branch
		move.w	#-$200,d1					; Underwater-specific
+
		cmp.w	y_vel(a0),d1					; is y speed greater than 4? (2 if underwater)
		ble.s	Sonic_InstaAndShieldMoves			; if not, branch
		move.b	(Ctrl_1_logical).w,d0
		andi.b	#btnA+btnB+btnC,d0				; are buttons A, B or C being held?
		bne.s	locret_118E8					; if yes, branch
		move.w	d1,y_vel(a0)					; cap jump height

locret_118E8:
		rts
; ---------------------------------------------------------------------------

Sonic_UpVelCap:
		tst.b	spin_dash_flag(a0)		; is Sonic charging his spin dash?
		bne.s	+				; if yes, branch
		move.w	#-$FC0,d0
		cmp.w	y_vel(a0),d0			; is Sonic's Y speed faster than -15.75 (-$FC0)?
		blt.s	+				; if not, branch
		move.w	d0,y_vel(a0)			; cap upward speed to -15.75
+
locret_118FE:
		rts
; ---------------------------------------------------------------------------

Sonic_InstaAndShieldMoves:
		tst.b	double_jump_flag(a0)		; is Sonic currently performing a double jump?
		bmi.s	locret_118FE			; if so, end
		btst	#Status_Invincible,status_secondary(a0)	; does Sonic have invincibility?
		bne.s	Sonic_DropDash				; if so, just test Drop Dash
		btst	#Status_Shield,status_secondary(a0)	; does Sonic have any shield?
		bne.s	Sonic_ShieldTest			; if so, test shields (if that fails it tests drop dash)
; test Insta-Shield
		tst.b	double_jump_flag(a0)		; did we already do this press?
		bne.s	Sonic_DropDash.check		; if so, branch
;		btst	#button_C,(Ctrl1_Player_Pr_ABC).w
		move.w	(Ctrl1_Player_Pr).w,d0
		andi.w	#button_ABC_mask,d0		; are buttons A, B, or C being pressed?
		beq.s	Sonic_DropDash
		move.b	#1,(v_Shield+anim).w
;		sfx	sfx_InstaAttack
		move.b	#1,double_jump_flag(a0)		; copy Sonic_DropDash start
;		rts
;		bra.s	.charge
		sfx	sfx_InstaAttack,1		; play Insta-Shield sound, end routine with delay mentioned below
Sonic_DropDash:
		tst.b	double_jump_flag(a0)		; did we already do this press?
		bne.s	.check				; if so, branch
		move.w	(Ctrl1_Player_Pr).w,d0
		andi.w	#button_ABC_mask,d0		; are buttons A, B, or C being pressed?
		beq.s	.end				; if not, end
		move.b	#1,double_jump_flag(a0)		; set that we pressed it, cont with .charge...
.end:
		rts	; or not! Drop Dash has 20 frame delay, and the fastest method would only give us 19

.charge:
		tst.b	double_jump_property(a0)	; if already set, branch
		bmi.s	.end				;
		addq.b	#7,double_jump_property(a0)	; increment until drop dash is allowed
		bpl.s	.end				; (19 frames until bmi range. Note previous delay)
		move.b	#id_Walk,anim(a0)		; id_DropDash ; set anim
		sfx	sfx_SpinDash,1			; play drop dash rev sound
.check:
		move.w	(Ctrl1_Player_Hd).w,d0
		andi.w	#button_ABC_mask,d0		; are buttons A, B, or C being held?
		bne.s	.charge				; if so, branch
		st	double_jump_flag(a0)		; stop checking ; Note, disables shields when mid-drop dash charge
		clr.b	double_jump_property(a0)	; don't drop dash
		move.b	#id_Roll,anim(a0)		; set back to regular roll
Sonic_ShieldTest_End:
		rts

Sonic_ShieldTest:
;		tst.b	double_jump_flag(a0)			; is Sonic currently performing a double jump?
;		bmi.s	Sonic_ShieldTest_End			; if yes, branch
		move.b	(Ctrl_1_pressed_logical).w,d0
		andi.b	#btnA+btnB+btnC,d0			; are buttons A, B, or C being pressed?
		beq.s	Sonic_DropDash				; if not, check drop dash
		st	double_jump_flag(a0)			; at this point we're definitely double jumping
		bclr	#Status_RollJump,status(a0)
		move.b	status_secondary(a0),d0
		andi.w	#Status_Elements,d0		; does Sonic have any elemental shield?
		beq.s	Sonic_DropDash			; if not, do drop dash

Sonic_FireShield:
		btst	#Status_FireShield,d0		; does Sonic have a Fire Shield?
		beq.s	Sonic_LightningShield		; if not, branch
		move.b	#1,(v_Shield+anim).w
		move.w	#$800,d0
		btst	#Status_Facing,status(a0)	; is Sonic facing left?
		beq.s	+				; if not, branch
		neg.w	d0				; reverse speed value, moving Sonic left
+
		move.w	d0,x_vel(a0)			; apply velocity...
		move.w	d0,ground_vel(a0)		; ...both ground and air
		clr.w	y_vel(a0)			; kill y-velocity
		lea	(H_scroll_frame_offset).w,a1
		move.b	#32,(a1)+			; H_scroll_frame_offset ; delay scrolling for 32 frames
		move.b	(Pos_table_byte).w,(a1)+	; H_scroll_frame_copy ; Back up the position array index for later.
;		bsr.w	Reset_Player_Position_Array	; this was a poorly implemented camera fix that isn't needed anymore
		sfx	sfx_FireAttack,1		; play Fire Shield attack sound
; ---------------------------------------------------------------------------

Sonic_LightningShield:
		btst	#Status_LtngShield,d0		; does Sonic have a Lightning Shield?
		beq.s	Sonic_BubbleShield		; if not, branch
		move.b	#1,(v_Shield+anim).w
		move.w	#-$580,y_vel(a0)		; bounce Sonic up, creating the double jump effect
		clr.b	jumping(a0)
		sfx	sfx_ElectricAttack,1		; play Lightning Shield attack sound
; ---------------------------------------------------------------------------

Sonic_BubbleShield:
		btst	#Status_BublShield,d0		; does Sonic have a Bubble Shield
		beq.s	Sonic_NoShield			; if not, branch
		move.b	#1,(v_Shield+anim).w
		st	double_jump_property(a0)	; set bounce flag
		clr.w	x_vel(a0)			; halt horizontal speed...
		clr.w	ground_vel(a0)			; ...both ground and air
		move.w	#$800,y_vel(a0)			; force Sonic down
		sfx	sfx_BubbleAttack,1		; play Bubble Shield attack sound
; ---------------------------------------------------------------------------

Sonic_NoShield:
locret_11A14:
		rts

; =============== S U B R O U T I N E =======================================

SonicKnux_Spindash:
		tst.b	spin_dash_flag(a0)
		bne.s	loc_11C5E
		cmpi.b	#id_Duck,anim(a0)
		bne.s	locret_11A14
		move.b	(Ctrl_1_pressed_logical).w,d0
		andi.b	#btnA+btnB+btnC,d0
		beq.s	locret_11A14
		move.b	#id_SpinDash,anim(a0)
		sfx	sfx_SpinDash
		addq.l	#4,sp
		move.b	#1,spin_dash_flag(a0)
		clr.w	spin_dash_counter(a0)
		cmpi.b	#12,air_left(a0)
		bcs.s	loc_11C24
		move.b	#2,anim(a6)		; v_Dust

loc_11C24:
		bsr.w	Player_LevelBound
		bra.w	Call_Player_AnglePos
; ---------------------------------------------------------------------------
; Sonic_UpdateSpindash:
loc_11C5E:
		btst	#button_down,(Ctrl_1_logical).w
		bne.w	loc_11D16
		move.w	#bytes_to_word(28/2,14/2),y_radius(a0)	; set y_radius and x_radius
		move.b	#id_Roll,anim(a0)
		addq.w	#5,y_pos(a0)
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_11C8C
		subi.w	#$A,y_pos(a0)

loc_11C8C:
		moveq	#0,d0
		move.b	d0,spin_dash_flag(a0)
		move.b	spin_dash_counter(a0),d0
		add.w	d0,d0
		move.w	word_11CF2(pc,d0.w),ground_vel(a0)
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
		move.b	d0,(a1)+			; H_scroll_frame_offset
		move.b	(Pos_table_byte).w,(a1)+	; H_scroll_frame_copy ; Back up the position array index for later.

		btst	#Status_Facing,status(a0)
		beq.s	loc_11CDC
		neg.w	ground_vel(a0)

loc_11CDC:
		bset	#Status_Roll,status(a0)
		clr.b	anim(a6)		; v_Dust
		sfx	sfx_Dash
		bra.s	loc_11D5E
; ---------------------------------------------------------------------------

word_11CF2:
		dc.w $800
		dc.w $880
		dc.w $900
		dc.w $980
		dc.w $A00
		dc.w $A80
		dc.w $B00
		dc.w $B80
		dc.w $C00
word_11D04:
		dc.w $B00
		dc.w $B80
		dc.w $C00
		dc.w $C80
		dc.w $D00
		dc.w $D80
		dc.w $E00
		dc.w $E80
		dc.w $F00
; ---------------------------------------------------------------------------

loc_11D16:
		tst.w	spin_dash_counter(a0)
		beq.s	loc_11D2E
		move.w	spin_dash_counter(a0),d0
		lsr.w	#5,d0
		sub.w	d0,spin_dash_counter(a0)
		bcc.s	loc_11D2E
		clr.w	spin_dash_counter(a0)

loc_11D2E:
		move.b	(Ctrl_1_pressed_logical).w,d0
		andi.b	#btnA+btnB+btnC,d0
		beq.w	loc_11D5E
		move.w	#bytes_to_word(id_SpinDash,id_Walk),anim(a0)
		sfx	sfx_SpinDash
		addi.w	#$200,spin_dash_counter(a0)
		cmpi.w	#$800,spin_dash_counter(a0)
		bcs.s	loc_11D5E
		move.w	#$800,spin_dash_counter(a0)

loc_11D5E:
	if	ExtendedCamera
		moveq	#0,d0
		move.b	spin_dash_counter(a0),d0
		add.w	d0,d0
		move.w	word_11CF2(pc,d0.w),ground_vel(a0)
		btst	#Status_Facing,status(a0)
		beq.s	+
		neg.w	ground_vel(a0)
+
	endif
		addq.l	#4,sp
		cmpi.w	#$60,(a5)
		beq.s	loc_11D6C
		bcc.s	loc_11D6A
		addq.w	#4,(a5)

loc_11D6A:
		subq.w	#2,(a5)

loc_11D6C:
		bsr.w	Player_LevelBound
		bra.w	Call_Player_AnglePos

; ---------------------------------------------------------------------------
; Subroutine to slow Sonic walking up a slope
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Player_SlopeResist:
		move.b	angle(a0),d0
		addi.b	#$60,d0
		cmpi.b	#$C0,d0
		bcc.s	locret_11DDA
		move.b	angle(a0),d0
		jsr	(GetSineCosine).w
		muls.w	#$20,d0
		asr.l	#8,d0
		tst.w	ground_vel(a0)
		beq.s	loc_11DDC
		bmi.s	loc_11DD6
		tst.w	d0
		beq.s	locret_11DD4
		add.w	d0,ground_vel(a0)

locret_11DD4:
		rts
; ---------------------------------------------------------------------------

loc_11DD6:
		add.w	d0,ground_vel(a0)

locret_11DDA:
		rts
; ---------------------------------------------------------------------------

loc_11DDC:
		move.w	d0,d1
		bpl.s	loc_11DE2
		neg.w	d1

loc_11DE2:
		cmpi.w	#$D,d1
		bcs.s	locret_11DDA
		add.w	d0,ground_vel(a0)
		rts

; ---------------------------------------------------------------------------
; Subroutine to push Sonic down a slope while he's rolling
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Player_RollRepel:
		move.b	angle(a0),d0
		addi.b	#$60,d0
		cmpi.b	#$C0,d0
		bcc.s	locret_11E28
		move.b	angle(a0),d0
		jsr	(GetSineCosine).w
		muls.w	#$50,d0
		asr.l	#8,d0
		tst.w	ground_vel(a0)
		bmi.s	loc_11E1E
		tst.w	d0
		bpl.s	loc_11E18
		asr.l	#2,d0

loc_11E18:
		add.w	d0,ground_vel(a0)
		rts
; ---------------------------------------------------------------------------

loc_11E1E:
		tst.w	d0
		bmi.s	loc_11E24
		asr.l	#2,d0

loc_11E24:
		add.w	d0,ground_vel(a0)

locret_11E28:
		rts

; ---------------------------------------------------------------------------
; Subroutine to push Sonic down a slope
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Player_SlopeRepel:
		tst.b	stick_to_convex(a0)
		bne.s	locret_11E6E
		tst.w	move_lock(a0)
		bne.s	loc_11E86
		move.b	angle(a0),d0
		addi.b	#$18,d0
		cmpi.b	#$30,d0
		bcs.s	locret_11E6E
		move.w	ground_vel(a0),d0
		bpl.s	loc_11E4E
		neg.w	d0

loc_11E4E:
		cmpi.w	#$280,d0
		bcc.s	locret_11E6E
		move.w	#30,move_lock(a0)
		move.b	angle(a0),d0
		addi.b	#$30,d0
		cmpi.b	#$60,d0
		bcs.s	loc_11E70
		bset	#Status_InAir,status(a0)

locret_11E6E:
		rts
; ---------------------------------------------------------------------------

loc_11E70:
		cmpi.b	#$30,d0
		bcs.s	loc_11E7E
		addi.w	#$80,ground_vel(a0)
		rts
; ---------------------------------------------------------------------------

loc_11E7E:
		subi.w	#$80,ground_vel(a0)
		rts
; ---------------------------------------------------------------------------

loc_11E86:
		subq.w	#1,move_lock(a0)
		rts

; ---------------------------------------------------------------------------
; Subroutine to return Sonic's angle to 0 as he jumps
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Player_JumpAngle:
		move.b	angle(a0),d0	; get Sonic's angle
		beq.s	Player_JumpFlip	; if already 0, branch
		bpl.s	loc_11E9C	; if higher than 0, branch
		addq.b	#2,d0		; increase angle
		bcc.s	loc_11E9A
		moveq	#0,d0

loc_11E9A:
		bra.s	Player_JumpAngleSet
; ---------------------------------------------------------------------------

loc_11E9C:
		subq.b	#2,d0		; decrease angle
		bcc.s	Player_JumpAngleSet
		moveq	#0,d0

Player_JumpAngleSet:
		move.b	d0,angle(a0)
		; continue straight to Player_JumpFlip

; ---------------------------------------------------------------------------
; Updates Sonic's secondary angle if he's tumbling
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Player_JumpFlip:
		move.b	flip_angle(a0),d0
		beq.s	locret_11EEA
		tst.w	ground_vel(a0)
		bmi.s	Player_JumpLeftFlip

Player_JumpRightFlip:
		move.b	flip_speed(a0),d1
		add.b	d1,d0
		bcc.s	loc_11EC8
		subq.b	#1,flips_remaining(a0)
		bcc.s	loc_11EC8
		moveq	#0,d0
		move.b	d0,flips_remaining(a0)

loc_11EC8:
		bra.s	Player_JumpFlipSet
; ---------------------------------------------------------------------------

Player_JumpLeftFlip:
		tst.b	flip_type(a0)
		bmi.s	Player_JumpRightFlip
		move.b	flip_speed(a0),d1
		sub.b	d1,d0
		bcc.s	Player_JumpFlipSet
		subq.b	#1,flips_remaining(a0)
		bcc.s	Player_JumpFlipSet
		moveq	#0,d0
		move.b	d0,flips_remaining(a0)

Player_JumpFlipSet:
		move.b	d0,flip_angle(a0)

locret_11EEA:
		rts

; ---------------------------------------------------------------------------
; Subroutine for Sonic to interact with the floor and walls when he's in the air
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================
; Sonic_Floor:
Player_DoLevelCollision:
		SetCollAddrPlane_macro
		move.b	lrb_solid_bit(a0),d5
		move.w	x_vel(a0),d1
		move.w	y_vel(a0),d2
		jsr	(GetArcTan).w
		subi.b	#$20,d0
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	Player_HitLeftWall
		cmpi.b	#$80,d0
		beq.w	Player_HitCeilingAndWalls
		cmpi.b	#$C0,d0
		beq.w	loc_12102
		bsr.w	CheckLeftWallDist
		tst.w	d1
		bpl.s	loc_11F44
		sub.w	d1,x_pos(a0)
		clr.w	x_vel(a0)	; stop Sonic since he hit a wall

loc_11F44:
		bsr.w	CheckRightWallDist
		tst.w	d1
		bpl.s	loc_11F56
		add.w	d1,x_pos(a0)
		clr.w	x_vel(a0)	; stop Sonic since he hit a wall

loc_11F56:
		bsr.w	sub_11FD6
		tst.w	d1
		bpl.s	locret_11FD4
		move.b	y_vel(a0),d2
		addq.b	#8,d2
		neg.b	d2
		cmp.b	d2,d1
		bge.s	loc_11F6E
		cmp.b	d2,d0
		blt.s		locret_11FD4

loc_11F6E:
		move.b	d3,angle(a0)
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_11F7A
		neg.w	d1

loc_11F7A:
		add.w	d1,y_pos(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.s	loc_11FAE
		move.b	d3,d0
		addi.b	#$10,d0
		andi.b	#$20,d0
		beq.s	loc_11F9C
		asr	y_vel(a0)
		bra.s	loc_11FC2
; ---------------------------------------------------------------------------

loc_11F9C:
		clr.w	y_vel(a0)
		move.w	x_vel(a0),ground_vel(a0)
		bra.w	Player_TouchFloor_Check_Spindash
; ---------------------------------------------------------------------------

loc_11FAE:
		clr.w	x_vel(a0)	; stop Sonic since he hit a wall
		cmpi.w	#$FC0,y_vel(a0)
		ble.s		loc_11FC2
		move.w	#$FC0,y_vel(a0)

loc_11FC2:
		bsr.w	Player_TouchFloor_Check_Spindash
		move.w	y_vel(a0),ground_vel(a0)
		tst.b	d3
		bpl.s	locret_11FD4
		neg.w	ground_vel(a0)

locret_11FD4:
		rts

; =============== S U B R O U T I N E =======================================

sub_11FD6:
		tst.b	(Reverse_gravity_flag).w
		beq.w	Sonic_CheckFloor
		bsr.w	Sonic_CheckCeiling
		addi.b	#$40,d3
		neg.b	d3
		subi.b	#$40,d3
		rts

; =============== S U B R O U T I N E =======================================

sub_11FEE:
		tst.b	(Reverse_gravity_flag).w
		beq.w	Sonic_CheckCeiling
		bsr.w	Sonic_CheckFloor
		addi.b	#$40,d3
		neg.b	d3
		subi.b	#$40,d3
		rts

; =============== S U B R O U T I N E =======================================

ChooseChkFloorEdge:
		tst.b	(Reverse_gravity_flag).w
		beq.w	ChkFloorEdge_Part2
		bra.w	ChkFloorEdge_ReverseGravity
; ---------------------------------------------------------------------------

Player_HitLeftWall:
		bsr.w	CheckLeftWallDist
		tst.w	d1
		bpl.s	Player_HitCeiling	; branch if distance is positive (not inside wall)
		sub.w	d1,x_pos(a0)
		clr.w	x_vel(a0)		; stop Sonic since he hit a wall
		move.w	y_vel(a0),ground_vel(a0)

Player_HitCeiling:
		bsr.w	sub_11FEE
		tst.w	d1
		bpl.s	loc_12068	; branch if distance is positive (not inside ceiling)
		neg.w	d1
		cmpi.w	#$14,d1
		bcc.s	loc_12054
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_12042
		neg.w	d1

loc_12042:
		add.w	d1,y_pos(a0)
		tst.w	y_vel(a0)
		bpl.s	locret_12052
		clr.w	y_vel(a0)	; stop Sonic in y since he hit a ceiling

locret_12052:
		rts
; ---------------------------------------------------------------------------

loc_12054:
		bsr.w	CheckRightWallDist
		tst.w	d1
		bpl.s	locret_12066
		add.w	d1,x_pos(a0)
		clr.w	x_vel(a0)

locret_12066:
		rts
; ---------------------------------------------------------------------------

loc_12068:
		tst.b	(WindTunnel_flag).w
		bne.s	loc_12074
		tst.w	y_vel(a0)
		bmi.s	locret_1209C

loc_12074:
		bsr.w	sub_11FD6
		tst.w	d1
		bpl.s	locret_1209C
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_12084
		neg.w	d1

loc_12084:
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		clr.w	y_vel(a0)
		move.w	x_vel(a0),ground_vel(a0)
		bsr.w	Player_TouchFloor_Check_Spindash

locret_1209C:
		rts
; ---------------------------------------------------------------------------

Player_HitCeilingAndWalls:
		bsr.w	CheckLeftWallDist
		tst.w	d1
		bpl.s	loc_120B0
		sub.w	d1,x_pos(a0)
		clr.w	x_vel(a0)	; stop Sonic since he hit a wall

loc_120B0:
		bsr.w	CheckRightWallDist
		tst.w	d1
		bpl.s	loc_120C2
		add.w	d1,x_pos(a0)
		clr.w	x_vel(a0)	; stop Sonic since he hit a wall

loc_120C2:
		bsr.w	sub_11FEE
		tst.w	d1
		bpl.s	locret_12100
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_120D2
		neg.w	d1

loc_120D2:
		sub.w	d1,y_pos(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.s	loc_120EA
		clr.w	y_vel(a0)	; stop Sonic in y since he hit a ceiling
		rts
; ---------------------------------------------------------------------------

loc_120EA:
		move.b	d3,angle(a0)
		bsr.w	Player_TouchFloor_Check_Spindash
		move.w	y_vel(a0),ground_vel(a0)
		tst.b	d3
		bpl.s	locret_12100
		neg.w	ground_vel(a0)

locret_12100:
		rts
; ---------------------------------------------------------------------------

loc_12102:
		bsr.w	CheckRightWallDist
		tst.w	d1
		bpl.s	loc_1211A
		add.w	d1,x_pos(a0)
		clr.w	x_vel(a0)
		move.w	y_vel(a0),ground_vel(a0)

loc_1211A:
		bsr.w	sub_11FEE
		tst.w	d1
		bpl.s	loc_1213C
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_1212A
		neg.w	d1

loc_1212A:
		sub.w	d1,y_pos(a0)
		tst.w	y_vel(a0)
		bpl.s	locret_1213A
		clr.w	y_vel(a0)

locret_1213A:
		rts
; ---------------------------------------------------------------------------

loc_1213C:
		tst.b	(WindTunnel_flag).w
		bne.s	loc_12148
		tst.w	y_vel(a0)
		bmi.s	locret_1213A

loc_12148:
		bsr.w	sub_11FD6
		tst.w	d1
		bpl.s	locret_1213A
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_12158
		neg.w	d1

loc_12158:
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		clr.w	y_vel(a0)
		move.w	x_vel(a0),ground_vel(a0)

; =============== S U B R O U T I N E =======================================

Player_TouchFloor_Check_Spindash:
		tst.b	spin_dash_flag(a0)
		bne.s	loc_121D8
		clr.b	anim(a0)	; id_Walk

Sonic_ResetOnFloor:
		cmpi.b	#1,character_id(a0)
		beq.w	Tails_TouchFloor
		cmpi.b	#2,character_id(a0)
		beq.w	Knux_TouchFloor

		move.b	y_radius(a0),d0
		move.b	default_y_radius(a0),y_radius(a0)
		move.b	default_x_radius(a0),x_radius(a0)
		btst	#Status_Roll,status(a0)
		beq.s	loc_121D8
		bclr	#Status_Roll,status(a0)
		clr.b	anim(a0)	; id_Walk
		sub.b	default_y_radius(a0),d0
		ext.w	d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_121C4
		neg.w	d0

loc_121C4:
		move.w	d0,-(sp)
		move.b	angle(a0),d0
		addi.b	#$40,d0
		bpl.s	loc_121D2
		neg.w	(sp)

loc_121D2:
		move.w	(sp)+,d0
		add.w	d0,y_pos(a0)

loc_121D8:
		bclr	#Status_InAir,status(a0)
		bclr	#Status_Push,status(a0)
		bclr	#Status_RollJump,status(a0)
		moveq	#0,d0
		move.b	d0,jumping(a0)
		move.b	d0,(Chain_bonus_counter).w
		move.b	d0,flip_angle(a0)
		move.b	d0,flip_type(a0)
		move.b	d0,flips_remaining(a0)
		move.b	d0,scroll_delay_counter(a0)
		move.b	d0,double_jump_flag(a0)		; clear
; checks bubble shield bouncing and Drop Dash
	;	tst.b	character_id(a0)		; are we Sonic?
	;	bne.s	+				; if not, branch
		tst.b	double_jump_property(a0)	; is reset_on_floor action flag set?
		bpl.s	+				; if not, branch
		move.b	double_jump_property(a0),d0
		clr.b	double_jump_property(a0)	; clear
		addq.b	#1,d0				; add 1 to copy
		beq.w	BubbleShield_Bounce	; if it was -1 (bubble shield bounce), branch
		bra.s	DropDash_LandProcess
+
		rts

; =============== S U B R O U T I N E =======================================
; https://sonicresearch.org/community/index.php?threads/how-the-drop-dash-works-in-mania.5185/
; TODO: Optimize and make more accurate
DropDash_LandProcess:
		movem.l	d1-d2,-(sp)
		move.w	#$800,d0	; Set normal speed $800
		move.w	#$C00,d1	; Set speed cap
;		tst.b	(Super_flag).w	; are we Super/Hyper?
;		beq.s	+		; If not, branch
;		move.w	#$0C00,d0	; Set super speed
;		move.w	#$0D00,d1	; Set super cap
+
; check x_vel. If moving opposite of your facing direction, branch
		move.w	x_vel(a0),d2
		beq.s	++
		btst	#Status_Facing,status(a0)	; are we facing left?
		beq.s	+		; if not, branch
		neg.w	d2		; reverse if facing left
+
		tst.w	d2
		bmi.s	.slopecheck	; if moving backwards, branch
+
		mvabs.w	ground_vel(a0),d2
		asr.w	#2,d2		; divide ground_vel by 4 (>>2)
		bra.s	.captofinal
.slopecheck:
		tst.b	angle(a0)	; is there an angle on the floor?
		beq.s	.capwithoutadd	; if not, just set speed to d0
; half reversed ground_vel
		move.w	ground_vel(a0),d2
		beq.s	.capwithoutadd
		bmi.s	+		; if so, branch
		neg.w	d2		; reverse if facing right
+
		asl.w	#1,d2		; half velocity
.captofinal:
		add.w	d2,d0		; add to speed
.capwithoutadd:
		cmp.w	d0,d1		; compare new d0 to d1
		bls.s	.finalspeed	; if d0 is the same or lower, branch
		move.w	d1,d0		; cap speed
;		bra.s	.finalspeed
.finalspeed:
		btst	#Status_Underwater,status(a0)	; are we underwater?
		beq.s	+				; if not, branch
		asr.w	#1,d0				; half value
+
		btst	#Status_Facing,status(a0)	; are we facing left?
		beq.s	+				; if not, branch
		neg.w	d0				; reverse if facing left
+
		move.w	d0,x_vel(a0)
		move.w	d0,ground_vel(a0)
		movem.l	(sp)+,d1-d2
; since landing resets rolling by default, we gotta work around that
		move.b	#id_Roll,anim(a0)		; Rolling anim
		bset	#Status_Roll,status(a0)		; Rolling
		move.w	#bytes_to_word(28/2,14/2),y_radius(a0)	; set y and x radius
		move.b	y_radius(a0),d0
		sub.b	default_y_radius(a0),d0
		ext.w	d0
	if ReverseGravity=1
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		neg.w	d0
+
	endif
		sub.w	d0,y_pos(a0)
		btst	#Status_Underwater,status(a0)	; are we underwater?
		bne.s	+				; if so, branch
	;	move.b	#4,(v_Dust+anim).w		; drop dash dust
		move.b	#16,(H_scroll_frame_offset).w	; set delay to scroll movement
		move.b	(Pos_table_byte).w,(H_scroll_frame_copy).w
+
		sfx	sfx_Dash,1

; =============== S U B R O U T I N E =======================================

BubbleShield_Bounce:
		movem.l	d1-d2,-(sp)
		move.w	#$780,d2
		btst	#Status_Underwater,status(a0)
		beq.s	+
		move.w	#$400,d2
+		moveq	#0,d1
		move.b	angle(a0),d1
		subi.b	#$40,d1
		jsr	(GetSineCosine.angd1).w
		muls.w	d2,d1
		asr.l	#8,d1
		add.w	d1,x_vel(a0)
		muls.w	d2,d0
		asr.l	#8,d0
		add.w	d0,y_vel(a0)
		movem.l	(sp)+,d1-d2
		bset	#Status_InAir,status(a0)
		bclr	#Status_Push,status(a0)
		move.b	#1,jumping(a0)
		clr.b	stick_to_convex(a0)
		move.w	#bytes_to_word(28/2,14/2),y_radius(a0)	; set y_radius and x_radius
		move.b	#id_Roll,anim(a0)
		bset	#Status_Roll,status(a0)
		move.b	y_radius(a0),d0
		sub.b	default_y_radius(a0),d0
		ext.w	d0
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		neg.w	d0
+		sub.w	d0,y_pos(a0)
		move.b	#2,(v_Shield+anim).w
		sfx	sfx_BubbleAttack,1
; ---------------------------------------------------------------------------
; similar to this tutorial: https://info.sonicretro.org/SCHG_How-to:Fix_Speed_Bugs_in_Sonic_2
; inputs:
; a0, a1 = Player
; a4, a2 = Max_speed
; overwrites a1 and a2, make sure to backup if needed!
Player_SetSpeed:
		lea	(a0),a1
		lea	(a4),a2
.regset
		moveq	#0,d0
		move.b	character_id(a1),d0
		lsl.w	#5,d0	; 
	;	lsl.w	#6,d0
		btst	#Status_Underwater,status(a1)
		beq.s	+
		addq.w	#.water-.normal,d0	; add underwater
+
		btst	#Status_SpeedShoes,status_secondary(a1)
		beq.s	+
		add.w	#.speed-.normal,d0	; add speed shoes
+
	;	tst.b	(Super).w
	;	beq.s	+
	;	add.w	#.super-.normal,d0	; add super
+
		lea	.data(pc,d0.w),a1
		move.l	(a1)+,(a2)+		; Max_speed-Max_speed    ; Set Max_speed and Acceleration
		move.l	(a1)+,(a2)+		; Deceleration-Max_speed ; Set Deceleration and Jump_height
		rts
; data size is x8, each thing that can effect speed makes it go up by another power of 2
.data:
; 0 = Sonic.
.normal
	dc.w	$700, $10, $80, $680
.water
	dc.w	$380,   8, $40, $380
.speed
	dc.w	$E00, $20, $80, $680
.speedwater
	dc.w	$700, $10, $40, $380
;.super
;	dc.w	0, 0, 0, 0
;.superwater
;	dc.w	0, 0, 0, 0
;.superspeed
;	dc.w	0, 0, 0, 0
;.superspeedwater
;	dc.w	0, 0, 0, 0
; 1 = Tails
	dc.w	$600,  $C, $80, $680
	dc.w	$300,   6, $40, $380
	dc.w	$C00, $18, $80, $680
	dc.w	$600,  $C, $40, $380
;	dc.w	0, 0, 0, 0
;	dc.w	0, 0, 0, 0
;	dc.w	0, 0, 0, 0
;	dc.w	0, 0, 0, 0
; 2 = Knuckles
	dc.w	$600,  $C, $80, $600
	dc.w	$300,   6, $40, $300
	dc.w	$C00, $18, $80, $600
	dc.w	$600,  $C, $40, $300
;	dc.w	0, 0, 0, $600
;	dc.w	0, 0, 0, $300
;	dc.w	0, 0, 0, $600
;	dc.w	0, 0, 0, $300
; ---------------------------------------------------------------------------

Sonic_Hurt:
	if GameDebug
		tst.b	(Debug_mode_flag).w
		beq.s	+
		btst	#button_B,(Ctrl_1_pressed).w
		beq.s	+
		move.w	#1,(Debug_placement_mode).w
		clr.b	(Ctrl_1_locked).w
		rts
; ---------------------------------------------------------------------------
+
	endif
		jsr	(MoveSprite2_TestGravity).w
		addi.w	#$30,y_vel(a0)
		btst	#Status_Underwater,status(a0)
		beq.s	loc_122F2
		subi.w	#$20,y_vel(a0)

loc_122F2:
		cmpi.w	#-$100,(Camera_min_Y_pos).w
		bne.s	loc_12302
		move.w	(Screen_Y_wrap_value).w,d0
		and.w	d0,y_pos(a0)

loc_12302:
		bsr.s	sub_12318
		bsr.w	Player_LevelBound
		bsr.w	Sonic_RecordPos
		bsr.w	sub_125E0
		jmp	(Draw_Sprite).w

; =============== S U B R O U T I N E =======================================

sub_12318:
		tst.b	(Disable_death_plane).w
		bne.s	loc_12344
		tst.b	(Reverse_gravity_flag).w
		bne.s	loc_12336
		move.w	(Camera_max_Y_pos).w,d0
		addi.w	#224,d0
		cmp.w	y_pos(a0),d0
		blt.s		loc_1238A
		bra.s	loc_12344
; ---------------------------------------------------------------------------

loc_12336:
		move.w	(Camera_min_Y_pos).w,d0
		cmp.w	y_pos(a0),d0
		blt.s		loc_12344
		bra.s	loc_1238A
; ---------------------------------------------------------------------------

loc_12344:
		movem.l	a4-a6,-(sp)
		bsr.w	Player_DoLevelCollision
		movem.l	(sp)+,a4-a6
		btst	#Status_InAir,status(a0)
		bne.s	locret_12388
		moveq	#0,d0
		move.w	d0,y_vel(a0)
		move.w	d0,x_vel(a0)
		move.w	d0,ground_vel(a0)
		move.b	d0,object_control(a0)
		clr.b	anim(a0)	; id_Walk
		move.w	#make_priority(2),priority(a0)
		move.b	#id_SonicControl,routine(a0)
		move.b	#2*60,invulnerability_timer(a0)
		clr.b	spin_dash_flag(a0)

locret_12388:
		rts
; ---------------------------------------------------------------------------

loc_1238A:
		jmp	Kill_Character(pc)

; =============== S U B R O U T I N E =======================================

Sonic_Death:
	if GameDebug
		tst.b	(Debug_mode_flag).w
		beq.s	+
		btst	#button_B,(Ctrl_1_pressed).w
		beq.s	+
		move.w	#1,(Debug_placement_mode).w
		clr.b	(Ctrl_1_locked).w
		rts
; ---------------------------------------------------------------------------
+
	endif
		bsr.s	sub_123C2
		jsr	(MoveSprite_TestGravity).w
		bsr.w	Sonic_RecordPos
		bsr.w	sub_125E0
		jmp	(Draw_Sprite).w

; =============== S U B R O U T I N E =======================================

sub_123C2:
		cmpa.w	#Player_1,a0
		bne.s	.sidekick
		st	(Scroll_lock).w

.sidekick
		move.w	(Camera_Y_pos).w,d0
		clr.b	spin_dash_flag(a0)
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_123FA
		subi.w	#$10,d0
		cmp.w	y_pos(a0),d0
		bge.s	loc_12410

locret_123F8:
		rts
; ---------------------------------------------------------------------------

loc_123FA:
		addi.w	#$100,d0
		cmp.w	y_pos(a0),d0
		bge.s	locret_123F8

loc_12410:
		cmpi.b	#1,character_id(a0)
		bne.s	loc_12432
		cmpi.w	#2,(Player_mode).w
		beq.s	loc_12432
		move.b	#2,routine(a0)
		bra.w	sub_13ECA
; ---------------------------------------------------------------------------

loc_12432:
		move.b	#id_SonicRestart,routine(a0)
		move.w	#1*60,restart_timer(a0)
		clr.b	(Respawn_table_keep).w
		addq.b	#1,(Update_HUD_life_count).w
		subq.b	#1,(Life_count).w
		bne.s	.test_timeover
		clr.b	(Time_over_flag).w
		moveq	#0,d0	; use Game Over frames
		bra.s	.gameover
.test_timeover
		tst.b	(Time_over_flag).w
		beq.s	locret_1258E
		moveq	#2,d0	; use Time Over frames
.gameover
		clr.w	restart_timer(a0)	; don't restart with player object (use Game Over instead)
		lea	(v_GameOver_Game).w,a1
		lea	v_GameOver_Over-v_GameOver_Game(a1),a2
		move.l	#Obj_GameOver,address(a1)
		move.l	#Obj_GameOver,address(a2)
		move.b	#ren_screenpos|objflag_continue,render_flags(a1)
		move.b	#ren_screenpos|objflag_continue,render_flags(a2)
		move.b	d0,mapping_frame(a1)
		addq.w	#1,d0
		move.b	d0,mapping_frame(a2)
		clr.b	(Update_HUD_timer).w
		music	mus_GameOver								; play the Game Over song
		lea	(ArtKosM_GameOver).l,a1
		move.w	#tiles_to_bytes(ArtTile_Shield),d2
		jmp	(Queue_Kos_Module).w

; =============== S U B R O U T I N E =======================================

Sonic_Restart:
		tst.w	restart_timer(a0)
		beq.s	locret_1258E
		subq.w	#1,restart_timer(a0)
		bne.s	locret_1258E
		st	(Restart_level_flag).w

locret_1258E:
		rts

; =============== S U B R O U T I N E =======================================

loc_12590:
		tst.w	(H_scroll_amount).w
		bne.s	+
		tst.w	(V_scroll_amount).w
		bne.s	+
		move.b	#id_SonicControl,routine(a0)
+		bsr.s	sub_125E0
		jmp	(Draw_Sprite).w

; =============== S U B R O U T I N E =======================================

Sonic_Drown:
	if GameDebug
		tst.b	(Debug_mode_flag).w
		beq.s	+
		btst	#button_B,(Ctrl_1_pressed).w
		beq.s	+
		move.w	#1,(Debug_placement_mode).w
		clr.b	(Ctrl_1_locked).w
		rts
; ---------------------------------------------------------------------------
+
	endif
		jsr	(MoveSprite2_TestGravity).w
		addi.w	#$10,y_vel(a0)
		bsr.w	Sonic_RecordPos
		bsr.s	sub_125E0
		jmp	(Draw_Sprite).w

; =============== S U B R O U T I N E =======================================

sub_125E0:
		bsr.s	Animate_Sonic
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		eori.b	#2,render_flags(a0)
+		bra.w	Sonic_Load_PLC

; =============== S U B R O U T I N E =======================================

Animate_Sonic:
		lea	(AniSonic).l,a1
		moveq	#0,d0
		move.b	anim(a0),d0
		cmp.b	prev_anim(a0),d0
		beq.s	SAnim_Do
		move.b	d0,prev_anim(a0)
		clr.b	anim_frame(a0)
		clr.b	anim_frame_timer(a0)
		bclr	#Status_Push,status(a0)

SAnim_Do:
		add.w	d0,d0
		adda.w	(a1,d0.w),a1
		move.b	(a1),d0
		bmi.s	SAnim_WalkRun
		move.b	status(a0),d1
		andi.b	#1,d1
		andi.b	#-4,render_flags(a0)
		or.b	d1,render_flags(a0)
		subq.b	#1,anim_frame_timer(a0)
		bpl.s	SAnim_Delay
		move.b	d0,anim_frame_timer(a0)

SAnim_Do2:
		moveq	#0,d1
		move.b	anim_frame(a0),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#-4,d0
		bcc.s	SAnim_End_FF

SAnim_Next:
		move.b	d0,mapping_frame(a0)
		addq.b	#1,anim_frame(a0)

SAnim_Delay:
		rts
; ---------------------------------------------------------------------------

SAnim_End_FF:
		addq.b	#1,d0
		bne.s	SAnim_End_FE
		clr.b	anim_frame(a0)
		move.b	1(a1),d0
		bra.s	SAnim_Next
; ---------------------------------------------------------------------------

SAnim_End_FE:
		addq.b	#1,d0
		bne.s	SAnim_End_FD
		move.b	2(a1,d1.w),d0
		sub.b	d0,anim_frame(a0)
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0
		bra.s	SAnim_Next
; ---------------------------------------------------------------------------

SAnim_End_FD:
		addq.b	#1,d0
		bne.s	SAnim_End
		move.b	2(a1,d1.w),anim(a0)

SAnim_End:
		rts
; ---------------------------------------------------------------------------

SAnim_WalkRun:
		addq.b	#1,d0
		bne.w	loc_12A2A
		moveq	#0,d0
		tst.b	flip_type(a0)
		bmi.w	loc_127C0
		move.b	flip_angle(a0),d0
		bne.w	loc_127C0
		moveq	#0,d1
		move.b	angle(a0),d0
		bmi.s	loc_126C8
		beq.s	loc_126C8
		subq.b	#1,d0

loc_126C8:
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_126D4
		not.b	d0

loc_126D4:
		addi.b	#$10,d0
		bpl.s	loc_126DC
		moveq	#3,d1

loc_126DC:
		andi.b	#-4,render_flags(a0)
		eor.b	d1,d2
		or.b	d2,render_flags(a0)
		btst	#Status_Push,status(a0)
		bne.w	SAnim_Push
		lsr.b	#4,d0
		andi.b	#6,d0
		move.w	ground_vel(a0),d2
		bpl.s	loc_12700
		neg.w	d2

loc_12700:
		add.w	(HScroll_Shift).w,d2
		tst.b	status_secondary(a0)
		bpl.w	loc_1270A
		add.w	d2,d2

loc_1270A:
		lea	(SonAni_Run).l,a1 	; use running	animation
		cmpi.w	#$600,d2
		bcc.s	loc_12724
		lea	(SonAni_Walk).l,a1 	; use walking animation
		add.b	d0,d0

loc_12724:
		add.b	d0,d0
		move.b	d0,d3
		moveq	#0,d1
		move.b	anim_frame(a0),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#-1,d0
		bne.s	loc_12742
		clr.b	anim_frame(a0)
		move.b	1(a1),d0

loc_12742:
		move.b	d0,mapping_frame(a0)
		add.b	d3,mapping_frame(a0)
		subq.b	#1,anim_frame_timer(a0)
		bpl.s	locret_12764
		neg.w	d2
		addi.w	#$800,d2
		bpl.s	loc_1275A
		moveq	#0,d2

loc_1275A:
		lsr.w	#8,d2
		move.b	d2,anim_frame_timer(a0)
		addq.b	#1,anim_frame(a0)

locret_12764:
		rts
; ---------------------------------------------------------------------------

loc_127C0:
		move.b	flip_type(a0),d1
		andi.w	#$7F,d1
		bne.s	loc_12872
		move.b	flip_angle(a0),d0
		moveq	#0,d1
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_1281E
		andi.b	#-4,render_flags(a0)
		tst.b	flip_type(a0)
		bpl.s	loc_12806
		ori.b	#2,render_flags(a0)
		neg.b	d0
		addi.b	#$8F,d0
		bra.s	loc_1280A
; ---------------------------------------------------------------------------

loc_12806:
		addi.b	#$B,d0

loc_1280A:
		divu.w	#$16,d0
		addi.b	#$31,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

loc_1281E:
		andi.b	#-4,render_flags(a0)
		ori.b	#3,render_flags(a0)
		neg.b	d0
		addi.b	#$8F,d0
		divu.w	#$16,d0
		addi.b	#$31,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

byte_1286E:
		dc.b 0
		dc.b $3D
		dc.b $49
		dc.b $49
; ---------------------------------------------------------------------------

loc_12872:
		move.b	byte_1286E(pc,d1.w),d3
		cmpi.b	#1,d1
		bne.s	loc_128CA
		move.b	flip_angle(a0),d0
		moveq	#0,d1
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_128A8
		andi.b	#-4,render_flags(a0)
		addi.b	#-8,d0
		divu.w	#$16,d0
		add.b	d3,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

loc_128A8:
		andi.b	#-4,render_flags(a0)
		ori.b	#1,render_flags(a0)
		addi.b	#-8,d0
		divu.w	#$16,d0
		add.b	d3,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

loc_128CA:
		cmpi.b	#2,d1
		bne.s	loc_12920
		move.b	flip_angle(a0),d0
		moveq	#0,d1
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_128FC
		andi.b	#-4,render_flags(a0)
		addi.b	#$B,d0
		divu.w	#$16,d0
		add.b	d3,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

loc_128FC:
		andi.b	#-4,render_flags(a0)
		ori.b	#3,render_flags(a0)
		neg.b	d0
		addi.b	#$8F,d0
		divu.w	#$16,d0
		add.b	d3,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

loc_12920:
		cmpi.b	#3,d1
		bne.s	loc_1297C
		move.b	flip_angle(a0),d0
		moveq	#0,d1
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_1295A
		andi.b	#-4,render_flags(a0)
		ori.b	#2,render_flags(a0)
		neg.b	d0
		addi.b	#$8F,d0
		divu.w	#$16,d0
		add.b	d3,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

loc_1295A:
		andi.b	#-4,render_flags(a0)
		ori.b	#1,render_flags(a0)
		addi.b	#$B,d0
		divu.w	#$16,d0
		add.b	d3,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

loc_1297C:
		cmpi.b	#4,d1
		bne.s	loc_129F6
		move.b	flip_angle(a0),d0
		moveq	#0,d1
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_129BC
		andi.b	#-4,render_flags(a0)
		tst.b	flip_type(a0)
		bpl.s	loc_129A4
		addi.b	#$B,d0
		bra.s	loc_129A8
; ---------------------------------------------------------------------------

loc_129A4:
		addi.b	#$B,d0

loc_129A8:
		divu.w	#$16,d0
		addi.b	#$31,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

loc_129BC:
		andi.b	#-4,render_flags(a0)
		tst.b	flip_type(a0)
		bpl.s	loc_129D6
		ori.b	#3,render_flags(a0)
		neg.b	d0
		addi.b	#$8F,d0
		bra.s	loc_129E2
; ---------------------------------------------------------------------------

loc_129D6:
		ori.b	#3,render_flags(a0)
		neg.b	d0
		addi.b	#$8F,d0

loc_129E2:
		divu.w	#$16,d0
		addi.b	#$31,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

loc_129F6:
		move.b	flip_angle(a0),d0
		andi.b	#-4,render_flags(a0)
		moveq	#0,d1
		move.b	status(a0),d2
		andi.b	#1,d2
		beq.s	loc_12A12
		ori.b	#1,render_flags(a0)

loc_12A12:
		addi.b	#$B,d0
		divu.w	#$16,d0
		addi.b	#$31,d0
		move.b	d0,mapping_frame(a0)
		clr.b	anim_frame_timer(a0)
		rts
; ---------------------------------------------------------------------------

loc_12A2A:
		move.b	status(a0),d1
		andi.b	#1,d1
		andi.b	#-4,render_flags(a0)
		or.b	d1,render_flags(a0)
		subq.b	#1,anim_frame_timer(a0)
		bpl.w	SAnim_Delay
		mvabs.w	ground_vel(a0),d2	;
		add.w	(HScroll_Shift).w,d2
		lea	(SonAni_Roll2).l,a1
		cmpi.w	#$600,d2
		bcc.s	loc_12A5E
		lea	(SonAni_Roll).l,a1

loc_12A5E:
		neg.w	d2
		addi.w	#$400,d2
		bpl.s	loc_12A68
		moveq	#0,d2

loc_12A68:
		lsr.w	#8,d2
		move.b	d2,anim_frame_timer(a0)
		bra.w	SAnim_Do2
; ---------------------------------------------------------------------------

SAnim_Push:
		subq.b	#1,anim_frame_timer(a0)
		bpl.w	SAnim_Delay
		move.w	ground_vel(a0),d2	; TODO: Create the opposite of mvabs
		bmi.s	+
		neg.w	d2
+
		addi.w	#$800,d2
		bpl.s	loc_12A8A
		moveq	#0,d2

loc_12A8A:
		lsr.w	#6,d2
		move.b	d2,anim_frame_timer(a0)
		lea	(SonAni_Push).l,a1
		bra.w	SAnim_Do2

; =============== S U B R O U T I N E =======================================

Sonic_Load_PLC:
		lea	(a0),a1
		moveq	#0,d0
		move.b	mapping_frame(a0),d0

Sonic_Load_PLC2:
		cmp.b	mapping_frame_copy(a1),d0
		beq.s	.return
		move.b	d0,mapping_frame_copy(a1)
		lea	(DPLC_Sonic).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d5
		subq.w	#1,d5
		bmi.s	.return
		move.w	#tiles_to_bytes(ArtTile_Player_1),d4
		move.l	#dmaSource(ArtUnc_Sonic),d6
		cmpi.w	#$DA*2,d0
		blo.s	.loop
		move.l	#dmaSource(ArtUnc_Sonic_Extra),d6

.loop
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
		dbf	d5,.loop

.return
		rts

; =============== S U B R O U T I N E =======================================
; input
; a1 = player address
Perform_Player_DPLC:
		move.b	character_id(a1),d1
		beq.s	Sonic_Load_PLC2		; 0 = Sonic
		subq.b	#1,d1			; 1 = Tails
		beq.w	Tails_Load_PLC2
		bra.w	Knuckles_Load_PLC2	; 2+ = Knuckles

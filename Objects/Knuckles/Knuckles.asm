
; =============== S U B R O U T I N E =======================================

Obj_Knuckles:
		movea.w	playadd_addr(a0),a4
		lea	screen_distance(a4),a5
		lea	(v_Dust).w,a6

		tst.w	(Debug_placement_mode).w
		beq.s	Knuckles_Normal
		cmpi.b	#1,(Debug_placement_type).w
		beq.s	loc_16488
		btst	#4,(Ctrl_1_pressed).w
		beq.s	loc_1646C
		move.w	#0,(Debug_placement_mode).w

loc_1646C:
		addq.b	#1,mapping_frame(a0)
		cmpi.b	#$FB,mapping_frame(a0)
		blo.s		loc_1647E
		move.b	#0,mapping_frame(a0)

loc_1647E:
		bsr.w	Knuckles_Load_PLC
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

loc_16488:
		jmp	(DebugMode).l
; ---------------------------------------------------------------------------

Knuckles_Normal:
		moveq	#0,d0
		move.b	routine(a0),d0
		move.w	Knuckles_Index(pc,d0.w),d0
		jmp	Knuckles_Index(pc,d0.w)
; ---------------------------------------------------------------------------

Knuckles_Index: offsetTable
	offsetTableEntry.w Knuckles_Init,id_SonicInit
	offsetTableEntry.w Knuckles_Control,id_SonicControl
	offsetTableEntry.w Knuckles_Hurt,id_SonicHurt
	offsetTableEntry.w Knuckles_Death,id_SonicDeath
	offsetTableEntry.w Knuckles_Restart,id_SonicRestart
	offsetTableEntry.w loc_17CCE
	offsetTableEntry.w Knuckles_Drown,id_SonicDrown
; ---------------------------------------------------------------------------

Knuckles_Init:
		addq.b	#2,routine(a0)
		move.b	#2,character_id(a0)
		move.w	#bytes_to_word(ren_camerapos,objflag_continue),render_flags(a0)
		move.w	#bytes_to_word($18,$18),height_pixels(a0)
		move.w	#make_priority(2),priority(a0)
		move.l	#Map_Knuckles,mappings(a0)
		bsr.w	Player_SetSpeed
		bsr.w	Player_SetRadius
		move.w	y_radius(a0),default_y_radius(a0)	; set default_y_radius and default_x_radius
		tst.b	(Last_star_post_hit).w
		bne.s	Knuckles_Init_Continued

		; only happens when not starting at a checkpoint:
		move.w	#make_art_tile(ArtTile_Player_1,0,0),art_tile(a0)
		move.w	#bytes_to_word($C,$D),top_solid_bit(a0)

		; only happens when not starting at a Special Stage ring:
		move.w	x_pos(a0),(Saved_X_pos).w
		move.w	y_pos(a0),(Saved_Y_pos).w
		move.w	art_tile(a0),(Saved_art_tile).w
		move.w	top_solid_bit(a0),(Saved_solid_bits).w

Knuckles_Init_Continued:
		move.b	#0,flips_remaining(a0)
		move.b	#4,flip_speed(a0)
		move.b	#$1E,air_left(a0)
		subi.w	#$20,x_pos(a0)
		addi.w	#4,y_pos(a0)
		jsr	(Reset_Player_Position_Array).l
		addi.w	#$20,x_pos(a0)
		subi.w	#4,y_pos(a0)
		loadnullplayerobj
		move.w	#Pos_table,pos_table(a4)
		rts
; ---------------------------------------------------------------------------

Knuckles_Control:
		tst.b	(Debug_mode_flag).w
		beq.s	loc_165A2
		bclr	#6,(Ctrl_1_pressed).w
		beq.s	loc_16580
		eori.b	#1,(Reverse_gravity_flag).w

loc_16580:
		btst	#4,(Ctrl_1_pressed).w
		beq.s	loc_165A2
		move.w	#1,(Debug_placement_mode).w
		clr.b	(Ctrl_1_locked).w
		btst	#5,(Ctrl_1).w
		beq.s	locret_165A0
		move.w	#2,(Debug_placement_mode).w

locret_165A0:
		rts
; ---------------------------------------------------------------------------

loc_165A2:
		tst.b	(Ctrl_1_locked).w
		bne.s	+
		move.l	(Ctrl1).w,playctrl(a4)		; copy new buttons, to enable joypad control
+		btst	#0,object_control(a0)
		beq.s	loc_165BE
		move.b	#0,double_jump_flag(a0)
		bra.s	loc_165D8
; ---------------------------------------------------------------------------

loc_165BE:
		movem.l	a4-a6,-(sp)
		moveq	#0,d0
		move.b	status(a0),d0
		andi.w	#(1<<Status_InAir|1<<Status_Roll),d0
		move.w	Knux_Modes(pc,d0.w),d1
		jsr	Knux_Modes(pc,d1.w)
		movem.l	(sp)+,a4-a6

loc_165D8:
		cmpi.w	#-$100,(Camera_min_Y_pos).w
		bne.s	loc_165E8
		move.w	(Screen_Y_wrap_value).w,d0
		and.w	d0,y_pos(a0)

loc_165E8:
		bsr.w	Knuckles_Display
		bsr.w	Sonic_RecordPos
		bsr.w	Knuckles_Water
		move.b	(Primary_Angle).w,next_tilt(a0)
		move.b	(Secondary_Angle).w,tilt(a0)
		tst.b	(WindTunnel_flag).w
		beq.s	loc_16614
		tst.b	anim(a0)
		bne.s	loc_16614
		move.b	$21(a0),anim(a0)

loc_16614:
		btst	#1,object_control(a0)
		bne.s	loc_16630
		bsr.w	Animate_Knuckles
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_1662C
		eori.b	#2,render_flags(a0)

loc_1662C:
		bsr.w	Knuckles_Load_PLC

loc_16630:
		move.b	object_control(a0),d0
		andi.b	#-$60,d0
		bne.s	locret_16640
		jsr	(TouchResponse).l

locret_16640:
		rts
; ---------------------------------------------------------------------------
Knux_Modes: offsetTable
	offsetTableEntry.w Knux_Stand_Path,(0<<Status_InAir|0<<Status_Roll)
	offsetTableEntry.w Knux_Stand_Freespace,(1<<Status_InAir|0<<Status_Roll)
	offsetTableEntry.w Knux_Spin_Path,(0<<Status_InAir|1<<Status_Roll)
	offsetTableEntry.w Knux_Spin_Freespace,(1<<Status_InAir|1<<Status_Roll)

; =============== S U B R O U T I N E =======================================


Knuckles_Display = Player_Display
Knuckles_Water = Player_Water

; =============== S U B R O U T I N E =======================================

Knux_Stand_Path:
		bsr.w	SonicKnux_Spindash
		bsr.w	Knux_Jump
		bsr.w	Player_SlopeResist
		bsr.w	Knux_InputAcceleration_Path
		bsr.w	SonicKnux_Roll
		bsr.w	Player_LevelBound
		jsr	(MoveSprite2_TestGravity).w
		bsr.w	Call_Player_AnglePos
		bra.w	Player_SlopeRepel
; ---------------------------------------------------------------------------

Knux_Stand_Freespace:
		tst.b	double_jump_flag(a0)
		bne.s	Knux_Glide_Freespace
	if RollInAir
		bsr.w	Sonic_ChgFallAnim
	endif
		bsr.w	Knux_JumpHeight
		bsr.w	Knux_ChgJumpDir
		bsr.w	Player_LevelBound
		jsr	(MoveSprite_TestGravity).w
		btst	#Status_Underwater,status(a0)
		beq.s	loc_16872
		subi.w	#$28,y_vel(a0)

loc_16872:
		bsr.w	Player_JumpAngle
		bra.w	Player_DoLevelCollision
; ---------------------------------------------------------------------------

Knux_Glide_Freespace:
		bsr.w	Knuckles_Move_Glide
		bsr.w	Player_LevelBound
		jsr	(MoveSprite2_TestGravity).w
		bsr.w	Knuckles_Glide

locret_1688E:
		rts

; =============== S U B R O U T I N E =======================================

Knuckles_Glide:
		move.b	double_jump_flag(a0),d0
		beq.s	locret_1688E
		cmpi.b	#2,d0
		beq.w	Knuckles_Fall_From_Glide
		cmpi.b	#3,d0
		beq.w	Knuckles_Sliding
		cmpi.b	#4,d0
		beq.w	Knuckles_Wall_Climb
		cmpi.b	#5,d0
		beq.w	Knuckles_Climb_Ledge

		; This function updates 'Gliding_collision_flags'.
		move.l	a4,-(sp)
		bsr.w	Knux_DoLevelCollision_CheckRet
		move.l	(sp)+,a4

		btst	#Status_InAir,(Gliding_collision_flags).w
		beq.s	Knux_Gliding_HitFloor

		btst	#Status_Push,(Gliding_collision_flags).w
		bne.w	Knuckles_Gliding_HitWall

		move.w	playctrl_hd(a4),d0
		andi.w	#btnABC,d0
		bne.s	.continueGliding

		; The player has let go of the jump button, so exit the gliding state
		; and enter the falling state.
		move.b	#2,double_jump_flag(a0)
		move.b	#$21,anim(a0)
		bclr	#Status_Facing,status(a0)
		tst.w	x_vel(a0)
		bpl.s	.skip1
		bset	#Status_Facing,status(a0)

.skip1:
		; Divide Knuckles' X velocity by 4.
		asr.w	x_vel(a0)
		asr.w	x_vel(a0)

		move.w	default_y_radius(a0),y_radius(a0)
		rts
; ---------------------------------------------------------------------------
; loc_1690A:
.continueGliding:
		bra.w	Knuckles_Set_Gliding_Animation
; ---------------------------------------------------------------------------

Knux_Gliding_HitFloor:
		bclr	#Status_Facing,status(a0)
		tst.w	x_vel(a0)
		bpl.s	+
		bset	#Status_Facing,status(a0)
+
		move.b	angle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.s	loc_1693E

		move.w	ground_vel(a0),x_vel(a0)
		move.w	#0,y_vel(a0)

		bra.w	Knux_TouchFloor.ignoreroll
; ---------------------------------------------------------------------------

loc_1693E:
		move.b	#3,double_jump_flag(a0)
		move.b	#$CC,mapping_frame(a0)
		move.b	#$7F,anim_frame_timer(a0)
		move.b	#0,anim_frame(a0)

		; The drowning countdown uses the dust clouds' VRAM, so don't create
		; dust if Knuckles is drowning.
		cmpi.b	#12,air_left(a0)
		blo.s	+
		; Create dust clouds.
		move.b	#6,routine(a6)
		move.b	#$15,mapping_frame(a6)
+
		rts
; ---------------------------------------------------------------------------

Knuckles_Gliding_HitWall:
		tst.b	(Disable_wall_grab).w
		bmi.w	.fail

		move.b	lrb_solid_bit(a0),d5
		move.b	double_jump_property(a0),d0
		addi.b	#$40,d0
		bpl.s	.right

;.left:
		bset	#Status_Facing,status(a0)

		bsr.w	CheckLeftCeilingDist
		or.w	d0,d1
		bne.s	.checkFloorLeft

		addq.w	#1,x_pos(a0)
		bra.s	.success

.right:
		bclr	#Status_Facing,status(a0)

		bsr.w	CheckRightCeilingDist
		or.w	d0,d1
		bne.w	.checkFloorRight
; loc_169A6:
.success:
		move.w	#0,ground_vel(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.b	#4,double_jump_flag(a0)
		move.b	#$B7,mapping_frame(a0)
		move.b	#$7F,anim_frame_timer(a0)
		move.b	#0,anim_frame(a0)
		move.b	#3,double_jump_property(a0)
		; 'x_pos+2' holds the X coordinate that Knuckles was at when he first
		; latched onto the wall.
		move.w	x_pos(a0),x_pos+2(a0)
		sfx	sfx_Grab,1
; ---------------------------------------------------------------------------
; loc_16A00:
.checkFloorLeft:
		; This adds the Y radius to the X coordinate...
		; This appears to be a bug, but, luckily, the X and Y radius are both
		; 10, so this is harmless.
		move.w	x_pos(a0),d3
		move.b	x_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		subq.w	#1,d3

		tst.b	(Reverse_gravity_flag).w
		bne.s	.reverseGravity
; loc_16A14:
.checkFloorCommon:
		move.w	y_pos(a0),d2
		subi.w	#11,d2
		jsr	(ChkFloorEdge_Part3).l

		tst.w	d1
		bmi.s	.fail
		cmpi.w	#12,d1
		bhs.s	.fail
		add.w	d1,y_pos(a0)
		bra.w	.success
; ---------------------------------------------------------------------------
; loc_16A34:
.reverseGravity:
		move.w	y_pos(a0),d2
		addi.w	#11,d2
		eori.w	#$F,d2
		jsr	(ChkFloorEdge_ReverseGravity_Part2).l

		tst.w	d1
		bmi.s	.fail
		cmpi.w	#12,d1
		bhs.s	.fail
		sub.w	d1,y_pos(a0)
		bra.w	.success
; ---------------------------------------------------------------------------
; loc_16A58:
.checkFloorRight:
		; This adds the Y radius to the X coordinate...
		; This appears to be a bug, but, luckily, the X and Y radius are both
		; 10, so this is harmless.
		move.w	x_pos(a0),d3
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		addq.w	#1,d3

		tst.b	(Reverse_gravity_flag).w
		bne.s	Knuckles_Gliding_HitWall.reverseGravity

		bra.s	.checkFloorCommon
; ---------------------------------------------------------------------------
; loc_16A6E:
.fail:
		move.b	#2,double_jump_flag(a0)
		move.b	#$21,anim(a0)
		move.w	default_y_radius(a0),y_radius(a0)
		bset	#Status_InAir,(Gliding_collision_flags).w
		rts
; ---------------------------------------------------------------------------

Knuckles_Fall_From_Glide:
		bsr.w	Knux_ChgJumpDir

		; Apply gravity.
		addi.w	#$38,y_vel(a0)

		; Fall slower when underwater.
		btst	#Status_Underwater,status(a0)
		beq.s	.skip1
		subi.w	#$28,y_vel(a0)

.skip1:
		; This function updates 'Gliding_collision_flags'.
		move.l	a4,-(sp)
		bsr.w	Knux_DoLevelCollision_CheckRet
		move.l	(sp)+,a4

		btst	#Status_InAir,(Gliding_collision_flags).w
		bne.s	.return

		; Knuckles has touched the ground.
		move.w	#0,ground_vel(a0)
		move.l	#0,x_vel(a0)

		sfx	sfx_GlideLand
		move.b	angle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.s	.skip3
		bra.w	Knux_TouchFloor.ignoreroll
.skip3:
		bsr.w	Knux_TouchFloor.ignoreroll
		move.w	#$F,move_lock(a0)
		move.b	#$23,anim(a0)
; locret_16B04:
.return:
		rts
; ---------------------------------------------------------------------------

Knuckles_Sliding:
		move.w	playctrl_hd(a4),d0
		andi.w	#btnABC,d0
		beq.s	.getUp

		tst.w	x_vel(a0)
		bpl.s	.goingRight

;.goingLeft:
		addi.w	#$20,x_vel(a0)
		bmi.s	.continueSliding2

		bra.s	.getUp
; ---------------------------------------------------------------------------
; loc_16B20:
.continueSliding2:
		bra.s	.continueSliding
; ---------------------------------------------------------------------------
; loc_16B22:
.goingRight:
		subi.w	#$20,x_vel(a0)
		bpl.s	.continueSliding
; loc_16B2A:
.getUp:
		moveq	#0,d0
		move.l	d0,x_vel(a0)
		move.w	d0,ground_vel(a0)
		bsr.w	Knux_TouchFloor.ignoreroll
		move.w	#$F,move_lock(a0)
		move.b	#$22,anim(a0)		; getting up
		rts
; ---------------------------------------------------------------------------
; loc_16B64:
.continueSliding:
		move.l	a4,-(sp)
		bsr.w	Knux_DoLevelCollision_CheckRet

		; Get distance from floor in 'd1', and angle of floor in 'd3'.
		bsr.w	sub_11FD6
		move.l	(sp)+,a4

		; If the distance from the floor is suddenly really high, then
		; Knuckles must have slid off a ledge, so make him enter his falling
		; state.
		cmpi.w	#14,d1
		bge.s	.fail

		tst.b	(Reverse_gravity_flag).w
		beq.s	.skip2
		neg.w	d1

.skip2:
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)

		; Play the sliding sound every 8 frames.
		move.b	(Level_frame_counter+1).w,d0
		andi.b	#7,d0
		bne.s	.skip3
		sfx	sfx_GroundSlide,2

.skip3:
		rts
; ---------------------------------------------------------------------------
; loc_16B96:
.fail:
		move.b	#2,double_jump_flag(a0)
		move.b	#$21,anim(a0)

		move.w	default_y_radius(a0),y_radius(a0)

		bset	#Status_InAir,(Gliding_collision_flags).w
		rts
; ---------------------------------------------------------------------------

Knuckles_Wall_Climb:
		tst.b	(Disable_wall_grab).w
		bmi.w	Knuckles_LetGoOfWall

		; If Knuckles' X coordinate is no longer the same as when he first
		; latched onto the wall, then detach him from the wall. This is
		; probably intended to detach Knuckles from the wall if something
		; physically pushes him away from it.
		move.w	x_pos(a0),d0
		cmp.w	x_pos+2(a0),d0
		bne.w	Knuckles_LetGoOfWall

		; If an object is now carrying Knuckles, then detach him from the
		; wall.
		btst	#Status_OnObj,status(a0)
		bne.w	Knuckles_LetGoOfWall

		move.w	#0,ground_vel(a0)
		move.l	#0,x_vel(a0)

		SetCollAddrPlane_lrb_macro

		move.b	lrb_solid_bit(a0),d5

		moveq	#0,d1	; Climbing animation delta: make the animation pause.

		btst	#button_up,playctrl_hd_abc(a4)
		beq.w	.notClimbingUp

;.climbingUp:
		tst.b	(Reverse_gravity_flag).w
		bne.w	.climbingUp_ReverseGravity

		; Get Knuckles' distance from the wall in 'd1'.
		move.w	y_pos(a0),d2
		subi.w	#11,d2
		move.l	a4,-(sp)
		bsr.w	GetDistanceFromWall
		move.l	(sp)+,a4

		; If the wall is far away from Knuckles, then we must have reached a
		; ledge, so make Knuckles climb up onto it.
		cmpi.w	#4,d1
		bge.w	Knuckles_ClimbUp

		; If Knuckles has encountered a small dip in the wall, then make him
		; stop.
		tst.w	d1
		bne.w	.notMoving

		; Get Knuckles' distance from the ceiling in 'd1'.
		move.b	lrb_solid_bit(a0),d5
		move.w	y_pos(a0),d2
		subq.w	#8,d2
		move.w	x_pos(a0),d3
		move.l	a4,-(sp)
		bsr.w	CheckCeilingDist_WithRadius
		move.l	(sp)+,a4

		; Check if Knuckles has room above him.
		tst.w	d1
		bpl.s	.moveUp

		; Knuckles is bumping into the ceiling, so push him out.
		sub.w	d1,y_pos(a0)

		moveq	#1,d1	; Climbing animation delta: make the animation play forwards.
		bra.w	.finishMoving
; ---------------------------------------------------------------------------
; loc_16C4C:
.moveUp:
		subq.w	#1,y_pos(a0)

		moveq	#1,d1	; Climbing animation delta: make the animation play forwards.

		; Don't let Knuckles climb through the level's upper boundary.
		move.w	(Camera_min_Y_pos).w,d0

		; If the level wraps vertically, then don't bother with any of this.
		cmpi.w	#-$100,d0
		beq.w	.finishMoving

		; Check if Knuckles is over the level's top boundary.
		addi.w	#16,d0
		cmp.w	y_pos(a0),d0
		ble.w	.finishMoving

		; Knuckles is climbing over the level's top boundary: push him back
		; down.
		move.w	d0,y_pos(a0)
		bra.w	.finishMoving
; ---------------------------------------------------------------------------
; loc_16C7C:
.climbingDown_ReverseGravity:
		; Knuckles is climbing down.

		; ...I'm not sure what this code is for.
		cmpi.b	#$BD,mapping_frame(a0)
		bne.s	.skip3
		move.b	#$B7,mapping_frame(a0)
		subq.w	#3,y_pos(a0)
		subq.w	#3,x_pos(a0)
		btst	#Status_Facing,status(a0)
		beq.s	.skip3
		addq.w	#3*2,x_pos(a0)

.skip3:
		; Get Knuckles' distance from the wall in 'd1'.
		move.w	y_pos(a0),d2
		subi.w	#11,d2
		move.l	a4,-(sp)
		bsr.w	GetDistanceFromWall
		move.l	(sp)+,a4

		; If Knuckles is no longer against the wall (he has climbed off the
		; bottom of it) then make him let go.
		tst.w	d1
		bne.w	Knuckles_LetGoOfWall

		; Get Knuckles' distance from the floor in 'd1'.
		move.b	top_solid_bit(a0),d5
		move.w	y_pos(a0),d2
		subi.w	#9,d2
		move.w	x_pos(a0),d3
		move.l	a4,-(sp)
		bsr.w	CheckCeilingDist_WithRadius
		move.l	(sp)+,a4

		; Check if Knuckles has room below him.
		tst.w	d1
		bpl.s	.moveDown_ReverseGravity

		; Knuckles has reached the floor.
		sub.w	d1,y_pos(a0)
		move.b	(Primary_Angle).w,d0
		addi.b	#$40,d0
		neg.b	d0
		subi.b	#$40,d0
		move.b	d0,angle(a0)

		move.w	#0,ground_vel(a0)
		move.l	#0,x_vel(a0)

		bsr.w	Knux_TouchFloor.ignoreroll

		move.b	#5,anim(a0)

		rts
; ---------------------------------------------------------------------------
; loc_16CFC:
.moveDown_ReverseGravity:
		subq.w	#1,y_pos(a0)

		moveq	#-1,d1	; Climbing animation delta: make the animation play backwards.
		bra.w	.finishMoving
; ---------------------------------------------------------------------------
; loc_16D10:
.notClimbingUp:
		btst	#button_down,playctrl_hd_abc(a4)
		beq.w	.finishMoving

;.climbingDown:
		tst.b	(Reverse_gravity_flag).w
		bne.w	.climbingDown_ReverseGravity

		; ...I'm not sure what this code is for.
		cmpi.b	#$BD,mapping_frame(a0)
		bne.s	.skip4
		move.b	#$B7,mapping_frame(a0)
		addq.w	#3,y_pos(a0)
		subq.w	#3,x_pos(a0)
		btst	#Status_Facing,status(a0)
		beq.s	.skip4
		addq.w	#3*2,x_pos(a0)

.skip4:
		; Get Knuckles' distance from the wall in 'd1'.
		move.w	y_pos(a0),d2
		addi.w	#11,d2
		move.l	a4,-(sp)
		bsr.w	GetDistanceFromWall
		move.l	(sp)+,a4

		; If Knuckles is no longer against the wall (he has climbed off the
		; bottom of it) then make him let go.
		tst.w	d1
		bne.w	Knuckles_LetGoOfWall

		; Get Knuckles' distance from the floor in 'd1'.
		move.b	top_solid_bit(a0),d5
		move.w	y_pos(a0),d2
		addi.w	#9,d2
		move.w	x_pos(a0),d3
		move.l	a4,-(sp)
		bsr.w	sub_F828
		move.l	(sp)+,a4

		; Check if Knuckles has room below him.
		tst.w	d1
		bpl.s	.moveDown
; loc_16D6E:
.reachedFloor:
		; Knuckles has reached the floor.
		add.w	d1,y_pos(a0)
		move.b	(Primary_Angle).w,angle(a0)

		move.w	#0,ground_vel(a0)
		move.l	#0,x_vel(a0)

		bsr.w	Knux_TouchFloor.ignoreroll

		move.b	#5,anim(a0)

		rts
; ---------------------------------------------------------------------------
; loc_16D96:
.moveDown:
		addq.w	#1,y_pos(a0)

		moveq	#-1,d1	; Climbing animation delta: make the animation play backwards.
		bra.s	.finishMoving
; ---------------------------------------------------------------------------
; loc_16DA8:
.climbingUp_ReverseGravity:
		; Get Knuckles' distance from the wall in 'd1'.
		move.w	y_pos(a0),d2
		addi.w	#11,d2
		move.l	a4,-(sp)
		bsr.w	GetDistanceFromWall
		move.l	(sp)+,a4

		; If the wall is far away from Knuckles, then we must have reached a
		; ledge, so make Knuckles climb up onto it.
		cmpi.w	#4,d1
		bge.w	Knuckles_ClimbUp

		; If Knuckles has encountered a small dip in the wall, then make him
		; stop.
		tst.w	d1
		bne.w	.notMoving

		; Get Knuckles' distance from the ceiling in 'd1'.
		move.b	lrb_solid_bit(a0),d5
		move.w	y_pos(a0),d2
		addq.w	#8,d2
		move.w	x_pos(a0),d3
		move.l	a4,-(sp)
		bsr.w	sub_F828
		move.l	(sp)+,a4

		; Check if Knuckles has room above him.
		tst.w	d1
		bpl.s	.moveUp_ReverseGravity

		; Knuckles is bumping into the ceiling, so push him out.
		add.w	d1,y_pos(a0)

		moveq	#1,d1	; Climbing animation delta: make the animation play forwards.
		bra.s	.finishMoving
; ---------------------------------------------------------------------------
; loc_16DE2:
.moveUp_ReverseGravity:
		addq.w	#1,y_pos(a0)

		moveq	#1,d1	; Climbing animation delta: make the animation play forwards.

		; Don't let Knuckles climb through the level's upper boundary.

		; If the level wraps vertically, then don't bother with any of this.
		cmpi.w	#-$100,(Camera_min_Y_pos).w
		beq.s	.finishMoving

		; Check if Knuckles is over the level's top boundary.
		move.w	(Camera_max_Y_pos).w,d0
		addi.w	#$D0,d0
		cmp.w	y_pos(a0),d0
		bge.s	.finishMoving

		; Knuckles is climbing over the level's top boundary: push him back
		; down.
		move.w	d0,y_pos(a0)
; loc_16E10:
.finishMoving:
		; If Knuckles has not moved, skip this.
		tst.w	d1
		beq.s	.notMoving

		; Only animate every 4 frames.
		subq.b	#1,double_jump_property(a0)
		bpl.s	.notMoving
		move.b	#3,double_jump_property(a0)

	; Add delta to animation frame.
		add.b	mapping_frame(a0),d1

	; Make the animation loop.
		cmpi.b	#$B7,d1
		bhs.s	+
		moveq	#signextendB($BC),d1
+		cmpi.b	#$BC,d1
		bls.s	+
		moveq	#signextendB($B7),d1
+		move.b	d1,mapping_frame(a0)		; Apply the frame.
; loc_16E60:
.notMoving:
		move.b	#$20,anim_frame_timer(a0)
		move.b	#0,anim_frame(a0)

		move.w	playctrl_pr(a4),d0
		andi.w	#btnABC,d0
		beq.s	.hasNotJumped

		; Knuckles has jumped off the wall.
		move.w	#-$380,y_vel(a0)
		move.w	#$400,x_vel(a0)
		bchg	#Status_Facing,status(a0)
		bne.s	+
		neg.w	x_vel(a0)
+		bset	#Status_InAir,status(a0)
		bset	#Status_Roll,status(a0)
		move.b	#2,anim(a0)
		move.b	#1,jumping(a0)
		move.b	#0,double_jump_flag(a0)
		bra.w	Player_SetRadius
; locret_16EB8:
.hasNotJumped:
-		rts
; ---------------------------------------------------------------------------
; loc_16EBA:
Knuckles_ClimbUp:
		move.b	#5,double_jump_flag(a0)
		cmpi.b	#$BD,mapping_frame(a0)
		beq.s	-
		move.b	#0,double_jump_property(a0)
		bra.s	Knuckles_DoLedgeClimbingAnimation
; ---------------------------------------------------------------------------
; loc_16ED2:
Knuckles_LetGoOfWall:
		move.b	#2,double_jump_flag(a0)
		move.w	#$2121,anim(a0)
		move.b	#$CB,mapping_frame(a0)
		move.b	#7,anim_frame_timer(a0)
		move.b	#1,anim_frame(a0)
		move.w	default_y_radius(a0),y_radius(a0)
		rts

; =============== S U B R O U T I N E =======================================

; sub_16EFE:
Knuckles_DoLedgeClimbingAnimation:
		moveq	#0,d0
		move.b	double_jump_property(a0),d0
		lea	Knuckles_ClimbLedge_Frames(pc,d0.w),a1

		move.b	(a1)+,mapping_frame(a0)

		move.b	(a1)+,d0
		btst	#Status_Facing,status(a0)
		beq.s	+
		neg.b	d0
+		ext.w	d0
		add.w	d0,x_pos(a0)

		move.b	(a1)+,d1
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		neg.b	d1
+		ext.w	d1
		add.w	d1,y_pos(a0)

		move.b	(a1)+,anim_frame_timer(a0)

		addq.b	#4,double_jump_property(a0)
		move.b	#0,anim_frame(a0)
		rts
; ---------------------------------------------------------------------------
; Strangely, the last frame uses frame $D2. It will never be seen, however,
; because it is immediately overwritten by Knuckles' waiting animation.

Knuckles_ClimbLedge_Frames:
	; mapping_frame, x_pos, y_pos, anim_frame_timer
	dc.b  $BD,    3,   -3,    6
	dc.b  $BE,    8,  -10,    6
	dc.b  $BF,   -8,  -12,    6
	dc.b  $D2,    8,   -5,    6
Knuckles_ClimbLedge_Frames_End:

; =============== S U B R O U T I N E =======================================

; sub_16F4E:
GetDistanceFromWall:
		move.b	lrb_solid_bit(a0),d5
		btst	#Status_Facing,status(a0)
		bne.s	.facingLeft

;.facingRight:
		move.w	x_pos(a0),d3
		bra.w	loc_FAA4
; ---------------------------------------------------------------------------
; loc_16F62:
.facingLeft:
		move.w	x_pos(a0),d3
		subq.w	#1,d3
		bra.w	loc_FDC8
; ---------------------------------------------------------------------------

Knuckles_Climb_Ledge:
		tst.b	anim_frame_timer(a0)
		bne.s	locret_16FA6

		bsr.w	Knuckles_DoLedgeClimbingAnimation

		; Have we reached the end of the ledge-climbing animation?
		cmpi.b	#Knuckles_ClimbLedge_Frames_End-Knuckles_ClimbLedge_Frames,double_jump_property(a0)
		bne.s	locret_16FA6

		; Yes.
		move.w	#0,ground_vel(a0)
		move.l	#0,x_vel(a0)

		btst	#Status_Facing,status(a0)
		beq.s	+
		subq.w	#1,x_pos(a0)
+		fixplayerposition a0,jump	; either I fixed a bug or created one, but now without this the player is raised into the air a little when they climb up
		bsr.w	Knux_TouchFloor	; we just need the angle from Knux_TouchFloor
		move.b	#5,anim(a0)

locret_16FA6:
		rts

; =============== S U B R O U T I N E =======================================

Knuckles_Set_Gliding_Animation:
		move.b	#$20,anim_frame_timer(a0)
		move.b	#0,anim_frame(a0)
		move.w	#$2020,anim(a0)
		bclr	#Status_Push,status(a0)
		bclr	#Status_Facing,status(a0)

		; Update Knuckles' frame, depending on where he's facing.
		moveq	#0,d0
		move.b	double_jump_property(a0),d0
		addi.b	#$10,d0
		lsr.w	#5,d0
		move.b	RawAni_Knuckles_GlideTurn(pc,d0.w),d1
		move.b	d1,mapping_frame(a0)
		cmpi.b	#$C4,d1
		bne.s	+
		bset	#Status_Facing,status(a0)
		move.b	#$C0,mapping_frame(a0)
+		rts
; ---------------------------------------------------------------------------

RawAni_Knuckles_GlideTurn:
		dc.b $C0
		dc.b $C1
		dc.b $C2
		dc.b $C3
		dc.b $C4
		dc.b $C3
		dc.b $C2
		dc.b $C1

; =============== S U B R O U T I N E =======================================

Knuckles_Move_Glide:
		cmpi.b	#1,double_jump_flag(a0)
		bne.w	.doNotKillspeed

		move.w	ground_vel(a0),d0
		cmpi.w	#$400,d0
		bhs.s	.mediumSpeed

;.lowSpeed:
		; Increase Knuckles' speed.
		addq.w	#8,d0
		bra.s	.applySpeed
; ---------------------------------------------------------------------------
; loc_1700E:
.mediumSpeed:
		; If Knuckles is at his speed limit, then don't increase his speed.
		cmpi.w	#$1800,d0
		bhs.s	.applySpeed

		; If Knuckles is turning, then don't increase his speed either.
		move.b	double_jump_property(a0),d1
		andi.b	#$7F,d1
		bne.s	.applySpeed

		; Increase Knuckles' speed.
		addq.w	#4,d0

; loc_17028:
.applySpeed:
		move.w	d0,ground_vel(a0)

		move.b	double_jump_property(a0),d0
		btst	#button_left,playctrl_hd_abc(a4)
		beq.s	.notHoldingLeft

;.holdingLeft:
		; Playing is holding left.
		cmpi.b	#$80,d0
		beq.s	.notHoldingLeft
		tst.b	d0
		bpl.s	.doNotNegate1
		neg.b	d0

.doNotNegate1:
		addq.b	#2,d0
		bra.s	.setNewTurningValue
; ---------------------------------------------------------------------------
; loc_17048:
.notHoldingLeft:
		btst	#button_right,playctrl_hd_abc(a4)
		beq.s	.notHoldingRight

;.holdingRight:
		; Playing is holding right.
		tst.b	d0
		beq.s	.notHoldingRight
		bmi.s	.doNotNegate2
		neg.b	d0

.doNotNegate2:
		addq.b	#2,d0
		bra.s	.setNewTurningValue
; ---------------------------------------------------------------------------
; loc_1705C:
.notHoldingRight:
		move.b	d0,d1
		andi.b	#$7F,d1
		beq.s	.setNewTurningValue
		addq.b	#2,d0
; loc_17066:
.setNewTurningValue:
		move.b	d0,double_jump_property(a0)

	;	move.b	double_jump_property(a0),d0	; ???
		moveq	#0,d1
	calcsine_macro a1,cosined1,unsafe	; get cosine
		muls.w	ground_vel(a0),d1
		asr.l	#8,d1
		move.w	d1,x_vel(a0)

		; Is Knuckles is falling at a high speed, then create a parachute
		; effect, where gliding makes Knuckles fall slower.
		cmpi.w	#$80,y_vel(a0)
		blt.s	.fallingSlow
		subi.w	#$20,y_vel(a0)
		bra.s	.fallingFast
; ---------------------------------------------------------------------------
; loc_1708E:
.fallingSlow:
		; Apply gravity.
		addi.w	#$20,y_vel(a0)
; loc_17094:
.fallingFast:
		; If Knuckles is above the level's top boundary, then kill his
		; horizontal speed.
		move.w	(Camera_min_Y_pos).w,d0
		cmpi.w	#-$100,d0
		beq.w	.doNotKillspeed

		addi.w	#$10,d0
		cmp.w	y_pos(a0),d0
		ble.w	.doNotKillspeed

		asr.w	x_vel(a0)
		asr.w	ground_vel(a0)
; loc_170B4:
.doNotKillspeed:
	resetlookcamerapos (a5)
		rts
; ---------------------------------------------------------------------------

Knux_Spin_Path:
		tst.b	spin_dash_flag(a0)
		bne.s	loc_170CC
		bsr.w	Knux_Jump

loc_170CC:
		bsr.w	Player_RollRepel
		bsr.w	Knux_RollSpeed
		bsr.w	Player_LevelBound
		jsr	(MoveSprite2_TestGravity).w
		bsr.w	Call_Player_AnglePos
		bra.w	Player_SlopeRepel
; ---------------------------------------------------------------------------

Knux_Spin_Freespace:
		bsr.w	Knux_JumpHeight
		bsr.w	Knux_ChgJumpDir
		bsr.w	Player_LevelBound
		jsr	(MoveSprite_TestGravity).w
		btst	#Status_Underwater,status(a0)
		beq.s	loc_17138
		subi.w	#$28,y_vel(a0)

loc_17138:
		bsr.w	Player_JumpAngle
		bra.w	Player_DoLevelCollision

; =============== S U B R O U T I N E =======================================

Knux_InputAcceleration_Path:
		move.w	max_speed(a4),d6
		move.w	acceleration(a4),d5
		move.w	deceleration(a4),d4
		tst.b	status_secondary(a0)
		bmi.w	loc_17364
		tst.w	move_lock(a0)
		bne.w	loc_1731C
		btst	#button_left,playctrl_hd_abc(a4)
		beq.s	loc_17168
		btst	#button_right,playctrl_hd_abc(a4)
		bne.s	loc_17174
		bsr.w	sub_17428

loc_17168:
		btst	#button_right,playctrl_hd_abc(a4)
		beq.s	loc_17174
		bsr.w	sub_174B4

loc_17174:
		move.b	angle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.w	loc_1731C
		tst.w	ground_vel(a0)
		bne.w	loc_1731C
		bclr	#Status_Push,status(a0)
		move.b	#5,anim(a0)
		btst	#Status_OnObj,status(a0)
		beq.w	loc_1722C
		movea.w	interact(a0),a1
		tst.b	status(a1)
		bmi.w	loc_172A8
		moveq	#0,d1
		move.b	width_pixels(a1),d1
		move.w	d1,d2
		add.w	d2,d2
		subq.w	#2,d2
		add.w	x_pos(a0),d1
		sub.w	x_pos(a1),d1
		cmpi.w	#2,d1
		blt.s	loc_171FE
		cmp.w	d2,d1
		bge.s	loc_171D0
		bra.w	loc_172A8
; ---------------------------------------------------------------------------

loc_171D0:
		btst	#Status_Facing,status(a0)
		bne.s	loc_171E2
		move.b	#6,anim(a0)
		bra.w	loc_1731C
; ---------------------------------------------------------------------------

loc_171E2:
		bclr	#Status_Facing,status(a0)
		move.b	#0,anim_frame_timer(a0)
		move.b	#4,anim_frame(a0)
		move.w	#$606,anim(a0)
		bra.w	loc_1731C
; ---------------------------------------------------------------------------

loc_171FE:
		btst	#Status_Facing,status(a0)
		beq.s	loc_17210
		move.b	#6,anim(a0)
		bra.w	loc_1731C
; ---------------------------------------------------------------------------

loc_17210:
		bset	#Status_Facing,status(a0)
		move.b	#0,anim_frame_timer(a0)
		move.b	#4,anim_frame(a0)
		move.w	#$606,anim(a0)
		bra.w	loc_1731C
; ---------------------------------------------------------------------------

loc_1722C:
		move.w	x_pos(a0),d3
		move.l	a4,-(sp)	; save a4 (ChooseChkFloorEdge uses it)
		bsr.w	ChooseChkFloorEdge
		move.l	(sp)+,a4
		cmpi.w	#$C,d1
		blt.w	loc_172A8
		cmpi.b	#3,next_tilt(a0)
		bne.s	loc_17272
		btst	#Status_Facing,status(a0)
		bne.s	loc_17256
		move.b	#6,anim(a0)
		bra.w	loc_1731C
; ---------------------------------------------------------------------------

loc_17256:
		bclr	#Status_Facing,status(a0)
		move.b	#0,anim_frame_timer(a0)
		move.b	#4,anim_frame(a0)
		move.w	#$606,anim(a0)
		bra.w	loc_1731C
; ---------------------------------------------------------------------------

loc_17272:
		cmpi.b	#3,tilt(a0)
		bne.s	loc_172A8
		btst	#Status_Facing,status(a0)
		beq.s	loc_1728C
		move.b	#6,anim(a0)
		bra.w	loc_1731C
; ---------------------------------------------------------------------------

loc_1728C:
		bset	#Status_Facing,status(a0)
		move.b	#0,anim_frame_timer(a0)
		move.b	#4,anim_frame(a0)
		move.w	#$606,anim(a0)
		bra.w	loc_1731C
; ---------------------------------------------------------------------------

loc_172A8:
		btst	#button_down,playctrl_hd_abc(a4)
		beq.s	loc_172E2
		move.b	#8,anim(a0)
		addq.b	#1,scroll_delay_counter(a0)
		cmpi.b	#$78,scroll_delay_counter(a0)
		blo.s	loc_17322
		move.b	#$78,scroll_delay_counter(a0)
		tst.b	(Reverse_gravity_flag).w
		bne.s	+
		cmpi.w	#8,(a5)
		beq.s	loc_1732E
		subq.w	#2,(a5)
		bra.s	loc_1732E
+
		cmpi.w	#$D8,(a5)
		beq.s	loc_1732E
		addq.w	#2,(a5)
		bra.s	loc_1732E
; ---------------------------------------------------------------------------

loc_172E2:
		btst	#button_up,playctrl_hd_abc(a4)
		beq.s	loc_1731C
		move.b	#7,anim(a0)
		addq.b	#1,scroll_delay_counter(a0)
		cmpi.b	#$78,scroll_delay_counter(a0)
		blo.s	loc_17322
		move.b	#$78,scroll_delay_counter(a0)
		tst.b	(Reverse_gravity_flag).w
		bne.s	+
		cmpi.w	#$C8,(a5)
		beq.s	loc_1732E
		addq.w	#2,(a5)
		bra.s	loc_1732E
+
		cmpi.w	#$18,(a5)
		beq.s	loc_1732E
		subq.w	#2,(a5)
		bra.s	loc_1732E
; ---------------------------------------------------------------------------

loc_1731C:
		move.b	#0,scroll_delay_counter(a0)

loc_17322:
	resetlookcamerapos (a5)

loc_1732E:
		move.w	playctrl_hd(a4),d0
		andi.w	#btnLR,d0
		bne.s	loc_17364
		move.w	ground_vel(a0),d0
		beq.s	loc_17364
		bmi.s	loc_17358
		sub.w	d5,d0
		bcc.s	loc_17352
		move.w	#0,d0

loc_17352:
		move.w	d0,ground_vel(a0)
		bra.s	loc_17364
; ---------------------------------------------------------------------------

loc_17358:
		add.w	d5,d0
		bcc.s	loc_17360
		move.w	#0,d0

loc_17360:
		move.w	d0,ground_vel(a0)

loc_17364:
		move.b	angle(a0),d0
		jsr	(GetSineCosine).w
		muls.w	ground_vel(a0),d1
		asr.l	#8,d1
		move.w	d1,x_vel(a0)
		muls.w	ground_vel(a0),d0
		asr.l	#8,d0
		move.w	d0,y_vel(a0)

loc_17382:
		bra.w	loc_11350

; =============== S U B R O U T I N E =======================================

sub_17428:
		move.w	ground_vel(a0),d0
		beq.s	loc_17430
		bpl.s	loc_17462

loc_17430:
		bset	#Status_Facing,status(a0)
		bne.s	loc_17444
		bclr	#Status_Push,status(a0)
		move.b	#1,$21(a0)

loc_17444:
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_17456
		add.w	d5,d0
		cmp.w	d1,d0
		ble.s	loc_17456
		move.w	d1,d0

loc_17456:
		move.w	d0,ground_vel(a0)
		move.b	#0,anim(a0)
		rts
; ---------------------------------------------------------------------------

loc_17462:
		sub.w	d4,d0
		bcc.s	loc_1746A
		move.w	#-$80,d0

loc_1746A:
		move.w	d0,ground_vel(a0)
		move.b	angle(a0),d1
		addi.b	#$20,d1
		andi.b	#$C0,d1
		bne.s	locret_174B2
		cmpi.w	#$400,d0
		blt.s	locret_174B2
		tst.b	flip_type(a0)
		bmi.s	locret_174B2
		sfx	sfx_Skid
		move.b	#$D,anim(a0)
		bclr	#Status_Facing,status(a0)
		cmpi.b	#$C,air_left(a0)
		blo.s	locret_174B2
		move.b	#6,routine(a6)
		move.b	#$15,mapping_frame(a6)

locret_174B2:
		rts

; =============== S U B R O U T I N E =======================================

sub_174B4:
		move.w	ground_vel(a0),d0
		bmi.s	loc_174E8
		bclr	#Status_Facing,status(a0)
		beq.s	loc_174CE
		bclr	#Status_Push,status(a0)
		move.b	#1,$21(a0)

loc_174CE:
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_174DC
		sub.w	d5,d0
		cmp.w	d6,d0
		bge.s	loc_174DC
		move.w	d6,d0

loc_174DC:
		move.w	d0,ground_vel(a0)
		move.b	#0,anim(a0)
		rts
; ---------------------------------------------------------------------------

loc_174E8:
		add.w	d4,d0
		bcc.s	loc_174F0
		move.w	#$80,d0

loc_174F0:
		move.w	d0,ground_vel(a0)
		move.b	angle(a0),d1
		addi.b	#$20,d1
		andi.b	#$C0,d1
		bne.s	locret_17538
		cmpi.w	#-$400,d0
		bgt.s	locret_17538
		tst.b	flip_type(a0)
		bmi.s	locret_17538
		sfx	sfx_Skid
		move.b	#$D,anim(a0)
		bset	#Status_Facing,status(a0)
		cmpi.b	#$C,air_left(a0)
		blo.s	locret_17538
		move.b	#6,routine(a6)
		move.b	#$15,mapping_frame(a6)

locret_17538:
		rts

; =============== S U B R O U T I N E =======================================

Knux_RollSpeed = Sonic_RollSpeed
Knux_ChgJumpDir = Sonic_ChgJumpDir	; sub_17680:
Knux_Jump = Sonic_Jump


; =============== S U B R O U T I N E =======================================

Knux_JumpHeight:
		tst.b	jumping(a0)
		beq.s	loc_17818
		move.w	#-$400,d1
		btst	#Status_Underwater,status(a0)
		beq.s	loc_17800
		move.w	#-$200,d1

loc_17800:
		cmp.w	y_vel(a0),d1
		ble.w	Knux_Test_For_Glide
		move.b	playctrl_hd_abc(a4),d0
		andi.b	#btnABC,d0
		bne.s	+
		move.w	d1,y_vel(a0)
+		rts
; ---------------------------------------------------------------------------

loc_17818:
		tst.b	spin_dash_flag(a0)
		bne.s	+
		cmpi.w	#-$FC0,y_vel(a0)
		bge.s	+
		move.w	#-$FC0,y_vel(a0)
locret_178CC:
+		rts
; ---------------------------------------------------------------------------

Knux_Test_For_Glide:
		tst.b	double_jump_flag(a0)
		bne.s	locret_178CC
		move.w	playctrl_pr(a4),d0
		andi.w	#btnABC,d0
		beq.s	locret_178CC

		bclr	#Status_Roll,status(a0)
		move.w	#bytes_to_word($A,$A),y_radius(a0)
		bclr	#Status_RollJump,status(a0)
		move.b	#1,double_jump_flag(a0)
		addi.w	#$200,y_vel(a0)
		bpl.s	+
		move.w	#0,y_vel(a0)
+		move.w	#$400,d1
		move.w	#$800,d2
		btst	#Status_Underwater,status(a0)	; are you underwater?
		beq.s	+		; if not, branch
		move.w	#$280,d1
		move.w	#$580,d2
+		move.w	x_vel(a0),d0	; get absolute value of x_vel
		bpl.s	+
		neg.w	d0
+		cmp.w	d2,d0		; is it more then the cap?
		ble.s	+		; if not, branch
		move.w	d2,d0
		bra.s	++
+		cmp.w	d1,d0		; is it less then the cap?
		bhs.s	+		; if so, branch
		move.w	d1,d0
+		move.w	d0,ground_vel(a0)
		moveq	#0,d1
		btst	#Status_Facing,status(a0)	; are you facing left?
		beq.s	+		; if not, branch
		neg.w	d0
		moveq	#-$80,d1
+		move.w	d0,x_vel(a0)
		move.b	d1,double_jump_property(a0)
		move.w	#0,angle(a0)
		move.b	#0,(Gliding_collision_flags).w
		bset	#Status_InAir,(Gliding_collision_flags).w
		bra.w	Knuckles_Set_Gliding_Animation

; =============== S U B R O U T I N E =======================================

Knux_DoLevelCollision_CheckRet:
		SetCollAddrPlane_macro
		move.b	lrb_solid_bit(a0),d5
		move.w	x_vel(a0),d1
		move.w	y_vel(a0),d2
		jsr	(GetArcTan).w
		subi.b	#$20,d0
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	loc_179DA
		cmpi.b	#$80,d0
		beq.w	loc_17A62
		cmpi.b	#$C0,d0
		beq.w	loc_17AB0
		bsr.w	CheckLeftWallDist
		tst.w	d1
		bpl.s	loc_1799C
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#Status_Push,(Gliding_collision_flags).w

loc_1799C:
		bsr.w	CheckRightWallDist
		tst.w	d1
		bpl.s	loc_179B4
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#Status_Push,(Gliding_collision_flags).w

loc_179B4:
		move.l	a4,-(sp)
		bsr.w	sub_11FD6
		move.l	(sp)+,a4
		tst.w	d1
		bpl.s	locret_179D8
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_179C4
		neg.w	d1

loc_179C4:
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		move.w	#0,y_vel(a0)
		bclr	#Status_InAir,(Gliding_collision_flags).w

locret_179D8:
		rts
; ---------------------------------------------------------------------------

loc_179DA:
		bsr.w	CheckLeftWallDist
		tst.w	d1
		bpl.s	loc_179F2
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#Status_Push,(Gliding_collision_flags).w

loc_179F2:
		bsr.w	sub_11FEE
		tst.w	d1
		bpl.s	loc_17A36
		neg.w	d1
		cmpi.w	#$14,d1
		bhs.s	loc_17A1C
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_17A0A
		neg.w	d1

loc_17A0A:
		add.w	d1,y_pos(a0)
		tst.w	y_vel(a0)
		bpl.s	locret_17A1A
		move.w	#0,y_vel(a0)

locret_17A1A:
		rts
; ---------------------------------------------------------------------------

loc_17A1C:
		bsr.w	CheckRightWallDist
		tst.w	d1
		bpl.s	locret_17A34
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#Status_Push,(Gliding_collision_flags).w

locret_17A34:
		rts
; ---------------------------------------------------------------------------

loc_17A36:
		tst.w	y_vel(a0)
		bmi.s	locret_17A60
		move.l	a4,-(sp)
		bsr.w	sub_11FD6
		move.l	(sp)+,a4
		tst.w	d1
		bpl.s	locret_17A60
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_17A4C
		neg.w	d1

loc_17A4C:
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		move.w	#0,y_vel(a0)
		bclr	#Status_InAir,(Gliding_collision_flags).w

locret_17A60:
		rts
; ---------------------------------------------------------------------------

loc_17A62:
		bsr.w	CheckLeftWallDist
		tst.w	d1
		bpl.s	loc_17A7A
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#Status_Push,(Gliding_collision_flags).w

loc_17A7A:
		jsr	(CheckRightWallDist).l
		tst.w	d1
		bpl.s	loc_17A94
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#Status_Push,(Gliding_collision_flags).w

loc_17A94:
		bsr.w	sub_11FEE
		tst.w	d1
		bpl.s	locret_17AAE
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_17AA4
		neg.w	d1

loc_17AA4:
		sub.w	d1,y_pos(a0)
		move.w	#0,y_vel(a0)

locret_17AAE:
		rts
; ---------------------------------------------------------------------------

loc_17AB0:
		jsr	(CheckRightWallDist).l
		tst.w	d1
		bpl.s	loc_17ACA
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#Status_Push,(Gliding_collision_flags).w

loc_17ACA:
		bsr.w	sub_11FEE
		tst.w	d1
		bpl.s	loc_17AEC
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_17ADA
		neg.w	d1

loc_17ADA:
		sub.w	d1,y_pos(a0)
		tst.w	y_vel(a0)
		bpl.s	locret_17AEA
		move.w	#0,y_vel(a0)

locret_17AEA:
		rts
; ---------------------------------------------------------------------------

loc_17AEC:
		tst.w	y_vel(a0)
		bmi.s	locret_17B16
		move.l	a4,-(sp)
		bsr.w	sub_11FD6
		move.l	(sp)+,a4
		tst.w	d1
		bpl.s	locret_17B16
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_17B02
		neg.w	d1

loc_17B02:
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		move.w	#0,y_vel(a0)
		bclr	#Status_InAir,(Gliding_collision_flags).w

locret_17B16:
		rts

; =============== S U B R O U T I N E =======================================

Knux_TouchFloor:
		bclr	#Status_Roll,status(a0)
		beq.s	.alreadyclear
		clr.b	anim(a0)	; id_Walk
.ignoreroll
.alreadyclear
		move.w	d1,-(sp)
	fixplayerposition a0,land,1
		move.w	(sp)+,d1

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
		move.b	d0,double_jump_flag(a0)
		cmpi.b	#$20,anim(a0)
		blo.s	locret_17BB4
		move.b	d0,anim(a0)

locret_17BB4:
		rts
; ---------------------------------------------------------------------------

Knuckles_Hurt:
		tst.b	(Debug_mode_flag).w
		beq.s	loc_17BD0
		btst	#4,(Ctrl_1_pressed).w
		beq.s	loc_17BD0
		move.w	#1,(Debug_placement_mode).w
		clr.b	(Ctrl_1_locked).w
		rts
; ---------------------------------------------------------------------------

loc_17BD0:
		jsr	(MoveSprite2_TestGravity).w
		addi.w	#$30,y_vel(a0)
		btst	#Status_Underwater,status(a0)
		beq.s	loc_17BEA
		subi.w	#$20,y_vel(a0)

loc_17BEA:
		cmpi.w	#-$100,(Camera_min_Y_pos).w
		bne.s	loc_17BFA
		move.w	(Screen_Y_wrap_value).w,d0
		and.w	d0,y_pos(a0)

loc_17BFA:
		bsr.w	sub_17C10
		bsr.w	Player_LevelBound
		bsr.w	Sonic_RecordPos
		bsr.w	sub_17D1E
		jmp	(Draw_Sprite).w

; =============== S U B R O U T I N E =======================================

sub_17C10:
		tst.b	(Disable_death_plane).w
		bne.s	loc_17C3C
		tst.b	(Reverse_gravity_flag).w
		bne.s	loc_17C2E
		move.w	(Camera_max_Y_pos).w,d0
		addi.w	#$E0,d0
		cmp.w	y_pos(a0),d0
		blt.w	loc_17C82
		bra.s	loc_17C3C
; ---------------------------------------------------------------------------

loc_17C2E:
		move.w	(Camera_min_Y_pos).w,d0
		cmp.w	y_pos(a0),d0
		blt.s	loc_17C3C
		bra.w	loc_17C82
; ---------------------------------------------------------------------------

loc_17C3C:
		movem.l	a4-a6,-(sp)
		bsr.w	Player_DoLevelCollision
		movem.l	(sp)+,a4-a6
		btst	#Status_InAir,status(a0)
		bne.s	locret_17C80
		moveq	#0,d0
		move.w	d0,y_vel(a0)
		move.w	d0,x_vel(a0)
		move.w	d0,ground_vel(a0)
		move.b	d0,object_control(a0)
		move.b	#0,anim(a0)
		move.w	#make_priority(2),priority(a0)
		move.b	#2,routine(a0)
		move.b	#$78,$34(a0)
		move.b	#0,spin_dash_flag(a0)

locret_17C80:
		rts
; ---------------------------------------------------------------------------

loc_17C82:
		jmp	(Kill_Character).l
; ---------------------------------------------------------------------------

Knuckles_Death:
		tst.b	(Debug_mode_flag).w
		beq.s	loc_17CA2
		btst	#4,(Ctrl_1_pressed).w
		beq.s	loc_17CA2
		move.w	#1,(Debug_placement_mode).w
		clr.b	(Ctrl_1_locked).w
		rts
; ---------------------------------------------------------------------------

loc_17CA2:
		bsr.w	sub_123C2
		jsr	(MoveSprite_TestGravity).w
		bsr.w	Sonic_RecordPos
		bsr.w	sub_17D1E
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

Knuckles_Restart:
		tst.w	restart_timer(a0)
		beq.s	locret_17CCC
		subq.w	#1,restart_timer(a0)
		bne.s	locret_17CCC
		st	(Restart_level_flag).w

locret_17CCC:
		rts
; ---------------------------------------------------------------------------

loc_17CCE:
		tst.w	(Camera_RAM).w
		bne.s	loc_17CE0
		tst.w	(V_scroll_amount).w
		bne.s	loc_17CE0
		move.b	#2,routine(a0)

loc_17CE0:
		bsr.w	sub_17D1E
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

Knuckles_Drown:
		tst.b	(Debug_mode_flag).w
		beq.s	loc_17D04
		btst	#4,(Ctrl_1_pressed).w
		beq.s	loc_17D04
		move.w	#1,(Debug_placement_mode).w
		clr.b	(Ctrl_1_locked).w
		rts
; ---------------------------------------------------------------------------

loc_17D04:
		jsr	(MoveSprite2_TestGravity).w
		addi.w	#$10,y_vel(a0)
		bsr.w	Sonic_RecordPos
		bsr.w	sub_17D1E
		jmp	(Draw_Sprite).w

; =============== S U B R O U T I N E =======================================

sub_17D1E:
		bsr.s	Animate_Knuckles
		tst.b	(Reverse_gravity_flag).w
		beq.s	loc_17D2C
		eori.b	#2,render_flags(a0)

loc_17D2C:
		bra.w	Knuckles_Load_PLC

; =============== S U B R O U T I N E =======================================

Animate_Knuckles:
		lea	(AniKnuckles).l,a1
		moveq	#0,d0
		move.b	anim(a0),d0
		cmp.b	$21(a0),d0
		beq.s	loc_17D58
		move.b	d0,$21(a0)
		move.b	#0,anim_frame(a0)
		move.b	#0,anim_frame_timer(a0)
		bclr	#Status_Push,status(a0)

loc_17D58:
		add.w	d0,d0
		adda.w	(a1,d0.w),a1
		move.b	(a1),d0
		bmi.s	loc_17DC8
		move.b	status(a0),d1
		andi.b	#1,d1
		andi.b	#-4,render_flags(a0)
		or.b	d1,render_flags(a0)
		subq.b	#1,anim_frame_timer(a0)
		bpl.s	locret_17D96
		move.b	d0,anim_frame_timer(a0)

loc_17D7E:
		moveq	#0,d1
		move.b	anim_frame(a0),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#-4,d0
		bhs.s	loc_17D98

loc_17D8E:
		move.b	d0,mapping_frame(a0)
		addq.b	#1,anim_frame(a0)

locret_17D96:
		rts
; ---------------------------------------------------------------------------

loc_17D98:
		addq.b	#1,d0
		bne.s	loc_17DA8
		move.b	#0,anim_frame(a0)
		move.b	1(a1),d0
		bra.s	loc_17D8E
; ---------------------------------------------------------------------------

loc_17DA8:
		addq.b	#1,d0
		bne.s	loc_17DBC
		move.b	2(a1,d1.w),d0
		sub.b	d0,anim_frame(a0)
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0
		bra.s	loc_17D8E
; ---------------------------------------------------------------------------

loc_17DBC:
		addq.b	#1,d0
		bne.s	locret_17DC6
		move.b	2(a1,d1.w),anim(a0)

locret_17DC6:
		rts
; ---------------------------------------------------------------------------

loc_17DC8:
		addq.b	#1,d0
		bne.w	loc_17E84
		moveq	#0,d0
		tst.b	flip_type(a0)
		bmi.w	loc_127C0
		move.b	$27(a0),d0
		bne.w	loc_127C0
		moveq	#0,d1
		move.b	angle(a0),d0
		bmi.s	loc_17DEC
		beq.s	loc_17DEC
		subq.b	#1,d0

loc_17DEC:
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_17DF8
		not.b	d0

loc_17DF8:
		addi.b	#$10,d0
		bpl.s	loc_17E00
		moveq	#3,d1

loc_17E00:
		andi.b	#-4,render_flags(a0)
		eor.b	d1,d2
		or.b	d2,render_flags(a0)
		btst	#Status_Push,status(a0)
		bne.w	loc_17ECC
		lsr.b	#4,d0
		andi.b	#6,d0
		move.w	ground_vel(a0),d2
		bpl.s	loc_17E24
		neg.w	d2

loc_17E24:
		tst.b	$2B(a0)
		bpl.w	loc_17E2E
		add.w	d2,d2

loc_17E2E:
		lea	(byte_17F48).l,a1
		cmpi.w	#$600,d2
		bhs.s	loc_17E42
		lea	(byte_17F3E).l,a1
		add.b	d0,d0

loc_17E42:
		add.b	d0,d0
		move.b	d0,d3
		moveq	#0,d1
		move.b	anim_frame(a0),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#-1,d0
		bne.s	loc_17E60
		move.b	#0,anim_frame(a0)
		move.b	1(a1),d0

loc_17E60:
		add.b	d3,d0
		move.b	d0,mapping_frame(a0)
		subq.b	#1,anim_frame_timer(a0)
		bpl.s	locret_17E82
		neg.w	d2
		addi.w	#$800,d2
		bpl.s	loc_17E78
		moveq	#0,d2

loc_17E78:
		lsr.w	#8,d2
		move.b	d2,anim_frame_timer(a0)
		addq.b	#1,anim_frame(a0)

locret_17E82:
		rts
; ---------------------------------------------------------------------------

loc_17E84:
		move.b	status(a0),d1
		andi.b	#1,d1
		andi.b	#-4,render_flags(a0)
		or.b	d1,render_flags(a0)
		subq.b	#1,anim_frame_timer(a0)
		bpl.w	locret_17D96
		move.w	ground_vel(a0),d2
		bpl.s	loc_17EA6
		neg.w	d2

loc_17EA6:
		lea	(byte_17F5C).l,a1
		cmpi.w	#$600,d2
		bhs.s	loc_17EB8
		lea	(byte_17F52).l,a1

loc_17EB8:
		neg.w	d2
		addi.w	#$400,d2
		bpl.s	loc_17EC2
		moveq	#0,d2

loc_17EC2:
		lsr.w	#8,d2
		move.b	d2,anim_frame_timer(a0)
		bra.w	loc_17D7E
; ---------------------------------------------------------------------------

loc_17ECC:
		subq.b	#1,anim_frame_timer(a0)
		bpl.w	locret_17D96
		move.w	ground_vel(a0),d2
		bmi.s	loc_17EDC
		neg.w	d2

loc_17EDC:
		addi.w	#$800,d2
		bpl.s	loc_17EE4
		moveq	#0,d2

loc_17EE4:
		lsr.w	#8,d2
		move.b	d2,anim_frame_timer(a0)
		lea	(byte_17F66).l,a1
		bra.w	loc_17D7E

; =============== S U B R O U T I N E =======================================

Knuckles_Load_PLC:
		lea	(a0),a1
		moveq	#0,d0
		move.b	mapping_frame(a0),d0

Knuckles_Load_PLC2:
		cmp.b	mapping_frame_copy(a1),d0
		beq.s	locret_18162
		move.b	d0,mapping_frame_copy(a1)
		move.w	#tiles_to_bytes(ArtTile_Player_1),d4	; placed here because PLC3
;loc_18122:
Knuckles_Load_PLC3:
		lea	(DPLC_Knuckles).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d5
		subq.w	#1,d5
		bmi.s	locret_18162
		move.l	#dmaSource(ArtUnc_Knux),d6

loc_1813A:
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
		dbf	d5,loc_1813A

locret_18162:
		rts

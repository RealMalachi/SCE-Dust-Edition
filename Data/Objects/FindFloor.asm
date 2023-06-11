
SetCollAddrPlane_macro macro reg
	if CompCollision=0
	move.l	(Primary_collision_addr).w,(Collision_addr).w
    if ("reg"="")
	cmpi.b	#$C,top_solid_bit(a0)
    else
	cmp.b	#$C,reg
    endif
	beq.s	.notprime
	move.l	(Secondary_collision_addr).w,(Collision_addr).w
.notprime
	else
	move.l	#Primary_collision,(Collision_addr).w
    if ("reg"="")
	cmpi.b	#$C,top_solid_bit(a0)
    else
	cmpi.b	#$C,top_solid_bit(reg)
    endif
	beq.s	.notprime
	addq.l	#Secondary_collision-Primary_collision,(Collision_addr).w
.notprime
	endif
	endm

SetCollAddrPlane_lrb_macro macro reg
	if CompCollision=0
	move.l	(Primary_collision_addr).w,(Collision_addr).w
    if ("reg"="")
	cmpi.b	#$D,lrb_solid_bit(a0)
    else
	cmp.b	#$D,reg
    endif
	beq.s	.notprime
	move.l	(Secondary_collision_addr).w,(Collision_addr).w
.notprime
	else
	move.l	#Primary_collision,(Collision_addr).w
    if ("reg"="")
	cmpi.b	#$D,lrb_solid_bit(a0)
    else
	cmp.b	#$D,reg
    endif
	beq.s	.notprime
	addq.l	#Secondary_collision-Primary_collision,(Collision_addr).w
.notprime
	endif
	endm
; =============== S U B R O U T I N E =======================================

Player_AnglePos:
		SetCollAddrPlane_macro
		move.b	top_solid_bit(a0),d5
		btst	#Status_OnObj,status(a0); are you standing on an object?
		beq.s	.groundcheck		; if not, branch
		clr.w	(Primary_Angle).w	; set Primary_Angle and Secondary_Angle to 0
		rts
.groundcheck
		move.w	#(3&$FF)<<8|(3&$FF),(Primary_Angle).w	; set Primary_Angle and Secondary_Angle to 3
		move.b	angle(a0),d1
		move.b	d1,d0
		addi.b	#$20,d0
		bpl.s	.angleonground
;		move.b	angle(a0),d0
;		bpl.s	+
;		subq.b	#1,d0	; if bmi, +$1F
;+		addi.b	#$20,d0	; if bpl, +$20
		tst.b	d1
		bpl.s	.angleonaircont
		bra.s	.angleonairsubtract

.angleonground
;		move.b	angle(a0),d0
;		bpl.s	+
;		addq.b	#1,d0	; if bmi, +$20
;+		addi.b	#$1F,d0	; if bpl, +$1F
		tst.b	d1
		bmi.s	.angleonaircont

.angleonairsubtract
		subq.b	#1,d0

.angleonaircont
		andi.w	#%11000000,d0
		tst.b	d0
		beq.s	Player_WalkFloor
		bmi.w	Player_WalkCeiling	; checks for Player_WalkVertR, or at least it's meant to
		bra.w	Player_WalkVertL
	;	cmpi.b	#$40,d0
	;	beq.w	Player_WalkVertL
	;	cmpi.b	#$80,d0
	;	beq.w	Player_WalkCeiling
	;	cmpi.b	#$C0,d0
	;	beq.w	Player_WalkVertR

Player_WalkFloor:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Primary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindFloor
		move.w	(sp)+,d0
		bsr.w	Player_Angle
		tst.w	d1
		beq.s	+
		bpl.s	.sloped
		cmpi.w	#-$E,d1
		blt.s	+
		add.w	d1,y_pos(a0)
+		rts
; ---------------------------------------------------------------------------
.sloped
		tst.b	stick_to_convex(a0)
		bne.s	.convex
		move.b	x_vel(a0),d0
		bpl.s	+
		neg.b	d0
+		addq.b	#4,d0
		cmpi.b	#$E,d0
		ble.s	+
		moveq	#$E,d0
+		cmp.b	d0,d1
		bgt.s	.reset
.convex
		add.w	d1,y_pos(a0)
		rts
; ---------------------------------------------------------------------------
.reset
		bset	#Status_InAir,status(a0)
		bclr	#Status_Push,status(a0)
		move.b	#id_Run,prev_anim(a0)
		rts

; =============== S U B R O U T I N E =======================================

Player_Angle:
	;	move.w	d0,d3
		move.b	(Secondary_Angle).w,d2
		cmp.w	d0,d1
		ble.s	.usesecondary
		move.b	(Primary_Angle).w,d2
	;	move.w	d1,d3
		move.w	d0,d1
.usesecondary
	;	move.b	angle(a0),d3
		btst	#0,d2
		bne.s	.type2
		move.b	d2,d0
		sub.b	angle(a0),d0
		bpl.s	+
		neg.b	d0
+		cmpi.b	#$20,d0
		blo.s	.setangle
.type2
		move.b	angle(a0),d2
		addi.b	#$20,d2
		andi.b	#$C0,d2
.setangle
		move.b	d2,angle(a0)
		rts
; ---------------------------------------------------------------------------

Player_WalkVertR:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	x_radius(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d2
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Primary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindWall
		move.w	(sp)+,d0
		bsr.w	Player_Angle
		tst.w	d1
		beq.s	+
		bpl.s	.sloped
		cmpi.w	#-$E,d1
		blt.s	+
		add.w	d1,x_pos(a0)
+		rts
; ---------------------------------------------------------------------------
.sloped
		tst.b	stick_to_convex(a0)
		bne.s	.convex
		move.b	y_vel(a0),d0
		bpl.s	+
		neg.b	d0
+		addq.b	#4,d0
		cmpi.b	#$E,d0
		ble.s	+
		moveq	#$E,d0
+		cmp.b	d0,d1
		bgt.s	.reset
.convex
		add.w	d1,x_pos(a0)
		rts
; ---------------------------------------------------------------------------
.reset
		bset	#Status_InAir,status(a0)
		bclr	#Status_Push,status(a0)
		move.b	#id_Run,prev_anim(a0)
		rts
; ---------------------------------------------------------------------------

Player_WalkCeiling:
		cmpi.b	#$C0,d0
		beq.w	Player_WalkVertR
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#1<<$B,d6
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#1<<$B,d6
		bsr.w	FindFloor
		move.w	(sp)+,d0
		bsr.w	Player_Angle
		tst.w	d1
		beq.s	+
		bpl.s	.sloped
		cmpi.w	#-$E,d1
		blt.s	+
		sub.w	d1,y_pos(a0)
+		rts
; ---------------------------------------------------------------------------
.sloped
		tst.b	stick_to_convex(a0)
		bne.s	.convex
		move.b	x_vel(a0),d0
		bpl.s	+
		neg.b	d0
+		addq.b	#4,d0
		cmpi.b	#$E,d0
		ble.s	+
		moveq	#$E,d0
+		cmp.b	d0,d1
		bgt.s	.reset
.convex
		sub.w	d1,y_pos(a0)
		rts
; ---------------------------------------------------------------------------
.reset
		bset	#Status_InAir,status(a0)
		bclr	#Status_Push,status(a0)
		move.b	#id_Run,prev_anim(a0)
		rts
; ---------------------------------------------------------------------------

Player_WalkVertL:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	x_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#1<<$A,d6
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#1<<$A,d6
		bsr.w	FindWall
		move.w	(sp)+,d0
		bsr.w	Player_Angle
		tst.w	d1
		beq.s	+
		bpl.s	.sloped
		cmpi.w	#-$E,d1
		blt.s	+
		sub.w	d1,x_pos(a0)
+		rts
; ---------------------------------------------------------------------------
.sloped
		tst.b	stick_to_convex(a0)
		bne.s	.convex
		move.b	y_vel(a0),d0
		bpl.s	+
		neg.b	d0
+		addq.b	#4,d0
		cmpi.b	#$E,d0
		ble.s	+
		moveq	#$E,d0
+		cmp.b	d0,d1
		bgt.s	.reset
.convex
		sub.w	d1,x_pos(a0)
		rts
; ---------------------------------------------------------------------------
.reset
		bset	#Status_InAir,status(a0)
		bclr	#Status_Push,status(a0)
		move.b	#id_Run,prev_anim(a0)
		rts
; ---------------------------------------------------------------------------
; collision registers
; d2 = xpos
; d3 = ypos
; d4 = block tile, mostly used for collision
; d5 = solidity bit to test
; d6 = eor to d4 when checking collision, low byte used elsewhere
GetFloorPosition:
	if CompLevel=0
		movea.l	(Level_layout_addr_ROM).w,a1
	else
		lea	(Level_layout_header).w,a1
	endif
		move.w	d2,d0
		lsr.w	#5,d0
		and.w	(Layout_row_index_mask).w,d0
		move.w	8(a1,d0.w),d0
		andi.w	#$7FFF,d0
	;	adda.w	d0,a1
		move.w	d3,d1
		lsr.w	#3,d1
		move.w	d1,d4
		lsr.w	#4,d1
		add.w	d0,d1
		adda.w	d1,a1
		moveq	#-1,d1
		clr.w	d1
		move.b	(a1),d1
	;	add.w	d1,d1
	;	move.w	ChunkAddrArray(pc,d1.w),d1
		lsl.w	#7,d1	; (chunk number)*$80 ; $80 bytes per chunk
	if Chunk_table&$FFFF<>0
		add.w	#Chunk_table&$FFFF,d1	; add address to chunk RAM
	endif
		move.w	d2,d0
		andi.w	#$70,d0
		add.w	d0,d1
		andi.w	#$E,d4
		add.w	d4,d1
		movea.l	d1,a1
		rts
; ---------------------------------------------------------------------------

;ChunkAddrArray:
;.a	set	0
;	rept	$100
;		dc.w	 .a
;.a	set	.a+$80
;	endr

; =============== S U B R O U T I N E =======================================

FindCollision_macro macro failbra,wallflag
		movea.l	(Collision_addr).w,a2
		add.w	d0,d0
		move.b	(a2,d0.w),d0
		beq.ATTRIBUTE	failbra
		andi.w	#$FF,d0
		lea	(AngleArray),a2
		move.b	(a2,d0.w),d6	; copy collision angle into d6 (low byte is free)
	if ("wallflag"="")
		move.w	d3,d1
		btst	#$A,d4
		beq.s	+
		not.w	d1
		neg.b	d6
+
		andi.w	#$F,d1
		lsl.w	#4,d0
		add.w	d0,d1

		btst	#$B,d4
		beq.s	+
		moveq	#$40,d0
		add.b	d0,d6
		neg.b	d6
		sub.b	d0,d6
+
		lea	(HeightMaps),a2
	else
		move.w	d2,d1
		btst	#$B,d4
		beq.s	+
		not.w	d1
		add.b	#$40,d6		; TODO: Try to copy the $40 to a register
		neg.b	d6
		sub.b	#$40,d6
+
		andi.w	#$F,d1
		lsl.w	#4,d0
		add.w	d0,d1

		btst	#$A,d4
		beq.s	+
		neg.b	d6
+
		lea	(HeightMapsRot),a2
	endif
		move.b	d6,(a4)		; copy final angle into (a4)
		move.b	(a2,d1.w),d0	; use HeightMaps to get final collision data
		ext.w	d0
		eor.w	d6,d4
	if ("wallflag"="")
		btst	#$B,d4
	else
		btst	#$A,d4
	endif
		beq.s	+
		neg.w	d0
+
	endm
FindFloor:
		bsr.w	GetFloorPosition
		move.w	(a1),d4
		move.w	d4,d0
		andi.w	#$3FF,d0
		beq.s	loc_F274	; edgecase for block 0, hardcoded to have no collision
		btst	d5,d4
		beq.s	loc_F274
; loc_F282:
	FindCollision_macro loc_F274
		tst.w	d0
		beq.s	loc_F274
		bmi.s	loc_F2F2
		cmpi.b	#$10,d0
		beq.s	loc_F2FE
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_F274:
		add.w	a3,d2
		bsr.w	FindFloor2
		sub.w	a3,d2
		addi.w	#$10,d1
		rts
loc_F2F2:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.s	loc_F274
loc_F2FE:
		sub.w	a3,d2
		bsr.w	FindFloor2
		add.w	a3,d2
		subi.w	#$10,d1
		rts

; =============== S U B R O U T I N E =======================================

FindFloor2:
		bsr.w	GetFloorPosition
		move.w	(a1),d4
		move.w	d4,d0
		andi.w	#$3FF,d0
		beq.s	loc_F31C
		btst	d5,d4
		beq.s	loc_F31C
; loc_F32A:
	FindCollision_macro loc_F31C
		tst.w	d0
		beq.s	loc_F31C
		bmi.s	loc_F394
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_F31C:
		move.w	#$F,d1
		move.w	d2,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts
loc_F394:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.s	loc_F31C
		not.w	d1
		rts
; ---------------------------------------------------------------------------
; loc_F3A4:
FindFloor_Ring:
		bsr.w	GetFloorPosition
		move.w	(a1),d4
		move.w	d4,d0
		andi.w	#$3FF,d0
		beq.s	loc_F3EE
		btst	d5,d4
		beq.s	loc_F3EE
; loc_F3F4:
	FindCollision_macro loc_F3EE
		tst.w	d0
		beq.s	loc_F3EE
		bmi.s	loc_F464
		cmpi.b	#$10,d0
		beq.s	loc_F470
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_F3EE:
		move.w	#$10,d1
		rts

loc_F464:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.s	loc_F3EE

loc_F470:
		sub.w	a3,d2
		bsr.w	FindFloor2
		add.w	a3,d2
		subi.w	#$10,d1
		rts

; =============== S U B R O U T I N E =======================================

FindWall:
		bsr.w	GetFloorPosition
		move.w	(a1),d4
		move.w	d4,d0
		andi.w	#$3FF,d0
		beq.s	loc_F4EC
		btst	d5,d4
		beq.s	loc_F4EC
; loc_F4FA:
	FindCollision_macro loc_F4EC,0
		tst.w	d0
		beq.s	loc_F4EC
		bmi.s	loc_F56A
		cmpi.b	#$10,d0
		beq.s	loc_F576
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_F4EC:
		add.w	a3,d3
		bsr.w	FindWall2
		sub.w	a3,d3
		addi.w	#$10,d1
		rts

loc_F56A:
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.s	loc_F4EC

loc_F576:
		sub.w	a3,d3
		bsr.w	FindWall2
		add.w	a3,d3
		subi.w	#$10,d1
		rts

; =============== S U B R O U T I N E =======================================

FindWall2:
		bsr.w	GetFloorPosition
		move.w	(a1),d4
		move.w	d4,d0
		andi.w	#$3FF,d0
		beq.s	loc_F594
		btst	d5,d4
		beq.s	loc_F594
; loc_F5A2:
	FindCollision_macro loc_F594,0
		tst.w	d0
		beq.s	loc_F594
		bmi.s	loc_F60C
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ---------------------------------------------------------------------------

loc_F594:
		move.w	#$F,d1
		move.w	d3,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts
loc_F60C:
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.s	loc_F594
		not.w	d1
		rts

; =============== S U B R O U T I N E =======================================

sub_F61C:
CalcRoomInFront:
		SetCollAddrPlane_macro
		move.b	lrb_solid_bit(a0),d5
		move.l	x_pos(a0),d3
		move.l	y_pos(a0),d2
		move.w	x_vel(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d3
		move.w	y_vel(a0),d1
		tst.b	(Reverse_gravity_flag).w
		beq.s	+
		neg.w	d1
+		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d2
		swap	d2
		swap	d3
		move.b	d0,(Primary_Angle).w
		move.b	d0,(Secondary_Angle).w
		move.b	d0,d1
		addi.b	#$20,d0
		bpl.s	++
		move.b	d1,d0
		bpl.s	+
		subq.b	#1,d0
+		addi.b	#$20,d0
		bra.s	+++
; ---------------------------------------------------------------------------
+		move.b	d1,d0
		bpl.s	+
		addq.b	#1,d0
+		addi.b	#$1F,d0
+		andi.b	#$C0,d0
		beq.w	CheckFloorDist_Part2
		cmpi.b	#$80,d0
		beq.w	CheckCeilingDist_Part2
		andi.b	#$38,d1
		bne.s	+
		addq.w	#8,d2
+		cmpi.b	#$40,d0
		beq.w	CheckLeftWallDist_Part2
		bra.w	CheckRightWallDist_Part2
; ---------------------------------------------------------------------------
; Subroutine to calculate how much space is empty above Sonic's/Tails' head
; d0 = input angle perpendicular to the spine
; d1 = output about how many pixels are overhead (up to some high enough amount)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

CalcRoomOverHead:
		SetCollAddrPlane_macro
		move.b	lrb_solid_bit(a0),d5
		move.b	d0,(Primary_Angle).w
		move.b	d0,(Secondary_Angle).w
		addi.b	#$20,d0
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	CheckLeftCeilingDist
		cmpi.b	#$80,d0
		beq.w	Sonic_CheckCeiling
		cmpi.b	#$C0,d0
		beq.w	CheckRightCeilingDist

; ---------------------------------------------------------------------------
; Subroutine to check if Sonic/Tails is near the floor
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Sonic_CheckFloor:
		SetCollAddrPlane_macro
		move.b	top_solid_bit(a0),d5

Sonic_CheckFloor2:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Primary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#0,d2

loc_F7E2:
		move.b	(Secondary_Angle).w,d3
		cmp.w	d0,d1
		ble.s		+
		move.b	(Primary_Angle).w,d3
		exg	d0,d1
+		btst	#0,d3
		beq.s	+
		move.b	d2,d3
+		rts

; ---------------------------------------------------------------------------
; Checks a 16x16 block to find solid ground. May check an additional
; 16x16 block up for ceilings.
; d2 = y_pos
; d3 = x_pos
; d5 = ($c,$d) or ($e,$f) - solidity type bit (L/R/B or top)
; returns relevant block ID in (a1)
; returns distance in d1
; returns angle in d3, or zero if angle was odd
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

CheckFloorDist:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3

CheckFloorDist_Part2:
		addi.w	#$A,d2
		lea	(Primary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindFloor
		move.b	#0,d2

; d2 what to use as angle if (Primary_Angle).w is odd
; returns angle in d3, or value in d2 if angle was odd
loc_F81A:
		move.b	(Primary_Angle).w,d3
		btst	#0,d3
		beq.s	+
		move.b	d2,d3
+		rts

; =============== S U B R O U T I N E =======================================

sub_F828:
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		lea	(Primary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindFloor
		move.b	#0,d2
		bra.s	loc_F81A

; =============== S U B R O U T I N E =======================================

sub_F846:
		move.w	x_pos(a0),d3
		move.w	y_pos(a0),d2
		subq.w	#4,d2
		SetCollAddrPlane_lrb_macro
		lea	(Primary_Angle).w,a4
		clr.b	(a4)
		movea.w	#$10,a3
		moveq	#0,d6
		move.b	lrb_solid_bit(a0),d5
		movem.l	a4-a6,-(sp)
		bsr.w	FindFloor
		movem.l	(sp)+,a4-a6
		move.b	(Primary_Angle).w,d3
		btst	#0,d3
		beq.s	+
		move.b	#0,d3
+		rts

; =============== S U B R O U T I N E =======================================

ChkFloorEdge:
		move.w	x_pos(a0),d3

ChkFloorEdge_Part2:
		move.w	y_pos(a0),d2
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d2

ChkFloorEdge_Part3:
		SetCollAddrPlane_macro
		lea	(Primary_Angle).w,a4
		clr.b	(a4)
		movea.w	#$10,a3
		moveq	#0,d6
		move.b	top_solid_bit(a0),d5
		movem.l	a4-a6,-(sp)
		bsr.w	FindFloor
		movem.l	(sp)+,a4-a6
		move.b	(Primary_Angle).w,d3
		btst	#0,d3
		beq.s	+
		move.b	#0,d3
+		rts

; =============== S U B R O U T I N E =======================================

SonicOnObjHitFloor:
		move.w	x_pos(a1),d3

SonicOnObjHitFloor2:
		move.w	y_pos(a1),d2
		move.b	y_radius(a1),d0
		ext.w	d0
		add.w	d0,d2
		SetCollAddrPlane_macro
		lea	(Primary_Angle).w,a4
		clr.b	(a4)
		movea.w	#$10,a3
		moveq	#0,d6
		move.b	top_solid_bit(a1),d5
		bsr.w	FindFloor
		move.b	(Primary_Angle).w,d3
		btst	#0,d3
		beq.s	+
		move.b	#0,d3
+		rts

; ---------------------------------------------------------------------------
; Subroutine checking if an object should interact with the floor
; (objects such as a monitor Sonic bumps from underneath)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

ObjHitFloor:
ObjFloorDist:
ObjCheckFloorDist:
		move.w	x_pos(a0),d3

ObjHitFloor2:
ObjFloorDist2:
ObjCheckFloorDist2:
		move.w	y_pos(a0),d2			; Get object position
		move.b	y_radius(a0),d0		; Get object height
		ext.w	d0
		add.w	d0,d2
		lea	(Primary_Angle).w,a4
		clr.b	(a4)
		movea.w	#$10,a3
		moveq	#0,d6
		moveq	#$C,d5
		bsr.w	FindFloor
		move.b	(Primary_Angle).w,d3
		btst	#0,d3
		beq.s	+
		move.b	#0,d3
+		rts

; =============== S U B R O U T I N E =======================================

RingCheckFloorDist:
		move.w	x_pos(a0),d3
		move.w	y_pos(a0),d2
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		lea	(Primary_Angle).w,a4
		clr.b	(a4)
		movea.w	#$10,a3
		moveq	#0,d6
		moveq	#$C,d5
		bra.w	FindFloor_Ring

; =============== S U B R O U T I N E =======================================

CheckRightCeilingDist:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	x_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Primary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#-$40,d2
		bra.w	loc_F7E2

; =============== S U B R O U T I N E =======================================

sub_FA1A:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Primary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#-$40,d2
		bra.w	loc_F7E2

; =============== S U B R O U T I N E =======================================

CheckRightWallDist:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3

CheckRightWallDist_Part2:
		addi.w	#$A,d3
		lea	(Primary_Angle).w,a4
		movea.w	#$10,a3
		moveq	#0,d6
		bsr.w	FindWall
		move.b	#-$40,d2
		bra.w	loc_F81A
; ---------------------------------------------------------------------------

loc_FAA4:
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Primary_Angle).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	FindWall
		move.b	#-$40,d2
		bra.w	loc_F81A

; =============== S U B R O U T I N E =======================================

; ObjHitWall:
ObjHitWallRight:
ObjCheckRightWallDist:
		add.w	x_pos(a0),d3
		move.w	y_pos(a0),d2
		lea	(Primary_Angle).w,a4
		clr.b	(a4)
		movea.w	#$10,a3
		moveq	#0,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.b	(Primary_Angle).w,d3
		btst	#0,d3
		beq.s	+
		move.b	#-$40,d3
+		rts

; =============== S U B R O U T I N E =======================================

Sonic_CheckCeiling:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#$80,d2
		bra.w	loc_F7E2

; =============== S U B R O U T I N E =======================================

sub_FB5A:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		subq.w	#2,d0
		add.w	d0,d3
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		subq.w	#2,d0
		sub.w	d0,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#$80,d2
		bra.w	loc_F7E2

; =============== S U B R O U T I N E =======================================

CheckCeilingDist:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3

CheckCeilingDist_Part2:
		subi.w	#$A,d2
		eori.w	#$F,d2
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.b	#$80,d2
		bra.w	loc_F81A

; =============== S U B R O U T I N E =======================================

sub_FBEE:
CheckCeilingDist_WithRadius:
		move.b	x_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.b	#$80,d2
		bra.w	loc_F81A

; =============== S U B R O U T I N E =======================================

ObjHitCeiling:
ObjCheckCeilingDist:
		moveq	#$D,d5

ObjCheckCeilingDist_Part2:
		move.w	x_pos(a0),d3

ObjCheckCeilingDist_Part3:
		move.w	y_pos(a0),d2
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		bsr.w	FindFloor
		move.b	(Primary_Angle).w,d3
		btst	#0,d3
		beq.s	+
		move.b	#$80,d3
+		rts

; =============== S U B R O U T I N E =======================================

ChkFloorEdge_ReverseGravity:
		move.w	y_pos(a0),d2
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2

ChkFloorEdge_ReverseGravity_Part2:
		SetCollAddrPlane_macro
		lea	(Primary_Angle).w,a4
		clr.b	(a4)
		movea.w	#-$10,a3
		move.w	#$800,d6
		move.b	top_solid_bit(a0),d5
		movem.l	a4-a6,-(sp)
		bsr.w	FindFloor
		movem.l	(sp)+,a4-a6
		move.b	(Primary_Angle).w,d3
		btst	#0,d3
		beq.s	+
		move.b	#0,d3
+		rts

; =============== S U B R O U T I N E =======================================

sub_FCA0:
RingCheckFloorDist_ReverseGravity:
		move.w	x_pos(a0),d3
		move.w	y_pos(a0),d2
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		lea	(Primary_Angle).w,a4
		clr.b	(a4)
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$C,d5
		bra.w	FindFloor_Ring

; =============== S U B R O U T I N E =======================================

CheckLeftCeilingDist:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	x_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	x_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#$40,d2
		bra.w	loc_F7E2

; =============== S U B R O U T I N E =======================================

sub_FD32:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3
		move.b	y_radius(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	x_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(Secondary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#$40,d2
		bra.w	loc_F7E2

; =============== S U B R O U T I N E =======================================

CheckLeftWallDist:
		move.w	y_pos(a0),d2
		move.w	x_pos(a0),d3

CheckLeftWallDist_Part2:
		subi.w	#$A,d3
		eori.w	#$F,d3
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.b	#$40,d2
		bra.w	loc_F81A
; ---------------------------------------------------------------------------

loc_FDC8:
		move.b	$1F(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(Primary_Angle).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		bsr.w	FindWall
		move.b	#$40,d2
		bra.w	loc_F81A

; =============== S U B R O U T I N E =======================================

sub_FDEC:
		SetCollAddrPlane_macro
		move.w	x_pos(a0),d3
		move.w	y_pos(a0),d2
		move.b	y_radius(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(Primary_Angle).w,a4
		clr.b	(a4)
		movea.w	#-$10,a3
		move.w	#$400,d6
		move.b	lrb_solid_bit(a0),d5
		bsr.w	FindWall
		move.b	(Primary_Angle).w,d3
		btst	#0,d3
		beq.s	+
		move.b	#$40,d3
+		rts

; =============== S U B R O U T I N E =======================================

; ObjHitWall2:
ObjHitWallLeft:
ObjCheckLeftWallDist:
		add.w	x_pos(a0),d3
		eori.w	#$F,d3	; this was not here in S1/S2, resulting in a bug

ObjCheckLeftWallDist_Part2:
		move.w	y_pos(a0),d2
		lea	(Primary_Angle).w,a4
		clr.b	(a4)
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.b	(Primary_Angle).w,d3
		btst	#0,d3
		beq.s	+
		move.b	#$40,d3
+		rts

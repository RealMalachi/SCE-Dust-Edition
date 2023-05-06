animal_savedxvel	= $30
animal_savedyvel	= animal_savedxvel+2
animal_savedaddr	= animal_savedyvel+2	; long, routine to use when it lands on the ground
animal_capsuletimer	= $36	; word, used in the animal capsule routine
animal_capsuleflag	= $38	; byte, set if animal was from a capsule. Unused in S3K
animal_miscnotflag	= $2D	; byte, gets not'ed then checked if 0 or 1.

Animal_KeepUnused = 0
; ---------------------------------------------------------------------------
; Animal (Object)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

zoneAnimals macro first,second
	dc.b (Obj_Animal_Prop_first-Obj_Animal_Prop)
	dc.b (Obj_Animal_Prop_second-Obj_Animal_Prop)
	endm
; byte_2C7BA:
Obj_Animal_ZoneNumber:
	; This table declares what animals will appear in the zone.
	; When an enemy is destroyed, a random animal is chosen from the 2 selected animals.
	; Note: you must also load the corresponding art in the PLCs.
	zoneAnimals Flicky,Chicken	; DEZ
	zonewarning Obj_Animal_ZoneNumber,(2)

animaldecl macro	xvel,yvel,mappings,routine,{INTLABEL}
Obj_Animal_Prop___LABEL__: label *
	dc.l mappings
	dc.w xvel,yvel
	dc.l routine
	endm
; word_2C7EA:
Obj_Animal_Prop:
; This table declares the mappings, speed, and routine of each animal.
Rabbit:		animaldecl -$200,-$400,Map_Animals5,Obj_Animal_Walk
Chicken:	animaldecl -$200,-$300,Map_Animals1,Obj_Animal_Fly
Penguin:	animaldecl -$180,-$300,Map_Animals5,Obj_Animal_Walk
Seal:		animaldecl -$140,-$180,Map_Animals4,Obj_Animal_Walk
Pig:		animaldecl -$1C0,-$300,Map_Animals3,Obj_Animal_Walk
Flicky:		animaldecl -$300,-$400,Map_Animals1,Obj_Animal_Fly
Squirrel:	animaldecl -$280,-$380,Map_Animals2,Obj_Animal_Walk
;Eagle:		animaldecl -$280,-$300,Map_Animals1,Obj_Animal_Fly
;Mouse:		animaldecl -$200,-$380,Map_Animals2,Obj_Animal_Walk
;Monkey:		animaldecl -$2C0,-$300,Map_Animals2,Obj_Animal_Walk
;Turtle:		animaldecl -$140,-$200,Map_Animals2,Obj_Animal_Walk
;Bear:		animaldecl -$200,-$300,Map_Animals2,Obj_Animal_Walk

Obj_Animal:
		move.l	#.main,address(a0)
		jsr	(Random_Number).w
		move.w	#make_art_tile($580,0,0),d1
		andi.w	#1,d0
		beq.s	+
		move.w	#make_art_tile($592,0,0),d1
+		move.w	d1,art_tile(a0)
		moveq	#0,d1
		move.b	(Current_zone).w,d1
		add.w	d1,d1
		add.w	d0,d1
	;	add.w	d1,d1
		lea	Obj_Animal_ZoneNumber(pc),a1
		move.b	(a1,d1.w),d0
		lea	Obj_Animal_Prop(pc),a1
		adda.w	d0,a1
		move.l	(a1)+,mappings(a0)
		move.l	(a1)+,animal_savedxvel(a0)
		move.l	(a1)+,animal_savedaddr(a0)
		move.b	#24/2,y_radius(a0)
		move.b	#4,render_flags(a0)
		bset	#0,render_flags(a0)
		move.w	#make_priority(6),priority(a0)
		move.w	#bytes_to_word(24/2,16/2),height_pixels(a0)
		move.b	#7,anim_frame_timer(a0)
		move.b	#2,mapping_frame(a0)
		move.w	#-$400,y_vel(a0)
	if Animal_KeepUnused
		tst.b	animal_capsuleflag(a0)
		beq.s	+
		move.l	#Obj_Animal_Capsule,address(a0)
		clr.w	x_vel(a0)
+
	endif
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

.main:
		tst.b	render_flags(a0)
		bpl.s	.delete
		jsr	(MoveSprite).w
		tst.w	y_vel(a0)
		bmi.s	+
		jsr	(ObjCheckFloorDist).w
		tst.w	d1
		bpl.s	+
		add.w	d1,y_pos(a0)
		move.l	animal_savedxvel(a0),x_vel(a0)
		move.b	#1,mapping_frame(a0)
		move.l	animal_savedaddr(a0),address(a0)
	if Animal_KeepUnused
		tst.b	animal_capsuleflag(a0)
		beq.s	+
		btst	#4,(V_int_run_count+3).w
		beq.s	+
		neg.w	x_vel(a0)
		bchg	#0,render_flags(a0)
	endif
+		jmp	(Draw_Sprite).w
.delete:
		jmp	(Delete_Current_Sprite).w
; ---------------------------------------------------------------------------

Obj_Animal_Walk:
		jsr	(MoveSprite).w
		move.b	#1,mapping_frame(a0)
		tst.w	y_vel(a0)
		bmi.s	+
		clr.b	mapping_frame(a0)
		jsr	(ObjCheckFloorDist).w
		tst.w	d1
		bpl.s	+
		add.w	d1,y_pos(a0)
		move.w	animal_savedyvel(a0),y_vel(a0)
+
	if Animal_KeepUnused
		tst.b	subtype(a0)
		bne.s	Obj_Animal_EndDeleteHandler
	endif
		tst.b	render_flags(a0)
		bpl.s	Obj_Animal.delete
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

Obj_Animal_Fly:
		jsr	(MoveSprite2).w
		addi.w	#$18,y_vel(a0)
		tst.w	y_vel(a0)
		bmi.s	+
		jsr	(ObjCheckFloorDist).w
		tst.w	d1
		bpl.s	+
		add.w	d1,y_pos(a0)
		move.w	animal_savedyvel(a0),y_vel(a0)
	if Animal_KeepUnused
		tst.b	subtype(a0)
		beq.s	+
		cmpi.b	#$A,subtype(a0)
		beq.s	+
		neg.w	x_vel(a0)
		bchg	#0,render_flags(a0)
	endif
+		subq.b	#1,anim_frame_timer(a0)
		bpl.s	+
		move.b	#1,anim_frame_timer(a0)
		addq.b	#1,mapping_frame(a0)
		andi.b	#1,mapping_frame(a0)
+
	if Animal_KeepUnused
		tst.b	subtype(a0)
		bne.s	Obj_Animal_EndDeleteHandler
	endif
		tst.b	render_flags(a0)
		bpl.w	Obj_Animal.delete
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------
		if Animal_KeepUnused
Obj_Animal_EndDeleteHandler:
		move.w	x_pos(a0),d0
		sub.w	(Player_1+x_pos).w,d0
		bcs.s	+
		subi.w	#$180,d0
		bpl.s	+
		tst.b	render_flags(a0)
		bpl.w	Obj_Animal.delete
+		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

Obj_Animal_Capsule:
		tst.b	render_flags(a0)
		bpl.w	Obj_Animal.delete
		subq.w	#1,animal_capsuletimer(a0)
		bne.s	+
		move.l	#Obj_Animal.main,address(a0)
		move.w	#make_priority(1),priority(a0)
+		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

Obj_Animal_Ending:
		moveq	#0,d0
		move.b	subtype(a0),d0
	;	subi.w	#$A,d0
		lsl.w	#4,d0
		lea	Obj_EndAnimal_Routine(pc),a1
		adda.w	d0,a1
		move.l	(a1)+,address(a0)
		move.l	(a1)+,mappings(a0)
		move.l	(a1)+,d0	; get x_vel and y_vel
		move.l	d0,x_vel(a0)
		move.l	d0,animal_savedxvel(a0)
		move.l	(a2)+,priority(a0)
	;	move.w	(a2)+,art_tile(a0)
		move.b	#24/2,y_radius(a0)
		move.b	#4,render_flags(a0)
		bset	#0,render_flags(a0)
		move.w	#bytes_to_word(24/2,16/2),height_pixels(a0)
		move.b	#7,anim_frame_timer(a0)
		jmp	(Draw_Sprite).w

endanimaldecl macro	routine,mappings,xvel,yvel,prid,art,{INTLABEL}
Obj_EndAnimal_Routine___LABEL__: label *
	dc.l	routine,mappings
	dc.w	xvel,yvel,prid,art
	endm
Obj_EndAnimal_Routine:
E1:	endanimaldecl loc_2CB24,Map_Animals1,-$440,-$400,make_priority(6),make_art_tile($5A5,0,0)
E2:	endanimaldecl loc_2CB24,Map_Animals1,-$440,-$400,make_priority(6),make_art_tile($5A5,0,0)
E3:	endanimaldecl loc_2CB44,Map_Animals1,-$440,-$400,make_priority(6),make_art_tile($5A5,0,0)
E4:	endanimaldecl loc_2CB80,Map_Animals5,-$300,-$400,make_priority(6),make_art_tile($553,0,0)
E5:	endanimaldecl loc_2CBDC,Map_Animals5,-$300,-$400,make_priority(6),make_art_tile($553,0,0)
E6:	endanimaldecl loc_2CBFC,Map_Animals5,-$180,-$300,make_priority(6),make_art_tile($573,0,0)
E7:	endanimaldecl loc_2CBDC,Map_Animals5,-$180,-$300,make_priority(6),make_art_tile($573,0,0)
E8:	endanimaldecl loc_2CBFC,Map_Animals4,-$140,-$180,make_priority(6),make_art_tile($585,0,0)
E9:	endanimaldecl loc_2CBDC,Map_Animals3,-$1C0,-$300,make_priority(6),make_art_tile($593,0,0)
E10:	endanimaldecl loc_2CC3C,Map_Animals1,-$200,-$300,make_priority(6),make_art_tile($565,0,0)
E11:	endanimaldecl loc_2CB9C,Map_Animals2,-$280,-$380,make_priority(6),make_art_tile($5B3,0,0)

loc_2CB24:
		bsr.w	sub_2CCD2
		bcc.w	Obj_Animal_EndDeleteHandler
		move.l	animal_savedxvel(a0),x_vel(a0)
		move.l	#Obj_Animal_Fly,address(a0)
		bra.w	Obj_Animal_Fly
; ---------------------------------------------------------------------------

loc_2CB44:
		bsr.w	sub_2CCD2
		bpl.s	+
		clr.w	x_vel(a0)
		clr.w	animal_savedxvel(a0)
		jsr	(MoveSprite2).w
		addi.w	#$18,y_vel(a0)
		bsr.w	sub_2CC92
		bsr.w	sub_2CCBA
		subq.b	#1,anim_frame_timer(a0)
		bpl.s	+
		move.b	#1,anim_frame_timer(a0)
		addq.b	#1,mapping_frame(a0)
		andi.b	#1,mapping_frame(a0)
+		bra.w	Obj_Animal_EndDeleteHandler
; ---------------------------------------------------------------------------

loc_2CB80:
		bsr.w	sub_2CCD2
		bpl.s	loc_2CBD8
		move.l	animal_savedxvel(a0),x_vel(a0)
		move.l	#Obj_Animal_Walk,address(a0)
		bra.w	Obj_Animal_Walk
; ---------------------------------------------------------------------------

loc_2CB9C:
		jsr	(MoveSprite).w
		move.b	#1,mapping_frame(a0)
		tst.w	y_vel(a0)
		bmi.s	loc_2CBD8
		clr.b	mapping_frame(a0)
		jsr	(ObjCheckFloorDist).w
		tst.w	d1
		bpl.s	loc_2CBD8
		not.b	$2D(a0)
		bne.s	+
		neg.w	x_vel(a0)
		bchg	#0,render_flags(a0)
+		add.w	d1,y_pos(a0)
		move.w	animal_savedyvel(a0),y_vel(a0)

loc_2CBD8:
		bra.w	Obj_Animal_EndDeleteHandler
; ---------------------------------------------------------------------------

loc_2CBDC:
		bsr.w	sub_2CCD2
		bpl.s	+
		clr.w	x_vel(a0)
		clr.w	animal_savedxvel(a0)
		jsr	(MoveSprite).w
		bsr.w	sub_2CC92
		bsr.w	sub_2CCBA
+		bra.w	Obj_Animal_EndDeleteHandler
; ---------------------------------------------------------------------------

loc_2CBFC:
		bsr.w	sub_2CCD2
		bpl.s	+
		jsr	(MoveSprite).w
		move.b	#1,mapping_frame(a0)
		tst.w	y_vel(a0)
		bmi.s	+
		clr.b	mapping_frame(a0)
		jsr	(ObjCheckFloorDist).w
		tst.w	d1
		bpl.s	+
		neg.w	x_vel(a0)
		bchg	#0,render_flags(a0)
		add.w	d1,y_pos(a0)
		move.w	animal_savedyvel(a0),y_vel(a0)
+		bra.w	Obj_Animal_EndDeleteHandler
; ---------------------------------------------------------------------------

loc_2CC3C:
		bsr.w	sub_2CCD2
		bpl.s	+++
		jsr	(MoveSprite2).w
		addi.w	#$18,y_vel(a0)
		tst.w	y_vel(a0)
		bmi.s	++
		jsr	(ObjCheckFloorDist).w
		tst.w	d1
		bpl.s	++
		not.b	$2D(a0)
		bne.s	+
		neg.w	x_vel(a0)
		bchg	#0,render_flags(a0)
+		add.w	d1,y_pos(a0)
		move.w	animal_savedyvel(a0),y_vel(a0)
+		subq.b	#1,anim_frame_timer(a0)
		bpl.s	+
		move.b	#1,anim_frame_timer(a0)
		addq.b	#1,mapping_frame(a0)
		andi.b	#1,mapping_frame(a0)
+		bra.w	Obj_Animal_EndDeleteHandler

; =============== S U B R O U T I N E =======================================

sub_2CC92:
		move.b	#1,mapping_frame(a0)
		tst.w	y_vel(a0)
		bmi.s	+
		clr.b	mapping_frame(a0)
		jsr	(ObjCheckFloorDist).w
		tst.w	d1
		bpl.s	+
		add.w	d1,y_pos(a0)
		move.w	animal_savedyvel(a0),y_vel(a0)
+		rts

; =============== S U B R O U T I N E =======================================

sub_2CCBA:
		bset	#0,render_flags(a0)
		move.w	x_pos(a0),d0
		sub.w	(Player_1+x_pos).w,d0
		bcc.s	+
		bclr	#0,render_flags(a0)
+		rts

; =============== S U B R O U T I N E =======================================

sub_2CCD2:
		move.w	(Player_1+x_pos).w,d0
		sub.w	x_pos(a0),d0
		subi.w	#$B8,d0
		rts
; ---------------------------------------------------------------------------
	endif ; Animal_KeepUnused
		include "Objects/Animals/Object Data/Map - Animals 1.asm"
		include "Objects/Animals/Object Data/Map - Animals 2.asm"
		include "Objects/Animals/Object Data/Map - Animals 3.asm"
		include "Objects/Animals/Object Data/Map - Animals 4.asm"
		include "Objects/Animals/Object Data/Map - Animals 5.asm"

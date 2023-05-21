; ---------------------------------------------------------------------------
; Shields (Object)
; ---------------------------------------------------------------------------

; Elemental Shield DPLC variables
LastLoadedDPLC			= $34
Art_Address			= $38
DPLC_Address		 	= $3C
VRAM_Address			= vram_art
LastLoadedShield		= sub9_x_pos		; long, address of the shields init
Shield_PlayerAddr		= LastLoadedShield+4	; word


SetDPLC_Macro macro dplcadd,artadd,vrampos
	move.l	#dplcadd,DPLC_Address(a0)
	move.l	#dmaSource(artadd),Art_Address(a0)
	move.w	#tiles_to_bytes(vrampos),VRAM_Address(a0)
	st	LastLoadedDPLC(a0)	; Reset LastLoadedDPLC (used by PLCLoad_Shields)
	move.l	address(a0),LastLoadedShield(a0)	; just in case
	endm

; ---------------------------------------------------------------------------
; Fire Shield
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_FireShield:
		; init
		move.l	#Map_FireShield,mappings(a0)
		move.l	#words_to_long(make_priority(1),make_art_tile(ArtTile_Shield,0,0)),priority(a0)
		move.l	#bytes_to_long(ren_camerapos,objflag_continue,48/2,48/2),render_flags(a0)
		SetDPLC_Macro DPLC_FireShield,ArtUnc_FireShield,ArtTile_Shield
		btst	#7,(Player_1+art_tile).w
		beq.s	.nothighpriority
		bset	#7,art_tile(a0)

.nothighpriority
		move.w	#1,anim(a0)										; clear anim and set prev_anim to 1
		move.l	#.main,address(a0)

.main
		movea.w	Shield_PlayerAddr(a0),a2
	;	btst	#Status_Invincible,status_secondary(a2)		; is player invincible?
	;	bne.w	.return						; if so, do not display and do not update variables
		cmpi.b	#id_Null,anim(a2)								; is player in their 'blank' animation?
		beq.w	.return											; if so, do not display and do not update variables
		btst	#Status_Shield,status_secondary(a2) 					; should the player still have a shield?
		beq.w	.destroy											; if not, change to Insta-Shield
		btst	#Status_Underwater,status(a2)							; is player underwater?
		bne.s	.destroyunderwater								; if so, branch
		move.w	x_pos(a2),x_pos(a0)
		move.w	y_pos(a2),y_pos(a0)
		tst.b	anim(a0)											; is shield in its 'dashing' state?
		bne.s	.nothighpriority2									; if so, do not update orientation or allow changing of the priority art_tile bit
		move.b	status(a2),status(a0)								; inherit status
		andi.b	#1,status(a0)										; limit inheritance to 'orientation' bit
		tst.b	(Reverse_gravity_flag).w
		beq.s	.normalgravity
		ori.b	#2,status(a0)										; if in reverse gravity, reverse the vertical mirror render_flag bit (On if Off beforehand and vice versa)

.normalgravity
		andi.w	#drawing_mask,art_tile(a0)
		tst.w	art_tile(a2)
		bpl.s	.nothighpriority2
		ori.w	#high_priority,art_tile(a0)

.nothighpriority2
		lea	Ani_FireShield(pc),a1
		jsr	(Animate_Sprite).w
		move.w	#make_priority(1),priority(a0)									; layer shield over player sprite
		cmpi.b	#$F,mapping_frame(a0)							; are these the frames that display in front of the player?
		blo.s	.overplayer										; if so, branch
		move.w	#make_priority(4),priority(a0)								; if not, layer shield behind player sprite

.overplayer
		bsr.w	PLCLoad_Shields
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

.destroyunderwater
		andi.b	#$8E,status_secondary(a2)							; sets Status_Shield, Status_FireShield, Status_LtngShield, and Status_BublShield to 0
		jsr	(Create_New_Sprite).w								; set up for a new object
		bne.s	.destroy											; if that can't happen, branch
		move.l	#Obj_FireShield_Dissipate,address(a1)				; create dissipate object
		move.w	x_pos(a0),x_pos(a1)								; put it at shields' x_pos
		move.w	y_pos(a0),y_pos(a1)								; put it at shields' y_pos

.destroy
		andi.b	#$8E,status_secondary(a2)							; sets Status_Shield, Status_FireShield, Status_LtngShield, and Status_BublShield to 0
		move.l	#Obj_InstaShield,address(a0)						; replace the Fire Shield with the Insta-Shield

.return
		rts

; ---------------------------------------------------------------------------
; Lightning Shield
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_LightningShield:

		; load spark art
		QueueStaticDMA ArtUnc_Obj_LightningShield_Sparks,tiles_to_bytes(5),tiles_to_bytes(ArtTile_Shield_Sparks)

		; init
		move.l	#Map_LightningShield,mappings(a0)
		move.l	#words_to_long(make_priority(1),make_art_tile(ArtTile_Shield,0,0)),priority(a0)
		move.l	#bytes_to_long(ren_camerapos,objflag_continue,48/2,48/2),render_flags(a0)
		SetDPLC_Macro DPLC_LightningShield,ArtUnc_LightningShield,ArtTile_Shield
		btst	#7,(Player_1+art_tile).w
		beq.s	.nothighpriority
		bset	#7,art_tile(a0)

.nothighpriority
		move.w	#1,anim(a0)										; clear anim and set prev_anim to 1
		move.l	#.main,address(a0)

.main
		movea.w	Shield_PlayerAddr(a0),a2
	;	btst	#Status_Invincible,status_secondary(a2)		; is player invincible?
	;	bne.w	.return						; if so, do not display and do not update variables
		cmpi.b	#id_Null,anim(a2)								; is player in their 'blank' animation?
		beq.w	.return											; if so, do not display and do not update variables
		btst	#Status_Shield,status_secondary(a2)						; should the player still have a shield?
		beq.s	.destroy											; if not, change to Insta-Shield
		btst	#Status_Underwater,status(a2)							; is player underwater?
		bne.s	.destroyunderwater								; if so, branch
		move.w	x_pos(a2),x_pos(a0)
		move.w	y_pos(a2),y_pos(a0)
		move.b	status(a2),status(a0)								; inherit status
		andi.b	#1,status(a0)										; limit inheritance to 'orientation' bit
		tst.b	(Reverse_gravity_flag).w
		beq.s	.normalgravity
		ori.b	#2,status(a0)										; if in reverse gravity, reverse the vertical mirror render_flag bit (On if Off beforehand and vice versa)

.normalgravity
		andi.w	#drawing_mask,art_tile(a0)
		tst.w	art_tile(a2)
		bpl.s	.nothighpriority2
		ori.w	#high_priority,art_tile(a0)

.nothighpriority2
		tst.b	anim(a0)											; is shield in its 'double jump' state?
		beq.s	.display											; is not, branch and display
		bsr.s	Obj_LightningShield_Create_Spark					; create sparks
		clr.b	anim(a0)											; once done, return to non-'double jump' state

.display
		lea	Ani_LightningShield(pc),a1
		jsr	(Animate_Sprite).w
		move.w	#make_priority(1),priority(a0)									; layer shield over player sprite
		cmpi.b	#$E,mapping_frame(a0)							; are these the frames that display in front of the player?
		blo.s	.overplayer										; if so, branch
		move.w	#make_priority(4),priority(a0)								; if not, layer shield behind player sprite

.overplayer
		bsr.w	PLCLoad_Shields
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

.destroyunderwater
		tst.w	(Palette_fade_timer).w
		beq.s	.flashwater

.destroy
		andi.b	#$8E,status_secondary(a2)							; sets Status_Shield, Status_FireShield, Status_LtngShield, and Status_BublShield to 0
		move.l	#Obj_InstaShield,address(a0)						; replace the Lightning Shield with the Insta-Shield

.return
		rts
; ---------------------------------------------------------------------------

.flashwater
		move.l	#Obj_LightningShield_DestroyUnderwater2,address(a0)
		andi.b	#$8E,status_secondary(a2)							; sets Status_Shield, Status_FireShield, Status_LtngShield, and Status_BublShield to 0

		; Flashes the underwater palette white
		lea	(Water_palette).w,a1
		lea	(Target_water_palette).w,a2
		moveq	#(128/4)-1,d0										; size of Water_palette/4-1

.loop
		move.l	(a1),(a2)+										; backup palette entries
		move.l	#$0EEE0EEE,(a1)+								; overwrite palette entries with white
		dbf	d0,.loop												; loop until entire thing is overwritten
		move.b	#3,anim_frame_timer(a0)
		rts

; ---------------------------------------------------------------------------
; Create Lightning Shield (Spark)
; ---------------------------------------------------------------------------

SparkVelocities:	; x_vel, y_vel
		dc.w -$200, -$200
		dc.w $200, -$200
		dc.w -$200, $200
		dc.w $200, $200

; =============== S U B R O U T I N E =======================================

Obj_LightningShield_Create_Spark:
		moveq	#1,d2											; set anim

.part2															; skip anim
		lea	SparkVelocities(pc),a2
		moveq	#4-1,d1

.loop
		jsr	(Create_New_Sprite).w				; find free object slot
		bne.s	.return						; if one can't be found, return
		move.l	#Obj_LightningShield_Spark,address(a1)		; make new object a Spark
		move.w	x_pos(a0),x_pos(a1)				; (Spark) inherit x_pos from source object (Lightning Shield, Hyper Sonic Stars)
		move.w	y_pos(a0),y_pos(a1)				; (Spark) inherit y_pos from source object (Lightning Shield, Hyper Sonic Stars)
		move.l	mappings(a0),mappings(a1)			; (Spark) inherit mappings from source object (Lightning Shield, Hyper Sonic Stars)
		move.w	art_tile(a0),art_tile(a1)			; (Spark) inherit art_tile from source object (Lightning Shield, Hyper Sonic Stars)
		move.b	#ren_camerapos,render_flags(a1)
		move.w	#make_priority(1),priority(a1)
		move.w	#bytes_to_word(16/2,16/2),height_pixels(a1)	; set height and width
		move.b	d2,anim(a1)
		move.l	(a2)+,x_vel(a1)					; (Spark) give x_vel and y_vel (unique to each of the four Sparks)
		dbf	d1,.loop

.return
		rts

; ---------------------------------------------------------------------------
; Lightning Shield (Spark)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_LightningShield_Spark:
		jsr	(MoveSprite2).w
		addi.w	#$18,y_vel(a0)
		lea	Ani_LightningShield(pc),a1
		jsr	(Animate_Sprite).w
		tst.b	routine(a0)											; changed by Animate_Sprite
		bne.s	.delete
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

.delete
		jmp	(Delete_Current_Sprite).w

; =============== S U B R O U T I N E =======================================

Obj_LightningShield_DestroyUnderwater2:
		subq.b	#1,anim_frame_timer(a0)							; is it time to end the white flash?
		bpl.s	.return											; if not, return
		move.l	#Obj_InstaShield,address(a0)						; replace Lightning Shield with Insta-Shield
		lea	(Target_water_palette).w,a1
		lea	(Water_palette).w,a2
		moveq	#(128/4)-1,d0										; size of Water_palette/4-1

.loop
		move.l	(a1)+,(a2)+										; restore backed-up underwater palette
		dbf	d0,.loop												; loop until entire thing is restored

.return
		rts

; ---------------------------------------------------------------------------
; Bubble Shield
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_BubbleShield:

		; init
		move.l	#Map_BubbleShield,mappings(a0)
		move.l	#words_to_long(make_priority(1),make_art_tile(ArtTile_Shield,0,0)),priority(a0)
		move.l	#bytes_to_long(ren_camerapos,objflag_continue,48/2,48/2),render_flags(a0)
		SetDPLC_Macro DPLC_BubbleShield,ArtUnc_BubbleShield,ArtTile_Shield
		btst	#7,(Player_1+art_tile).w
		beq.s	.nothighpriority
		bset	#7,art_tile(a0)

.nothighpriority
		move.w	#1,anim(a0)										; clear anim and set prev_anim to 1
		lea	(Player_1).w,a1
		jsr	(Player_ResetAirTimer).l
		move.l	#.main,address(a0)

.main
		movea.w	Shield_PlayerAddr(a0),a2
	;	btst	#Status_Invincible,status_secondary(a2)		; is player invincible?
	;	bne.s	.return						; if so, do not display and do not update variables
		cmpi.b	#id_Null,anim(a2)								; is player in their 'blank' animation?
		beq.s	.return											; if so, do not display and do not update variables
		btst	#Status_Shield,status_secondary(a2)						; should the player still have a shield?
		beq.s	.destroy											; if not, change to Insta-Shield
		move.w	x_pos(a2),x_pos(a0)
		move.w	y_pos(a2),y_pos(a0)
		move.b	status(a2),status(a0)								; inherit status
		andi.b	#1,status(a0)										; limit inheritance to 'orientation' bit
		tst.b	(Reverse_gravity_flag).w
		beq.s	.normalgravity
		ori.b	#2,status(a0)										; reverse the vertical mirror render_flag bit (On if Off beforehand and vice versa)

.normalgravity
		andi.w	#drawing_mask,art_tile(a0)
		tst.w	art_tile(a2)
		bpl.s	.nothighpriority2
		ori.w	#high_priority,art_tile(a0)

.nothighpriority2
		lea	Ani_BubbleShield(pc),a1
		jsr	(Animate_Sprite).w
		bsr.w	PLCLoad_Shields
		jmp	(Draw_Sprite).w
; ---------------------------------------------------------------------------

.destroy
		andi.b	#$8E,status_secondary(a2)							; sets Status_Shield, Status_FireShield, Status_LtngShield, and Status_BublShield to 0
		move.l	#Obj_InstaShield,address(a0)						; replace the Bubble Shield with the Insta-Shield

.return
		rts

; ---------------------------------------------------------------------------
; Insta Shield
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Obj_InstaShield:

		; init
		move.l	#Map_InstaShield,mappings(a0)
		move.l	#words_to_long(make_priority(1),make_art_tile(ArtTile_Shield,0,0)),priority(a0)
		move.l	#bytes_to_long(ren_camerapos,objflag_continue,48/2,48/2),render_flags(a0)
		SetDPLC_Macro DPLC_InstaShield,ArtUnc_InstaShield,ArtTile_Shield
		btst	#7,(Player_1+art_tile).w
		beq.s	.nothighpriority
		bset	#7,art_tile(a0)

.nothighpriority
		move.w	#1,anim(a0)							; clear anim and set prev_anim to 1
;		move.l	address(a0),LastLoadedShield(a0)	; just in case
		move.l	#.main,address(a0)

.main
		movea.w	Shield_PlayerAddr(a0),a2
	;	btst	#Status_Invincible,status_secondary(a2)		; is the player invincible?
	;	bne.s	Obj_BubbleShield.return				; if so, return
		move.w	x_pos(a2),x_pos(a0)						; inherit player's x_pos
		move.w	y_pos(a2),y_pos(a0)						; inherit player's y_pos
		move.b	status(a2),status(a0)						; inherit status
		andi.b	#1,status(a0)							; limit inheritance to 'orientation' bit
		tst.b	(Reverse_gravity_flag).w
		beq.s	.normalgravity
		ori.b	#2,status(a0)			; reverse the vertical mirror render_flag bit (On if Off beforehand and vice versa)

.normalgravity
		andi.w	#drawing_mask,art_tile(a0)
		tst.w	art_tile(a2)
		bpl.s	.nothighpriority2
		ori.w	#high_priority,art_tile(a0)

.nothighpriority2
		lea	Ani_InstaShield(pc),a1
		jsr	(Animate_Sprite).w
		cmpi.b	#7,mapping_frame(a0)							; has it reached then end of its animation?
		bne.s	.notover											; if not, branch
		tst.b	double_jump_flag(a2)									; is it in its attacking state?
		beq.s	.notover											; if not, branch
		move.b	#2,double_jump_flag(a2)							; mark attack as over

.notover
		tst.b	mapping_frame(a0)									; is this the first frame?
		beq.s	.loadnewdplc										; if so, branch and load the DPLC for this and the next few frames
		cmpi.b	#3,mapping_frame(a0)							; is this the third frame?
		bne.s	.skipdplc											; if not, branch as we don't need to load another DPLC yet

.loadnewdplc
		bsr.s	PLCLoad_Shields

.skipdplc
		jmp	(Draw_Sprite).w

; ---------------------------------------------------------------------------
; Shields (DPLC)
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

PLCLoad_Shields:
		moveq	#0,d0
		move.b	mapping_frame(a0),d0
		cmp.b	LastLoadedDPLC(a0),d0
		beq.s	.return
		move.b	d0,LastLoadedDPLC(a0)
		movea.l	DPLC_Address(a0),a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d5
		subq.w	#1,d5
		bmi.s	.return
		move.w	vram_art(a0),d4

.readentry
		moveq	#0,d1
		move.w	(a2)+,d1
		move.w	d1,d3
		lsr.w	#8,d3
		andi.w	#$F0,d3
		addi.w	#$10,d3
		andi.w	#$FFF,d1
		lsl.l	#4,d1
		add.l	Art_Address(a0),d1
		move.w	d4,d2
		add.w	d3,d4
		add.w	d3,d4
		jsr	(Add_To_DMA_Queue).w
		dbf	d5,.readentry

.return
		rts
; ---------------------------------------------------------------------------

		include "Objects/Shields/Invincibility.asm"
;		include "Objects/Shields/Super Stars.asm"
; ---------------------------------------------------------------------------

Map_Invincibility:	include "Objects/Shields/Object Data/Map - Invincibility.asm"
		include "Objects/Shields/Object Data/Anim - Fire Shield.asm"
		include "Objects/Shields/Object Data/Map - Fire Shield.asm"
		include "Objects/Shields/Object Data/DPLC - Fire Shield.asm"
		include "Objects/Shields/Object Data/Anim - Lightning Shield.asm"
Map_LightningShield:	include "Objects/Shields/Object Data/Map - Lightning Shield.asm"
		include "Objects/Shields/Object Data/DPLC - Lightning Shield.asm"
		include "Objects/Shields/Object Data/Anim - Bubble Shield.asm"
Map_BubbleShield:	include "Objects/Shields/Object Data/Map - Bubble Shield.asm"
DPLC_BubbleShield:	include "Objects/Shields/Object Data/DPLC - Bubble Shield.asm"
		include "Objects/Shields/Object Data/Anim - Insta-Shield.asm"
		include "Objects/Shields/Object Data/Map - Insta-Shield.asm"
		include "Objects/Shields/Object Data/DPLC - Insta-Shield.asm"

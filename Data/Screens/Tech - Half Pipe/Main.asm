HDPipe_VDP:
	dc.w	$8B03	; EXT-INT disabled, V scroll by screen, H scroll by line
	dc.w	$8004
	dc.w	$8ADF
	dc.w	$8200|(VRAM_SS_Plane_A_Name_Table1/$400)
	dc.w	$8400|(VRAM_SS_Plane_B_Name_Table/$2000)
	dc.w	$8C08		; H res 32 cells, no interlace, S/H enabled
	dc.w	$9003		; Scroll table size: 128x32
	dc.w	$8730		; Background palette: PAL3-0
	dc.w	$8D00|(VRAM_SS_Horiz_Scroll_Table/$400)		; H scroll table base: $FC00
	dc.w	$8500|(VRAM_SS_Sprite_Attribute_Table/$200)	; Sprite attribute table base: $F800
	dc.w	0
; ===========================================================================
; loc_4F64:
SpecialStage:
	cmpi.b	#7,(Current_Special_Stage).w
	blo.s	+
	clr.b	(Current_Special_Stage).w
+
	sfx	SndID_SpecStageEntry	; play that funky special stage entry sound
	music	MusID_FadeOut		; fade out the music
	bsr.w	Pal_FadeToWhite

	lea	Detect_VDP(pc),a1
	jsr	(Load_VDP).w
	disableScreen (a6)
;	lea	(VDP_control_port).l,a6
	ResetDMAQueue
	dmaFillVRAM 0,VRAM_SS_Plane_A_Name_Table2,VRAM_SS_Plane_Table_Size ; clear Plane A pattern name table 1
	dmaFillVRAM 0,VRAM_SS_Plane_A_Name_Table1,VRAM_SS_Plane_Table_Size ; clear Plane A pattern name table 2
	dmaFillVRAM 0,VRAM_SS_Plane_B_Name_Table,VRAM_SS_Plane_Table_Size ; clear Plane B pattern name table
	dmaFillVRAM 0,VRAM_SS_Horiz_Scroll_Table,VRAM_SS_Horiz_Scroll_Table_Size  ; clear Horizontal scroll table

	clearRAM Sprite_Table,Sprite_Table_End
	clearRAM SS_Horiz_Scroll_Buf_1,SS_Horiz_Scroll_Buf_1_End
	clearRAM SS_Shared_RAM,SS_Shared_RAM_End
	clearRAM Sprite_Table_Input,Sprite_Table_Input_End
	clearRAM Object_RAM,Object_RAM_End
	clr.l	(Vscroll_Factor).w
	clr.b	(SpecialStage_Started).w
	clr.w	(SpecialStage_CurrentSegment).w
	clr.b	(Level_started_flag).w
	clr.l	(Camera_X_pos).w	; fixes rendering
	clr.l	(Camera_Y_pos).w
	clr.l	(Camera_X_pos_copy).w
	clr.l	(Camera_Y_pos_copy).w

	lea	(VDP_control_port).l,a6
	move.w	#$8F02,(a6)		; VRAM pointer increment: $0002
	bsr.w	HdPipe_LoadGraphics
	bsr.w	HDPipe_LoadPlayer
	bsr.w	HDPipe_LoadBackground
	bsr.w	ssInitTableBuffers
	bsr.w	ssLdComprsdData
	move.l	#$C0000,(SS_New_Speed_Factor).w

	move.b	#VintID_CtrlDMA,(Vint_routine).w
	bsr.w	WaitForVint
	moveq	#signextendB(MusID_SpecStage),d0
	bsr.w	PlayMusic
	move.w	(VDP_Reg1_val).w,d0
	ori.b	#$40,d0
	move.w	d0,(VDP_control_port).l
	bsr.w	Pal_FadeFromWhite
	move.b	#Vint_HDPipe,(Vint_routine).w
.mainloop
	bsr.w	PauseGame
	jsr	(Process_Kos_Queue).w
	bsr.w	WaitForVint
	bsr.w	SSTrack_Draw
	bsr.w	SSSetGeometryOffsets
	bsr.w	SSLoadCurrentPerspective
	bsr.w	SSObjectsManager
	bsr.w	SS_ScrollBG
	bsr.w	PalCycle_SS
	move.w	(Ctrl_1).w,(Ctrl_1_Logical).w
	move.w	(Ctrl_2).w,(Ctrl_2_Logical).w
	jsr	(RunObjects).l
	tst.b	(SS_Check_Rings_flag).w
	bne.s	+
	jsr	(BuildSprites).l
	jsr	(HDPipe_BuildShadows).l	; shadow rendering routine
	bsr.w	RunPLC_RAM
	bra.s	.mainloop
; ===========================================================================
+
	andi.b	#7,(Emerald_count).w
	move.w	(Ring_count).w,d0
	add.w	(Ring_count_2P).w,d0
+
	cmp.w	(SS_Perfect_rings_left).w,d0
	bne.s	+
	st.b	(Perfect_rings_flag).w
+
	bsr.w	Pal_FadeToWhite
	tst.b	(Two_player_mode_copy).w
	bne.w	loc_540C
	move	#$2700,sr
	lea	(VDP_control_port).l,a6
	move.w	#$8200|(VRAM_Menu_Plane_A_Name_Table/$400),(a6)		; PNT A base: $C000
	move.w	#$8400|(VRAM_Menu_Plane_B_Name_Table/$2000),(a6)	; PNT B base: $E000
	move.w	#$9001,(a6)		; Scroll table size: 64x32
	move.w	#$8C81,(a6)		; H res 40 cells, no interlace, S/H disabled
	bsr.w	ClearScreen
	jsrto	Hud_Base, JmpTo_Hud_Base

	move	#$2300,sr
	moveq	#PalID_Result,d0
	bsr.w	PalLoad_Now
	moveq	#PLCID_Std1,d0
	bsr.w	LoadPLC2
	move.l	#vdpComm(tiles_to_bytes(ArtTile_VRAM_Start+2),VRAM,WRITE),d0
	lea	SpecialStage_ResultsLetters(pc),a0
	jsrto	LoadTitleCardSS, JmpTo_LoadTitleCardSS
	move.l	#vdpComm(tiles_to_bytes(ArtTile_ArtNem_SpecialStageResults),VRAM,WRITE),(VDP_control_port).l
	lea	(ArtNem_SpecialStageResults).l,a0
	bsr.w	NemDec
	move.w	(Player_mode).w,d0
	beq.s	++
	subq.w	#1,d0
	beq.s	+
	clr.w	(Ring_count).w
	bra.s	++
; ===========================================================================
+
	clr.w	(Ring_count_2P).w
+
	move.w	(Ring_count).w,(Bonus_Countdown_1).w
	move.w	(Ring_count_2P).w,(Bonus_Countdown_2).w
	clr.w	(Total_Bonus_Countdown).w
	tst.b	(Got_Emerald).w
	beq.s	+
	move.w	#1000,(Total_Bonus_Countdown).w
+
	move.b	#1,(Update_HUD_score).w
	move.b	#1,(Update_Bonus_score).w
	moveq	#signextendB(MusID_EndLevel),d0
	jsr	(PlaySound).w

	clearRAM Sprite_Table_Input,Sprite_Table_Input_End
	clearRAM Object_RAM,Object_RAM_End

	move.b	#ObjID_SSResults,(SpecialStageResults+id).w ; load Obj6F (special stage results) at $FFFFB800
-
	move.b	#VintID_Level,(Vint_routine).w
	bsr.w	WaitForVint
	jsr	(RunObjects).l
	jsr	(BuildSprites).l
	bsr.w	RunPLC_RAM
	tst.w	(Level_Inactive_flag).w
	beq.s	-
	tst.l	(Plc_Buffer).w
	bne.s	-
	moveq	#signextendB(SndID_SpecStageEntry),d0
	bsr.w	PlaySound
	bsr.w	Pal_FadeToWhite
	tst.b	(Two_player_mode_copy).w
	bne.s	loc_540C
	move.b	#GameModeID_Level,(Game_Mode).w ; => Level (Zone play mode)
	rts
; ===========================================================================

loc_540C:
	move.w	#VsRSID_SS,(Results_Screen_2P).w
	move.b	#GameModeID_2PResults,(Game_Mode).w ; => TwoPlayerResults
	rts
; ===========================================================================

; loc_541A:
SpecialStage_Unpause:
	move.b	#MusID_Unpause,(Sound_Queue.Music0).w
	move.b	#VintID_Level,(Vint_routine).w
	bra.w	WaitForVint

; ===========================================================================
; ---------------------------------------------------------------------------
; Animated color of the twinkling stars in the special stage background
; ---------------------------------------------------------------------------
; loc_542A: Pal_UNK8:
Pal_SpecialStageStars:	; TODO:  maybe do an interleaved format?
	dc.w	$EEE,$CCC,$AAA,$888
.star2
	dc.w	$888,$AAA,$CCC,$EEE	; star 1 ends here
	dc.w	$EEE,$CCC,$AAA,$888	; star 2 ends here

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_543A
PalCycle_SS:
	tst.b	(HalfPipe_Seizure).w	; did you collect the final emerald?
	bne.s	SSCheckpoint_rainbow	; if so, give autistic people a fucking seizure
	move.b	(Vint_runcount+3).w,d0
	andi.b	#3,d0
	bne.s	.testgateanim
	move.b	(SS_Star_color).w,d0
	addq.b	#2,(SS_Star_color).w
	andi.w	#%00001110,d0	; 8 frames
	move.w	Pal_SpecialStageStars(pc,d0.w),(Normal_palette_line4+$1C).w
	addq.w	#Pal_SpecialStageStars.star2-Pal_SpecialStageStars,d0
	move.w	Pal_SpecialStageStars(pc,d0.w),(Normal_palette_line4+$1E).w

.testgateanim
	tst.b	(SS_Checkpoint_Rainbow_flag).w
	beq.s	.rts	; rts
	move.b	(Vint_runcount+3).w,d0
	andi.b	#7,d0
	bne.s	.rts	; rts
	move.w	(SS_Rainbow_palette).w,d0
	addq.w	#6,(SS_Rainbow_palette).w
	cmpi.w	#PalCycle_SS.gaywrath-PalCycle_SS.gaypride,(SS_Rainbow_palette).w
	blo.s	.notyet
	clr.w	(SS_Rainbow_palette).w
.notyet
	move.l	.gaypride(pc,d0.w),(Normal_palette_line+$16).w
	move.w	.gaypride+4(pc,d0.w),(Normal_palette_line+$1A).w
.rts
	rts
; ===========================================================================
; special stage rainbow blinking sprite palettes
.gaypride	; gay pride is over
	dc.w $0EE,$0CC,$088
	dc.w $0E0,$0C0,$080
	dc.w $EE0,$CC0,$880
	dc.w $E0E,$C0C,$808
.gaywrath	; it's time for gay wrath
; ===========================================================================

;loc_54DC
SSCheckpoint_rainbow:
	tst.b	(SS_Pause_Only_flag).w
	beq.s	.rts
	move.b	(Vint_runcount+3).w,d0
	andi.w	#1,d0
	bne.s	.rts
	lea	(Normal_palette+4).w,a0
	lea	(a0),a1
	move.w	(a0)+,d0	; save for the end
	moveq	#(13-1)-1,d1
-	move.w	(a0)+,(a1)+
	dbf	d1,-
	move.w	d0,(a1)
.rts
	rts
; End of function PalCycle_SS


;|||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_5514
SSLoadCurrentPerspective:
	cmpi.b	#4,(SSTrack_drawing_index).w
	bne.s	+	; rts
	movea.l	#SSRAM_MiscKoz_SpecialPerspective,a0
	moveq	#0,d0
	move.b	(SSTrack_mapping_frame).w,d0
	add.w	d0,d0
	adda.w	(a0,d0.w),a0
	move.l	a0,(SS_CurrentPerspective).w
+	rts
; End of function SSLoadCurrentPerspective


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_5534
SSObjectsManager:
	cmpi.b	#4,(SSTrack_drawing_index).w
	bne.w	return_55DC
	moveq	#0,d0
	move.b	(SpecialStage_CurrentSegment).w,d0
	cmp.b	(SpecialStage_LastSegment2).w,d0
	beq.w	return_55DC
	move.b	d0,(SpecialStage_LastSegment2).w
	movea.l	(SS_CurrentLevelLayout).w,a1
	move.b	(a1,d0.w),d3
	andi.w	#$7F,d3
	lea	(Ani_SSTrack_Len).l,a0
	move.b	(a0,d3.w),d3
	add.w	d3,d3
	add.w	d3,d3
	movea.l	(SS_CurrentLevelObjectLocations).w,a0
-
	bsr.w	SSSingleObjLoad
	bne.s	return_55DC
	moveq	#0,d0
	move.b	(a0)+,d0
	bmi.s	++
	move.b	d0,d1
	andi.b	#$40,d1
	bne.s	+
	addq.w	#1,(SS_Perfect_rings_left).w
	move.b	#ObjID_SSRing,id(a1)
	add.w	d0,d0
	add.w	d0,d0
	add.w	d3,d0
	move.w	d0,objoff_30(a1)
	move.b	(a0)+,angle(a1)
	bra.s	-
; ===========================================================================
+
	andi.w	#$3F,d0
	move.b	#ObjID_SSBomb,id(a1)
	add.w	d0,d0
	add.w	d0,d0
	add.w	d3,d0
	move.w	d0,objoff_30(a1)
	move.b	(a0)+,angle(a1)
	bra.s	-
; ===========================================================================
+
	move.l	a0,(SS_CurrentLevelObjectLocations).w
	addq.b	#1,d0
	beq.s	return_55DC
	addq.b	#1,d0
	beq.s	++
	addq.b	#1,d0
	beq.s	+
	st.b	(SS_NoCheckpoint_flag).w
	sf.b	(SS_NoCheckpointMsg_flag).w
	bra.s	++
; ===========================================================================
+
	tst.b	(SS_2p_Flag).w
	bne.s	+
	move.b	#ObjID_SSEmerald,id(a1)
	rts
; ===========================================================================
+
	move.b	#ObjID_SSMessage,id(a1)

return_55DC:
	rts
; End of function SSObjectsManager

; ===========================================================================

HDPipe_LoadPlayer:
	cmpi.w	#1,(Player_mode).w	; is this a Tails alone game?
	bgt.s	+			; if yes, branch
	move.b	#ObjID_SonicSS,(MainCharacter+id).w ; load Obj09 (special stage Sonic)
	tst.w	(Player_mode).w		; is this a Sonic and Tails game?
	bne.s	++			; if not, branch
+
	move.b	#ObjID_TailsSS,(Sidekick+id).w ; load Obj10 (special stage Tails)
+
	move.b	#ObjID_SSHUD,(SpecialStageHUD+id).w ; load Obj5E (special stage HUD)
	move.b	#ObjID_StartBanner,(SpecialStageStartBanner+id).w ; load Obj5F (special stage banner)
	move.b	#ObjID_SSNumberOfRings,(SpecialStageNumberOfRings+id).w ; load Obj87 (special stage ring count)
	move.w	#$80,(SS_Offset_X).w
	move.w	#$36,(SS_Offset_Y).w
	rts
; ===========================================================================

HDPipe_BuildShadows:
		tst.w	d7
		bmi.s	.end
; init shadow data
		lea	(Map_HDPipe_Shadow),a2
; init object check
		lea	(Sprite_table_input).w,a5
		lea	(Sprite_table_buffer).w,a6
; check viable objects
.lvlloop
		tst.w	(a5)			; does this level have any objects?
		beq.s	.nextlvl		; if not, check the next one
.fromnextlevel
		lea	2(a5),a4
.objloop
		movea.w	(a4)+,a0
		tst.l	address(a0)		; is there even an object?
		beq.s	.nextobj		; if not, branch
		tst.b	render_flags(a0)	; did it render?
		bpl.s	.nextobj		; if not, branch
		btst	#6,object_flags(a0)	; does the object want to render a shadow?
		beq.s	.nextobj		; if not, branch
; render shadow
		moveq	#0,d2
	; TODO: figure out which type of shadow it wants
		lsl.w	#3,d2
		lea	(a2),a1
		adda.w	d2,a1
		move.w	x_pos(a0),d0
		move.w	y_pos(a0),d1

		move.w	(a1)+,d2	; get ypos
		add.w	d1,d2		; add object ypos
		move.w	d2,(a6)+	; render
		move.b	(a1)+,(a6)+	; send tile size
		addq.w	#1,a1
		addq.w	#1,a6		; skip sprite link
		move.l	(a1)+,d2	; get xpos and art tile
		add.w	d0,d2		; add object xpos
		move.l	d2,(a6)+	; render

		subq.w	#1,d7
		bmi.s	.end
.nextobj
		subq.w	#2,(a5)
		bne.s	.objloop
.nextlvl
		lea	next_priority(a5),a5
		cmpa.w	#Sprite_table_input_end,a5
		blo.s	.lvlloop
.end
		rts

spritePieceIsolated macro xpos,ypos,width,height,tile,xflip,yflip,pal,pri
	dc.w	ypos
	dc.b	(((width-1)&3)<<2)|((height-1)&3)
	dc.b	0	; unused
	dc.w	((pri&1)<<15)|((pal&3)<<13)|((yflip&1)<<12)|((xflip&1)<<11)|(tile&$7FF)
	dc.w	xpos
	endm
; 9 frames each, biggest to smallest
Map_HDPipe_Shadow:
.straight
	spritePieceIsolated
.side
.edge
; ---------------------------------------------------------------------------
; Level
; ---------------------------------------------------------------------------

Level_VDP:
		dc.w $8004			; disable HInt, HV counter, 8-colour mode
		dc.w $8200+(vram_fg>>10)	; set foreground nametable address
		dc.w $8300+(vram_window>>10)	; set window nametable address
		dc.w $8400+(vram_bg>>13)	; set background nametable address
		dc.w $8700+(2<<4)		; set background colour (line 3; colour 0)
		dc.w $8B03			; line scroll mode
		dc.w $8C81			; set 40cell screen size, no interlacing, no s/h
		dc.w $9001			; 64x32 cell nametable area
		dc.w $9100			; set window H position at default
		dc.w $9200			; set window V position at default
		dc.w 0				; end

; =============== S U B R O U T I N E =======================================

Level_Screen:
		bset	#GameModeFlag_TitleCard,(Game_mode).w					; set bit 7 is indicate that we're loading the level
		music	mus_Fade											; fade out music
		jsr	(Clear_Kos_Module_Queue).w								; clear KosM PLCs
		jsr	(Pal_FadeToBlack).w
		disableInts
		move.l	#VInt,(V_int_addr).w
		move.l	#HInt,(H_int_addr).w
		jsr	(Clear_DisplayData).w
		enableInts
		tst.b	(Last_star_post_hit).w
		beq.s	.nostarpost											; if no starpost was set, branch
		move.w	(Saved_zone_and_act).w,(Current_zone_and_act).w
		move.w	(Saved_apparent_zone_and_act).w,(Apparent_zone_and_act).w

.nostarpost
		clearRAM Object_RAM, Object_RAM_end
		clr.b	(ObjectFreezeFlag).w
		clearRAM Lag_frame_count, Lag_frame_count_end
		clearRAM Camera_RAM, Camera_RAM_end
		clearRAM Oscillating_variables, Oscillating_variables_end
		lea	Level_VDP(pc),a1
		jsr	(Load_VDP).w

	if GameDebug
		btst	#button_C,(Ctrl_1_held).w									; is C button held?
		beq.s	.cnotheld												; if not, branch
		move.w	#$8C89,VDP_control_port-VDP_control_port(a6)			; set shadow/highlight mode

.cnotheld
		btst	#button_A,(Ctrl_1_held).w									; is A button held?
		beq.s	.anotheld												; if not, branch
		move.b	#1,(Debug_mode_flag).w 								; enable debug mode

.anotheld
	endif

		move.w	#$8A00+255,(H_int_counter_command).w				; set palette change position (for water)
		move.w	(H_int_counter_command).w,VDP_control_port-VDP_control_port(a6)
		ResetDMAQueue

		; load palette
		moveq	#palid_Sonic,d0
		cmpi.w	#3,(Player_mode).w
		bne.s	.notknux
		moveq	#palid_Knuckles,d0

.notknux
		move.w	d0,d1
		jsr	(LoadPalette).w											; load Player's palette
		move.w	d1,d0
		jsr	(LoadPalette_Immediate).w

		jsr	(CheckLevelForWater).l
		clearRAM Water_palette_line_2, Normal_palette
		tst.b	(Water_flag).w
		beq.s	.notwater
		move.w	#$8014,VDP_control_port-VDP_control_port(a6)			; H-int enabled

		; load water palette
		moveq	#palid_WaterSonic,d0
		cmpi.w	#3,(Player_mode).w
		bne.s	.notwaterknux
		moveq	#palid_WaterKnuckles,d0

.notwaterknux
		move.w	d0,d1
		jsr	(LoadPalette2).w											; load Player's water palette
		move.w	d1,d0
		jsr	(LoadPalette2_Immediate).w

.notwater
		move.w	(Current_zone_and_act).w,d0
		ror.b	#2,d0
		lsr.w	#6,d0
		lea	(LevelMusic_Playlist).l,a1				; load music playlist
		move.b	(a1,d0.w),d0
		move.w	d0,(Current_music).w
		music								; play music
		move.l	#Obj_TitleCard,(Dynamic_object_RAM+(object_size*5)).w	; load title card object
		move.l	#VInt_Fade,(V_int_routine).w

-		jsr	(Process_Kos_Queue).w
		jsr	(Wait_VSync).w
		jsr	(Process_Sprites).w
		jsr	(Render_Sprites).w
		jsr	(Process_Kos_Module_Queue).w
		tst.w	(Kos_modules_left).w					; are there any items in the pattern load cue?
		bne.s	-							; if yes, branch
		move.w	#cAqua,(Normal_palette).w	; mark palette
; for better use of loading time
		move.w	(Player_mode).w,d0
		add.w	d0,d0
		add.w	d0,d0
		lea	PLC_PlayerIndex(pc),a5
		movea.l	(a5,d0.w),a5
		jsr	(LoadPLC_Raw_KosM).w		; load hud and ring art
		jsr	(LoadLevelLoadBlock).w

-		jsr	(Process_Kos_Queue).w
		jsr	(Wait_VSync).w
		jsr	(Process_Sprites).w
		jsr	(Render_Sprites).w
		jsr	(Process_Kos_Module_Queue).w
		tst.w	(Kos_modules_left).w					; are there any items in the pattern load cue?
		bne.s	-							; if yes, branch
		move.w	#cGreen,(Normal_palette).w	; mark palette
		tst.w	(Dynamic_object_RAM+(object_size*5)+objoff_48).w	; has title card sequence finished?
		bne.s	-							; if not, branch

	;	move.w	#cRed,(Normal_palette).w	; mark palette
		jsr	(LoadLevelPointer).w
		jsr	(Get_LevelSizeStart).l
		jsr	(DeformBgLayer).w
		jsr	(LoadLevelLoadBlock2).w
		jsr	(Load_Solids).w
	;	disableInts
		jsr	(LevelSetup).l
		jsr	(HUD_DrawInitial).w
	;	enableInts
		jsr	(Handle_Onscreen_Water_Height).l
		moveq	#0,d0
		move.l	d0,(Ctrl1).w
		move.l	d0,(Ctrl2).w
		move.l	d0,(Ctrl1_Player).w
		move.l	d0,(Ctrl2_Player).w
		move.b	d0,(HUD_RAM.status).w
		tst.b	(Last_star_post_hit).w							; are you starting from a starpost?
		bne.s	.starpost									; if yes, branch
		move.w	d0,(Ring_count).w						; clear rings
		move.l	d0,(Timer).w								; clear time
		move.b	d0,(Extra_life_flags).w
		move.b	d0,(Saved_status_secondary).w
		move.b	d0,(Respawn_table_keep).w

.starpost
		move.b	d0,(Time_over_flag).w
		jsr	(OscillateNumInit).w
		moveq	#1,d0
		move.b	d0,(Ctrl_1_locked).w
		move.b	d0,(Ctrl_2_locked).w
		move.b	d0,(Update_HUD_score).w					; update score counter
		move.b	d0,(Update_HUD_ring_count).w			; update rings counter
		move.b	d0,(Update_HUD_timer).w					; update time counter
		move.b	d0,(Level_started_flag).w
		move.l	#Load_Sprites_Init,(Object_load_addr_RAM).w
		move.l	#Load_Rings_Init,(Rings_manager_addr_RAM).w
		tst.b	(Water_flag).w
		beq.s	.notwater2
		move.l	#Obj_WaterWave,(v_WaterWave).w

.notwater2
		bsr.w	SpawnLevelMainSprites
		jsr	(Load_Sprites).w
		jsr	(Load_Rings).w
		jsr	(Process_Sprites).w
		jsr	(Render_Sprites).w
		jsr	(Animate_Tiles).l
		jsr	(LoadWaterPalette).l
		clearRAM Water_palette_line_2, Normal_palette
		move.w	#bytes_to_word(16*2,48-1),(Palette_fade_info).w	; set fade info and fade count
		jsr	(Pal_FillBlack).w
		moveq	#22,d0
		move.w	d0,(Palette_fade_timer).w								; time for Pal_FromBlack
		move.w	d0,(Dynamic_object_RAM+(object_size*5)+objoff_2E).w	; time for Title Card
		move.b	#$7F,(Ctrl_1_held).w
		move.b	#$7F,(Ctrl_2_held).w
		andi.b	#$7F,(Last_star_post_hit).w
		jsr	(Wait_VSync).w		; add a bit of delay for frame timing. Remove if unnecessary
		bclr	#GameModeFlag_TitleCard,(Game_mode).w		; subtract $80 from mode to end pre-level stuff
		move.l	#VInt_Level,(V_int_routine).w

		move.w	(Target_palette).w,(Normal_palette).w	;
.loop
		jsr	(Pause_Game).w
		jsr	(Process_Kos_Queue).w
		jsr	(Wait_VSync).w
		addq.w	#1,(Level_frame_counter).w
; handle object code first
		jsr	(Load_Sprites).w
		jsr	(Process_Sprites).w
		tst.b	(Restart_level_flag).w	; if object prompts a restart, restart
		bne.w	Level_Screen
; handle level movement
		jsr	(DeformBgLayer).w
		jsr	(ScreenEvents).l
		jsr	(Handle_Onscreen_Water_Height).l
		jsr	(Load_Rings).w
		jsr	(Animate_Palette).l
		jsr	(Animate_Tiles).l
		jsr	(Process_Kos_Module_Queue).w
		jsr	(OscillateNumDo).w
		jsr	(ChangeRingFrame).w
		jsr	(Render_Sprites).w
		move.w	(Ctrl1_Hd).w,d0
		andi.w	#button_mode_mask|button_XYZ_mask,d0	; did P1 press start or mode?
		bne.s	+
		cmpi.b	#id_LevelScreen,(Game_mode).w
		beq.s	.loop
+
		clr.b	(ObjectFreezeFlag).w
		rts
; ---------------------------------------------------------------------------

PLC_PlayerIndex:
		dc.l PLC_Sonic		; 0
		dc.l PLC_Sonic		; 1
		dc.l PLC_Tails		; 2
		dc.l PLC_Knuckles		; 3

; =============== S U B R O U T I N E =======================================

SpawnLevelMainSprites:
		move.l	#Obj_ResetCollisionResponseList,(Reserved_object_3).w
		move.l	#Obj_InstaShield,(v_Shield+address).w
		move.w	#Player_1,(v_Shield+Shield_PlayerAddr).w
		move.w	#v_Tails_tails,(Player_1+playadd_addr).w
		move.w	(Player_mode).w,d0
		bne.s	.sonicalone

		; Sonic and Tails
		move.l	#Obj_Sonic,(Player_1).w
		move.l	#Obj_DashDust,(v_Dust).w
		move.l	#Obj_InstaShield,(v_Shield_P2+address).w
		move.w	#Player_2,(v_Shield_P2+Shield_PlayerAddr).w
		move.l	#Obj_Tails,(Player_2).w
		move.w	#v_Tails_tails_2P,(Player_2+playadd_addr).w
		move.w	(Player_1+x_pos).w,(Player_2+x_pos).w
		move.w	(Player_1+y_pos).w,(Player_2+y_pos).w
		subi.w	#$20,(Player_2+x_pos).w
		addi.w	#4,(Player_2+y_pos).w
		move.l	#Obj_DashDust,(v_Dust_P2).w
		move.w	#0,(Tails_CPU_routine).w
		rts
; ---------------------------------------------------------------------------

.sonicalone
		subq.w	#1,d0
		bne.s	.tailsalone

		; Sonic alone
		move.l	#Obj_Sonic,(Player_1).w
		move.l	#Obj_DashDust,(v_Dust).w
		rts
; ---------------------------------------------------------------------------

.tailsalone
		subq.w	#1,d0
		bne.s	.knuxalone

		; Tails alone
		move.l	#Obj_Tails,(Player_1).w
		move.l	#Obj_DashDust,(v_Dust_P2).w
		addi.w	#4,(Player_1+y_pos).w
		move.w	#0,(Tails_CPU_routine).w
		rts
; ---------------------------------------------------------------------------

.knuxalone

		; Knuckles alone
		move.l	#Obj_Knuckles,(Player_1).w
		move.l	#Obj_DashDust,(v_Dust).w
		rts

; =============== S U B R O U T I N E =======================================

Obj_ResetCollisionResponseList:
		clr.w	(Collision_response_list).w
		rts

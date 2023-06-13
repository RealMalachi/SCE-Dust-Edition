UpdatePaletteVint macro
	tst.b	(Water_full_screen_flag).w
	beq.s	+
	dma68kToVDP Water_palette,$0000,$80,CRAM
	bra.s	++
+	dma68kToVDP Normal_palette,$0000,$80,CRAM
+
	move.w	#bytes_to_word($87,$20),VDP_control_port-VDP_control_port(a5)
	endm
; if PAL, slow down the CPU to umm ehh mmm aaaah
PALAdjustVint macro
;	btst	#6,(Graphics_flags).w
;	beq.s	+			; branch if it's not a PAL system
;	move.w	#$700,d0
;	dbf	d0,*			; otherwise, waste a bit of time here
;+
	endm
; test if the console is currently handling the Vblank
TestVblank macro reg
	if "reg"=""
-	btst	#3,(VDP_control_port+1)
	else
-	btst	#3,reg
	endif
	beq.s	-
	endm
; test if the console is handling a Hblank
TestHblank macro reg
	if "reg"=""
-	btst	#2,(VDP_control_port+1)
	else
-	btst	#2,reg
	endif
	beq.s	-
	endm
; hand-written code would be faster, but these are a massive edgecase
QuickController macro polltype
	if polltype=0
	moveq	#0,d0
	else
	move.w	#bytes_to_word(polltype,polltype),d0
	endif
	lea	(HW_Port_1_Data),a1
	movep.w	d0,HW_Port_1_Data-HW_Port_1_Data(a1)	; poll both control ports at the same time
;	move.l	#words_to_long(polltype,polltype),(HW_Port_1_Data-1)	; poll both control ports at the same time
	move.b	HW_Port_1_Data-HW_Port_1_Data(a1),d0
	move.b	HW_Port_2_Data-HW_Port_1_Data(a1),d1
	endm
; ---------------------------------------------------------------------------
; Vertical interrupt handler
; ---------------------------------------------------------------------------

VInt:
		movem.l	d0-a6,-(sp)				; save all the registers to the stack
		lea	(VDP_data_port).l,a6
		lea	VDP_control_port-VDP_data_port(a6),a5
	;	lea	(VDP_control_port+1)-VDP_data_port(a6),a5
	;TestVblank (VDP_control_port+1)-(VDP_control_port+1)(a5)	; wait until vertical blanking is taking place
	;	subq.w	#1,a5			; VDP_control_port

		tst.b	(V_int_flag).w		; has the game finished its routines before the end of the frame?
		beq.s	VInt_Lag_Main		; if not, handle lag

		move.l	#vdpComm($0000,VSRAM,WRITE),VDP_control_port-VDP_control_port(a5)
		move.l	(V_scroll_value).w,VDP_data_port-VDP_data_port(a6) ; send screen ypos to VSRAM
	PALAdjustVint

		st	(H_int_flag).w		; allow Horizontal Interrupt code to run
		st	(V_int_flag).w		; set that Vsync was successful
		movea.l	(V_int_routine).w,a0	; load address to the gamemodes Vint routine
		jsr	(a0)			; run code

VInt_Music:
		UpdateSoundDriver		; update SMPS	; warning: a5-a6 will be overwritten

VInt_Done:
		jsr	(Random_Number).w
		addq.l	#1,(V_int_run_count).w
	if Lagometer
		move.w	#$9193,(VDP_control_port).l	; window H right side, base point $80
	endif
		movem.l	(sp)+,d0-a6		; return saved registers from the stack
		rte
ExtInt:
	move.l	d0,-(sp)
	sfx	sfx_Menu
	move.l	(sp)+,d0
	rte

; ---------------------------------------------------------------------------
; Lag
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

VInt_Lag:
;		addq.w	#4,sp

VInt_Lag_Main:
		addq.w	#1,(Lag_frame_count).w

		; branch if a level is running
		cmpi.b	#GameModeID_TitleCard|id_LevelScreen,(Game_mode).w
		beq.s	VInt_Lag_Level
		cmpi.b	#id_LevelScreen,(Game_mode).w		; is game on a level?
		beq.s	VInt_Lag_Level
		bra.s	VInt_Music							; otherwise, return from V-int
; ---------------------------------------------------------------------------

VInt_Lag_Level:
		tst.b	(Water_flag).w
		beq.w	VInt_Lag_NoWater
	PALAdjustVint
		st	(H_int_flag).w							; set HInt flag
		stopZ80
	UpdatePaletteVint
		move.w	(H_int_counter_command).w,VDP_control_port-VDP_control_port(a5)
		startZ80
		bra.w	VInt_Music
; ---------------------------------------------------------------------------

VInt_Lag_NoWater:
	PALAdjustVint
		st	(H_int_flag).w
		move.w	(H_int_counter_command).w,VDP_control_port-VDP_control_port(a5)

VInt_Lag_Done:
		bra.w	VInt_Music

; ---------------------------------------------------------------------------
; Main
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

VInt_Main:
		bsr.s	Do_ControllerPal
		tst.w	(Demo_timer).w
		beq.s	.return
		subq.w	#1,(Demo_timer).w
.return
		rts

; ---------------------------------------------------------------------------
; Menu
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

VInt_Menu:
		bsr.s	Do_ControllerPal
		tst.w	(Demo_timer).w
		beq.s	.kosm
		subq.w	#1,(Demo_timer).w
.kosm
		jmp	(Set_Kos_Bookmark).w

; ---------------------------------------------------------------------------
; Fade
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

VInt_Fade:
		bsr.s	Do_ControllerPal
		move.w	(H_int_counter_command).w,VDP_control_port-VDP_control_port(a5)
		jmp	(Set_Kos_Bookmark).w

; ---------------------------------------------------------------------------
; Main updates
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Do_ControllerPal:
		stopZ80
		stopZ802
		jsr	(Poll_Controllers).w
		startZ802
	UpdatePaletteVint
		dma68kToVDP Sprite_table_buffer,vram_sprites,$280,VRAM
		dma68kToVDP H_scroll_buffer,vram_hscroll,(ScreenSize_LineCount<<2),VRAM
		if OptimiseStopZ80=0
		jsr	(Process_DMA_Queue).w
		startZ80
		rts
		else
		jmp	(Process_DMA_Queue).w
		endif

; ---------------------------------------------------------------------------
; Sega
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

VInt_Sega:
		move.b	(V_int_run_count+3).w,d0
		andi.w	#$F,d0
		bne.s	.skip	; run the following code once every 16 frames
		stopZ80
		stopZ802
		jsr	(Poll_Controllers).w
		startZ802
		startZ80
.skip
		tst.w	(Demo_timer).w
		beq.s	.kosm
		subq.w	#1,(Demo_timer).w
.kosm
		jmp	(Set_Kos_Bookmark).w

; ---------------------------------------------------------------------------
; Level
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

VInt_Level:
		stopZ80
		stopZ802
		jsr	(Poll_Controllers).w
		startZ802
		tst.b	(Game_paused).w
		bne.s	VInt_Level_NoNegativeFlash
		tst.b	(Hyper_Sonic_flash_timer).w
		beq.s	VInt_Level_NoFlash

		; flash screen white
		subq.b	#1,(Hyper_Sonic_flash_timer).w
		move.l	#vdpComm($0000,CRAM,WRITE),VDP_control_port-VDP_control_port(a5)
		moveq	#64/2-1,d1
		move.l	#cWhite<<16|cWhite,d0

.copy
		move.l	d0,VDP_data_port-VDP_data_port(a6)
		dbf	d1,.copy	; fill entire palette with white
		bra.w	VInt_Level_Cont
; ---------------------------------------------------------------------------

VInt_Level_NoFlash:
		tst.b	(Negative_flash_timer).w
		beq.s	VInt_Level_NoNegativeFlash

		; flash screen negative
		subq.b	#1,(Negative_flash_timer).w
		btst	#2,(Negative_flash_timer).w
		beq.s	VInt_Level_NoNegativeFlash
		move.l	#vdpComm($0000,CRAM,WRITE),VDP_control_port-VDP_control_port(a5)
		moveq	#64/2-1,d1
		move.l	#$0EEE0EEE,d2
		lea	(Normal_palette).w,a1

.copy
		move.l	(a1)+,d0
		not.l	d0
		and.l	d2,d0
		move.l	d0,VDP_data_port-VDP_data_port(a6)
		dbf	d1,.copy
		bra.s	VInt_Level_Cont
; ---------------------------------------------------------------------------

VInt_Level_NoNegativeFlash:
	UpdatePaletteVint
		move.w	(H_int_counter_command).w,VDP_control_port-VDP_control_port(a5)

VInt_Level_Cont:
		dma68kToVDP H_scroll_buffer,vram_hscroll,(ScreenSize_LineCount<<2),VRAM
		dma68kToVDP Sprite_table_buffer,vram_sprites,80*8,VRAM
		jsr	(Process_DMA_Queue).w
		jsr	(VInt_DrawLevel).w
		startZ80
		enableInts
;		tst.b	(Water_flag).w
;		beq.s	.notwater
;		cmpi.b	#92,(H_int_counter).w	; is H-int occuring on or below line 92?
;		bhs.s	.notwater				; if it is, branch
;		st	(Do_Updates_in_H_int).w
;		jsr	(Set_Kos_Bookmark).w
;		addq.l	#4,sp
;		bra.w	VInt_Done
;.notwater
		bsr.s	Do_Updates
		jmp	(Set_Kos_Bookmark).w

; ---------------------------------------------------------------------------
; Other updates
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Do_Updates:
		tst.w	(Demo_timer).w		; is there time left on the demo?
		beq.s	.return
		subq.w	#1,(Demo_timer).w	; subtract 1 from time left
.return
	;	clr.w	(Lag_frame_count).w
		jmp	(UpdateHUD).w

; ---------------------------------------------------------------------------
; Horizontal interrupt
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

HInt:
	tst.b	(H_int_flag).w
	beq.s	.done
	clr.b	(H_int_flag).w
	TestHblank
	move.w	#bytes_to_word($87,$2B),(VDP_control_port).l
.done
	rte

		disableInts
		tst.b	(H_int_flag).w
		beq.s	HInt_Done
		clr.b	(H_int_flag).w

		move.l	a5,-(sp)
		lea	(VDP_control_port).l,a5
		move.w	#$8A00+223,VDP_control_port-VDP_control_port(a5)
		dma68kToVDP Water_palette,$0000,$80,CRAM
		move.l	(sp)+,a5

	;	tst.b	(Do_Updates_in_H_int).w
	;	beq.s	HInt_Done
	;	clr.b	(Do_Updates_in_H_int).w
	;	movem.l	d0-a6,-(sp)		; move all the registers to the stack
	;	bsr.w	Do_Updates
	;	UpdateSoundDriver		; Update SMPS
	;	movem.l	(sp)+,d0-a6		; load saved registers from the stack
HInt_Done:
		rte

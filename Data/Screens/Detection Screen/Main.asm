; ---------------------------------------------------------------------------
Detect_VDP:
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
	dc.w 0	; end
; ---------------------------------------------------------------------------
; displays data from the hardware detection routines
DetectionScreen:
		lea	Detect_VDP(pc),a1
		jsr	(Load_VDP).w
		disableScreen
		jsr	(Clear_DisplayData).w
		jsr	(Clear_Palette).w
		move.l	#VInt,(V_int_addr).w
		move.l	#HInt,(H_int_addr).w
; load graphics
		ResetDMAQueue
		lea	(ArtKosM_LevelSelectText).l,a1
		move.w	#tiles_to_bytes(1),d2
		jsr	(Queue_Kos_Module).w
		move.l	#VInt_Fade,(V_int_routine).w
.waitplc
		jsr	(Process_Kos_Queue).w
		jsr	(Wait_VSync).w
		jsr	(Process_Kos_Module_Queue).w
		tst.w	(Kos_modules_left).w
		bne.s	.waitplc
		move.l	#VInt_Main,(V_int_routine).w
		jsr	(Wait_VSync).w
		enableScreen
		lea	(Pal_LevelSelect).l,a1
		lea	(Normal_palette).w,a2
		jsr	(PalLoad_Line32).w
		bsr.w	DetectionScreen_LoadText
		move.l	#VInt_Main,(V_int_routine).w
.loop
		jsr	(Wait_VSync).w
		tst.b	(Ctrl1_Hd_ABC).w
		bpl.s	.loop
		move.b	#id_LevelSelectScreen,(Game_mode).w
		rts
; ---------------------------------------------------------------------------
; TODO: this is disgusting
DetectionScreen_LoadText:
		lea	(VDP_data_port).l,a6
		lea	VDP_control_port-VDP_data_port(a6),a5
		lea	Emulators,a4

		locVRAM	(vram_fg+(1*$80)),VDP_control_port-VDP_control_port(a5)
		moveq	#0,d0
		move.b	(Emulator_ID).w,d0
		add.w	d0,d0
		lea	Emulators-Emulators(a4),a0
		move.w	(a0,d0.w),d0
		lea	(a0,d0.w),a0
		bsr	.loadtext

	;	locVRAM	(vram_fg+(2*$80)),VDP_control_port-VDP_control_port(a5)
		moveq	#0,d0
		move.b	(Graphics_flags).w,d0
		lsr.b	#6-1,d0
		lea	Region-Emulators(a4),a0
		move.w	(a0,d0.w),d0
		lea	(a0,d0.w),a0
		bsr	.loadtext

		locVRAM	(vram_fg+(2*$80)),VDP_control_port-VDP_control_port(a5)
		move.b	(Hardware_flags).w,d0
		andi.w	#1<<hard_tasmanian,d0
		add.w	d0,d0
		lea	TASbroke-Emulators(a4),a0
		move.w	(a0,d0.w),d0
		lea	(a0,d0.w),a0
		bsr	.loadtext

		locVRAM	(vram_fg+(3*$80)),VDP_control_port-VDP_control_port(a5)
		moveq	#0,d7
		move.b	(Addons_flags).w,d7
		move.w	d7,d0
		andi.w	#1<<addon_32x|1<<addon_cdhardware,d0
		add.w	d0,d0
		lea	Tower-Emulators(a4),a0
		move.w	(a0,d0.w),d0
		lea	(a0,d0.w),a0
		bsr	.loadtext

		locVRAM	(vram_fg+(4*$80)),VDP_control_port-VDP_control_port(a5)
		move.w	d7,d0
		andi.w	#1<<addon_mcd,d0
		lsr.w	#addon_mcd-1,d0
		lea	MCDlike-Emulators(a4),a0
		move.w	(a0,d0.w),d0
		lea	(a0,d0.w),a0
		bsr	.loadtext

		locVRAM	(vram_fg+(5*$80)),VDP_control_port-VDP_control_port(a5)
		move.w	d7,d0
		andi.w	#1<<addon_everdrive,d0
		lsr.w	#addon_everdrive-1,d0
		lea	EverdriveTest-Emulators(a4),a0
		move.w	(a0,d0.w),d0
		lea	(a0,d0.w),a0
		bsr	.loadtext

		locVRAM	(vram_fg+(6*$80)),VDP_control_port-VDP_control_port(a5)
		move.w	d7,d0
		andi.w	#1<<addon_megasd,d0
		lsr.w	#addon_megasd-1,d0
		lea	MegaSDTest-Emulators(a4),a0
		move.w	(a0,d0.w),d0
		lea	(a0,d0.w),a0
		bsr	.loadtext

		locVRAM	(vram_fg+(7*$80)),VDP_control_port-VDP_control_port(a5)
		move.w	d7,d0
		andi.w	#1<<addon_wifi,d0
		lsr.w	#addon_wifi-1,d0
		lea	WifiDetect-Emulators(a4),a0
		move.w	(a0,d0.w),d0
		lea	(a0,d0.w),a0
		bsr	.loadtext
	;	tst.b	d7
	;	bpl.s	.nowifi
	;	locVRAM	(vram_fg+(8*$80)),VDP_control_port-VDP_control_port(a5)
		move.w	d7,d0
		andi.w	#1<<addon_retrolink|1<<addon_megawifi,d0
		lsr.w	#addon_retrolink-1,d0
		lea	FoundWifi-Emulators(a4),a0
		move.w	(a0,d0.w),d0
		lea	(a0,d0.w),a0
;.nowifi
.loadtext
		moveq	#0,d6
		move.b	(a0)+,d6
		moveq	#0,d0
-		move.b	(a0)+,d0
		move.w	d0,VDP_data_port-VDP_data_port(a6)
		dbf	d6,-
.nowifi
		rts
; ---------------------------------------------------------------------------
Emulators:	offsetTable
	offsetTableEntry.w Emulators_Hardware
	offsetTableEntry.w Emulators_GPGX
	offsetTableEntry.w Emulators_Regen
	offsetTableEntry.w Emulators_Kega
	offsetTableEntry.w Emulators_Gens
	offsetTableEntry.w Emulators_BlastEm
	offsetTableEntry.w Emulators_Exodus
	offsetTableEntry.w Emulators_MegaSg
	offsetTableEntry.w Emulators_Steam
	offsetTableEntry.w Emulators_Picodrive
	offsetTableEntry.w Emulators_Flashback
	offsetTableEntry.w Emulators_Firecore
	offsetTableEntry.w Emulators_Genecyst
Emulators_Hardware:	levselstr "HARDWARE"
Emulators_GPGX:		levselstr "GENESIS PLUS GX"
Emulators_Regen:	levselstr "REGEN"
Emulators_Kega:		levselstr "KEGA FUSION"
Emulators_Gens:		levselstr "GENS"
Emulators_BlastEm:	levselstr "BLASTEM"
Emulators_Exodus:	levselstr "EXODUS"
Emulators_MegaSg:	levselstr "MEGA SG"
Emulators_Steam:	levselstr "STEAM"
Emulators_Picodrive:	levselstr "PICODRIVE"
Emulators_Flashback:	levselstr "ATGAMES FLASHBACK"
Emulators_Firecore:	levselstr "ATGAMES FIRECORE"
Emulators_Genecyst:	levselstr "GENECYST"
	even

Region:	offsetTable
	offsetTableEntry.w Region_JP
	offsetTableEntry.w Region_JP50
	offsetTableEntry.w Region_US
	offsetTableEntry.w Region_PAL
Region_JP:	levselstr " - JP"
Region_JP50:	levselstr " - JP50"
Region_US:	levselstr " - USA"
Region_PAL:	levselstr " - PAL"
	even

TASbroke:	offsetTable
	offsetTableEntry.w TASbroke_Old
	offsetTableEntry.w TASbroke_New
TASbroke_Old:	levselstr "TAS BROKEN"
TASbroke_New:	levselstr "TAS WORKING"
	even

Tower:	offsetTable
	offsetTableEntry.w Tower_MD
	offsetTableEntry.w Tower_32x
	offsetTableEntry.w Tower_MCD
	offsetTableEntry.w Tower_Power
Tower_MD:	levselstr "NO ADDONS FOUND"
Tower_32x:	levselstr "32X FOUND"
Tower_MCD:	levselstr "MEGA CD FOUND"
Tower_Power:	levselstr "TOWER OF POWER FOUND"
	even

MCDlike:	offsetTable
	offsetTableEntry.w MCDlike_No
	offsetTableEntry.w MCDlike_Ya
MCDlike_No:	levselstr "MEGA CD NOT SUPPORTED"
MCDlike_Ya:	levselstr "MEGA CD SUPPORT"
	even

EverdriveTest:	offsetTable
	offsetTableEntry.w Everdrive_No
	offsetTableEntry.w Everdrive_Ya
Everdrive_No:	levselstr "EVERDRIVE NOT FOUND"
Everdrive_Ya:	levselstr "EVERDRIVE FOUND"
	even

MegaSDTest:	offsetTable
	offsetTableEntry.w MegaSD_No
	offsetTableEntry.w MegaSD_Ya
MegaSD_No:	levselstr "MEGASD NOT FOUND"
MegaSD_Ya:	levselstr "MEGASD FOUND"
	even

WifiDetect:	offsetTable
	offsetTableEntry.w Wifi_No
	offsetTableEntry.w Wifi_Ya
Wifi_No:	levselstr "WIFI NOT FOUND - "
Wifi_Ya:	levselstr "WIFI FOUND - "
	even

FoundWifi:	offsetTable
	offsetTableEntry.w FoundWifi_No
	offsetTableEntry.w FoundWifi_RetroLink
	offsetTableEntry.w FoundWifi_MegaWifi
	offsetTableEntry.w FoundWifi_Both
FoundWifi_No:		levselstr "NONE"
FoundWifi_RetroLink:	levselstr "RETROLINK"
FoundWifi_MegaWifi:	levselstr "MEGAWIFI"
FoundWifi_Both:		levselstr "BOTH"
	even

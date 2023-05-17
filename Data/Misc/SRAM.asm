; ---------------------------------------------------------------------------
; SRAM
; https://plutiedev.com/saving-sram
; ---------------------------------------------------------------------------
SRAM_GetWord macro sram,reg
	if AddressSRAM=0
	move.w	sram,reg
	else
	movep.w	sram,reg
	endif
	endm
SRAM_SetWord macro reg,sram
	if AddressSRAM=0
	move.w	reg,sram
	else
	movep.w	reg,sram
	endif
	endm
SRAM_GetLong macro sram,reg
	if AddressSRAM=0
	move.l	sram,reg
	else
	movep.l	sram,reg
	endif
	endm
SRAM_SetLong macro reg,sram
	if AddressSRAM=0
	move.l	reg,sram
	else
	movep.l	reg,sram
	endif
	endm
; ---------------------------------------------------------------------------

Init_SRAM:
		enableSRAM
		lea	(SRAM_Address).l,a1
		move.l	a1,(Save_pointer).w
		move.l	#SRAM_InitText_String,d1
		move.l	#SRAM_InitText_String2,d2
		SRAM_GetLong sram_inittext(a1),d0
		cmp.l	d0,d1
		bne.s	.stringfail
		SRAM_GetLong sram_inittext2(a1),d0
		cmp.l	d0,d2
		beq.s	.stringsuccess
; it's never been saved to before. Set some stuff, clear others
.stringfail
		SRAM_SetLong d1,sram_inittext(a1)
		SRAM_SetLong d2,sram_inittext2(a1)
	; clear SRAM (in case of junk data)
	if AddressSRAM=0
		lea	sram_inittext2+4(a1),a2
		move.w	#(sram_copy_end-(sram_inittext2+4))-1,d1
	else
		lea	sram_inittext2+8(a1),a2
		move.w	#((sram_copy_end-(sram_inittext2+8))/2)-1,d1
	endif
		moveq	#0,d0

-		move.b	d0,(a2)+
	if AddressSRAM<>0
		addq.l	#1,a2
	endif	
		dbf	d1,-
	;	move.l	a1,-(sp)
	;	bsr.s	SRAM_SaveBackup
	;	move.l	(sp)+,a1
		move.b	#SRAM_GameVersion,sram_version(a1)
		move.b	#SRAM_DefaultSettings,sram_settings(a1)
		bsr.s	SRAM_GetChecksum
		SRAM_SetWord d1,sram_checksum(a1)
.end
		disableSRAM
		rts
; now that we've determined SRAM has been saved over before...
.stringsuccess
; check the version. If not the same, init the save conversion
		moveq	#0,d0
		move.b	sram_version(a1),d0
		cmp.b	#SRAM_GameVersion,d0
		beq.s	.versionsuccess
		bhi.w	SRAM_LaterVersionDetected	; if a later number, branch
		bsr.w	SRAM_OlderVersionDetected	; if an earlier version, silently fix it
		bra.s	.end
.versionsuccess
; check the checksum, in case data got corrupted, or was altered by an outside force >:(
		bsr.s	SRAM_GetChecksum
		SRAM_GetWord sram_checksum(a1),d0
		cmp.w	d0,d1
		beq.s	.end
		SRAM_SetWord d0,sram_checksum(a1)
		bsr.s	SRAM_LoadBackup
		bra.s	.end
; ---------------------------------------------------------------------------
; gets the SRAM checksum in d1
; suplimental to other SRAM related code
SRAM_GetChecksum:
		lea	(SRAM_Address+sram_inittext).l,a2
		moveq	#0,d1
		move.w	#((sram_padding-sram_inittext)/(2*SRAM_RAMSize))-1,d2
-
	if AddressSRAM=0
		add.w	(a2)+,d1
	else
		movep.w	(a2),d0
		addq.l	#2*SRAM_RAMSize,a2
		add.w	d0,d1
	endif
		dbf	d2,-
	;	move.l	#'HALP',d0
	;	SRAM_SetLong d0,(a2)	; debug text, to see where it ends
		rts
; ---------------------------------------------------------------------------
; loads or saves the backup SRAM
; TODO: Speed up loading process
SRAM_LoadBackup:
		lea	(SRAM_Address+sram_main).l,a1
		lea	(SRAM_Address+sram_copy).l,a2
		bra.s	+

SRAM_SaveBackup:
		lea	(SRAM_Address+sram_copy).l,a1
		lea	(SRAM_Address+sram_main).l,a2
+		move.w	#(sram_copy_end-sram_copy)-1,d1
-		move.b	(a2)+,(a1)+
	if AddressSRAM<>0
		addq.l	#1,a1
		addq.l	#1,a2
	endif	
		dbf	d1,-
		rts
; ---------------------------------------------------------------------------
; convert older versions of the games SRAM into the newest format
; TODO: No older versions
SRAM_OlderVersionDetected:
	;	moveq	#0,d0
	;	move.b	sram_version(a1),d0
		move.b	#SRAM_GameVersion,sram_version(a1)	; set old version to current one
		add.w	d0,d0
		move.w	.index(pc,d0.w),d1
		jmp	.index(pc,d1.w)
; ---------------------------------------------------------------------------
.index	offsetTable
	offsetTableEntry.w SRAM_OlderVersionDetected.ver0
	offsetTableEntry.w SRAM_OlderVersionDetected.ver1
; ---------------------------------------------------------------------------
.ver0
.ver1
	rts
; ---------------------------------------------------------------------------
; I think this should be handled on a game-by-game basis
; my one sends you to an error screen, similar to those spooooooky fake piracy screens
SRAM_LaterVersionDetected:
; we've exhausted all of our options.
		move.b	#id_ContinueScreen,(Game_mode).w	; WIP
		disableSRAM
		rts
; ===========================================================================
; Game specific
LoadSRAMtoRAM:
		lea	(Save_RAM).l,a1
		movea.l	(Save_pointer).w,a2
		move.w	#((sram_padding-sram_start)/SRAM_RAMSize)-1,d1
-		move.b	(a2)+,(a1)+
	if AddressSRAM<>0
		addq.l	#1,a2
	endif	
		dbf	d1,-
		rts

LoadRAMtoSRAM:
		movea.l	(Save_pointer).w,a1
		lea	(Save_RAM).l,a2
		move.w	#((sram_padding-sram_start)/SRAM_RAMSize)-1,d1
-		move.b	(a2)+,(a1)+
	if AddressSRAM<>0
		addq.l	#1,a1
	endif	
		dbf	d1,-
		rts
; ---------------------------------------------------------------------------
	;	movea.l	(Save_pointer).w,a1
	;	move.b	sramsave2+sram_main_emeraldcount(a1),d0
SaveGame:
	enableSRAM
		bsr.s	LoadRAMtoSRAM		; save the RAM alterations to SRAM
		bsr.w	SRAM_SaveBackup		; save the SRAM main to SRAM copy
		bsr.w	SRAM_GetChecksum	; calculate the checksum
	disableSRAM
		rts

;LoadGame:
;		rts

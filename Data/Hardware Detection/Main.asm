; ---------------------------------------------------------------------------

Init_HardwareDetect:
		bsr	DetectEmulator		; figure out if we're running on a certain list of emulators
		move.b	d0,(Emulator_ID).w
		bsr	DetectHardware
		move.b	d0,(Hardware_flags).w
		bsr	DetectAddon		; detect optional console or cartridge addons
		move.b	d0,(Addons_flags).w
		enableInts
;		bsr.s	DetectVblankSpeed
;		rts

; counts how many cycles it waits until it Vblanks again, divided by around 30 cycles
; it should be noted that it only gives an approximate number. There is certainly room for error
DetectVblankSpeed:
		lea	(VDP_control_port).l,a5
		move.w	#$8174,(a5)	; VDP Command $8174 - Display on, VInt on, DMA on, PAL off
		moveq	#0,d0

$$waitForVBlankStart:
		btst	#3,1(a5)
		beq.s	$$waitForVBlankStart

$$waitForVBlankEnd:
		btst	#3,1(a5)
		bne.s	$$waitForVBlankEnd	; Wait for VBlank to run once

$$waitForNextVBlank:
		addq.w	#1,d0			; 4
;		move.w	(a5),d1			; 8
;		andi.w	#8,d1			; 8
		btst	#3,1(a5)		; 16
		beq.s	$$waitForNextVBlank	; 10
		move.w	d0,(V_blank_cycles).w	; save approximate cycles between a full frame VBlanks /30
		rts
; End of function DetectPAL
; ---------------------------------------------------------------------------
; d0.b - hardware capability bitfield
; uses minor differences to detect certain official hardware revisions
; also helps determine differences in emulation
DetectHardware:
; get region types
		move.b	(HW_Version),d6
		andi.b	#$C0,d6
		move.b	d6,(Region_flags).w	; get region setting
		btst	#6,d6
		sne	d0			; if PAL, set d0. If not, clear d0
		andi.w	#3,d0			; remove bits, leaving it on either slow PAL mode or NTSC
		move.b	d0,(PAL_flag).w
; test certain features that only certain revisions can handle
; let's start simple with TAS. On earlier machines, TAS (test and set) on memory would only handle a test due to a hardware bug
; Genesis 3 models fixed this bug
		lea	(RAM_start).l,a0
		move.b	(a0),d1			; save RAM
		moveq	#0,d0
		move.b	d0,(a0)		; clear
		tas.b	(a0)			; use TAS only for its set, in a scenario where it wouldn't work on older machines
		move.b	(a0),d0
	;	tas.b	d0
		rol.b	#1,d0			; put bit 7 into bit 0
		move.b	d1,(a0)			; restore RAM

; last, set two bits for V30
; check systems that'll support V30 on either
		moveq	#signextendB(1<<hard_v3050|1<<hard_v3060),d4
		move.b	(Emulator_ID).w,d3	; get emulator id
		moveq	#(VDP_V30_emu.end-VDP_V30_emu)-1,d1
		lea	VDP_V30_emu(pc),a1
-		move.b	(a1)+,d2
		cmp.b	d3,d2			; is the detected emulator in the list?
		beq.s	.end			; if so, branch
		dbf	d1,-
; check systems that don't support V30 at all
		moveq	#0,d4
		moveq	#(VDP_V28_emu.end-VDP_V28_emu)-1,d1
		lea	VDP_V28_emu(pc),a1
-		move.b	(a1)+,d2
		cmp.b	d3,d2			; is the detected emulator in the list?
		beq.s	.end			; if so, branch
		dbf	d1,-
; from this point, systems are assumed to only support V30 50Hz
		moveq	#signextendB(1<<hard_v3050),d4
.end
		or.b	d4,d0

		moveq	#signextendB(1<<hard_cramdot),d4
		move.b	(Emulator_ID).w,d3	; get emulator id
		moveq	#(BlastProc_NoList.end-BlastProc_NoList)-1,d1
		lea	BlastProc_NoList(pc),a1
-		move.b	(a1)+,d2
		cmp.b	d3,d2			; is the detected emulator in the list?
		beq.s	.end2			; if so, branch
		dbf	d1,-
		moveq	#0,d4
.end2
		or.b	d4,d0
		rts

; list of all the emulators that support V30 60Hz...
VDP_V30_emu:
	dc.b EMU_BLASTEM_OLD,EMU_REGEN
.end
; ...or don't support V30 at all
VDP_V28_emu:
	dc.b EMU_GENECYST	; TODO: Verify Genecyst
.end
; list of all emulators that don't support CRAM dots, and by proxy, blast processing
BlastProc_NoList:
	dc.b EMU_KEGA,EMU_GPGX,EMU_PICODRIVE,EMU_GENS,EMU_REGEN,EMU_CLOWNMDEMU,EMU_GENECYST,EMU_STEAM
.end
	even
; ---------------------------------------------------------------------------
; detects and initiates certain hardware addons
DetectAddon:
		moveq	#0,d0
		moveq	#0,d6
	;	move.b	(Emulator_ID).w,d7	; ignore certain checks if certain emulators would create certain bugs
; 32x
		cmp.l	#"MARS",(S32x_Signature)	; for 32x games, this helps make sure they don't boot without a 32x attached
		bne.s	+				; we're basically doing that in reverse
		bset	d6,d0
+		addq.w	#1,d6
; Mega CD hardware
		btst	#5,(HW_Version)		; is the MCD plugged in?
		bne.s	+			; if not, branch (0 = yes)
		bset	d6,d0
+		addq.w	#1,d6
; Mega CD capability
		cmpi.l	#"SEGA",(CdBootRom_SEGA)	; check for 'SEGA' in CD bios (for flashcarts like the Everdrive, which physically can't set bit 5)
		bne.s	+
		bset	d6,d0
+		addq.w	#1,d6
; Everdrive Pro
		addq.w	#1,d6
; MegaSD
		move.w	#MSD_OverlayValue,(MSD_OverlayPort)
		move.w	(MSD_OverlaySignature),d1
		lsl.l	#8,d1
		lsl.l	#8,d1
		move.w	(MSD_OverlaySignature+2),d1
		cmp.l	#'BATE',d1	; $42415445... but the docs said it was RATE
	;	cmp.l	#'BATE',(MSD_OverlaySignature)	; oh if only
		bne.s	+
		bset	d6,d0
+		addq.w	#1,d6
		move.w	d1,(MSD_OverlayPort)	; disable for now
; RetroLink
; https://github.com/b1tsh1ft3r/retro.link/blob/main/sega_genesis/asm_example/example.asm
	if EnableWifi=1
		lea	(UART_RHR).l,a1		; saves a lot of space
		move.b	#$80,UART_LCR-UART_RHR(a1)
		move.b	#$00,UART_DLM-UART_RHR(a1)
		move.b	#$00,UART_DLL-UART_RHR(a1)
		cmp.b	#$10,UART_DVID-UART_RHR(a1)	; 0x10 = Present
		bne.s	+				; if not present, branch
		move.b	#$83,UART_LCR-UART_RHR(a1)	; Init UART
		move.b	#$00,UART_DLM-UART_RHR(a1)
		move.b	#$01,UART_DLL-UART_RHR(a1)
		move.b	#$03,UART_LCR-UART_RHR(a1)
		move.b	#$00,UART_MCR-UART_RHR(a1)
		move.b	#$01,UART_FCR-UART_RHR(a1)
		move.b	#$07,UART_FCR-UART_RHR(a1)	; flush send/receive fifos
		move.b	#$00,UART_IER-UART_RHR(a1)
	  if addon_wifi=7
		tas	d0
	  else
		bset	#addon_wifi,d0
	  endif
		bset	d6,d0
	endif
+	;	addq.w	#1,d6
; MegaWifi
	;	addq.w	#1,d6
.end
		rts
; ---------------------------------------------------------------------------

	include "Data/Hardware Detection/emudetect.asm"

; ---------------------------------------------------------------------------
-	; used for !org
; Hardware capabilities bitfield.
; A bunch of flags to approximately determine which machine revision you own, separately from determining if you have hardware at all
	phase 0		; Hard on
hard_tasmanian		ds.b 1		; TAS memory error flag
	dephase
; Addons bitfield
; I feel like there are gonna be more in the future. So, the code is built to be safely extended into a long
	phase 0
addon_32x		ds.b 1	; TODO: Make use
addon_cdhardware	ds.b 1	; real MegaCD hardware
addon_mcd		ds.b 1	; MegaCD functionality, but not strictly real hardware (such as flashcarts)
addon_everdrive		ds.b 1	; TODO: Everything ; Everdrive Pro
addon_megasd		ds.b 1	; TODO: Everything
addon_retrolink		ds.b 1	; TODO: Make use
addon_megawifi		ds.b 1	; TODO: Everything
addon_wifi		ds.b 1	; TODO: Make use ; some form of wifi
	dephase
; Emulator ID
; TODO: add clownmdemu?
	phase 0
EMU_HARDWARE		ds.b 1		; Hardware
EMU_GPGX		ds.b 1		; Genesis Plus GX
EMU_REGEN		ds.b 1		; Regen
EMU_KEGA		ds.b 1		; Kega Fusion
EMU_GENS		ds.b 1		; Gens
EMU_BLASTEM_OLD		ds.b 1		; Old versions of BlastEm
EMU_EXODUS		ds.b 1		; Exodus
EMU_MEGASG		ds.b 1		; Mega Sg
EMU_STEAM		ds.b 1		; Steam
EMU_PICODRIVE		ds.b 1		; Picodrive
EMU_FLASHBACK		ds.b 1		; AtGames Flashback
EMU_FIRECORE		ds.b 1		; AtGames Firecore
EMU_GENECYST		ds.b 1		; Genecyst
	dephase
	!org -

; ---------------------------------------------------------------------------

Init_HardwareDetect:
		bsr.w	DetectEmulator		; figure out if we're running on a certain list of emulators
		move.b	d0,(Emulator_ID).w
		bsr.s	DetectHardware
		move.b	d0,(Hardware_flags).w
		bsr.s	DetectAddon		; detect optional console or cartridge addons
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

		rts
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
		bset	d6,d0		; TODO: fix whatever is softlocking the game
+		addq.w	#1,d6
; Everdrive Pro
		addq.w	#1,d6
; MegaSD
		addq.w	#1,d6
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

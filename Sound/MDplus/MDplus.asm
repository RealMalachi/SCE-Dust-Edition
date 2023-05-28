; ---------------------------------------------------------------------------
; https://drive.google.com/file/d/1RY5O5MIPMFo4luMQ6T-_gpQwKhciLSuh/view - mirrow of MegaSD dev doc
	ifndef MSD_OverlayValue
; MegaSD: 3F7F6h-3FFFFh, can seemingly only read and write in words
; Functions similar to SRAM, so code you intend to run shouldn't overlap with MSD addresses
MSD_OverlaySignature =		$03F7F6	; 'RATE' if overlay port was successful
MSD_OverlayPort =		$03F7FA	; write $CD54 to enable MegaSD control
MSD_ResultPort =		$03F7FC
MSD_CommandPort =		$03F7FE
MSD_ParameterData =		$03F800	; data from the ARM cpu

MSD_OverlayValue =		$CD54
	endif
; high byte of commands for command port. smart to use bytes_to_word function
msd_comm_version =		$10	; retrives the particular version of the MegaSD
msd_comm_playsong =		$11	; play a song
pld_comm_playonce =		msd_comm_playsong
msd_comm_playloop =		$12	; play a song and loop it when it's done
msd_comm_pause =		$13	; 1.04 uses parameter for a fadeout
msd_comm_resume =		$14
msd_comm_volume =		$15	; volume between 0-FFh
msd_comm_status =		$16	; 1.04 ; 0 = no song playing, 1 = song playing
msd_comm_sectoread =		$17	; requests a cd sector read. Will return data in 3F800h-3F803h
msd_comm_sectortrans =		$18
msd_comm_sectoreadnext =	$19
msd_comm_playloopoffset =	$1A	;
msd_comm_playspecificsector =	$1B
msd_comm_selectreadfile =	$1C	; 1.04
msd_comm_readfile =		$1D	; 1.04
msd_comm_readdirectfile =	$1E
msd_comm_playwav =		$1F	; plays WAV file
msd_comm_readfileblock =	$20
msd_comm_readnextblock =	$21

; notes for .cue loop points (1.04)
;REM LOOP
;REM LOOP xxxxx
;REM NOLOOP
;REM COMMENT "xxxxx"
; ---------------------------------------------------------------------------

	ifndef MSD_CheckACE
; safety measure to ensure the bankswitching doesn't overlap
MSD_CheckACE macro
	if ((*)>=(MSD_OverlaySignature))&&((*)<=($03FFFF))	; I hate this so much
	fatal "ACE ERROR: MegaSD code overlaps with the bankswitch overlay! $\{*}"
	endif
	endm
	endif

	ifndef MSD_WaitForARM
; Copies command port and checks the high byte. If it's 0, the command is done
MSD_WaitForARM macro reg
	MSD_CheckACE
	if ("reg" == "")
-	move.w	(MSD_CommandPort),d0
	else
-	move.w	reg,d0
	endif
	andi.w	#$FF00,d0
	bne.s	-
	MSD_CheckACE
	endm
	endif

	ifndef MSD_SoundDriver_Init
; loads initial data for sound driver
MSD_SoundDriver_Init macro ifnotbranch
	btst	#addon_megasd,(Addons_flags).w
	beq.s	ifnotbranch
	MSD_CheckACE
	move.w	#MSD_OverlayValue,(MSD_OverlayPort)
	move.w	#bytes_to_word(msd_comm_volume,$FF),(MSD_CommandPort)
	move.w	#0,(MSD_OverlayPort)
	MSD_CheckACE
+
	endm
	endif

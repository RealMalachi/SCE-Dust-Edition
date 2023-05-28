UpdateSoundDriver macro
;	MSD_SoundDriver		; TODO: limited version for Z80 drivers
	SMPS_UpdateSoundDriver
	endm
Size_of_Snd_driver_guess	= Size_of_Mega_PCM_guess	; Specifically, the size of the Z80 portion
Size_of_Snd_driver2_guess	= 0

; ---------------------------------------------------------------------------
; play a sound effect or music
; input: track, terminate routine, branch or jump, move operand size
; ---------------------------------------------------------------------------

;	fatal "Sound Driver does not support its core function of music"
music:	macro track,terminate,byte
	  if  ("track"="0") || ("track"="")	; assume ID is already set
	  else
	    if ("byte"="0") || ("byte"="")
		moveq	#signextendB(track),d0
	    elseif byte=1
		move.b	#(track),d0
	    else
		move.w	#(track),d0
	    endif
	  endif
	      if ("terminate"="0") || ("terminate"="")
		jsr	(SMPS_QueueSound1).w
	      else
		jmp	(SMPS_QueueSound1).w
	      endif
    endm
;	fatal "Sound Driver does not support FM/PSG sound effects"
sfx:	macro track,terminate,byte
	  if  ("track"="0") || ("track"="")	; assume ID is already set
	  else
	    if ("byte"="0") || ("byte"="")
		moveq	#signextendB(track),d0
	    elseif byte=1
		move.b	#(track),d0
	    else
		move.w	#(track),d0
	    endif
	  endif
	      if ("terminate"="0") || ("terminate"="")
		jsr	(SMPS_QueueSound2).w
	      else
		jmp	(SMPS_QueueSound2).w
	      endif
    endm
;	fatal "Sound Driver does not support independant PCM playback"
sample:	macro track,terminate,byte,volume,channel
	  if  ("track"="0") || ("track"="")	; assume ID is already set
	  else
 	    if ("byte"="0") || ("byte"="")
		moveq	#signextendB(track),d0
	    elseif byte=1
		move.b	#(track),d0
	    else
		move.w	#(track),d0
	    endif
	  endif
	    if  ("volume"="0") || ("volume"="")
		moveq	#0,d1
	    else
		moveq	#signextendB(volume),d1
	    endif
	    if  ("channel"="0") || ("channel"="")
		moveq	#1*2,d2
	    else
		moveq	#signextendB(channel*2),d2
	    endif
	      if ("terminate"="0") || ("terminate"="")
		jsr	(SMPS_PlaySample).w
	      else
		jmp	(SMPS_PlaySample).w
	      endif
    endm

	include "Sound/Definitions.asm"		; include sound driver macros and functions

; safety measure to ensure the bankswitching doesn't overlap
MSD_CheckACE macro
	if ((*)>=(MSD_OverlaySignature))&&((*)<=($03FFFF))	; I hate this so much
	fatal "ACE ERROR: MegaSD code overlaps with the bankswitch overlay! $\{*}"
	endif
	endm
; Copies command port and checks the high byte. If it's 0, the command is done
MSD_WaitForARM macro reg
	if ("reg" == "")
-	move.w	(MSD_CommandPort),d0
	else
-	move.w	reg,d0
	endif
	andi.w	#$FF00,d0
	bne.s	-
	MSD_CheckACE
	endm
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
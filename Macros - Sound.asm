UpdateSoundDriver macro
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
sample:	macro track,terminate,byte
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
		jsr	(SMPS_PlayDACSample).w
	      else
		jmp	(SMPS_PlayDACSample).w
	      endif
    endm

	include "Sound/Definitions.asm"		; include sound driver macros and functions
; ---------------------------------------------------------------------------
; Called at the end of each frame to perform vertical synchronization
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Wait_VSync:
DelayProgram:
	if Lagometer
		move.w	#$9100,(VDP_control_port).l	; window H position at default
	endif
		lea	(V_int_flag),a0
		move.b	#1,(a0)			; set that we've reached Vsync
		enableInts
.wait
		tst.b	(a0)			; wait until V-int's run
		bpl.s	.wait			; until then wait
		clr.b	(a0)			; wait for next frame
		clr.w	(Lag_frame_count).w
		rts
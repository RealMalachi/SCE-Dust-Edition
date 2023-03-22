; ---------------------------------------------------------------------------
; Called at the end of each frame to perform vertical synchronization
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Wait_VSync:
DelayProgram:
	if Lagometer
		move.w	#$9100,(VDP_control_port).l	; window H position at default
	endif
		move.b	#1,(V_int_flag).w	; set that we've reached Vsync
		enableInts
.wait
		tst.b	(V_int_flag).w		; wait until V-int's run
		bpl.s	.wait	
		clr.b	(V_int_flag).w		; wait for next frame
		rts
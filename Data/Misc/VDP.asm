; ---------------------------------------------------------------------------
; VDP init
; ---------------------------------------------------------------------------

VDP_register_values:
	dc.w $8004			; H-int disabled
;	dc.w $8100+%00111100		; V-int enabled, display blanked, DMA enabled, 240 line display
;	dc.w $8100+%00110100		; V-int enabled, display blanked, DMA enabled, 224 line display
	dc.w $8200+(vram_fg>>10)	; Scroll A PNT base $C000
	dc.w $8300+(vram_window>>10)	; Window PNT base $C000
	dc.w $8400+(vram_bg>>13)	; Scroll B PNT base $E000
	dc.w $8500+(vram_sprites>>9)	; Sprite attribute table base $F800
	dc.w $8600			; Sprite Pattern Generator Base Address: low 64KB VRAM
	dc.w $8700+(0<<4)		; Backdrop color is color 0 of the first palette line
;	dc.w $8800			; unused
;	dc.w $8900			; unused
	dc.w $8A00			; default H.interrupt register
	dc.w $8B00			; Full-screen horizontal and vertical scrolling
	dc.w $8C81			; 40 cell wide display, no interlace, S/H disabled
	dc.w $8D00+(vram_hscroll>>10)	; Horizontal scroll table base $F000
	dc.w $8E00			; Nametable Pattern Generator Base Address: low 64KB VRAM
	dc.w $8F02			; VDP auto increment is 2
	dc.w $9001			; Scroll planes are 64x32 cells (512x256)
	dc.w $9100			; Window horizontal position
	dc.w $9200			; Window vertical position
;	dc.w $9300			; DMA related
;	dc.w $9400			; ditto
;	dc.w $9500			; ditto.
;	dc.w $9600			; ditto..
;	dc.w $9700			; ditto...
	dc.w 0				; end

; =============== S U B R O U T I N E =======================================

Init_VDP:
; load VDPs without exceptions
		lea	VDP_register_values(pc),a1
		bsr.w	Load_VDP
		lea	VDP_control_port-VDP_control_port(a6),a5	; put control port to a5 (used in VRAM clearing macro)
		lea	VDP_data_port-VDP_control_port(a5),a6		; set data port to a6 instead

		move.w	#$8100+%00111100,d0	; V-int enabled, display blanked, DMA enabled, 240 line display
		move.b	(Hardware_flags).w,d1
;	if hard_v3060=7
;		bmi.s	.v30
;	else
		btst	#hard_v3060,d1		; does it support V30 60Hz?
		bne.s	.v30			; if so, branch
;	endif
		btst	#hard_v3050,d1		; does it support V30 50Hz?
		beq.s	.v28			; if not, branch
		tst.b	(PAL_flag).w		; is it on 50Hz
		bne.s	.v30			; if so, branch
.v28
		move.w	#$8100+%00110100,d0	; V-int enabled, display blanked, DMA enabled, 224 line display
.v30
		move.w	d0,VDP_control_port-VDP_control_port(a5)	; 
		move.w	d0,(VDP_reg_1_command).w
		bsr.s	Set_ScreenSize
	;	andi.w	#$FF,d1
		ori.w	#$8A00,d1
		move.w	d1,(H_int_counter_command).w	; $8A00|vert-1
; Clear Vertical Scrolling
		moveq	#0,d0
		move.l	#vdpComm($0000,VSRAM,WRITE),VDP_control_port-VDP_control_port(a5)
		move.l	d0,VDP_data_port-VDP_data_port(a6)	; FG/BG
		move.l	d0,(V_scroll_value).w
		move.l	d0,(H_scroll_value).w
; Clear Palette
		move.l	#vdpComm($0000,CRAM,WRITE),VDP_control_port-VDP_control_port(a5)
		moveq	#64/2-1,d1
-		move.l	d0,VDP_data_port-VDP_data_port(a6)
		dbf	d1,-	; clear the CRAM
; Clear VRAM
		dmaFillVRAM 0,$0000,($1000<<4)	; clear entire VRAM
		rts

; ---------------------------------------------------------------------------
; VDP load
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Load_VDP:
		lea	(VDP_control_port).l,a6

.main
		move.w	(a1)+,d0

.loop
		move.w	d0,VDP_control_port-VDP_control_port(a6)
		move.w	(a1)+,d0
		bmi.s	.loop
		rts
; ---------------------------------------------------------------------------

Set_ScreenSize:
		move.w	(VDP_reg_1_command).w,d0
.preload
		andi.w	#%00001000,d0	; only keep the vertical line bit
		sne	d0		; if V30, set to -1. Otherwise, 0
		move.b	d0,(ScreenSize_V_Flag).w	; set number to screen size flag
		move.l	#words_to_long(320-1,224-1),d1	; get horizontal and vertical
		tst.b	d0
		beq.s	+
		move.w	#240-1,d1	; V30 ratio
+		move.l	d1,(ScreenSize_Horz).w
		rts

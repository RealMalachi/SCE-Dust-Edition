; ---------------------------------------------------------------------------
; Subroutine to convert mappings (etc) to proper Megadrive sprites
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================

Init_SpriteTable:
		lea	(Sprite_table_buffer).w,a0
		moveq	#0,d0
		moveq	#1,d1
		moveq	#80-1,d7

-		move.w	d0,(a0)
		move.b	d1,3(a0)
		addq.w	#1,d1
		addq.w	#8,a0
		dbf	d7,-
		move.b	d0,-5(a0)
		clearRAM Sprite_table_input, Sprite_table_input_end
		rts

; =============== S U B R O U T I N E =======================================

Render_Sprites:
		moveq	#80-1,d7
	;	moveq	#64-1,d7
		moveq	#0,d6
		lea	(Camera_X_pos_copy).w,a3
		lea	(Sprite_table_input).w,a5
		lea	(Sprite_table_buffer).w,a6
		tst.b	(Level_started_flag).w
		beq.s	Render_Sprites_LevelLoop
		bsr.w	Render_HUD
		bsr.w	Render_Rings

Render_Sprites_LevelLoop:
		tst.w	(a5)					; does this level have any objects?
		beq.w	Render_Sprites_NextLevel		; if not, check the next one
.fromnextlevel
		lea	2(a5),a4

Render_Sprites_ObjLoop:
		movea.w	(a4)+,a0 				; a0=object
		tst.l	address(a0)				; is this object slot occupied?
		beq.w	Render_Sprites_NextObj			; if not, check next one
		andi.b	#$7F,render_flags(a0)			; clear on-screen flag
		move.b	render_flags(a0),d6
		move.w	x_pos(a0),d0
		move.w	y_pos(a0),d1

		btst	#renbit_excessive,d6	; if excessive, skip position rendering check
		beq.s	.notexcessiveinit

		btst	#renbit_camerapos,d6	; is this to be positioned by screen coordinates?
		beq.s	+			; if so, branch
		sub.w	(a3),d0
		sub.w	4(a3),d1
+		move.w	#128,d4
		add.w	d4,d0			; adjust positions for VDP
		add.w	d4,d1
		btst	#renbit_multidraw,d6		; is the multi-draw flag set?
		beq.s	Render_Sprites_ExcessiveSkip	; if not,branch
		bra.w	Render_Sprites_MultiDraw_ExcessiveSkip
.notexcessiveinit
		btst	#renbit_wordframe,d6	; is the rendering handled by a box?
		beq.s	+
		moveq	#0,d3
		move.b	render_box(a0),d3
		move.w	d3,d2
		swap	d2
		move.w	d3,d2
		bra.s	++
+
		moveq	#0,d2
		move.b	height_pixels(a0),d2	; do height_pixels first because it's handled last
		swap	d2
		move.b	width_pixels(a0),d2
+
		btst	#renbit_multidraw,d6			; is the multi-draw flag set?
		bne.w	Render_Sprites_MultiDraw		; if so, branch
		btst	#renbit_camerapos,d6			; is this to be positioned by screen coordinates?
		beq.s	Render_Sprites_ScreenSpaceObj		; if so, branch
		sub.w	(a3),d0
		move.w	d0,d3
		add.w	d2,d3					; is the object right edge to the left of the screen?
		bmi.s	Render_Sprites_NextObj			; if it is, branch
		move.w	d0,d3
		sub.w	d2,d3
		cmpi.w	#320,d3					; is the object left edge to the right of the screen?
		bge.s	Render_Sprites_NextObj			; if it is, branch
		sub.w	4(a3),d1
		swap	d2					; swap to height_pixels
		add.w	d2,d1
	;	bmi.s	Render_Sprites_NextObj			; if it is, branch
		and.w	(Screen_Y_wrap_value).w,d1
		move.w	d2,d3
		add.w	d2,d2
		addi.w	#224,d2
		cmp.w	d2,d1
		bhs.s	Render_Sprites_NextObj			; if the object is below the screen
		sub.w	d3,d1

Render_Sprites_ScreenSpaceObj:
		move.w	#128,d4
		add.w	d4,d0		; adjust positions for VDP
		add.w	d4,d1
		ori.b	#ren_onscreen,render_flags(a0)		; set on-screen flag

Render_Sprites_ExcessiveSkip:
		tst.w	d7					; have we exceeded the amount of sprites it can handle?
		bmi.s	Render_Sprites_CantAnymore		; if so, branch
		movea.l	mappings(a0),a1
		moveq	#0,d4
		btst	#renbit_static,d6			; is the static mappings flag set?
		bne.s	.static					; if it is, branch
		move.b	mapping_frame(a0),d4
		add.w	d4,d4
		btst	#renbit_wordframe,d6			; is the rendering handled by a box?
		beq.s	.bytemap
		move.w	mapping_frame_word(a0),d4
		add.w	d4,d4
.bytemap
		adda.w	(a1,d4.w),a1
		move.w	(a1)+,d4
		subq.w	#1,d4					; get number of pieces
		bmi.s	Render_Sprites_NextObj	; if there are 0 pieces, branch
.static
		move.w	art_tile(a0),d5
		bsr.w	SpriteRenderProcess

Render_Sprites_MultiDraw_TestIfDone:
	;	tst.w	d7					; have we exceeded the amount of sprites it can handle?
	;	bmi.s	Render_Sprites_CantAnymore		; if so, branch
Render_Sprites_CantAnymore:
Render_Sprites_NextObj:
		subq.w	#2,(a5)					; decrement object count
		bne.w	Render_Sprites_ObjLoop			; if there are objects left, repeat

Render_Sprites_NextLevel:
		lea	next_priority(a5),a5			; load next priority level
		cmpa.w	#Sprite_table_input_end,a5		; have you reached the end of rendering?
		blo.w	Render_Sprites_LevelLoop		; if not, branch
	;	bra.s	Render_Sprites_CantAnymore.skipendchk
	;	bhs.s	Render_Sprites_CantAnymore.skipendchk	; if so, branch
	;	tst.w	(a5)					; does this level have any objects?
	;	beq.s	Render_Sprites_NextLevel		; if not, check the next one
	;	bra.w	Render_Sprites_LevelLoop.fromnextlevel
; end routine when you've rendered all the available sprites
; the original game continued chugging along until all the objects counts were cleared
; however, it makes more sense to just clear them, considering they can't even render...
; at least, that would be the case if it wasn't for render_flags
;Render_Sprites_CantAnymore:
	;	moveq	#0,d0
	;	move.w	#Sprite_table_input_end,d1	; may or may not be faster
-	;	move.w	d0,(a5)					; clear remaining object count
	;	lea	next_priority(a5),a5			; load next priority level
	;	cmpa.w	d1,a5					; have you reached the end of rendering?
	;	blo.s	-					; if not, branch
.skipendchk
		move.w	d7,d6					; copy d7 to d6 for Sprites_drawn
		bmi.s	+					; if it's full, branch
		moveq	#0,d0
-		move.w	d0,(a6)					; to remaining sprites, set y_pos offscreen
		addq.w	#8,a6
		dbf	d7,-
+		subi.w	#80-1,d6
		neg.w	d6
		move.b	d6,(Sprites_drawn).w
		rts
; ---------------------------------------------------------------------------

Render_Sprites_MultiDraw:
		move.w	#128,d4		; also clears high byte for later
		btst	#renbit_camerapos,d6				; is this to be positioned by screen coordinates?
		bne.s	Render_Sprites_MultiDraw_CameraSpaceObj		; if not, branch
	; check if object is within X bounds
		sub.w	d4,d0
		move.w	d0,d3
		add.w	d2,d3
		bmi.s	Render_Sprites_NextObj
		move.w	d0,d3
		sub.w	d2,d3
		cmpi.w	#320,d3
		bge.s	Render_Sprites_NextObj
	; check if object is within Y bounds
		swap	d2					; swap to height_pixels
		sub.w	d4,d1
		move.w	d1,d3
		add.w	d2,d3
		bmi.s	Render_Sprites_NextObj
		move.w	d1,d3
		sub.w	d2,d3
		cmpi.w	#224,d3
		bge.s	Render_Sprites_NextObj
		bra.s	Render_Sprites_MultiDraw_CameraSpaceObj.screencont
; ---------------------------------------------------------------------------

Render_Sprites_MultiDraw_CameraSpaceObj:
	; check if object is within X bounds
		sub.w	(a3),d0
		move.w	d0,d3
		add.w	d2,d3
		bmi.w	Render_Sprites_NextObj
		move.w	d0,d3
		sub.w	d2,d3
		cmpi.w	#320,d3
		bge.w	Render_Sprites_NextObj
	; check if object is within Y bounds
		swap	d2					; swap to height_pixels
		sub.w	4(a3),d1
		add.w	d2,d1
	;	bmi.s	Render_Sprites_NextObj
		and.w	(Screen_Y_wrap_value).w,d1
		move.w	d2,d3
		add.w	d2,d2
		addi.w	#224,d2
		cmp.w	d2,d1
		bhs.w	Render_Sprites_NextObj
		sub.w	d3,d1
.screencont
		add.w	d4,d0		; adjust positions for VDP
		add.w	d4,d1
		ori.b	#$80,render_flags(a0)			; set on-screen flag

Render_Sprites_MultiDraw_ExcessiveSkip:
		tst.w	d7					; have we exceeded the amount of sprites it can handle?
		bmi.w	Render_Sprites_CantAnymore		; if so, branch
		move.w	art_tile(a0),d5
		movea.l	mappings(a0),a1
		btst	#renbit_static,d6			; is the static mappings flag set?
		beq.s	+					; if not, branch
		moveq	#0,d4
		move.w	d6,d3
		bsr.w	SpriteRenderProcess
		bra.s	.staticont
+
		btst	#renbit_wordframe,d6	; is the rendering handled by a box?
		beq.s	.bytemap
		move.w	mapping_frame_word(a0),d4
		beq.s	+
		bra.s	.wordmap
.bytemap
		move.b	mapping_frame(a0),d4
		beq.s	+
.wordmap
		add.w	d4,d4
		adda.w	(a1,d4.w),a1
		move.w	(a1)+,d4
		subq.w	#1,d4
		bmi.s	+
		move.w	d6,d3
		bsr.w	SpriteRenderProcess_OriginalExcessive
.staticont
		tst.w	d7
		bmi.w	Render_Sprites_CantAnymore
		move.w	d3,d6
+
		move.w	mainspr_childsprites(a0),d3
		subq.w	#1,d3
		bcs.w	Render_Sprites_NextObj
		lea	sub2_x_pos(a0),a2
.multiloop
		move.w	(a2)+,d0
		move.w	(a2)+,d1
		moveq	#128-8,d4	; also clears high byte for later
		btst	#renbit_camerapos,d6		; is this to be positioned by screen coordinates?
		beq.s	+				; if so, branch
		sub.w	(a3),d0
		sub.w	4(a3),d1
		addq.w	#8,d4		;
		add.w	d4,d0		; adjust positions for VDP
		add.w	d4,d1		; the camera coord versions are pre-adjusted, then?
		and.w	(Screen_Y_wrap_value).w,d1
+
		addq.w	#1,a2
		movea.l	mappings(a0),a1
		btst	#renbit_static,d6		; is the static mappings flag set?
		beq.s	+				; if not, branch
		moveq	#0,d4
		move.w	d6,-(sp)
		bsr.w	SpriteRenderProcess
		bra.s	.staticont2
+
		move.b	(a2)+,d4
		add.w	d4,d4
		adda.w	(a1,d4.w),a1
		move.w	(a1)+,d4
		subq.w	#1,d4
		bmi.s	+
		move.w	d6,-(sp)
		bsr.w	SpriteRenderProcess_OriginalExcessive
.staticont2
		move.w	(sp)+,d6
+
		tst.w	d7
		dbmi	d3,.multiloop	; if so, continue
		bra.w	Render_Sprites_MultiDraw_TestIfDone

; =============== S U B R O U T I N E =======================================
; fix odd tearing bug in x_pos
; only keep the 9 bits the VDP actually reads, branch if not 0. Make 1 if it's 0
; excessive rendering checks well beyond this point
sprprocess_xbugfix macro
	andi.w	#$1FF,d2
	bne.s	+
	addq.w	#1,d2
+
	endm

SpriteRenderProcess:
		btst	#renbit_excessive,d6
		bne.w	SpriteRenderProcess_Excessive
		lsr.b	#1,d6
		bcs.s	.oxny_checky
		lsr.b	#1,d6
		bcs.w	.nxoy_loop
.nxny_loop
		move.b	(a1)+,d2
		ext.w	d2
		add.w	d1,d2
		move.w	d2,(a6)+
		move.b	(a1)+,(a6)+
		addq.w	#1,a6
		move.w	(a1)+,d2
		add.w	d5,d2
		move.w	d2,(a6)+
		move.w	(a1)+,d2
		add.w	d0,d2
		sprprocess_xbugfix
		move.w	d2,(a6)+
		subq.w	#1,d7
		dbmi	d4,.nxny_loop
		rts
; ---------------------------------------------------------------------------

.oxny_checky
		lsr.b	#1,d6
		bcs.s	.oxoy_loop
.oxny_loop
		move.b	(a1)+,d2
		ext.w	d2
		add.w	d1,d2
		move.w	d2,(a6)+
		move.b	(a1)+,d6
		move.b	d6,(a6)+
		addq.w	#1,a6
		move.w	(a1)+,d2
		add.w	d5,d2
		eori.w	#$800,d2
		move.w	d2,(a6)+
		move.w	(a1)+,d2
		neg.w	d2
		move.b	.xdata(pc,d6.w),d6
		sub.w	d6,d2
		add.w	d0,d2
		sprprocess_xbugfix
		move.w	d2,(a6)+
		subq.w	#1,d7
		dbmi	d4,.oxny_loop
		rts
; ---------------------------------------------------------------------------
.xdata
		dc.b  8,  8,  8,  8
		dc.b 16, 16, 16, 16
		dc.b 24, 24, 24, 24
		dc.b 32, 32, 32, 32
; ---------------------------------------------------------------------------

.oxoy_loop
		move.b	(a1)+,d2
		ext.w	d2
		neg.w	d2
		move.b	(a1),d6
		move.b	.ydata(pc,d6.w),d6
		sub.w	d6,d2
		add.w	d1,d2
		move.w	d2,(a6)+
		move.b	(a1)+,d6
		move.b	d6,(a6)+
		addq.w	#1,a6
		move.w	(a1)+,d2
		add.w	d5,d2
		eori.w	#$1800,d2
		move.w	d2,(a6)+
		move.w	(a1)+,d2
		neg.w	d2
		move.b	.xdata(pc,d6.w),d6
		sub.w	d6,d2
		add.w	d0,d2
		sprprocess_xbugfix
		move.w	d2,(a6)+
		subq.w	#1,d7
		dbmi	d4,.oxoy_loop
		rts
; ---------------------------------------------------------------------------
.ydata
		dc.b 8, 16, 24, 32
		dc.b 8, 16, 24, 32
		dc.b 8, 16, 24, 32
		dc.b 8, 16, 24, 32
; ---------------------------------------------------------------------------

.nxoy_loop
		move.b	(a1)+,d2
		ext.w	d2
		neg.w	d2
		move.b	(a1)+,d6
		move.b	d6,2(a6)
		move.b	.ydata(pc,d6.w),d6
		sub.w	d6,d2
		add.w	d1,d2
		move.w	d2,(a6)+
		addq.w	#2,a6
		move.w	(a1)+,d2
		add.w	d5,d2
		eori.w	#$1000,d2
		move.w	d2,(a6)+
		move.w	(a1)+,d2
		add.w	d0,d2
		sprprocess_xbugfix
		move.w	d2,(a6)+
		subq.w	#1,d7
		dbmi	d4,.nxoy_loop
		rts

; =============== S U B R O U T I N E =======================================

SpriteRenderProcess_OriginalExcessive:
		btst	#renbit_excessive,d6
		bne.w	SpriteRenderProcess_Excessive
		lsr.b	#1,d6
		bcs.s	.oxny_checky
		lsr.b	#1,d6
		bcs.w	.nxoy_loop
.nxny_loop
		move.b	(a1)+,d2
		ext.w	d2
		add.w	d1,d2
		cmpi.w	#128-32,d2
		bls.s	.nxny_yfail
		cmpi.w	#224+128,d2
		bhs.s	.nxny_yfail
		move.w	d2,(a6)+
		move.b	(a1)+,(a6)+
		addq.w	#1,a6
		move.w	(a1)+,d2
		add.w	d5,d2
		move.w	d2,(a6)+
		move.w	(a1)+,d2
		add.w	d0,d2
		cmpi.w	#128-32,d2
		bls.s	.nxny_xfail
		cmpi.w	#320+128,d2
		bhs.s	.nxny_xfail
		move.w	d2,(a6)+
		subq.w	#1,d7
		dbmi	d4,.nxny_loop
		rts
.nxny_xfail
		subq.w	#6,a6
		dbf	d4,.nxny_loop
		rts
.nxny_yfail
		addq.w	#5,a1
		dbf	d4,.nxny_loop
		rts
; ---------------------------------------------------------------------------

.oxny_checky
		lsr.b	#1,d6
		bcs.s	.oxoy_loop
.oxny_loop
		move.b	(a1)+,d2
		ext.w	d2
		add.w	d1,d2
		cmpi.w	#$60,d2
		bls.s	.oxny_yfail
		cmpi.w	#$160,d2
		bhs.s	.oxny_yfail
		move.w	d2,(a6)+
		move.b	(a1)+,d6
		move.b	d6,(a6)+
		addq.w	#1,a6
		move.w	(a1)+,d2
		add.w	d5,d2
		eori.w	#$800,d2
		move.w	d2,(a6)+
		move.w	(a1)+,d2
		neg.w	d2
		move.b	.xdata(pc,d6.w),d6
		sub.w	d6,d2
		add.w	d0,d2
		cmpi.w	#$60,d2
		bls.s	.oxny_xfail
		cmpi.w	#$1C0,d2
		bhs.s	.oxny_xfail
		move.w	d2,(a6)+
		subq.w	#1,d7
		dbmi	d4,.oxny_loop
		rts
.oxny_xfail
		subq.w	#6,a6
		dbf	d4,.oxny_loop
		rts
.oxny_yfail
		addq.w	#5,a1
		dbf	d4,.oxny_loop
		rts
; ---------------------------------------------------------------------------
.xdata
		dc.b  8,  8,  8,  8
		dc.b 16, 16, 16, 16
		dc.b 24, 24, 24, 24
		dc.b 32, 32, 32, 32
; ---------------------------------------------------------------------------

.oxoy_loop
		move.b	(a1)+,d2
		ext.w	d2
		neg.w	d2
		move.b	(a1),d6
		move.b	.ydata(pc,d6.w),d6
		sub.w	d6,d2
		add.w	d1,d2
		cmpi.w	#$60,d2
		bls.s	.oxoy_yfail
		cmpi.w	#$160,d2
		bhs.s	.oxoy_yfail
		move.w	d2,(a6)+
		move.b	(a1)+,d6
		move.b	d6,(a6)+
		addq.w	#1,a6
		move.w	(a1)+,d2
		add.w	d5,d2
		eori.w	#$1800,d2
		move.w	d2,(a6)+
		move.w	(a1)+,d2
		neg.w	d2
		move.b	.xdata(pc,d6.w),d6
		sub.w	d6,d2
		add.w	d0,d2
		cmpi.w	#$60,d2
		bls.s	.oxoy_xfail
		cmpi.w	#$1C0,d2
		bhs.s	.oxoy_xfail
		move.w	d2,(a6)+
		subq.w	#1,d7
		dbmi	d4,.oxoy_loop
		rts
.oxoy_xfail
		subq.w	#6,a6
		dbf	d4,.oxoy_loop
		rts
.oxoy_yfail
		addq.w	#5,a1
		dbf	d4,.oxoy_loop
		rts
; ---------------------------------------------------------------------------
.ydata
		dc.b  8, 16, 24, 32
		dc.b  8, 16, 24, 32
		dc.b  8, 16, 24, 32
		dc.b  8, 16, 24, 32
; ---------------------------------------------------------------------------

.nxoy_loop
		move.b	(a1)+,d2
		ext.w	d2
		neg.w	d2
		move.b	(a1)+,d6
		move.b	d6,2(a6)
		move.b	.ydata(pc,d6.w),d6
		sub.w	d6,d2
		add.w	d1,d2
		cmpi.w	#$60,d2
		bls.s	.nxoy_yfail
		cmpi.w	#$160,d2
		bhs.s	.nxoy_yfail
		move.w	d2,(a6)+
		addq.w	#2,a6
		move.w	(a1)+,d2
		add.w	d5,d2
		eori.w	#$1000,d2
		move.w	d2,(a6)+
		move.w	(a1)+,d2
		add.w	d0,d2
		cmpi.w	#$60,d2
		bls.s	.nxoy_xfail
		cmpi.w	#$1C0,d2
		bhs.s	.nxoy_xfail
		move.w	d2,(a6)+
		subq.w	#1,d7
		dbmi	d4,.nxoy_loop
		rts
.nxoy_xfail
		subq.w	#6,a6
		dbf	d4,.nxoy_loop
		rts
.nxoy_yfail
		addq.w	#4,a1
		dbf	d4,.nxoy_loop
		rts
; =============== S U B R O U T I N E =======================================
; render a bit more excessively; stops rendering individual sprites if it's offscreen
; Trivia: S3K's multidraw had a lesser version of this. That's why the title card and end results used multidraw
excessrender_macro macro xflip,yflip
		move.w	d3,-(sp)	; save d3
		move.w	d7,-(sp)	; save d7 (for onscreen check)
.loop
; y_pos
		move.b	(a1)+,d2	; get mapping y_pos
		ext.w	d2		; extend
		move.b	(a1),d6		; Get tile amount
		move.b	.ydata(pc,d6.w),d6	; get actual size of tiles
	if yflip=1
		neg.w	d2		; reverse mapping position
		sub.w	d6,d2		; subtract by tile amount
	endif
		add.w	d1,d2		; add object y_pos

		move.w	#128,d3		;
		sub.w	d6,d3		; sub by tile amount
		cmp.w	d3,d2
		blo.s	.yfail
		move.w	(ScreenSize_Vert).w,d3	; get vertical screen size -1
		addi.w	#128+1,d3		; add VDP offset, account for -1
		cmp.w	d3,d2		; compare that to the x_pos of the sprite
		bhs.s	.yfail		; if offscreen, don't render
; success
		move.w	d2,(a6)+	; set y_pos
		move.b	(a1)+,d6	; get tile amount for x_pos flip check
		move.b	d6,(a6)+	; set tile amount
		addq.w	#1,a6		; skip sprite link
; art_tile
		move.w	(a1)+,d2	; get mapping art_tile
		add.w	d5,d2		; add object art_tile
	if xflip|yflip<>0	;
		eori.w	#(xflip<<11)+(yflip<<12),d2	; flip art_tile
	endif
		move.w	d2,(a6)+	; send final copy
; x_pos
		move.w	(a1)+,d2	; get mapping x_pos
		move.b	.xdata(pc,d6.w),d6	; get actual size of tiles	
	if xflip=1
		neg.w	d2		; reverse mapping position
		sub.w	d6,d2		; subtract by tile amount
	endif
		add.w	d0,d2		; add object x_pos
		move.w	#128,d3		;
		sub.w	d6,d3		; sub by tile amount
		cmp.w	d3,d2
		blo.s	.xfail
		move.w	(ScreenSize_Horz).w,d3	; get horizontal screen size -1
		addi.w	#128+1,d3		; add VDP offset, account for -1
		cmp.w	d3,d2		; compare that to the x_pos of the sprite
		bhs.s	.xfail		; if offscreen, don't render
		move.w	d2,(a6)+	; set x_pos
		subq.w	#1,d7		; count down successful sprite loads
		dbmi	d4,.loop	; if d7 hits bmi range, end. If not, decrement d4. If d4 is now 0, end
.endcheckrndr
		move.w	(sp)+,d3; restore original d7
		cmp.w	d3,d7
		beq.s	.none	; if they're the same, branch
		ori.b	#ren_onscreen,render_flags(a0)	; set onscreen flag
.none
		move.w	(sp)+,d3; restore d3
		rts
.xfail
; x happens at the end of rendering
; all the mapping frame was incremented and almost all the other sprite data was written
; in the case something else doesn't overwrite this, it removes the data at the end of rendering
		subq.w	#8-2,a6
		dbf	d4,.loop
		bra.s	.endcheckrndr
.yfail
; y happens at the start of rendering
; only a byte of the frame was incremented, and nothing was written
		addq.w	#spritemap_size-1,a1
		dbf	d4,.loop
		bra.s	.endcheckrndr
	endm

SpriteRenderProcess_Excessive:
	lsr.b	#1,d6
	bcs.w	SpriteRenderProcess_Excessive_noXnoY.xflip
	lsr.b	#1,d6
	bcs.w	JustADotResetter_ExRndr.yflip
;	btst	#Render_XFlip,d6		; is object horizontally flipped?
;	bne.w	SpriteRenderProcess_Excessive_noXnoY.xflip	; if so, render as such
;	btst	#Render_YFlip,d6		; is object vertically flipped?
;	bne.w	JustADotResetter_ExRndr.yflip	; if so, render as such
SpriteRenderProcess_Excessive_noXnoY:
	excessrender_macro 0,0
.ydata:
	rept 4
	dc.b 8,$10,$18,$20
	endm
.xdata:
	dc.b   8,  8,  8,  8
	dc.b $10,$10,$10,$10
	dc.b $18,$18,$18,$18
	dc.b $20,$20,$20,$20
.xflip:
	lsr.b	#1,d6
	bcs.w	JustADotResetter_ExRndr.xyflip
;	btst	#Render_YFlip,d6	; is object also vertically flipped?
;	bne.w	JustADotResetter_ExRndr.xyflip	; if so, render as such
	excessrender_macro 1,0
JustADotResetter_ExRndr:	; small space optimization for data
.xyflip:
	excessrender_macro 1,1
.ydata:
	rept 4
	dc.b 8,$10,$18,$20
	endm
.xdata:
	dc.b   8,  8,  8,  8
	dc.b $10,$10,$10,$10
	dc.b $18,$18,$18,$18
	dc.b $20,$20,$20,$20
.yflip:
	excessrender_macro 0,1
; End of function SpriteRenderProcess_Excessive
; ---------------------------------------------------------------------------
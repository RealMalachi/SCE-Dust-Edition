; ---------------------------------------------------------------------------
; Object code execution subroutine
; a0 - Object Address (set to the start of Object_RAM at init)
; a1 - ROM Address from a0's object.
; d0 - this is what's used to quickly transfer a0's ROM address to a1
; the only variable you need to maintain is a0
; ObjectRAMMarker idea by lavagaming1
; ---------------------------------------------------------------------------
; placed here for branch accessibility
; this code is assuming most objects will be frozen, so is focusing on space over speed
RunSomeObjects:
.frzloop:
	move.l	address(a0),d0		; load address to d0
	bmi.s	.rts			; if we've reached ObjectRAMMarker, end routine
	beq.s	.frzskip		; if we don't have an address loaded, skip
	tst.b	object_flags(a0)	; is the object set to continue its code?
	bmi.s	.frzburn		; if so, don't stop
	tst.b	render_flags(a0)	; is on-screen flag set?
	bpl.s	.frznorndr		; if not, don't display
	bsr.w	Draw_Sprite
	bra.s	.frzcont		;
.frzburn:
	movea.l	d0,a1			; move that address to a1
	jsr	(a1)			; execute code
.frzskip:
.frznorndr:
.frzcont:
	lea	next_object(a0),a0
	bra.s	.frzloop
.rts:
	if ErrorChecks<>0
	cmpa.w	#Object_RAM_end,a0
	beq.s	+	; if not at the end of Object_RAM, force crash
	RaiseError "Exceeded Object RAM!!!:", Debug_ExceededObjectRAM
+
	endif
	rts				; 16

Process_Sprites:
RunObjects:
	lea	(Object_RAM).w,a0	; 8  ; Set to the start of Object RAM
	tst.b	(ObjectFreezeFlag).w	; 12 ; is the game set to only process some objects?
	bne.s	RunSomeObjects		; 8, 10 if frozen ; if so, branch
; okay, cycle counts. Let's assume the absolute worst with a cap of 100 objects, and an alive player
;	S2:  init (12+8+8+4+4+16+8+16+8+8+12+8+16+8)136 + main & loop ((8+8+4+4+18+16+4+8+14)x100)8,400 + end (16) = 8,552 cycles
;	S3K: init (12+8+8+12+8+16+8+16+8+4)100 + main & loop ((12+8+4+16+8+14)x100)6,200 + end (16) = 6,316 cycles
;	new: init (8+12+8)28 + main (12+8+4+16+8x100)4,800 + failed marker & loop (8+10x(100%10))180 + successful marker (12+10+16)38 = 5,046 cycles
; S2 is slightly faster at discarding unused slots, since the id system uses a byte
; S3K and new method are faster at using objects by a more considerable degree, in addition to being more flexible.
; the new method frees up d7, allowing more register use (and fixes a rather dumb crash with CPZs boss in Sonic 2)

; of course there's an obvious faster method, at the cost of ROM space
.loop:
; a     failed object takes 30 cycles
; a successful object takes 48 cycles + whatever code it runs
; the first objects per loop take an additional 8 cycles
	move.l	address(a0),d0		; 12 ; load ROM address to d0 (if not used later, a tst.l will do fine)
	bmi.s	RunSomeObjects.rts	; 8, 10 but ends routine ; if we've reached ObjectRAMMarker (or an illegal routine.), end routine
	beq.s	+			; 8, 10 but skips...     ; if we don't have an address loaded, skip
;	movea.l	address(a0),a1		; 12 ; load ROM address to a1
	movea.l	d0,a1			; 4  ; move that address to a1
	jsr	(a1)			; 16 ; execute code
+
	lea	next_object(a0),a0	; 8
	rept 10-1	; the same, but without the marker check. Due to how it's setup, it's impossible to fail (beyond poor maintainance of a0)
;	rept Object_Amount-1	; the "obvious faster method"
	move.l	address(a0),d0		; 12
	beq.s	+			; 8, 10 but skips...
;	movea.l	address(a0),a1		; 12
	movea.l	d0,a1			; 4
	jsr	(a1)			; 16
+
	lea	next_object(a0),a0	; 8
	endm

;	if ErrorChecks<>0
;	cmpa.w	#Object_RAM_end-next_object,a0
;	beq.s	+	; if not at the end of Object_RAM, force crash
;	RaiseError "Exceeded Object RAM!!!:", Debug_ExceededObjectRAM
;+
;	endif
;	move.l	address(a0),d0		; 12
;	beq.s	+			; 8, 10 but skips...
;	movea.l	d0,a1			; 4
;	jmp	(a1)			; 8
;+
;	rts
	bra.s	.loop			; 10
; End of function Process_Sprites
; ------------------------------------------------------------------------
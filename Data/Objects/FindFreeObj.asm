; ---------------------------------------------------------------------------
; Subroutine to find a free object space
; input:
; a0 (Create_New_Sprite3)   = Object in Dynamic_object_RAM
; a1 (Create_New_Sprite4,5) = Arbitrary position in Dynamic_object_RAM
; output:
; d0 (Create_New_Sprite)    = loop
; a1 = free position in object RAM
; Always follow up with a bne that skips loading the object, in the case it fails
; ---------------------------------------------------------------------------
; TODO: createsprite_macro
; functions as an inlined version of the code, better designed around being inlined
; a lot of code will gain some advantage by copying Create_New_Sprite4 especially

; =============== S U B R O U T I N E =======================================
; find free object from start of dynamic object RAM to the end
FindFreeObj:
SingleObjLoad:
Create_New_Sprite:
	lea	(Dynamic_object_RAM-next_object).w,a1	; start address for dynamic object RAM
	moveq	#((Dynamic_object_RAM_end-Dynamic_object_RAM)/object_size)-1,d0
.cont
.loop
	lea	next_object(a1),a1	; goto next object RAM slot
.arbitrary
	tst.l	address(a1)		; is object RAM slot empty?
	dbeq	d0,.loop		; if so, rts. Otherwise, loop. If loop counter hits 0, rts
	rts
; ---------------------------------------------------------------------------
; find free object from start of dynamic object RAM to the end, without the use of d0
; NOTICE: This differs from Sonic 3 and Knuckles' version, which was basically a copy of Create_New_Sprite3
Create_New_Sprite2:
	lea	(Dynamic_object_RAM).w,a1	; start address for dynamic object RAM
	bra.s	Create_New_Sprite5		; skip next_object the first time around
; find free object directly after another object, or whatever's in a0
SingleObjLoad2:
FindNextFreeObj:
Create_New_Sprite3:
	movea.l	a0,a1
;	lea	(a0),a1
; find free slot starting directly after an arbitrary position (assumed to be in Dynamic_Object_RAM)
; commonly used as a continuation in object creating loops
Create_New_Sprite4:
.loop
	lea	next_object(a1),a1	; advance from the main object to the next slot
; find free slot starting in an arbitrary position (assumed to be in Dynamic_Object_RAM)
Create_New_Sprite5:
	if ErrorChecks<>0
	cmpa.w	#Object_RAM,a1		; if before the start, force crash
	blo.s	+
	cmpa.w	#Object_RAM_end,a1	; if beyond the end, force crash
	ble.s	++	; if neither, success! branch
+
	RaiseError "Exceeded Object RAM when creating an object!!!:", Debug_TriedFindingSlotsBeyondObjectRAM
+
	endif
	tst.l	address(a1)		; test the object address
	beq.s	.foundfreeobj		; if this object slot is free, then set its codes after this routine
	bpl.s	Create_New_Sprite4.loop	; loop if we didn't find a clear object or reach ObjectRamMarker
; if we hit ObjectRamMarker, end routine (Can stop at $80000000, but ROM addresses can't go beyond $003F0000 or $009F0000)
; the bne does the rest
.foundfreeobj:
	rts
; End of function Create_New_Sprite
; ---------------------------------------------------------------------------
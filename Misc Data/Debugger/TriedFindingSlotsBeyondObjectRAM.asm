; Called when Create_New_Sprite goes before of beyond Object_RAM
; TODO: Add it to inlined macro version
Debug_TriedFindingSlotsBeyondObjectRAM:
	lea	(Object_RAM_end).w,a0	;
	Console.Write "Intended RAM End: %<.l a0> "
;	Console.Write "Intended RAM End: %<.l Object_RAM_End> "
	Console.BreakLine
	Console.Write "Final Object (a1): %<.l a1> "
	Console.BreakLine
	Console.Write "RAM Marker: %<.b ObjectRamMarker> "
	rts
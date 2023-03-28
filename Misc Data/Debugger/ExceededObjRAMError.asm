; Called when Run_Objects exceeds the allocated space in Object RAM, (logically) assuming an error
; most errors would be caused by tampering with the address of a0
Debug_ExceededObjectRAM:
	lea	(Object_RAM_end).w,a1	; admittedly, a hackish solution to get the ending RAM address.
	Console.Write "Intended RAM End: %<.l a1> "
;	Console.Write "Intended RAM End: %<.l Object_RAM_end> "
	Console.BreakLine
	Console.Write "Final Object (a0): %<.l a0> "
	Console.BreakLine
	Console.Write "RAM Marker: %<.b ObjectRamMarker> "
	Console.BreakLine
	rts

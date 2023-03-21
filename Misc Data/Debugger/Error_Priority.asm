Debug_Priority:
	Console.Write "Object Address: %<.l a0> "
	Console.BreakLine
	move.l	address(a0),d0
	Console.Write "Object: %<.l d0> "
	Console.BreakLine
	move.l	a1,d0
	Console.Write "Priority Address: %<.w d0> "
	Console.BreakLine
	sub.w	#Sprite_table_input,d0
	Console.Write "Priority: %<.w d0> "
	Console.BreakLine
	divu.w	#object_size,d0
	Console.Write "Priority ID: %<.w d0> "
;	Console.BreakLine
;	Console.Write "RAM Marker: %<.b ObjectRamMarker> "
	rts
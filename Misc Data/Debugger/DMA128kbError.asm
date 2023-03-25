; Called when the game REALLY doesn't want 128kb DMAs
Debug_DMA128kbError:
	move.l	d1,d7
	lsl.l	#1,d7	; adjust d1 to a readable address
	Console.Write "Art    (d1): %<.w d1> (%<.l d7 sym>)"	; location of the art

	Console.BreakLine
	move.w	d3,d7
	lsr.w	#4,d7	; adjust to a readable number
	Console.Write "Amount (d3): %<.w d3> (%<.w d7 dec>)"	; the amount of tiles it tried to DMA

	Console.BreakLine
	Console.Write "Total  (d0): %<.w d0>"	; the calculation that determined it wasn't safe to begin with

	Console.BreakLine
	move.l	address(a0),d7
	Console.Write "Object (a0): %<.l d7 sym> (%<.l a0>)"	; Object code and RAM addresses (if it is one)
	rts
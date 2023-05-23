; ---------------------------------------------------------------------------

-	; used for !org
; Hardware capabilities bitfield.
; A bunch of flags to approximately determine which machine revision you own, separately from determining if you have hardware at all
	phase 0		; Hard on
hard_tasmanian		ds.b 1		; TAS memory error flag
hard_v3050		ds.b 1		; note: set if hardware support V30 at all
hard_v3060		ds.b 1
	dephase
; Addons bitfield
; I feel like there are gonna be more in the future. So, the code is built to be safely extended into a long
	phase 0
addon_32x		ds.b 1	; TODO: Make use
addon_cdhardware	ds.b 1	; real MegaCD hardware
addon_mcd		ds.b 1	; MegaCD functionality, but not strictly real hardware (such as flashcarts)
addon_everdrive		ds.b 1	; TODO: Everything ; Everdrive Pro
addon_megasd		ds.b 1	; TODO: Everything
addon_retrolink		ds.b 1	; TODO: Make use
addon_megawifi		ds.b 1	; TODO: Everything
addon_wifi		ds.b 1	; TODO: Make use ; some form of wifi
	dephase
; Emulator ID
; TODO: add clownmdemu?
	phase 0
EMU_HARDWARE		ds.b 1		; Hardware
EMU_GPGX		ds.b 1		; Genesis Plus GX
EMU_REGEN		ds.b 1		; Regen
EMU_KEGA		ds.b 1		; Kega Fusion
EMU_GENS		ds.b 1		; Gens
EMU_BLASTEM_OLD		ds.b 1		; Old versions of BlastEm
EMU_EXODUS		ds.b 1		; Exodus
EMU_MEGASG		ds.b 1		; Mega Sg
EMU_STEAM		ds.b 1		; Steam
EMU_PICODRIVE		ds.b 1		; Picodrive
EMU_FLASHBACK		ds.b 1		; AtGames Flashback
EMU_FIRECORE		ds.b 1		; AtGames Firecore
EMU_GENECYST		ds.b 1		; Genecyst
	dephase
	!org -
; ---------------------------------------------------------------------------
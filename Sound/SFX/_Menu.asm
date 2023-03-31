; https://github.com/MDTravisYT/Hiroshi-Kubota-SMPS-Decomps/blob/main/Sonic/Sonic%202/Simon%20Wai/D8%20-%20Bonus%20Bumper.asm
Sound_MenuHeader:
	smpsHeaderStartSong 2
	smpsHeaderVoice     Sound_MenuVoices
	smpsHeaderTempoSFX  $01
	smpsHeaderChanSFX   $01

	smpsHeaderSFXChannel cFM5, Sound_MenuFM5, $00, $00

; FM5 Data
Sound_MenuFM5:
	smpsSetvoice        $00
	dc.b	nFs4, $03, nBb4, $03, nBb5, $0A

Sound_MenuLoop00:
	smpsAlterVol        $08
	dc.b	nBb5, $05, nRst, $05
	smpsLoop            $00, $03, Sound_MenuLoop00
	smpsStop

Sound_MenuVoices:
;	Voice $00
;	$3C
;	$05, $01, $0A, $01, 	$56, $5C, $5C, $5C, 	$0E, $11, $11, $11
;	$09, $0A, $06, $0A, 	$4F, $3F, $3F, $3F, 	$17, $80, $20, $80
	smpsVcAlgorithm     $04
	smpsVcFeedback      $07
	smpsVcUnusedBits    $00
	smpsVcDetune        $00, $00, $00, $00
	smpsVcCoarseFreq    $01, $0A, $01, $05
	smpsVcRateScale     $01, $01, $01, $01
	smpsVcAttackRate    $1C, $1C, $1C, $16
	smpsVcAmpMod        $00, $00, $00, $00
	smpsVcDecayRate1    $11, $11, $11, $0E
	smpsVcDecayRate2    $0A, $06, $0A, $09
	smpsVcDecayLevel    $03, $03, $03, $04
	smpsVcReleaseRate   $0F, $0F, $0F, $0F
	smpsVcTotalLevel    $00, $20, $00, $17

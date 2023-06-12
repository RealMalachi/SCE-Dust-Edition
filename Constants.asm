; ===========================================================================
; Constants
; ===========================================================================

; ---------------------------------------------------------------------------
; Misc
; ---------------------------------------------------------------------------

Ref_Checksum_String			= 'INIT'
Security_addr =				$A14000	; 
Security_flag =				$A14101	;

; ---------------------------------------------------------------------------
; VDP addresses
; ---------------------------------------------------------------------------

VDP_data_port =				$C00000
VDP_control_port =			$C00004
VDP_counter =				$C00008
VDP_h_counter =				VDP_counter
VDP_v_counter =				VDP_counter+1

PSG_input =				$C00011

VDP_debug_reg =				$C0001C

; ---------------------------------------------------------------------------
; Address equates
; ---------------------------------------------------------------------------

; Z80 addresses
Z80_RAM =				$A00000	; start of Z80 RAM
Z80_RAM_end =				$A02000	; end of non-reserved Z80 RAM
Z80_Sound =				$A04000

Z80_bus_request =			$A11100
Z80_reset =				$A11200

; ---------------------------------------------------------------------------
; I/O Area
; ---------------------------------------------------------------------------

HW_Version =				$A10001
HW_Port_1_Data =			$A10003
HW_Port_2_Data =			$A10005
HW_Expansion_Data =			$A10007
HW_Port_1_Control =			$A10009
HW_Port_2_Control =			$A1000B
HW_Expansion_Control =			$A1000D
HW_Port_1_TxData =			$A1000F
HW_Port_1_RxData =			$A10011
HW_Port_1_SCtrl =			$A10013
HW_Port_2_TxData =			$A10015
HW_Port_2_RxData =			$A10017
HW_Port_2_SCtrl =			$A10019
HW_Expansion_TxData =			$A1001B
HW_Expansion_RxData =			$A1001D
HW_Expansion_SCtrl =			$A1001F

; ---------------------------------------------------------------------------
; SRAM addresses
; ---------------------------------------------------------------------------
	if AddressSRAM=3
SRAM_Address =				$200001	; Odd
	else
SRAM_Address =				$200000	; Even
	endif
SRAM_access_flag =			$A130F1
SRAM_InitText_String			= 'VMAL'
SRAM_InitText_String2			= 'ACHI'
SRAM_GameVersion =			0		; change this every time the SRAM changes for a retail version
SRAM_DefaultSettings =			%10000000

; used for handling the unused bytes of SRAM
	if AddressSRAM=0
sramaddr macro num,saveramflag
	if ("saveramflag"="")
	ds.b	num
	elseif saveramflag = 0
	ds.b	num_end-num
	elseif saveramflag = 1
	ds.b	num_end-num
	else
	fatal "Undefined SRAM addressing type"
	endif
	endm
SRAM_RAMSize	= 1
	else
sramaddr macro num,saveramflag
	if ("saveramflag"="")
	ds.w	num
	elseif saveramflag = 0
	ds.w	num_end-num
	elseif saveramflag = 1
	ds.b	num_end-num
	else
	fatal "Undefined SRAM addressing type"
	endif
	endm
SRAM_RAMSize	= 2
	endif
; padding for word and longword data, to ensure AddressSRAM type 0 doesn't crash
srampad macro
	if AddressSRAM=0
	  if (*)&1
	ds.b 1
	  endif
	endif
	endm
sram_checkace macro
	if * >= $200000
	fatal "Code that's handling SRAM is in SRAM bankswitch area"
	endif
	endm

; Emulates structs without using AS' structs, by separating it from the main SRAM labels
; Also frequently used in RAM, so it helps simplify setting that up
	phase 0
sram_main
sram_main_lives		sramaddr 1
sram_main_continues	sramaddr 1
sram_main_emeraldcount	sramaddr 1
	srampad
sram_main_emeraldarray	sramaddr 2
sram_main_end
	dephase
; Proof of concept
	phase 0
sram_submode
	sramaddr 2
sram_submode_end
	dephase


	phase 0
sram_start
sram_checksum	sramaddr 2
sram_inittext	sramaddr 4
sram_inittext2	sramaddr 4
sram_version	sramaddr 1
	sramaddr 1	; just in case
sram_afterchecks
; universal save data
sram_settings	sramaddr 1
	srampad
; separate save data
sram_saves
sramsave1	sramaddr sram_main,1
	srampad
sramsave2	sramaddr sram_main,1
	srampad
sramsub		sramaddr sram_submode,1
	srampad
sram_saves_end
; copy of separate save data
sram_copy	sramaddr sram_saves,1
sram_copy_end

sram_static;	sramaddr 1
sram_static_end
	srampad

sram_padding
; padding fixes some save data issues, notably on BlastEm
; this space can potentially hold junk data, and should never be read
	sramaddr $FF-(*/SRAM_RAMSize)
sram_end
	if * >= $200000
	fatal "SRAM exceeds its maximum limit of $200000 bytes! Fix immediately."
	elseif * > $FFFF
	  if MOMPASS=0
	message "SRAM exceeds word length. It'll still work, just please try to optimize it a little."
	  endif
	endif
	dephase
; ---------------------------------------------------------------------------
; MCD addresses
; ---------------------------------------------------------------------------
CdBootRom =			$400000   ; Main-CPU boot ROM
CdBootRom_SEGA =		$400100
CdPrgRam =			$420000   ; PRG-RAM window
CdWordRam =			$600000   ; WORD-RAM window

CdSubCtrl =			$A12000   ; Sub-CPU reset/busreq, etc.
CdMemCtrl =			$A12002   ; Mega CD memory mode, bank, etc.
; Main-CPU to Sub-CPU ports
CdCommMain1 =			$A12010
CdCommMain2 =			$A12012
CdCommMain3 =			$A12014
CdCommMain4 =			$A12016
CdCommMain5 =			$A12018
CdCommMain6 =			$A1201A
CdCommMain7 =			$A1201C
CdCommMain8 =			$A1201E
; Sub-CPU to Main-CPU ports
CdCommSub1 =			$A12020
CdCommSub2 =			$A12022
CdCommSub3 =			$A12024
CdCommSub4 =			$A12026
CdCommSub5 =			$A12028
CdCommSub6 =			$A1202A
CdCommSub7 =			$A1202C
CdCommSub8 =			$A1202E
; ---------------------------------------------------------------------------
; 32x addresses
; ---------------------------------------------------------------------------
S32x_Signature =		$A130EC		; reads 'MARS' if 32x is attached
S32x_Reg0 =			$A15180
S32x_PWM_Comm =			$A15128		; as used in Clonedriver

; ---------------------------------------------------------------------------
; Flashcart addresses
; ---------------------------------------------------------------------------
; MegaSD: 3F7F6h-3FFFFh, can seemingly only read and write in words
; Functions similar to SRAM, so code you intend to run shouldn't overlap with MSD addresses
MSD_OverlaySignature =		$03F7F6		; 'RATE' if overlay port was successful
MSD_OverlayPort =		$03F7FA		; write $CD54 to enable MegaSD control
MSD_ResultPort =		$03F7FC
MSD_CommandPort =		$03F7FE
MSD_ParameterData =		$03F800		; data from the ARM cpu

MSD_OverlayValue =		$CD54

; ---------------------------------------------------------------------------
; Wifi Hardware addresses
; ---------------------------------------------------------------------------
	if EnableWifi=1
; MegaWifi

; RetroLink
UART_RHR =			$A130C1		; Receive holding register
UART_THR =			UART_RHR	; Transmit holding register
UART_IER =			$A130C3		; Interrupt enable register
UART_FCR =			$A130C5		; FIFO control register
UART_LCR =			$A130C7		; Line control register
UART_MCR =			$A130C9		; Modem control register
UART_LSR =			$A130CB		; Line status register
UART_DLL =			UART_RHR	; Div latch low byte
UART_DLM =			UART_IER	; Div latch high byte
UART_DVID =			UART_IER	; Device ID
; D, F, and even numbers are unused, probably reserved for MegaWifi
	endif

; ---------------------------------------------------------------------------
; Level Misc
; ---------------------------------------------------------------------------

RingTable_Count:			= 512	; The maximum rings on the level. Even addresses only
ObjectTable_Count:			= 768	; The maximum objects on the level. Even addresses only

; ---------------------------------------------------------------------------
; PLC queues
; ---------------------------------------------------------------------------

PLCKosM_Count:				= 20		; The greater the queues, the more RAM is used for the buffer

; ---------------------------------------------------------------------------
; Resolution
; ---------------------------------------------------------------------------

; The hardware supports two horizontal screen size modes; 32 tiles and 40 tiles
; H32 is the default for SMS compatability, and got stretched by the TVs at the time to odd rectangles. A lot of consoles had this as the only option
; H40 usually displays as square pixels, which is much easier to work with in our modern displays, and generally adds more detail to art
; An interesting thing about this, is that it basically just adds an extra 8 rows of tiles. The same is true for widescreen, ironically enough
ScreenSize_H64	= 512 ; 64 tiles*8 ;
ScreenSize_H40	= 320 ; 40 tiles*8
ScreenSize_H32	= 256 ; 32 tiles*8
;ScreenSize_H40	= 384 ; 48 tiles*8	; 8:5 aspect ratio
;ScreenSize_H32	= 320 ; 40 tiles*8

; the hardware also supports two vertical screen modes, but the displayed width depends on either emulation or the consoles Hz rate
; If 60Hz, 224 lines are visible
; If 50Hz, 240 lines are visible
; Most emulators support V30 60Hz, while some don't support V30 at all. Make sure to account for this.
ScreenSize_V28	= 224 ; 28 tiles
ScreenSize_V30	= 240 ; 30 tiles
ScreenSize_LineCount 	= ScreenSize_V30 ; for simplicity, most code uses PAL sizes

; ---------------------------------------------------------------------------
; Game modes
; ---------------------------------------------------------------------------

offset :=	Game_Modes
ptrsize :=	1
idstart :=	0

id_LevelSelectScreen =			id(ptr_LevelSelect)		; 0
id_LevelScreen =			id(ptr_Level)			; 4
id_ContinueScreen =			id(ptr_Continue)		; 8
	if GameDebug
id_Detection =				id(ptr_Detection)
	endif

GameModeFlag_TitleCard =		7				; flag bit
GameModeID_TitleCard =			1<<GameModeFlag_TitleCard	; flag mask

; ---------------------------------------------------------------------------
; Sonic routines
; ---------------------------------------------------------------------------

offset :=	Sonic_Index
ptrsize :=	1
idstart :=	0

id_SonicInit =				id(ptr_Sonic_Init)		; 0
id_SonicControl =			id(ptr_Sonic_Control)		; 2
id_SonicHurt =				id(ptr_Sonic_Hurt)		; 4
id_SonicDeath =				id(ptr_Sonic_Death)		; 6
id_SonicRestart =			id(ptr_Sonic_Restart)		; 8

id_SonicDrown =				id(ptr_Sonic_Drown)		; C

; ---------------------------------------------------------------------------
; Levels
; ---------------------------------------------------------------------------

	phase -1	;
id_LNull:	ds.b 1	; -1	
id_DEZ:		ds.b 1	; 0, so on
	if * <> ZoneCount
	fatal "Level IDs haven't been properly set. $\{*} defined, $\{ZoneCount} intended"
	endif
	dephase

; ---------------------------------------------------------------------------
; Buttons bit numbers
; ---------------------------------------------------------------------------

; Input bit numbers
; NOTE: if using btst on something that isn't a data register, check the exact RAM location (Ctrl1_Hd_XYZ for example)
	phase	0	;
button_up	ds.b 1
button_down	ds.b 1
button_left	ds.b 1
button_right	ds.b 1
button_B	ds.b 1
button_C	ds.b 1
button_A	ds.b 1
button_start	ds.b 1
; 6-button controllers
; when using these, you'll get a 'truncated' notice when btst is used on something that isn't a data register
button_Z	ds.b 1
button_Y	ds.b 1
button_X	ds.b 1
button_mode	ds.b 1
; the extra four bits are unused
	dephase
; if you REALLY don't want to deal with the truncatation notice, use these instead
button6_Z =	button_Z-8
button6_Y =	button_Y-8
button6_X =	button_X-8
button6_mode =	button_mode-8
; Input numbers (masks??). Essentially the byte number the bits represent
; these allow checking more then one button press at the same time (like jumping using A,B,C)
; 1 << x == pow(2, x)
button_up_mask =	1<<button_up	;   $01
button_down_mask =	1<<button_down	;   $02
button_left_mask =	1<<button_left	;   $04
button_right_mask =	1<<button_right	;   $08
button_B_mask =		1<<button_B	;   $10
button_C_mask =		1<<button_C	;   $20
button_A_mask =		1<<button_A	;   $40
button_start_mask =	1<<button_start	;   $80
button_Z_mask =		1<<button_Z	; $0100
button_Y_mask =		1<<button_Y	; $0200
button_X_mask =		1<<button_X	; $0400
button_mode_mask =	1<<button_mode	; $0800
; additional ones for ease of code
button_directional_mask =	button_up_mask|button_down_mask|button_left_mask|button_right_mask	; $F
button_ABC_mask =		button_B_mask|button_C_mask|button_A_mask	; $70
button_XYZ_mask =		button_Z_mask|button_Y_mask|button_X_mask	; $0700

; smaller variants
btnM =		button_mode_mask			; Mode button
btnX =		button_X_mask				; X
btnY =		button_Y_mask				; Y
btnZ =		button_Z_mask				; Z
btnS =		button_start_mask			; Start button
btnA =		button_A_mask				; A
btnC =		button_C_mask				; C
btnB =		button_B_mask				; B
btnR =		button_right_mask			; Right
btnL =		button_left_mask			; Left
btnD =		button_down_mask			; Down
btnU =		button_up_mask				; Up
btnXYZM =	button_XYZ_mask|button_mode_mask	; X, Y, Z or Mode
btnXYZ =	button_XYZ_mask				; X, Y, or Z
btnXY =		button_X_mask|button_Y_mask		; X or Y
btnXZ =		button_X_mask|button_Z_mask		; X or Z
btnYZ =		button_Y_mask|button_Z_mask		; Y or Z
btnABCS =	button_ABC_mask|button_start_mask	; A, B, C or Start
btnABC =	button_ABC_mask				; A, B or C
btnAB =		button_A_mask|button_B_mask		; A or B
btnAC =		button_A_mask|button_C_mask		; A or C
btnBC =		button_C_mask|button_B_mask		; B or C
btnDir =	button_directional_mask			; Any direction
btnLR =		button_left_mask|button_right_mask	; Left or Right
btnUD =		button_up_mask|button_down_mask		; Up or Down

bitM =		button_mode
bitX =		button_X
bitY =		button_Y
bitZ =		button_Z
bitS =		button_start
bitA =		button_A
bitC =		button_C
bitB =		button_B
bitR =		button_right
bitL =		button_left
bitD =		button_down
bitU =		button_up


btnMode =	btnM
btnMo =		btnM
btnStart =	btnS
btnSt =		btnS
btnDn =		btnD
btnUp =		btnU

bitMode =	bitM
bitMo =		bitM
bitStart =	bitS
bitSt =		bitS
bitDn =		bitD
bitUp =		bitU



; ---------------------------------------------------------------------------
; Art tile stuff
; ---------------------------------------------------------------------------

	include "VRAM.asm"

flip_x				= (1<<11)
flip_y				= (1<<12)
palette_bit_0			= 5
palette_bit_1			= 6
palette_line0			= (0<<13)
palette_line_0			= (0<<13)
palette_line1			= (1<<13)
palette_line_1			= (1<<13)
palette_line2			= (2<<13)
palette_line_2			= (2<<13)
palette_line3			= (3<<13)
palette_line_3			= (3<<13)
high_priority_bit		= 7
high_priority			= (1<<15)
palette_mask			= $6000
tile_size			= $20
tile_mask			= $7FF
nontile_mask			= $F800
drawing_mask			= $7FFF

; ---------------------------------------------------------------------------
; Colours
; ---------------------------------------------------------------------------

cBlack:				equ $000		; colour black
cWhite:				equ $EEE		; colour white
cBlue:				equ $E00		; colour blue
cGreen:				equ $0E0		; colour green
cRed:				equ $00E		; colour red
cYellow:			equ cGreen+cRed		; colour yellow
cAqua:				equ cGreen+cBlue	; colour aqua
cMagenta:			equ cBlue+cRed		; colour magenta

palette_line_size		= 16*2			; 16 word entries
; ---------------------------------------------------------------------------
; Object stuff
; ---------------------------------------------------------------------------

	include "Objects/Constants.asm"

; ---------------------------------------------------------------------------

	include "Data/Hardware Detection/Constants.asm"

	!org	0		; Reset the program counter

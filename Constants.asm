; ===========================================================================
; Constants
; ===========================================================================

Ref_Checksum_String			= 'INIT'

; ---------------------------------------------------------------------------
; VDP addresses
; ---------------------------------------------------------------------------

VDP_data_port =				$C00000
VDP_control_port =			$C00004
VDP_counter =				$C00008

PSG_input =				$C00011

; ---------------------------------------------------------------------------
; Address equates
; ---------------------------------------------------------------------------

; Z80 addresses
Z80_RAM =				$A00000	; start of Z80 RAM
Z80_RAM_end =				$A02000	; end of non-reserved Z80 RAM
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
SRAM_Size =				$200000

SRAM_access_flag =			$A130F1
Security_addr =				$A14000

; ---------------------------------------------------------------------------
; MCD addresses
; ---------------------------------------------------------------------------
CdBootRom =				$400000   ; Main-CPU boot ROM
CdBootRom_SEGA =			$400100
CdPrgRam =				$420000   ; PRG-RAM window
CdWordRam =				$600000   ; WORD-RAM window

CdSubCtrl =				$A12000   ; Sub-CPU reset/busreq, etc.
CdMemCtrl =				$A12002   ; Mega CD memory mode, bank, etc.
; Main-CPU to Sub-CPU ports
CdCommMain1 =				$A12010
CdCommMain2 =				$A12012
CdCommMain3 =				$A12014
CdCommMain4 =				$A12016
CdCommMain5 =				$A12018
CdCommMain6 =				$A1201A
CdCommMain7 =				$A1201C
CdCommMain8 =				$A1201E
; Sub-CPU to Main-CPU ports
CdCommSub1 =				$A12020
CdCommSub2 =				$A12022
CdCommSub3 =				$A12024
CdCommSub4 =				$A12026
CdCommSub5 =				$A12028
CdCommSub6 =				$A1202A
CdCommSub7 =				$A1202C
CdCommSub8 =				$A1202E
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
; Game modes
; ---------------------------------------------------------------------------

offset :=	Game_Modes
ptrsize :=	1
idstart :=	0

id_LevelSelectScreen =			id(ptr_LevelSelect)		; 0
id_LevelScreen =			id(ptr_Level)			; 4
id_ContinueScreen =			id(ptr_Continue)		; 8

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
button_up:	ds.b 1
button_down:	ds.b 1
button_left:	ds.b 1
button_right:	ds.b 1
button_B:	ds.b 1
button_C:	ds.b 1
button_A:	ds.b 1
button_start:	ds.b 1
; 6-button controllers
; when using these, you'll get a 'truncated' notice when btst is used on something that isn't a data register
button_Z:	ds.b 1
button_Y:	ds.b 1
button_X:	ds.b 1
button_mode:	ds.b 1
; the extra four bits are used to figure out which controller type is plugged in
	dephase		; Reset the program counter
; if you REALLY don't want to deal with the truncatation notice, use these instead
button6_Z:	= button_Z-8
button6_Y:	= button_Y-8
button6_X:	= button_X-8
button6_mode:	= button_mode-8
; Input numbers (masks??). Essentially the byte number the bits represent
; these allow checking more then one button press at the same time (like jumping using A,B,C)
; 1 << x == pow(2, x)
button_up_mask:		= 1<<button_up		;   $01
button_down_mask:	= 1<<button_down	;   $02
button_left_mask:	= 1<<button_left	;   $04
button_right_mask:	= 1<<button_right	;   $08
button_B_mask:		= 1<<button_B		;   $10
button_C_mask:		= 1<<button_C		;   $20
button_A_mask:		= 1<<button_A		;   $40
button_start_mask:	= 1<<button_start	;   $80
button_Z_mask:		= 1<<button_Z		; $0100
button_Y_mask:		= 1<<button_Y		; $0200
button_X_mask:		= 1<<button_X		; $0400
button_mode_mask:	= 1<<button_mode	; $0800
; additional ones for ease of code
button_directional_mask:	= button_up_mask+button_down_mask+button_left_mask+button_right_mask	; $F
button_ABC_mask:		= button_B_mask+button_C_mask+button_A_mask	; $70
button_XYZ_mask:		= button_Z_mask+button_Y_mask+button_X_mask	; $0700

btnMode:	equ button_mode_mask			; Mode ($800)
btnX:		equ button_X_mask			; X ($400)
btnY:		equ button_Y_mask			; Y ($200)
btnZ:		equ button_Z_mask			; Z ($100)
btnR:		equ button_right_mask			; Right ($08)
btnL:		equ button_left_mask			; Left ($04)
btnUD:		equ button_up_mask|button_down_mask	; Up or Down ($03)
btnDn:		equ button_down_mask			; Down ($02)
btnUp:		equ button_up_mask			; Up ($01)
btnLR:		equ button_left_mask|button_right_mask	; Left or Right ($0C)
btnDir:		equ button_directional_mask		; Any direction ($0F)
btnABCS:	equ button_ABC_mask|button_start_mask	; A, B, C or Start ($F0)
btnStart:	equ button_start_mask			; Start button ($80)
btnABC:		equ button_ABC_mask			; A, B or C ($70)
btnAC:		equ button_A_mask|button_C_mask		; A or C ($60)
btnAB:		equ button_A_mask|button_B_mask		; A or B ($50)
btnA:		equ button_A_mask			; A ($40)
btnBC:		equ button_C_mask|button_B_mask		; B or C ($30)
btnC:		equ button_C_mask			; C ($20)
btnB:		equ button_B_mask			; B ($10)

bitMode:	equ button_mode
bitX:		equ button_X
bitY:		equ button_Y
bitZ:		equ button_Z
bitStart:	equ button_start
bitA:		equ button_A
bitC:		equ button_C
bitB:		equ button_B
bitR:		equ button_right
bitL:		equ button_left
bitDn:		equ button_down
bitUp:		equ button_up


; ---------------------------------------------------------------------------
; property of all objects
; ---------------------------------------------------------------------------

object_size =		$4A	; the size of an object's status table entry
next_object =		object_size

; ---------------------------------------------------------------------------
; Object Status Table offsets
; Common object conventions:
; ---------------------------------------------------------------------------
	phase 0
;id			; TODO: Doesn't apply to S3K.
address			ds.l 1 ; long ; Direct ROM address to object code
render_flags		ds.b 1 ; bitfield ; refer to SCHG for details
routine			ds.b 1 ; byte
height_pixels		ds.b 1 ; byte
width_pixels		ds.b 1 ; byte
priority		ds.w 1 ; word ; in units of $80
art_tile		ds.w 1 ; word ; PCCVHAAA AAAAAAAA ; P = priority, C = palette line, V = y-flip, H = x-flip, A = starting cell index of art
mappings		ds.l 1 ; long
x_pixel			; word ; x-coordinate for objects using screen positioning
x_pos			ds.w 1 ; word, long when extra precision is required
x_sub			ds.w 1 ; word
y_pixel			; word ; y-coordinate for objects using screen positioning
y_pos			ds.w 1 ; word, long when extra precision is required
y_sub			ds.w 1 ; word

x_vel			ds.w 1 ; word
y_vel			ds.w 1 ; word
inertia		; TODO: not that many objects outside of the player use ground_vel. Maybe make it exclusive
ground_vel		ds.w 1 ; word ; overall velocity along ground, not updated when in the air
y_radius		ds.b 1 ; byte ; collision height / 2
x_radius		ds.b 1 ; byte ; collision width / 2
anim			ds.b 1 ; byte
next_anim	; when this isn't equal to anim the animation restarts (yes, previous and next are the same in this context)
prev_anim		ds.b 1 ; byte ; when this isn't equal to anim the animation restarts
mapping_frame		ds.b 1 ; byte
anim_frame		ds.b 1 ; byte
anim_frame_timer	ds.b 1 ; byte

collision_backup	ds.b 1 ; $25, byte ; commonly used for a copy of collision_flags
angle			ds.b 1 ; byte ; angle about axis into plane of the screen (00 = vertical, 360 degrees = 256)
	ds.b 1 ; $27
collision_flags		ds.b 1 ; byte ; TT SSSSSS ; TT = collision type, SSSSSS = size
collision_property	ds.b 1 ; byte ; usage varies, bosses use it as a hit counter
status			ds.b 1 ; bitfield ; refer to SCHG for details
shield_reaction		ds.b 1 ; byte ; bit 3 = bounces off shield, bit 4 = negated by fire shield, bit 5 = negated by lightning shield, bit 6 = negated by bubble shield
subtype			ds.b 1 ; byte
	ds.b 1	; $2D, Super Flickies use this to mark that the object's been locked on to. Overlaps with multidraw.
wait			ds.w 1 ; word
aniraw			ds.l 1 ; long
jump			ds.l 1 ; long
	ds.b 1	; $38, unknown, but usually a bitfield of some type
count			ds.b 1 ; byte
	ds.b 1	; $3A, unknown
ros_bit			ds.b 1 ; byte ; the bit to be cleared when an object is destroyed if the ROS flag is set
routine_secondary	; byte ; used by monitors for this purpose at least
ros_addr		ds.w 1 ; word ; the RAM address whose bit to clear when an object is destroyed if the ROS flag is set
	ds.w 1	; $3E, $3F, unknown
vram_art		ds.w 1 ; word ; address of art in VRAM (same as art_tile * $20)
parent		; ds.w 1 ; word ; address of the object that owns or spawned this one, if applicable
child_dx		ds.b 1 ; byte ; X offset of child relative to parent
child_dy		ds.b 1 ; byte ; Y offset of child relative to parent
parent4			ds.w 1 ; word
parent3			ds.w 1 ; word ; parent of child objects
parent2		; ds.w 1 ; word ; several objects use this instead
respawn_addr		ds.w 1 ; word ; the address of this object's entry in the respawn table
	if * > object_size
	fatal "Standard Object variables are too big by $\{*-object_size} bytes"
	endif
	dephase
; ---------------------------------------------------------------------------
; Conventions specific to Sonic/Tails/Knuckles:
; ---------------------------------------------------------------------------

	phase collision_backup
double_jump_property	ds.b 1 ; byte ; remaining frames of flight / 2 for Tails, gliding-related for Knuckles
	ds.b 1	; $26 ; angle
flip_angle		ds.b 1 ; byte ; angle about horizontal axis (360 degrees = 256)
	ds.b 2	; $28, $29 ; unused????
	ds.b 1	; $2A ; status
status_secondary	ds.b 1 ; byte ; see SCHG for details

air_left		ds.b 1 ; byte
flip_type		ds.b 1 ; byte ; bit 7 set means flipping is inverted, lower bits control flipping type
object_control		ds.b 1 ; byte ; bit 0 set means character can jump out, bit 7 set means he can't
double_jump_flag	ds.b 1 ; byte ; meaning depends on current character, see SCHG for details
flips_remaining		ds.b 1 ; byte
flip_speed		ds.b 1 ; byte
move_lock		ds.w 1 ; word ; horizontal control lock, counts down to 0
invulnerability_timer	ds.b 1 ; byte ; decremented every frame
invincibility_timer	ds.b 1 ; byte ; decremented every 8 frames
speed_shoes_timer	ds.b 1 ; byte ; decremented every 8 frames
status_tertiary		ds.b 1 ; byte ; see SCHG for details
character_id		ds.b 1 ; byte ; 0 = Sonic, 1 = Tails, 2 = Knuckles
scroll_delay_counter	ds.b 1 ; byte ; incremented each frame the character is looking up/down, camera starts scrolling when this reaches 120
next_tilt		ds.b 1 ; byte ; angle on ground in front of character
tilt			ds.b 1 ; byte ; angle on ground
stick_to_convex		ds.b 1 ; byte ; used to make character stick to convex surfaces such as the rotating discs in CNZ
spin_dash_flag		ds.b 1 ; byte ; bit 1 indicates spin dash, bit 7 indicates forced roll
restart_timer		; word
spin_dash_counter	ds.w 1 ; word
jumping			ds.b 1 ; byte
mapping_frame_copy	ds.b 1 ; byte, $41 ; used for DPLC routines
interact		ds.w 1 ; word ; RAM address of the last object the character stood on
default_y_radius	ds.b 1 ; byte ; default value of y_radius
default_x_radius	ds.b 1 ; byte ; default value of x_radius
top_solid_bit		ds.b 1 ; byte ; the bit to check for top solidity (either $C or $E)
lrb_solid_bit		ds.b 1 ; byte ; the bit to check for left/right/bottom solidity (either $D or $F)
	if * > object_size
	fatal "Player Object variables are too big by $\{*-object_size} bytes"
	endif
	dephase
; ---------------------------------------------------------------------------
; Conventions followed by some/most bosses:
; ---------------------------------------------------------------------------

boss_invulnerable_time =	ground_vel		; byte ; flash time
collision_restore_flags =	collision_backup	; byte ; restore collision after hit
boss_hitcount2 =		collision_property	; byte ; usage varies, bosses use it as a hit counter

; ---------------------------------------------------------------------------
; When childsprites are activated (i.e. bit #6 of render_flags set)
; ---------------------------------------------------------------------------
next_subspr		= 6		; size between multidraw data

	phase y_sub	; store child sprite amount in y_sub... TODO, uhh, maybe don't.
mainspr_childsprites 	ds.w 1	; amount of child sprites

sub2_x_pos		ds.w 1	; note: x and y isn't relative to the main one like child_dx, they're separate
sub2_y_pos		ds.w 1	;
		ds.b 1	; used for non-subsprite data
sub2_mapframe		ds.b 1	;
sub3_x_pos		ds.w 1
sub3_y_pos		ds.w 1
		ds.b 1
sub3_mapframe		ds.b 1
sub4_x_pos		ds.w 1
sub4_y_pos		ds.w 1
		ds.b 1	
sub4_mapframe		ds.b 1
sub5_x_pos		ds.w 1
sub5_y_pos		ds.w 1
		ds.b 1
sub5_mapframe		ds.b 1
sub6_x_pos		ds.w 1
sub6_y_pos		ds.w 1
		ds.b 1
sub6_mapframe		ds.b 1
sub7_x_pos		ds.w 1
sub7_y_pos		ds.w 1
		ds.b 1
sub7_mapframe		ds.b 1
sub8_x_pos		ds.w 1
sub8_y_pos		ds.w 1
		ds.b 1
sub8_mapframe		ds.b 1
sub9_x_pos		ds.w 1
sub9_y_pos		ds.w 1
		ds.b 1
sub9_mapframe		ds.b 1
	if * > object_size
	fatal "Multidraw Object variables are too big by $\{*-object_size} bytes"
	endif
	dephase

; ---------------------------------------------------------------------------
; Unknown or inconsistently used offsets that are not applicable to Sonic:
; ---------------------------------------------------------------------------

 enum		objoff_00=$00,objoff_01,objoff_02,objoff_03,objoff_04,objoff_05,objoff_06
 nextenum	objoff_07,objoff_08,objoff_09,objoff_0A,objoff_0B,objoff_0C,objoff_0D
 nextenum	objoff_0E,objoff_0F,objoff_10,objoff_11,objoff_12,objoff_13,objoff_14
 nextenum	objoff_15,objoff_16,objoff_17,objoff_18,objoff_19,objoff_1A,objoff_1B
 nextenum	objoff_1C,objoff_1D,objoff_1E,objoff_1F,objoff_20,objoff_21,objoff_22
 nextenum	objoff_23,objoff_24,objoff_25,objoff_26,objoff_27,objoff_28,objoff_29
 nextenum	objoff_2A,objoff_2B,objoff_2C,objoff_2D,objoff_2E,objoff_2F,objoff_30
 nextenum	objoff_31,objoff_32,objoff_33,objoff_34,objoff_35,objoff_36,objoff_37
 nextenum	objoff_38,objoff_39,objoff_3A,objoff_3B,objoff_3C,objoff_3D,objoff_3E
 nextenum	objoff_3F,objoff_40,objoff_41,objoff_42,objoff_43,objoff_44,objoff_45
 nextenum	objoff_46,objoff_47,objoff_48,objoff_49

; ---------------------------------------------------------------------------
; Sonic 1-esque object variable names for backwards compatibility
; ---------------------------------------------------------------------------
;obId =			id			;
obAddress =		address			; Direct ROM address to object code
obRender =		render_flags		; bitfield for x/y flip, display mode
obRoutine =		routine			; routine number
obHeight =		height_pixels		; height/2
obWidth =		width_pixels		; width/2
obPriority =		priority		; word ; sprite stack priority -- 0 is front
obGfx =			art_tile		; palette line & VRAM setting (2 bytes)
obMap =			mappings		; mappings address (4 bytes)
obX =			x_pos			; x-axis position (2-4 bytes)
obY =			y_pos			; y-axis position (2-4 bytes)
obVelX =		x_vel			; x-axis velocity (2 bytes)
obVelY =		y_vel			; y-axis velocity (2 bytes)
obInertia =		inertia			; potential speed (2 bytes)
obAnim =		anim			; current animation
obNextAni =		next_anim		; next animation
obFrame =		mapping_frame		; current frame displayed
obAniFrame =		anim_frame		; byte
obTimeFrame =		anim_frame_timer	; byte
obAngle =		angle			; angle
obColType =		collision_flags		; collision response type
obColProp =		collision_property	; collision extra property
obStatus =		status			; orientation or mode
obSubtype =		subtype			; object subtype
obTimer =		wait			; object timer
obParent =		parent			; word ; parent of child objects
obParent4 =		parent4			; word ; parent of child objects
obParent3 =		parent3			; word ; parent of child objects
obParent2 =		parent2			; word ; parent of child objects
obRespawnNo =		respawn_addr		; word ; the address of this object's entry in the respawn table

; ---------------------------------------------------------------------------
; Bits 3-6 of an object's status after a SolidObject call is a
; bitfield with the following meaning:
; ---------------------------------------------------------------------------

p1_standing_bit			= 3
p2_standing_bit			= p1_standing_bit + 1
p1_standing			= 1<<p1_standing_bit
p2_standing			= 1<<p2_standing_bit
pushing_bit_delta		= 2
p1_pushing_bit			= p1_standing_bit + pushing_bit_delta
p2_pushing_bit			= p1_pushing_bit + 1
p1_pushing			= 1<<p1_pushing_bit
p2_pushing			= 1<<p2_pushing_bit
standing_mask			= p1_standing|p2_standing
pushing_mask			= p1_pushing|p2_pushing

; ---------------------------------------------------------------------------
; The high word of d6 after a SolidObject call is a bitfield
; with the following meaning:
; ---------------------------------------------------------------------------

p1_touch_side_bit		= 0
p2_touch_side_bit		= p1_touch_side_bit + 1
p1_touch_side			= 1<<p1_touch_side_bit
p2_touch_side			= 1<<p2_touch_side_bit
touch_side_mask			= p1_touch_side|p2_touch_side
p1_touch_bottom_bit		= p1_touch_side_bit + pushing_bit_delta
p2_touch_bottom_bit		= p1_touch_bottom_bit + 1
p1_touch_bottom			= 1<<p1_touch_bottom_bit
p2_touch_bottom			= 1<<p2_touch_bottom_bit
touch_bottom_mask		= p1_touch_bottom|p2_touch_bottom
p1_touch_top_bit		= p1_touch_bottom_bit + pushing_bit_delta
p2_touch_top_bit		= p1_touch_top_bit + 1
p1_touch_top			= 1<<p1_touch_top_bit
p2_touch_top			= 1<<p2_touch_top_bit
touch_top_mask			= p1_touch_top|p2_touch_top

; ---------------------------------------------------------------------------
; Player status variables
; ---------------------------------------------------------------------------
Status_Facing			= 0
Status_InAir			= 1
Status_Roll			= 2
Status_OnObj			= 3
Status_RollJump			= 4
Status_Push			= 5
Status_Underwater		= 6
; TODO: 7 is used, but purpose is unknown

; ---------------------------------------------------------------------------
; Player status secondary and object shield_reaction variables
; ---------------------------------------------------------------------------
Status_Shield			= 0
Status_Invincible		= 1
Status_SpeedShoes		= 2

Status_FireShield		= 4
Status_LtngShield		= 5
Status_BublShield		= 6
Status_Sliding			= 7

Shield_Reflect			= 3	; TODO: Make consistent with Status_Shield instead
Status_FireImmune		= Status_FireShield
Status_LtngImmune		= Status_LtngShield
Status_BublImmune		= Status_BublShield
; S2 labels
status_sec_hasShield:		= Status_Shield
status_sec_isInvincible:	= Status_Invincible
status_sec_hasSpeedShoes:	= Status_SpeedShoes
status_sec_isSliding:		= Status_Sliding
status_sec_hasShield_mask:	= 1<<status_sec_hasShield	; $01
status_sec_isInvincible_mask:	= 1<<status_sec_isInvincible	; $02
status_sec_hasSpeedShoes_mask:	= 1<<status_sec_hasSpeedShoes	; $04
status_sec_isSliding_mask:	= 1<<status_sec_isSliding	; $80

; ---------------------------------------------------------------------------
; Object Status Variables
; ---------------------------------------------------------------------------

Status_ObjOrienX		= 0
Status_ObjOrienY		= 1
Status_ObjTouch			= 6
Status_ObjDefeated		= 7

; ---------------------------------------------------------------------------
; Universal (used on all standard levels)
; ---------------------------------------------------------------------------

ArtTile_SpikesSprings		= $484
ArtTile_Monitors		= $4AC
ArtTile_CutsceneKnux		= $4DA
ArtTile_StarPost		= $5E4
ArtTile_Player_1		= $680
ArtTile_Player_2		= $6A0
ArtTile_Player_2_Tail		= $6B0
ArtTile_Ring			= $6BC
ArtTile_Ring_Sparks		= ArtTile_Ring+4
ArtTile_HUD			= $6C4
ArtTile_Shield			= $79C
ArtTile_Shield_Sparks		= ArtTile_Shield+$1F
ArtTile_LifeIcon		= $7D4
ArtTile_DashDust		= $7E0
ArtTile_DashDust_P2		= $7F0

; ---------------------------------------------------------------------------
; VRAM data
; ---------------------------------------------------------------------------

vram_fg:			= $C000 ; foreground namespace
vram_window:			= vram_bg ; window namespace
vram_bg:			= $E000 ; background namespace
vram_hscroll:			= $F000 ; horizontal scroll table
vram_sprites:			= $F800 ; sprite table

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
; Art tile stuff
; ---------------------------------------------------------------------------

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
; VRAM and tile art base addresses.
; VRAM Reserved regions.
; ---------------------------------------------------------------------------

VRAM_Plane_A_Name_Table	= $C000	; Extends until $CFFF
VRAM_Plane_B_Name_Table	= $E000	; Extends until $EFFF
VRAM_Plane_Table_Size	= $1000	; 64 cells x 32 cells x 2 bytes per cell

; ---------------------------------------------------------------------------
; misc object labels
; ---------------------------------------------------------------------------
next_priority		= ((1+63)*2)	; first word for overall number of queues to handle
priority_amount		= 8
priority_queue		= priority_amount-1	; queue starts at 0

; ---------------------------------------------------------------------------
; Sprite render screen flags
; ---------------------------------------------------------------------------
renbit_xflip		= 0
renbit_yflip		= 1
renbit_camerapos	= 2	; if 0, base object position on the screen position. If 1, base on camera position
renbit_screenpos	= renbit_camerapos
; TODO, move out of render_flags when possible
objflagbit_continue	= 3	; if 1, continue object routine when the player has died
;renbit_excessive	= 4	; if 1, do a more exhaustive sprite rendering check
renbit_static		= 5	; if 1, enable static rendering
renbit_multidraw	= 6	; if 1, enable multidraw
renbit_onscreen		= 7	; if 1, object successfully rendered

ren_xflip		= 1<<renbit_xflip
ren_yflip		= 1<<renbit_yflip
ren_camerapos		= 1<<renbit_camerapos
ren_screenpos		= 0<<renbit_screenpos
objflag_continue	= 1<<objflagbit_continue
ren_static		= 1<<renbit_static
ren_multidraw		= 1<<renbit_multidraw
ren_onscreen		= 1<<renbit_onscreen

; backwards compatibility
rbCoord			= renbit_screenpos	; screen coordinates bit
rbStatic		= renbit_static		; static mappings bit
rbMulti			= renbit_multidraw	; multi-draw bit
rbOnscreen		= renbit_onscreen	; on-screen bit

rfCoord			= ren_camerapos		; screen coordinates flag ($04)
rfStatic		= ren_static		; static mappings flag ($20)
rfMulti			= ren_multidraw		; multi-draw flag ($40)
rfOnscreen		= ren_onscreen		; on-screen flag ($80)

; ---------------------------------------------------------------------------
; Animation flags
; ---------------------------------------------------------------------------

afEnd			= $FF	; return to beginning of animation
afBack			= $FE	; go back (specified number) bytes
afChange		= $FD	; run specified animation
afRoutine		= $FC	; increment routine counter and continue load next anim bytes
afReset			= $FB	; move offscreen for remove(Using the Sprite_OnScreen_Test, etc...)

; ---------------------------------------------------------------------------
; Animation Raw flags
; ---------------------------------------------------------------------------

arfEnd			= $FC	; return to beginning of animation
arfBack			= $F8	; go back (specified number) bytes
arfJump			= $F4	; jump from $34(a0) address

	!org	0		; Reset the program counter
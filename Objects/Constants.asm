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
routine		; byte ; determines the objects current routine. Can't be $80 or beyond, gets cleared when address is set
; I really want to emphasize how much problems routine being $80 would cause. RunObjects uses it to determine when the ENTIRE routine should end.
address			ds.l 1 ; tri, long ; Direct 24-bit ROM address to object code. Refer to make_objaddr in Macros.asm
render_flags		ds.b 1 ; bitfield ; flags used for sprite rendering
object_flags		ds.b 1 ; bitfield ; flags used to determine certain traits of objects
mapping_frame_word	; word
height_pixels		ds.b 1 ; byte
width_pixels		ds.b 1 ; byte
priority		ds.w 1 ; word ; in units of $80
art_tile		ds.w 1 ; word ; PCCVHAAA AAAAAAAA ; P = priority, C = palette line, V = y-flip, H = x-flip, A = starting cell index of art
; TODO: more tribyte abuse
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
prev_anim
anim_copy		ds.b 1 ; byte ; when this isn't equal to anim the animation restarts
render_box		; byte
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
	ds.w 1	; unused for now
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
playeradd_parent	; word ; RAM address of the player parent object for child objects (Tails' tails)
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
Status_Underwater		= 6	; if 1, mark that you're underwater
Status_WaterMove		= 7	; if 1, apply water physics (separate for "Gravity Suit")

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

Status_Shield_Mask		= 1<<Status_Shield
Status_Invincible_Mask		= 1<<Status_Invincible
Status_SpeedShoes_Mask		= 1<<Status_SpeedShoes

Status_FireShield_Mask		= 1<<Status_FireShield
Status_LtngShield_Mask		= 1<<Status_LtngShield
Status_BublShield_Mask		= 1<<Status_BublShield
Status_Sliding_Mask		= 1<<Status_Sliding

Status_Elements			= Status_FireShield_Mask|Status_LtngShield_Mask|Status_BublShield_Mask
Status_AllShields		= Status_Elements|Status_Shield_Mask

; shield_reaction, should mirror status_secondary
Shield_Reflect			= 3	; TODO: Status_Shield instead
Shield_FireImmune		= Status_FireShield
Shield_LtngImmune		= Status_LtngShield
Shield_BublImmune		= Status_BublShield

Shield_Reflect_Mask		= 1<<Shield_Reflect
Shield_FireImmune_Mask		= 1<<Shield_FireImmune
Shield_LtngImmune_Mask		= 1<<Shield_LtngImmune
Shield_BublImmune_Mask		= 1<<Shield_BublImmune


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
renbit_wordframe	= 3	; if 1, inverts height/width_pixels and mapping_frame, giving you word-sized frames at the cost of a square render box
;renbit_excessive	= 4	; if 1, do a more exhaustive sprite rendering check
renbit_static		= 5	; if 1, enable 'static' single sprite rendering. Ignores ren_excessive
renbit_multidraw	= 6	; if 1, enable multidraw
renbit_onscreen		= 7	; if 1, object successfully rendered

ren_xflip		= 1<<renbit_xflip
ren_yflip		= 1<<renbit_yflip
ren_camerapos		= 1<<renbit_camerapos
ren_screenpos		= 0<<renbit_screenpos
ren_wordframe		= 1<<renbit_wordframe
ren_byteframe		= 0<<renbit_wordframe
;ren_excessive		= 1<<renbit_excessive
ren_static		= 1<<renbit_static
ren_multidraw		= 1<<renbit_multidraw
ren_onscreen		= 1<<renbit_onscreen


renbit_subsprite	= renbit_multidraw
ren_subsprite		= ren_multidraw

; backwards compatibility
rbCoord			= renbit_screenpos	; screen coordinates bit
rbStatic		= renbit_static		; static mappings bit
rbMulti			= renbit_multidraw	; multi-draw bit
rbOnscreen		= renbit_onscreen	; on-screen bit

rfCoord			= ren_camerapos		; screen coordinates flag
rfStatic		= ren_static		; static mappings flag
rfMulti			= ren_multidraw		; multi-draw flag
rfOnscreen		= ren_onscreen		; on-screen flag

; ---------------------------------------------------------------------------
; object_flags
; ---------------------------------------------------------------------------
objflagbit_continue	= 7	; if 1, object continues running code when ObjectFreezeFlag is set


objflag_continue	= 1<<objflagbit_continue

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



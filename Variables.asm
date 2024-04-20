; ===========================================================================
; RAM variables
; ===========================================================================

; RAM variables - General
;	phase	ramaddr($00FF0000)	; Pretend we're in the RAM
	phase	ramaddr($FFFF0000)	; Pretend we're in the RAM
RAM_start:				= *
Chunk_table:				ds.b $8000	; Chunk (128x128) definitions, $80 bytes per definition
Chunk_table_end				= *

	if CompBlocks=1
; engine supports $400 max uncompressed
; compressed is variable, but will usually be $300
Block_table:				ds.w	$300*4
Block_table_end:
	endif

	if CompLevel=1
Level_layout:
Level_layout_header:
Level_layout_header_FG_horz:		ds.w 1		; amount of chunks to read horizontally
Level_layout_header_BG_horz:		ds.w 1
Level_layout_header_FG_vert:		ds.w 1		; same for vertical
Level_layout_header_BG_vert:		ds.w 1
Level_layout_main:			ds.w $40	; $40 word-sized line pointers followed by actual layout data
					ds.b $F78	; 3,960 chunks
Level_layout_end:
	endif

	if CompCollision=1
Collision_table:			ds.b $300*2
Collision_table_end:
Primary_collision:			= Collision_table
Secondary_collision:			= Primary_collision+1
	endif
; ---------------------------------------------------------------------------

Player_1:					= *			; Main character in 1 player mode
v_player:					= *
Object_RAM:					ds.b object_size
Player_2:					ds.b object_size
Reserved_object_3:				ds.b object_size	; During a level, an object whose sole purpose is to clear the collision response list is stored here
Dynamic_object_RAM:				ds.b object_size*88	; 90 objects
Dynamic_object_RAM_end				= *
v_Breathing_bubbles:				ds.b object_size
v_Breathing_bubbles_P2:				ds.b object_size
v_Dust:						ds.b object_size
v_Dust_P2:					ds.b object_size
v_Invincibility_stars:
v_Shield:					ds.b object_size
v_Invincibility_stars_P2:
v_Shield_P2:					ds.b object_size
v_Tails_tails:					ds.b object_size
v_Tails_tails_2P:				ds.b object_size
v_WaterWave:					ds.b object_size
Object_RAM_end					= *
v_GameOver_Game	=	v_Breathing_bubbles
v_GameOver_Over	=	v_Breathing_bubbles_P2
	if ((Object_RAM_end-Object_RAM)/object_size)#10<>0	;
	fatal "Object RAM slots aren't divisible by 10 (off by \{((Object_RAM_end-Object_RAM)/object_size)#10})"
	endif
ObjectRamMarker			ds.b 1	; a fast failsafe to end dynamic object checking routines dynamically, set during game init
ObjectFreezeFlag		ds.b 1	; set when player 1 dies, freezes most objects

; used by DPLC routines to detect whether a DMA transfer is required
Player_prev_frame			= Player_1+mapping_frame_copy
Player_prev_frame_tail			= v_Tails_tails+mapping_frame_copy
Distance_from_top:			= v_Tails_tails+screen_distance		; The vertical scroll manager scrolls the screen until the player's distance from the top of the screen is equal to this (or between this and this + $40 when in the air). $60 by default
Pos_table_byte:				= v_Tails_tails+pos_index
Pos_table_index:			= Pos_table_byte	; usually read as a byte. Clear the high byte and change those instances
H_scroll_frame_offset:			= v_Tails_tails+hscroll_table	; byte, word ; If this is non-zero, scrolling is based on the player's x position + 1 frames ago
H_scroll_frame_copy:			= v_Tails_tails+hscroll_table_poscopy	;
;Max_speed:				= v_Tails_tails+max_speed
;Acceleration:				= v_Tails_tails+acceleration
;Deceleration:				= v_Tails_tails+deceleration
;Jump_height:				= v_Tails_tails+jump_height

Player_prev_frame_P2			= Player_2+mapping_frame_copy
Player_prev_frame_P2_tail		= v_Tails_tails_2P+mapping_frame_copy
Distance_from_top_P2:			= v_Tails_tails_2P+screen_distance
Pos_table_byte_P2:			= v_Tails_tails_2P+pos_index
Pos_table_index_P2:			= Pos_table_byte_P2	; same, change word writes to bytes
H_scroll_frame_offset_P2:		= v_Tails_tails_2P+hscroll_table		; byte, word	;
H_scroll_frame_copy_P2:			= v_Tails_tails_2P+hscroll_table_poscopy	;
;Max_speed_P2:				= v_Tails_tails_2P+max_speed
;Acceleration_P2:			= v_Tails_tails_2P+acceleration
;Deceleration_P2:			= v_Tails_tails_2P+deceleration
;Jump_height_P2:			= v_Tails_tails_2P+jump_height
; ---------------------------------------------------------------------------
	if EnableSRAM=1
Save_pointer:			ds.l 1		; SRAM address to copy the RAM data to and vice versa
Saved_data			=	*
Save_RAM:			ds.b sram_main_end-sram_main
Save_RAM_End:
; ---------------------------------------------------------------------------
	endif
	if EnableWifi=1
Wifi_flag:			ds.b 1		; 0 = none, 1 = MegaWifi, -1 = Retro.Link
	endif
	evenram

Kos_decomp_buffer:				ds.w $800		; Each module in a KosM archive is decompressed here and then DMAed to VRAM

H_scroll_buffer:				ds.l 224		; Horizontal scroll table is built up here and then DMAed to VRAM
H_scroll_table:					ds.b 512		; offsets for background scroll positions, used by ApplyDeformation
H_scroll_buffer_end				= *
V_scroll_buffer:				ds.l 320/16		; vertical scroll buffer used in various levels(320 pixels for MD1, 512 pixels for MD2)
V_scroll_buffer_end				= *

Collision_response_list:			ds.w 64			; Only objects in this list are processed by the collision response routines
Stat_table					= *			; used by Tails' AI in a Sonic and Tails game
Pos_table_P2:					ds.l 64			; Recorded player XY position buffer
Pos_table:					ds.l 64			; Recorded player XY position buffer
Ring_status_table:				ds.w RingTable_Count	; Ring status table(1 word)
Ring_status_table_end				= *
Object_respawn_table:				ds.b ObjectTable_Count	; Object respawn table(1 byte)
Object_respawn_table_end			= *
Sprite_table_buffer:				ds.b 80*8
Sprite_table_buffer_end				= *
Sprite_table_input:				ds.b (next_priority)*priority_amount		; Sprite table input buffer
Sprite_table_input_end				= *

DMA_queue:					= *
VDP_Command_Buffer:				ds.b 18*14	; 18 queues, 14 bytes each ; Stores all the VDP commands necessary to initiate a DMA transfer
DMA_queue_slot:					= *
VDP_Command_Buffer_Slot:			ds.w 1		; Points to the next free slot on the queue

; ---------------------------------------------------------------------------

Camera_RAM:					= *			; Various camera and scroll-related variables are stored here
H_scroll_amount:				ds.w 1			; Number of pixels camera scrolled horizontally in the last frame * $100
V_scroll_amount:				ds.w 1			; Number of pixels camera scrolled vertically in the last frame * $100
H_scroll_amount_P2:				ds.w 1			; Number of pixels camera scrolled horizontally in the last frame * $100
V_scroll_amount_P2:				ds.w 1			; Number of pixels camera scrolled vertically in the last frame * $100
Camera_target_min_X_pos:			ds.w 1
Camera_target_max_X_pos:			ds.w 1
Camera_target_min_Y_pos:			ds.w 1
Camera_target_max_Y_pos:			ds.w 1
Camera_min_X_pos:				ds.w 1
Camera_max_X_pos:				ds.w 1
Camera_min_Y_pos:				ds.w 1			; -$100 allows camera to wrap vertically via Screen_Y_wrap_value
Camera_max_Y_pos:				ds.w 1
Camera_stored_max_X_pos:			ds.w 1
Camera_stored_min_X_pos:			ds.w 1
Camera_stored_min_Y_pos:			ds.w 1
Camera_stored_max_Y_pos:			ds.w 1
Camera_min_X_pos_Saved:				ds.w 1
Camera_max_X_pos_Saved:				ds.w 1
Camera_min_Y_pos_Saved:				ds.w 1
Camera_max_Y_pos_Saved:				ds.w 1

Camera_max_Y_pos_changing:			ds.b 1			; Set when the maximum camera Y pos is undergoing a change
Fast_V_scroll_flag:				ds.b 1			; If this is set vertical scroll when the player is on the ground and has a speed of less than $800 is capped at 24 pixels per frame instead of 6
Scroll_lock:					ds.b 1			; If this is set scrolling routines aren't called
	evenram
v_screenposx:					= *
Camera_X_pos:					ds.l 1
v_screenposy:					= *
Camera_Y_pos:					ds.l 1
Camera_X_pos_copy:				ds.l 1
Camera_Y_pos_copy:				ds.l 1
Camera_X_pos_rounded:				ds.w 1			; rounded down to the nearest block boundary ($10th pixel)
Camera_Y_pos_rounded:				ds.w 1			; rounded down to the nearest block boundary ($10th pixel)
Camera_X_pos_BG_copy:				ds.l 1
Camera_Y_pos_BG_copy:				ds.l 1
Camera_X_pos_BG_rounded:			ds.w 1			; rounded down to the nearest block boundary ($10th pixel)
Camera_Y_pos_BG_rounded:			ds.w 1			; rounded down to the nearest block boundary ($10th pixel)
Camera_X_pos_coarse:				ds.w 1			; Rounded down to the nearest chunk boundary (128th pixel)
Camera_Y_pos_coarse:				ds.w 1			; Rounded down to the nearest chunk boundary (128th pixel)
Camera_X_pos_coarse_back:			ds.w 1			; Camera_X_pos_coarse - $80
Camera_Y_pos_coarse_back:			ds.w 1			; Camera_Y_pos_coarse - $80
Plane_double_update_flag:			ds.w 1			; Set when two block are to be updated instead of one (i.e. the camera's scrolled by more than $10 pixels)
HScroll_Shift:					= *
Camera_Hscroll_shift:				ds.w 3
	if ExtendedCamera
Camera_X_center:				ds.w 1
	endif
Screen_X_wrap_value:				ds.w 1			; Set to $FFFF
Screen_Y_wrap_value:				ds.w 1			; Either $FFFF (No wrap), $7FF or $FFF
Camera_Y_pos_mask:				ds.w 1			; Either $7F0 or $FF0
Layout_row_index_mask:				ds.w 1			; Either $3C or $7C
Screen_shaking_flag:				ds.w 1			; flag for enabling screen shake. Negative values cause screen to shake infinitely, positive values make the screen shake for a short amount of time
Screen_shaking_offset:				ds.w 1			; vertical offset when screen_shake_flag is enabled. This is added to camera position later
Screen_shaking_last_offset:			ds.w 1			; value of Screen_shake_offset for the previous frame
Events_fg:					ds.b $18		; various flags used by foreground events
Draw_delayed_position:				ds.w 1			; position to redraw screen from. Screen is reloaded 1 row at a time to avoid game lag
Draw_delayed_rowcount:				ds.w 1			; number of rows for screen redrawing. Screen is reloaded 1 row at a time to avoid game lag
Events_bg:					ds.b $18		; various flags used by background events
Boss_events:					ds.b $10
Camera_RAM_end					= *
; ---------------------------------------------------------------------------

Ring_start_addr_ROM:				ds.l 1			; Address in the ring layout of the first ring whose X position is >= camera X position - 8
Ring_end_addr_ROM:				ds.l 1			; Address in the ring layout of the first ring whose X position is >= camera X position + 328
Ring_start_addr_RAM:				ds.w 1			; Address in the Ring_status_table of the first ring whose X position is >= camera X position - 8
Ring_consumption_table:				= *			; Stores the addresses of all rings currently being consumed
Ring_consumption_count:				ds.w 1			; The number of rings being consumed currently
Ring_consumption_list:				ds.w $3F		; The remaining part of the ring consumption table
Ring_consumption_table_end			= *

Plane_buffer:					ds.w $240		; Used by level drawing routines
; ---------------------------------------------------------------------------

v_snddriver_ram:			ds.b $399;+$160	; Start of RAM for the sound driver data
v_snddriver_ram_end:
; this abstraction allows you to turn them off
SoundDriverAddon_flags:			ds.b 1	; bitfield flags to enable sound driver options from addons
	evenram

; sound data moreso related to game code then driver code
Current_music:				ds.w 1		; music id to play back when a jingle ends
	evenram
; ---------------------------------------------------------------------------
v_gamemode:				= *
Game_mode:				ds.b 1
V_int_flag:				ds.b 1		; If 0, game hasn't reached Vsync, lag. If 1, waiting for Vsync. If -1, Vsync has occurred
V_int_routine:				= *
v_vbla_routine:				ds.l 1		; address to routine that V-int will run if not lagging
; ---------------------------------------------------------------------------
; joypad control
Ctrl1:			; longword
Ctrl1_Hd:		; word
Ctrl1_Hd_XYZ:		ds.b 1
Ctrl1_Hd_ABC:		ds.b 1
Ctrl1_Pr:		; word
Ctrl1_Pr_XYZ:		ds.b 1
Ctrl1_Pr_ABC:		ds.b 1
Ctrl2:			; longword
Ctrl2_Hd:		; word
Ctrl2_Hd_XYZ:		ds.b 1
Ctrl2_Hd_ABC:		ds.b 1
Ctrl2_Pr:		; word
Ctrl2_Pr_XYZ:		ds.b 1
Ctrl2_Pr_ABC:		ds.b 1
	if Joypad_MultiSupport
Ctrl3:			; longword
Ctrl3_Hd:		; word
Ctrl3_Hd_XYZ:		ds.b 1
Ctrl3_Hd_ABC:		ds.b 1
Ctrl3_Pr:		; word
Ctrl3_Pr_XYZ:		ds.b 1
Ctrl3_Pr_ABC:		ds.b 1
Ctrl4:			; longword
Ctrl4_Hd:		; word
Ctrl4_Hd_XYZ:		ds.b 1
Ctrl4_Hd_ABC:		ds.b 1
Ctrl4_Pr:		; word
Ctrl4_Pr_XYZ:		ds.b 1
Ctrl4_Pr_ABC:		ds.b 1
	endif

; TODO: Merge logical with player variables
Ctrl1_Player =		v_Tails_tails+playctrl	; longword
Ctrl1_Player_Hd =	v_Tails_tails+playctrl_hd	; word
Ctrl1_Player_Hd_XYZ =	v_Tails_tails+playctrl_hd_xyz
Ctrl1_Player_Hd_ABC =	v_Tails_tails+playctrl_hd_abc
Ctrl1_Player_Pr =	v_Tails_tails+playctrl_hd	; word
Ctrl1_Player_Pr_XYZ =	v_Tails_tails+playctrl_pr_xyz
Ctrl1_Player_Pr_ABC =	v_Tails_tails+playctrl_pr_abc

Ctrl2_Player =		v_Tails_tails_2P+playctrl	; longword
Ctrl2_Player_Hd =	v_Tails_tails_2P+playctrl_hd	; word
Ctrl2_Player_Hd_XYZ =	v_Tails_tails_2P+playctrl_hd_xyz
Ctrl2_Player_Hd_ABC =	v_Tails_tails_2P+playctrl_hd_abc
Ctrl2_Player_Pr =	v_Tails_tails_2P+playctrl_hd	; word
Ctrl2_Player_Pr_XYZ =	v_Tails_tails_2P+playctrl_pr_xyz
Ctrl2_Player_Pr_ABC =	v_Tails_tails_2P+playctrl_pr_abc

	if Joypad_StateSupport=1
Ctrl1State:		ds.b 1		; controller type (0 = 3 button, -1 = 6 button)
Ctrl2State:		ds.b 1		; ditto
	else
; uses of CtrlXState should give undefined errors
	endif
	evenram
; backwards compatibility...ish
Joypad:			= Ctrl1_Hd_ABC
Ctrl_1:			= Ctrl1_Hd_ABC
Ctrl_1_held:		= Ctrl1_Hd_ABC
Ctrl_1_hold:		= Ctrl1_Hd_ABC
v_jpadhold1:		= Ctrl1_Hd_ABC
v_jpadpress1:		= Ctrl1_Pr_ABC
Ctrl_1_press:		= Ctrl1_Pr_ABC
Ctrl_1_pressed:		= Ctrl1_Pr_ABC

Ctrl_2:			= Ctrl2_Hd_ABC
Ctrl_2_held:		= Ctrl2_Hd_ABC
Ctrl_2_hold:		= Ctrl2_Hd_ABC
v_jpad2hold1:		= Ctrl2_Hd_ABC
v_jpad2press1:		= Ctrl2_Pr_ABC
Ctrl_2_press:		= Ctrl2_Pr_ABC
Ctrl_2_pressed:		= Ctrl2_Pr_ABC

; player control
SonicControl:			= Ctrl1_Player_Hd_ABC
Ctrl_1_logical:			= Ctrl1_Player_Hd_ABC
v_jpadhold2:			= Ctrl1_Player_Hd_ABC
Ctrl_1_held_logical:		= Ctrl1_Player_Hd_ABC
v_jpadpress2:			= Ctrl1_Player_Pr_ABC
Ctrl_1_pressed_logical:		= Ctrl1_Player_Pr_ABC

Ctrl_2_logical:			= Ctrl2_Player_Hd_ABC	; both held and pressed
Ctrl_2_held_logical:		= Ctrl2_Player_Hd_ABC
Ctrl_2_pressed_logical:		= Ctrl2_Player_Pr_ABC
; ---------------------------------------------------------------------------
; VDP
v_vdp_buffer1:			= *
VDP_reg_1_command:		ds.w 1		; AND the lower byte by $BF and write to VDP control port to disable display, OR by $40 to enable
Demo_timer:			= *
v_demolength:			ds.w 1		; The time left for a demo to start/run
V_scroll_value:			= *		; Both foreground and background
v_scrposy_dup:			= *
V_scroll_value_FG:		ds.w 1
V_scroll_value_BG:		ds.w 1
H_scroll_value:			= *
v_scrposx_dup:			= *
H_scroll_value_FG:		ds.w 1
H_scroll_value_BG:		ds.w 1
v_hbla_hreg:			= *
H_int_counter_command:		ds.b 1		; Contains a command to write to VDP register $0A (line interrupt counter)
v_hbla_line:			= *
H_int_counter:			ds.b 1		; Just the counter part of the command

; hardware flags
; basically, test PAL_flag if you just want to test if it's a PAL machine
Graphics_flags:		= *	; Bit 7 set = English system, bit 6 set = PAL system
Region_flags:			ds.b 1	; contains a copy of the region data at HW_Version. JP50 is illegal, PAL test on this is slower then PAL_flag
PAL_flag:			ds.b 1	; 0 = not PAL at all, 3 (bit 1 set, bit 7 not) = slow PAL, -3 (bit 1 not, bit 7 set) = PAL with hardware speedup
V_blank_cycles:			ds.w 1	; amount of cycles from the start of a frame until a Vblank, divided by 30 cycles

Emulator_ID:			ds.b 1	; refer to hardware detector/main.asm
Hardware_flags:			ds.b 1	; bitfield
;SegaCD_Mode:	; byte
Addons_flags:			ds.b 1	; bitfield

ScreenSize_V_Flag:		ds.b 1	; if -1, increase vertical screen size. 0 means never allow it to be set, 1 = allow it
; these are used for determining screen sizes. Make sure to adjust these when using alternate screen modes
ScreenSize_Horz:		ds.w 1	; 256 or 320 -1 (320 or 384 in Widescreen)
ScreenSize_Vert:		ds.w 1	; 224 or 240 -1


v_random:					= *
RNG_seed:					ds.l 1			; Used by the random number generator
v_pfade_start:					= *
Palette_fade_info:				= *			; Both index and count (word)
Palette_fade_index:				ds.b 1			; Colour to start fading from
v_pfade_size:					= *
Palette_fade_count:				ds.b 1			; The number of colours to fade
; ---------------------------------------------------------------------------

Lag_frame_count:				ds.w 1			; More specifically, the number of times V-int routine 0 has run. Reset at the end of a normal frame
v_spritecount:					= *
Sprites_drawn:					ds.w 1			; Used to ensure the sprite limit isn't exceeded
v_vdp_buffer2:					= *
DMA_data_thunk:					= *			; Used as a RAM holder for the final DMA command word. Data will NOT be preserved across V-INTs, so consider this space reserved
DMA_trigger_word:				ds.w 1			; Transferred from RAM to avoid crashing the Mega Drive
f_hbla_pal:					= *
H_int_flag:					ds.b 1			; Unless this is set H-int will return immediately
Hint_count:					ds.b 1		; Debug ; the amount of times a H-int occurs every frame

f_lockctrl:					= *
Ctrl_1_locked:					ds.b 1
Ctrl_2_locked:					ds.b 1
WindTunnel_flag:				ds.b 1
WindTunnel_flag_P2:				ds.b 1

v_framecount:					= *
Level_frame_counter:				ds.b 1			; The number of frames which have elapsed since the level started
v_framebyte					ds.b 1
Level_started_flag:				ds.b 1
f_pause:					= *
Game_paused:					ds.b 1
f_restart:					= *
Restart_level_flag:				ds.b 1
Disable_death_plane:				ds.b 1			; if set, going below the screen wont kill the player

Object_load_addr_front:				ds.l 1			; The address inside the object placement data of the first object whose X pos is >= Camera_X_pos_coarse + $280
Object_load_addr_back:				ds.l 1			; The address inside the object placement data of the first object whose X pos is >= Camera_X_pos_coarse - $80
Object_respawn_index_front:			ds.w 1			; The object respawn table index for the object at Obj_load_addr_front
Object_respawn_index_back:			ds.w 1			; The object respawn table index for the object at Obj_load_addr_back
Collision_addr:					ds.l 1			; Points to the primary or secondary collision data as appropriate
	if CompCollision=0
Primary_collision_addr:				ds.l 1
Secondary_collision_addr:			ds.l 1
	endif
Reverse_gravity_flag:				ds.b 1
	evenram
Primary_Angle:					ds.b 1
Secondary_Angle:				ds.b 1
Deform_lock:					ds.b 1
Boss_flag:					ds.b 1			; Set if a boss fight is going on
TitleCard_end_flag:				ds.b 1
LevResults_end_flag:				ds.b 1
NoBackground_event_flag:			ds.b 1
Screen_event_routine:				ds.b 1
Screen_event_flag:				ds.b 1
Background_event_routine:			ds.b 1
Background_event_flag:				ds.b 1
	evenram
Debug_placement_mode:				= *			; Both routine and type (word)
Debug_placement_routine:			ds.b 1
Debug_placement_type:				ds.b 1			; 0 = normal gameplay, 1 = normal object placement, 2 = frame cycling
Debug_camera_delay:				ds.b 1
Debug_camera_speed:				ds.b 1
Debug_object:					ds.b 1			; The current position in the debug mode object list
Level_end_flag:					ds.b 1
LastAct_end_flag:				ds.b 1
Debug_mode_flag:				ds.b 1
Slotted_object_bits:				ds.b 8			; Index of slot array to use
Signpost_addr:					ds.w 1
Palette_cycle_counters:				ds.b $10
Pal_fade_delay:					ds.w 1
Pal_fade_delay2:				ds.w 1
Hyper_Sonic_flash_timer:			ds.b 1
Negative_flash_timer:				ds.b 1
Time_bonus_countdown:				ds.w 1			; Used on the results screen
Ring_bonus_countdown:				ds.w 1			; Used on the results screen
Total_bonus_countup:				ds.w 1
Chain_bonus_counter:				ds.b 1
Palette_rotation_disable:			ds.b 1
Palette_rotation_custom:			ds.l 1
Palette_rotation_data:				ds.w 9

Tails_CPU_interact:				ds.w 1			; RAM address of the last object Tails stood on while controlled by AI
Tails_CPU_idle_timer:				ds.w 1			; counts down while controller 2 is idle, when it reaches 0 the AI takes over
Tails_CPU_flight_timer:				ds.w 1			; counts up while Tails is respawning, when it reaches 300 he drops into the level
Tails_CPU_routine:				ds.w 1			; Tails' current AI routine in a Sonic and Tails game
Tails_CPU_target_X:				ds.w 1			; Tails' target x-position
Tails_CPU_target_Y:				ds.w 1			; Tails' target y-position
Tails_CPU_auto_fly_timer:			ds.b 1			; counts up until AI Tails automatically flies up to maintain altitude, while grabbing Sonic in Marble Garden Act 2's boss
Tails_CPU_auto_jump_flag:			ds.b 1			; set to #1 when AI Tails needs to jump of his own accord, regardless of whether Sonic jumped or not

Flying_carrying_Sonic_flag:			ds.b 1			; set when Tails carries Sonic in a Sonic and Tails game
Flying_picking_Sonic_timer:			ds.b 1			; until this is 0 Tails can't pick Sonic up

_unkF744:					ds.w 1
_unkF74C:					ds.w 1
Tails_CPU_star_post_flag:			ds.b 1			; copy of Last_star_post_hit, sets Tails' starting behavior in a Sonic and Tails game
_unkFAAC:					ds.b 1
Gliding_collision_flags:			ds.b 1
Disable_wall_grab:				ds.b 1			; if set, disables Knuckles wall grab
	evenram
Lag_frame_count_end				= *
; ---------------------------------------------------------------------------

Water_level:					= *			; Keeps fluctuating
Water_Level_1:					ds.w 1
Water_Level_2:					= *
Mean_water_level:				ds.w 1			; The steady central value of the water level
Water_Level_3:					= *
Target_water_level:				ds.w 1
Water_on:					= *			; Is set based on Water_flag
Water_speed:					ds.b 1			; This is added to or subtracted from Mean_water_level every frame till it reaches Target_water_level
Water_routine:					= *
Water_entered_counter:				ds.b 1			; Incremented when entering and exiting water, read by the the floating AIZ spike log, cleared on level initialisation and dynamic events of certain levels
Water_move:					= *
Water_full_screen_flag:				ds.b 1			; Set if water covers the entire screen (i.e. the underwater pallete should be DMAed during V-int rather than the normal palette)
Water_flag:					ds.b 1

Next_extra_life_score:				ds.l 1

Last_star_post_hit:				= *
Last_star_pole_hit:				ds.b 1
Respawn_table_keep:				ds.b 1			; If set, respawn table is not reset during level load
Palette_fade_timer:				ds.w 1			; The palette gets faded in until this timer expires

	if CompBlocks=0
Block_table_addr_ROM:				ds.l 1			; Block table pointer(Block (16x16) definitions, 8 bytes per definition)
	endif

	if CompLevel=0
Level_layout_addr_ROM:				ds.l 1			; Level layout pointer
Level_layout2_addr_ROM:				ds.l 1			; Level layout 2 pointer (+8)
	endif

Rings_manager_addr_RAM:				ds.l 1			; Jump for the ring loading manager
Object_index_addr:				ds.l 1			; Points to either the object index for levels
Object_load_addr_RAM:				ds.l 1			; Jump for the object loading manager

Level_data_addr_RAM:				= *
.AnPal:						ds.l 1
.Resize:					ds.l 1
.WaterResize:					ds.l 1
.AfterBoss:					ds.l 1
.ScreenInit:					ds.l 1
.BackgroundInit:				ds.l 1
.ScreenEvent:					ds.l 1
.BackgroundEvent:				ds.l 1
.AnimateTiles:					ds.l 1
.AniPLC:					ds.l 1
Level_data_addr_RAM_end				= *
	evenram
; ---------------------------------------------------------------------------

Kos_decomp_queue_count:				ds.w 1			; The number of pieces of data on the queue. Sign bit set indicates a decompression is in progress
Kos_decomp_stored_registers:			ds.w 20			; Allows decompression to be spread over multiple frames
Kos_decomp_stored_SR:				ds.w 1
Kos_decomp_bookmark:				ds.l 1			; The address within the Kosinski queue processor at which processing is to be resumed
Kos_description_field:				ds.w 1			; Used by the Kosinski queue processor the same way the stack is used by the normal Kosinski decompression routine
Kos_decomp_queue:				ds.l 2*4		; 2 longwords per entry, first is source location and second is decompression location
Kos_decomp_source:				= Kos_decomp_queue	; The compressed data location for the first entry in the queue
Kos_decomp_destination:				= Kos_decomp_queue+4	; The decompression location for the first entry in the queue
Kos_decomp_queue_end				= *
Kos_modules_left:				ds.w 1			; The number of modules left to decompresses. Sign bit set indicates a module is being decompressed/has been decompressed
Kos_last_module_size:				ds.w 1			; The uncompressed size of the last module in words. All other modules are $800 words
Kos_module_queue:				ds.b 6*PLCKosM_Count	; 6 bytes per entry, first longword is source location and next word is VRAM destination
Kos_module_source:				= Kos_module_queue	; The compressed data location for the first module in the queue
Kos_module_destination:				= Kos_module_queue+4	; The VRAM destination for the first module in the queue
Kos_module_queue_end				= *
; ---------------------------------------------------------------------------

v_pal_water_dup:				= *
Target_water_palette:				= *			; Used by palette fading routines
Target_water_palette_line_1:			ds.w 16
Target_water_palette_line_2:			ds.w 16
Target_water_palette_line_3:			ds.w 16
Target_water_palette_line_4:			ds.w 16
v_pal_water:					= *
Water_palette:					= *			; This is what actually gets displayed
Water_palette_line_1:				ds.w 16
Water_palette_line_2:				ds.w 16
Water_palette_line_3:				ds.w 16
Water_palette_line_4:				ds.w 16
v_pal_dry:					= *
Normal_palette:					= *			; This is what actually gets displayed
Normal_palette_line_1:				ds.w 16
Normal_palette_line_2:				ds.w 16
Normal_palette_line_3:				ds.w 16
Normal_palette_line_4:				ds.w 16
v_pal_dry_dup:					= *
Target_palette:					= *			; Used by palette fading routines
Target_palette_line_1:				ds.w 16
Target_palette_line_2:				ds.w 16
Target_palette_line_3:				ds.w 16
Target_palette_line_4:				ds.w 16

v_vbla_count:					= *
V_int_run_count:				ds.w 1			; The number of times V-int has run
v_vbla_word:					ds.b 1
v_vbla_byte:					ds.b 1
v_zone:						= *
Current_zone:					= *
Current_zone_and_act:				ds.b 1
v_act:						= *
Current_act:					ds.b 1
a_zone:						= *
Apparent_zone:					= *
Apparent_zone_and_act:				ds.b 1
a_act:						= *
Apparent_act:					ds.b 1

Player_mode:					ds.w 1		; 0 = Sonic and Tails, 1 = Sonic alone, 2 = Tails alone, 3 = Knuckles alone
Life_count:					ds.b 1		; BCD Format
Continue_count:					ds.b 1		; Still hex
f_timeover:					= *
Time_over_flag:					ds.b 1
Extra_life_flags:				ds.b 1
Update_HUD_life_count:				ds.b 1
f_ringcount:					= *
Update_HUD_ring_count:				ds.b 1
f_timecount:					= *
Update_HUD_timer:				ds.b 1
f_scorecount:					= *
Update_HUD_score:				ds.b 1
v_rings:					= *
Ring_count:					ds.b 1
v_ringbyte:					ds.b 1
v_time:						= *
Timer:						ds.b 1
v_timemin:					= *
Timer_minute:					ds.b 1
v_timesec:					= *
Timer_second:					ds.b 1
v_timecent:					= *
Timer_frame:					= *
Timer_centisecond:				ds.b 1			; The second gets incremented when this reaches 60
v_score:					= *
Score:						ds.l 1
DecimalScoreRAM:				ds.l 1
DecimalScoreRAM2:				ds.l 1

HUD_RAM:					= *
.Xpos:						ds.w 1
.Ypos:						ds.w 1
.status:					ds.b 1
	evenram

Saved_zone_and_act:				ds.w 1
Saved_apparent_zone_and_act:			ds.w 1
Saved_X_pos:					ds.w 1
Saved_Y_pos:					ds.w 1
Saved_ring_count:				ds.w 1
Saved_timer:					ds.l 1
Saved_mappings:					ds.l 1
Saved_art_tile:					ds.w 1
Saved_solid_bits:				ds.w 1			; Copy of Player 1's top_solid_bit and lrb_solid_bit
Saved_camera_X_pos:				ds.w 1
Saved_camera_Y_pos:				ds.w 1
Saved_mean_water_level:				ds.w 1
Saved_camera_max_Y_pos:				ds.w 1
Saved_dynamic_resize:				ds.l 1
Saved_water_full_screen_flag:			ds.b 1
Saved_status_secondary:				ds.b 1
Saved_last_star_post_hit:			ds.b 1
	evenram

Oscillating_variables:				= *
Oscillating_Numbers:				= *
Oscillation_Control:				ds.w 1
Oscillating_Data:				ds.b $40
Anim_Counters:					ds.b $10		; Each word stores data on animated level art, including duration and current frame
Level_trigger_array:				ds.b $10		; Used by buttons, etc
Level_trigger_array_end				= *
Rings_frame_timer:				ds.b 1
Rings_frame:					ds.b 1
Ring_spill_anim_counter:			ds.b 1
Ring_spill_anim_frame:				ds.b 1
Ring_spill_anim_accum:				ds.w 1
Oscillating_variables_end			= *
	evenram

System_stack_size				ds.l 64			; ~$100 bytes ; this is the top of the stack, it grows downwards
System_stack:					= *
Checksum_string:				ds.l 1			; set to 'INIT' once the checksum routine has run
V_int_jump:					ds.w 1			; contains an instruction to jump to the V-int handler
V_int_addr:					ds.l 1
H_int_jump:					ds.w 1			; contains an instruction to jump to the H-int handler
H_int_addr:					ds.l 1
;	if * > $1000000	; Don't declare more space than the RAM can contain!
;		fatal "The RAM variable declarations are too large by $\{*} bytes."
;	endif
;	if MOMPASS=1
;		message "The current RAM available $\{0-*} bytes."
;	endif

	if * > 0	; Don't declare more space than the RAM can contain!
		fatal "The RAM variable declarations are too large by $\{*} bytes."
	endif
	if MOMPASS=1
		message "The current RAM available $\{0-*} bytes."
	endif

	dephase		; Stop pretending
	!org	0		; Reset the program counter

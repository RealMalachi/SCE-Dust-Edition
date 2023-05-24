; ---------------------------------------------------------------------------
; VRAM data
; ---------------------------------------------------------------------------

vram_fg =			$C000	; foreground namespace
vram_window =			vram_bg ; window namespace
vram_bg =			$E000	; background namespace
vram_fgsize =			$1000	; 64 cells x 32 cells x 2 bytes per cell
vram_hscroll =			$F000	; horizontal scroll table
vram_hscrollsize =		(ScreenSize_LineCount*2)
vram_sprites =			$F800	; sprite table


VRAM_Plane_A_Name_Table	=	vram_fg	; Extends until $CFFF
VRAM_Plane_B_Name_Table	=	vram_bg	; Extends until $EFFF
VRAM_Plane_Table_Size =		vram_fgsize	; 64 cells x 32 cells x 2 bytes per cell

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
ArtTile_Shield			= $79E
ArtTile_Shield_Sparks		= ArtTile_Shield+$1D
ArtTile_LifeIcon		= $7D4
ArtTile_DashDust		= $7E0
ArtTile_DashDust_P2		= $7F0


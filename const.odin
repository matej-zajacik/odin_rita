package main



//
// Core
//

FRAME_RATE :: 60
FIXED_DT   :: 1.0 / FRAME_RATE
MAX_ACTORS :: 256

//
// Map
//

TILE_SIZE      :: 64
HALF_TILE_SIZE :: TILE_SIZE / 2
SECTOR_SIZE    :: 8

//
// Movement
//

OVERSPEED_DRAG  :: 0.92
THRUST_DURATION :: 30

//
// Player
//

DIFFICULTY_DAMAGE_MODIFIER_EASY :: 0.5
DIFFICULTY_DAMAGE_MODIFIER_HARD :: 2
ARMOR_MITIGATION                :: 0.75

//
// Misc
//

ONE_PX_THICKNESS_SCALE :: 1.0 / TILE_SIZE
MAP_WIDTH = 32
MAP_HEIGHT = 32

SCREEN_TILES_WIDTH = 16
SCREEN_TILES_HEIGHT = 16

TERRAIN_TYPES = {
    PLAINS = { sprite = 1, cost = 1 },
    FOREST = { sprite = 3, cost = 2 },
    THICKET = { sprite = 4, cost = 4 },
    WATER = { sprite = 2, cost = nil }, -- impassable
    DEEP_WATER = { sprite = 6, cost = nil }, -- impassable
    SAND = { sprite = 5, cost = 2},
    MOUNTAIN = { sprite = 7, cost = nil } -- impassable
}

LAYERS = {
    -- Scale, weight
    -- { 1 / 32, 1 },
    { 1 / 16, 1 },
    { 1 / 8,  1 / 2 },
    { 1 / 4,  1 / 4 },
    { 1 / 2,  1 / 8 }
}

CAMERA_X = 0
CAMERA_Y = 0

GAME_STATE = "world"

NUM_PLAYER_UNITS = 9

SELECTED_UNIT = nil
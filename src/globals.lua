MAP_WIDTH = 32
MAP_HEIGHT = 32

SCREEN_TILES_WIDTH = 16
SCREEN_TILES_HEIGHT = 16

TERRAIN_TYPES = {
    PLAINS = { sprite = 1, cost = 1 },
    FOREST = { sprite = 3, cost = 2 },
    THICKET = { sprite = 4, cost = 4 },
    SHOAL = { sprite = 2, cost = nil }, -- impassable
    SEA = { sprite = 6, cost = nil }, -- impassable
    SAND = { sprite = 5, cost = 2 },
    MOUNTAIN = { sprite = 7, cost = nil } -- impassable
}

LAYERS = {
    { 1 / 16, 1 },
    { 1 / 8,  1 / 2 },
    { 1 / 4,  1 / 4 },
    { 1 / 2,  1 / 8 }
}

CAMERA = {
    x = 0,
    y = 0
}

UNITS = {}

GAME_STATE = "world"
IN_CASTLE = false

NUM_PLAYER_UNITS = 9

CURSOR = nil
SELECTED_UNIT = nil
SELECTED_CASTLE = nil
TRAVERSABLE_TILES = {}

MENU = {
    items = {},
    selected = 1,
    x = 0,
    is_open = false,
    anchor = ""
}

UI_STACK = {}
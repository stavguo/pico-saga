TERRAIN_COSTS = {
    [1] = 1, -- PLAINS
    [3] = 2 , -- FOREST
    [4] = 4 , -- THICKET
    [2] = 4 , -- SHOAL
    [6] = nil , -- SEA(impassable)
    [5] = 2 , -- SAND
    [7] = nil, -- MOUNTAIN(impassable)
    [8] = nil, -- PLAYER CASTLE
    [9] = nil -- ENEMY CASTLE
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

PLAYER_UNITS = {}
PLAYER_CASTLE_UNITS = {}
ENEMY_UNITS = {}

CURSOR = nil
TRAVERSABLE_TILES = {}

UI_STACK = {}

function SHUFFLE(items)
    for i = #items, 2, -1 do
        local j = flr(rnd(i)) + 1
        items[i], items[j] = items[j], items[i]
    end
end

UNIT_STATS = {
    ["Lance"] = { Sprite = 14, HP = 30, Str = 20, Mag = 0, Skl = 5, Spd = 5, Def = 5, Mdf = 0, Mov = 6 },
    ["Axe"] = { Sprite = 15, HP = 30, Str = 20, Mag = 0, Skl = 5, Spd = 5, Def = 5, Mdf = 0, Mov = 6 },
    ["Sword"] = { Sprite = 13, HP = 30, Str = 20, Mag = 0, Skl = 5, Spd = 5, Def = 5, Mdf = 0, Mov = 6 },
    ["Archer"] = { HP = 30, Str = 6, Mag = 0, Skl = 5, Spd = 5, Def = 7, Mdf = 0, Mov = 6 },
    ["Mage"] = { HP = 26, Str = 0, Mag = 7, Skl = 6, Spd = 6, Def = 1, Mdf = 5, Mov = 5 },
    ["Thief"] = { HP = 26, Str = 3, Mag = 0, Skl = 3, Spd = 7, Def = 1, Mdf = 0, Mov = 6 },
    ["Monk"] = { HP = 26, Str = 0, Mag = 7, Skl = 6, Spd = 6, Def = 1, Mdf = 7, Mov = 5 }
}

-- Weapon Triangle Matchups
local WEAPON_TRIANGLE = {
    ["Sword"] = {"Axe"},
    ["Axe"] = {"Lance"},
    ["Lance"] = {"Sword"},
    ["Monk"] = {"Archer", "Mage", "Thief"}
}

-- Terrain Effects on Hit Rate
local TERRAIN_EFFECTS = {
    [1] = 0,   -- Plains: no effect
    [3] = 10, -- Forest: -10% hit rate
    [4] = 15, -- Thicket: -15% hit rate
    [2] = 5,  -- Shoal: -5% hit rate
    [5] = 5,  -- Sand: -5% hit rate
    [6] = 20, -- Sea: -20% hit rate (unlikely to attack from here)
    [7] = 20, -- Mountain: -20% hit rate (unlikely to attack from here)
    [8] = 0,   -- Player Castle: no effect
    [9] = 0    -- Enemy Castle: no effect
}

ENEMY_INDEX = nil
ENEMY_POSITIONS = {}
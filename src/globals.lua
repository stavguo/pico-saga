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
SELECTED_UNIT = nil
SELECTED_CASTLE = nil
TRAVERSABLE_TILES = {}

UI_STACK = {}

function SHUFFLE(items)
    for i = #items, 2, -1 do
        local j = flr(rnd(i)) + 1
        items[i], items[j] = items[j], items[i]
    end
end

UNIT_STATS = {
    ["Social Knight"] = { HP = 30, Str = 7, Mag = 0, Skl = 6, Spd = 6, Def = 6, Mdf = 0, Mov = 8, Gold = 1000 },
    ["Lance Knight"] = { HP = 30, Str = 7, Mag = 0, Skl = 6, Spd = 6, Def = 6, Mdf = 0, Mov = 8, Gold = 1000 },
    ["Arch Knight"] = { HP = 30, Str = 7, Mag = 0, Skl = 6, Spd = 6, Def = 6, Mdf = 0, Mov = 8, Gold = 1000 },
    ["Axe Knight"] = { HP = 30, Str = 7, Mag = 0, Skl = 6, Spd = 6, Def = 6, Mdf = 0, Mov = 8, Gold = 1000 },
    ["Free Knight"] = { HP = 30, Str = 7, Mag = 0, Skl = 6, Spd = 6, Def = 6, Mdf = 0, Mov = 8, Gold = 1000 },
    ["Troubadour"] = { HP = 26, Str = 3, Mag = 3, Skl = 6, Spd = 6, Def = 3, Mdf = 3, Mov = 8, Gold = 1000 },
    ["Lord Knight"] = { HP = 40, Str = 10, Mag = 0, Skl = 7, Spd = 7, Def = 7, Mdf = 3, Mov = 9, Gold = 3000 },
    ["Duke Knight"] = { HP = 40, Str = 12, Mag = 0, Skl = 7, Spd = 7, Def = 8, Mdf = 3, Mov = 9, Gold = 3000 },
    ["Master Knight"] = { HP = 40, Str = 12, Mag = 7, Skl = 12, Spd = 12, Def = 12, Mdf = 7, Mov = 9, Gold = 3000 },
    ["Paladin (M)"] = { HP = 40, Str = 9, Mag = 5, Skl = 9, Spd = 9, Def = 9, Mdf = 5, Mov = 9, Gold = 3000 },
    ["Paladin (F)"] = { HP = 40, Str = 9, Mag = 5, Skl = 9, Spd = 9, Def = 9, Mdf = 5, Mov = 9, Gold = 3000 },
    ["Bow Knight"] = { HP = 40, Str = 10, Mag = 0, Skl = 8, Spd = 8, Def = 8, Mdf = 3, Mov = 9, Gold = 3000 },
    ["Forrest Knight"] = { HP = 40, Str = 8, Mag = 0, Skl = 15, Spd = 12, Def = 8, Mdf = 3, Mov = 9, Gold = 3000 },
    ["Mage Knight"] = { HP = 40, Str = 5, Mag = 10, Skl = 7, Spd = 7, Def = 5, Mdf = 7, Mov = 9, Gold = 3000 },
    ["Great Knight"] = { HP = 40, Str = 12, Mag = 0, Skl = 7, Spd = 7, Def = 10, Mdf = 3, Mov = 9, Gold = 3000 },
    ["Pegasus Rider"] = { HP = 30, Str = 6, Mag = 0, Skl = 5, Spd = 10, Def = 3, Mdf = 5, Mov = 8, Gold = 1000 },
    ["Pegasus Knight"] = { HP = 35, Str = 7, Mag = 0, Skl = 7, Spd = 12, Def = 5, Mdf = 7, Mov = 8, Gold = 3000 },
    ["Falcon Knight"] = { HP = 40, Str = 7, Mag = 7, Skl = 10, Spd = 15, Def = 6, Mdf = 12, Mov = 8, Gold = 5000 },
    ["Dragon Rider"] = { HP = 35, Str = 9, Mag = 0, Skl = 5, Spd = 5, Def = 8, Mdf = 0, Mov = 9, Gold = 1000 },
    ["Dragon Knight"] = { HP = 40, Str = 10, Mag = 0, Skl = 7, Spd = 6, Def = 11, Mdf = 0, Mov = 9, Gold = 3000 },
    ["Dragon Master"] = { HP = 40, Str = 12, Mag = 0, Skl = 9, Spd = 7, Def = 14, Mdf = 0, Mov = 9, Gold = 5000 },
    ["Bow Fighter"] = { HP = 30, Str = 7, Mag = 0, Skl = 10, Spd = 10, Def = 5, Mdf = 0, Mov = 6, Gold = 1000 },
    ["Swordfighter"] = { HP = 30, Str = 7, Mag = 0, Skl = 10, Spd = 10, Def = 5, Mdf = 0, Mov = 6, Gold = 1000 },
    ["Swordmaster"] = { HP = 40, Str = 12, Mag = 0, Skl = 15, Spd = 15, Def = 7, Mdf = 3, Mov = 6, Gold = 3000 },
    ["Sniper"] = { HP = 40, Str = 12, Mag = 0, Skl = 12, Spd = 12, Def = 7, Mdf = 3, Mov = 6, Gold = 3000 },
    ["Forrest"] = { HP = 40, Str = 12, Mag = 3, Skl = 12, Spd = 12, Def = 7, Mdf = 3, Mov = 6, Gold = 3000 },
    ["General"] = { HP = 40, Str = 10, Mag = 0, Skl = 6, Spd = 5, Def = 12, Mdf = 3, Mov = 5, Gold = 3000 },
    ["Emperor"] = { HP = 45, Str = 15, Mag = 15, Skl = 15, Spd = 15, Def = 15, Mdf = 15, Mov = 5, Gold = 6000 },
    ["Baron"] = { HP = 45, Str = 12, Mag = 7, Skl = 7, Spd = 7, Def = 12, Mdf = 7, Mov = 5, Gold = 5000 },
    ["Soldier"] = { HP = 30, Str = 6, Mag = 0, Skl = 5, Spd = 5, Def = 7, Mdf = 0, Mov = 6, Gold = 1000 },
    ["Spear Soldier"] = { Sprite = 14, HP = 30, Str = 6, Mag = 0, Skl = 5, Spd = 5, Def = 7, Mdf = 0, Mov = 6, Gold = 1000 },
    ["Axe Soldier"] = { Sprite = 15, HP = 30, Str = 6, Mag = 0, Skl = 5, Spd = 5, Def = 7, Mdf = 0, Mov = 6, Gold = 1000 },
    ["Archer"] = { HP = 30, Str = 6, Mag = 0, Skl = 5, Spd = 5, Def = 7, Mdf = 0, Mov = 6, Gold = 1000 },
    ["Sword Soldier"] = { Sprite = 13, HP = 30, Str = 6, Mag = 0, Skl = 5, Spd = 5, Def = 7, Mdf = 0, Mov = 6, Gold = 1000 },
    ["Armour"] = { HP = 40, Str = 9, Mag = 0, Skl = 5, Spd = 3, Def = 10, Mdf = 0, Mov = 5, Gold = 2000 },
    ["Axe Armour"] = { HP = 40, Str = 9, Mag = 0, Skl = 5, Spd = 3, Def = 10, Mdf = 0, Mov = 5, Gold = 2000 },
    ["Bow Armour"] = { HP = 40, Str = 9, Mag = 0, Skl = 5, Spd = 3, Def = 10, Mdf = 0, Mov = 5, Gold = 2000 },
    ["Sword Armour"] = { HP = 40, Str = 9, Mag = 0, Skl = 5, Spd = 3, Def = 10, Mdf = 0, Mov = 5, Gold = 2000 },
    ["Barbarian"] = { HP = 35, Str = 5, Mag = 0, Skl = 0, Spd = 7, Def = 5, Mdf = 0, Mov = 6, Gold = 1000 },
    ["Axe Fighter"] = { HP = 35, Str = 8, Mag = 0, Skl = 3, Spd = 10, Def = 8, Mdf = 0, Mov = 6, Gold = 2000 },
    ["Mountain Thief"] = { HP = 35, Str = 5, Mag = 0, Skl = 0, Spd = 7, Def = 5, Mdf = 0, Mov = 6, Gold = 5000 },
    ["Warrior"] = { HP = 40, Str = 11, Mag = 0, Skl = 5, Spd = 12, Def = 10, Mdf = 3, Mov = 6, Gold = 3000 },
    ["Hunter"] = { HP = 35, Str = 7, Mag = 0, Skl = 0, Spd = 7, Def = 5, Mdf = 0, Mov = 6, Gold = 1000 },
    ["Pirate"] = { HP = 35, Str = 5, Mag = 0, Skl = 0, Spd = 7, Def = 5, Mdf = 0, Mov = 6, Gold = 5000 },
    ["Junior Lord"] = { HP = 30, Str = 5, Mag = 0, Skl = 5, Spd = 5, Def = 5, Mdf = 0, Mov = 6, Gold = 6000 },
    ["Mage Fighter (M)"] = { HP = 30, Str = 5, Mag = 12, Skl = 10, Spd = 10, Def = 7, Mdf = 7, Mov = 6, Gold = 3000 },
    ["Prince"] = { HP = 30, Str = 8, Mag = 3, Skl = 7, Spd = 6, Def = 7, Mdf = 3, Mov = 6, Gold = 5000 },
    ["Princess"] = { HP = 26, Str = 5, Mag = 7, Skl = 5, Spd = 8, Def = 5, Mdf = 7, Mov = 6, Gold = 5000 },
    ["Mage Fighter (F)"] = { HP = 26, Str = 3, Mag = 12, Skl = 9, Spd = 12, Def = 5, Mdf = 10, Mov = 6, Gold = 3000 },
    ["Queen"] = { HP = 35, Str = 5, Mag = 15, Skl = 10, Spd = 12, Def = 10, Mdf = 15, Mov = 6, Gold = 6000 },
    ["Dancer"] = { HP = 26, Str = 3, Mag = 0, Skl = 1, Spd = 7, Def = 1, Mdf = 3, Mov = 6, Gold = 1000 },
    ["Priest"] = { HP = 26, Str = 0, Mag = 7, Skl = 6, Spd = 6, Def = 1, Mdf = 7, Mov = 5, Gold = 1000 },
    ["Mage"] = { HP = 26, Str = 0, Mag = 7, Skl = 6, Spd = 6, Def = 1, Mdf = 5, Mov = 5, Gold = 1000 },
    ["Fire Mage"] = { HP = 26, Str = 0, Mag = 10, Skl = 6, Spd = 6, Def = 1, Mdf = 5, Mov = 5, Gold = 1000 },
    ["Thunder Mage"] = { HP = 26, Str = 0, Mag = 7, Skl = 9, Spd = 6, Def = 1, Mdf = 5, Mov = 5, Gold = 1000 },
    ["Wind Mage"] = { HP = 26, Str = 0, Mag = 7, Skl = 6, Spd = 9, Def = 1, Mdf = 5, Mov = 5, Gold = 1000 },
    ["High Priest"] = { HP = 35, Str = 0, Mag = 12, Skl = 9, Spd = 8, Def = 3, Mdf = 8, Mov = 5, Gold = 3000 },
    ["Bishop"] = { HP = 35, Str = 0, Mag = 10, Skl = 8, Spd = 5, Def = 3, Mdf = 8, Mov = 5, Gold = 3000 },
    ["Sage"] = { HP = 35, Str = 0, Mag = 15, Skl = 12, Spd = 15, Def = 3, Mdf = 12, Mov = 6, Gold = 5000 },
    ["Bard"] = { HP = 30, Str = 0, Mag = 7, Skl = 7, Spd = 10, Def = 3, Mdf = 7, Mov = 6, Gold = 2000 },
    ["Shaman"] = { HP = 30, Str = 0, Mag = 8, Skl = 7, Spd = 7, Def = 3, Mdf = 10, Mov = 5, Gold = 2000 },
    ["Dark Mage"] = { HP = 40, Str = 0, Mag = 10, Skl = 8, Spd = 8, Def = 7, Mdf = 10, Mov = 5, Gold = 3000 },
    ["Dark Bishop"] = { HP = 40, Str = 0, Mag = 15, Skl = 10, Spd = 10, Def = 10, Mdf = 12, Mov = 5, Gold = 5000 },
    ["Thief"] = { HP = 26, Str = 3, Mag = 0, Skl = 3, Spd = 7, Def = 1, Mdf = 0, Mov = 6, Gold = 5000 },
    ["Thief Fighter"] = { HP = 30, Str = 7, Mag = 3, Skl = 7, Spd = 12, Def = 5, Mdf = 3, Mov = 7, Gold = 6000 },
    ["Civilian"] = { HP = 20, Str = 0, Mag = 0, Skl = 0, Spd = 10, Def = 2, Mdf = 0, Mov = 5, Gold = 0 },
    ["Child"] = { HP = 20, Str = 0, Mag = 0, Skl = 0, Spd = 0, Def = 0, Mdf = 0, Mov = 5, Gold = 0 },
    ["Long Arch"] = { HP = 30, Str = 0, Mag = 0, Skl = 0, Spd = 0, Def = 0, Mdf = 0, Mov = 0, Gold = 1000 },
    ["Iron Arch"] = { HP = 30, Str = 0, Mag = 0, Skl = 0, Spd = 0, Def = 10, Mdf = 0, Mov = 0, Gold = 1000 },
    ["Killer Arch"] = { HP = 30, Str = 0, Mag = 0, Skl = 0, Spd = 0, Def = 0, Mdf = 0, Mov = 0, Gold = 1000 },
    ["Great Arch"] = { HP = 30, Str = 0, Mag = 0, Skl = 0, Spd = 0, Def = 0, Mdf = 0, Mov = 0, Gold = 1000 },
    ["Dark Prince"] = { HP = 30, Str = 0, Mag = 15, Skl = 12, Spd = 12, Def = 10, Mdf = 15, Mov = 5, Gold = 0 }
  }
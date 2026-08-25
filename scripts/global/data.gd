extends Node

var player_level = 0
var difficulty: Enum.Difficulty = Enum.Difficulty.EASY
const TILE_SIZE = 16
var forecast_rain: bool
const PLAYER_SAVE_PATH := "user://player_save.json"
const PLAYER_SAVE_PATH_BACKUP := "user://player_save_backup.json"
const LEVEL_SAVE_PATH:= "user://level_save.json"
const LEVEL_SAVE_PATH_BACKUP := "user://level_save_backup.json"
const BACKUP_SAVE_INTERVAL_TIME_IN_SEC = 300



const PLAYER_SAVE_PATH_BACKUP := "user://player_save_backup.json"
const LEVEL_SAVE_PATH:= "user://level_save.json"
const LEVEL_SAVE_PATH_BACKUP := "user://level_save_backup.json"
const BACKUP_SAVE_INTERVAL_TIME_IN_SEC = 300

var day_time
var night_time
var blob_spawn_time

const DAY_TIMES = {
	Enum.Difficulty.EASY: 150,
	Enum.Difficulty.NORMAL: 125,
	Enum.Difficulty.HARD: 100
}

const NIGHT_TIMES = {
	Enum.Difficulty.EASY: 75,
	Enum.Difficulty.NORMAL: 100,
	Enum.Difficulty.HARD: 150
}

const BLOB_SPAWN_TIMES = {
	Enum.Difficulty.EASY: 10,
	Enum.Difficulty.NORMAL: 8,
	Enum.Difficulty.HARD: 6
}


const HOUSE_COST = {
	Enum.Difficulty.EASY: {1: {Enum.Item.WOOD: 25, Enum.Item.APPLE: 15}, 2: {Enum.Item.WOOD: 30, Enum.Item.APPLE: 25}},
	Enum.Difficulty.NORMAL: {1: {Enum.Item.WOOD: 30, Enum.Item.APPLE: 20}, 2: {Enum.Item.WOOD: 40, Enum.Item.APPLE: 30}},
	Enum.Difficulty.HARD: {1: {Enum.Item.WOOD: 35, Enum.Item.APPLE: 25}, 2: {Enum.Item.WOOD: 45, Enum.Item.APPLE: 35}},
}

func get_level_value(values: Array, level: int):
	return values[min(level, values.size() - 1)]

#region Plants
const PLANT_DATA = {
	Enum.Difficulty.EASY: {
		Enum.Seed.TOMATO: {
			'texture': "res://graphics/plants/tomato.png",
			'icon_texture': "res://graphics/icons/tomato.png",
			'name':'Tomato',
			'h_frames': 3,
			'grow_speed': 0.75,
			'death_max': 3,
			'reward': Enum.Item.TOMATO},
		Enum.Seed.CORN: {
			'texture': "res://graphics/plants/corn.png",
			'icon_texture': "res://graphics/icons/corn.png",
			'name':'Corn',
			'h_frames': 3,
			'grow_speed': 1.0,
			'death_max': 2,
			'reward': Enum.Item.CORN},
		Enum.Seed.PUMPKIN: {
			'texture': "res://graphics/plants/pumpkin.png",
			'icon_texture': "res://graphics/icons/pumpkin.png",
			'name':'Pumpkin',
			'h_frames': 3,
			'grow_speed': 0.25,
			'death_max': 3,
			'reward': Enum.Item.PUMPKIN},
		Enum.Seed.WHEAT: {
			'texture': "res://graphics/plants/wheat.png",
			'icon_texture': "res://graphics/icons/wheat.png",
			'name':'Wheat',
			'h_frames': 3,
			'grow_speed': 1.0,
			'death_max': 3,
			'reward': Enum.Item.WHEAT}
	},	
	Enum.Difficulty.NORMAL: {
		Enum.Seed.TOMATO: {
			'texture': "res://graphics/plants/tomato.png",
			'icon_texture': "res://graphics/icons/tomato.png",
			'name':'Tomato',
			'h_frames': 3,
			'grow_speed': 0.65,
			'death_max': 3,
			'reward': Enum.Item.TOMATO},
		Enum.Seed.CORN: {
			'texture': "res://graphics/plants/corn.png",
			'icon_texture': "res://graphics/icons/corn.png",
			'name':'Corn',
			'h_frames': 3,
			'grow_speed': 0.9,
			'death_max': 2,
			'reward': Enum.Item.CORN},
		Enum.Seed.PUMPKIN: {
			'texture': "res://graphics/plants/pumpkin.png",
			'icon_texture': "res://graphics/icons/pumpkin.png",
			'name':'Pumpkin',
			'h_frames': 3,
			'grow_speed': 0.22,
			'death_max': 3,
			'reward': Enum.Item.PUMPKIN},
		Enum.Seed.WHEAT: {
			'texture': "res://graphics/plants/wheat.png",
			'icon_texture': "res://graphics/icons/wheat.png",
			'name':'Wheat',
			'h_frames': 3,
			'grow_speed': 0.9,
			'death_max': 3,
			'reward': Enum.Item.WHEAT}
	},
	Enum.Difficulty.HARD: {
		Enum.Seed.TOMATO: {
			'texture': "res://graphics/plants/tomato.png",
			'icon_texture': "res://graphics/icons/tomato.png",
			'name':'Tomato',
			'h_frames': 3,
			'grow_speed': 0.6,
			'death_max': 3,
			'reward': Enum.Item.TOMATO},
		Enum.Seed.CORN: {
			'texture': "res://graphics/plants/corn.png",
			'icon_texture': "res://graphics/icons/corn.png",
			'name':'Corn',
			'h_frames': 3,
			'grow_speed': 0.8,
			'death_max': 2,
			'reward': Enum.Item.CORN},
		Enum.Seed.PUMPKIN: {
			'texture': "res://graphics/plants/pumpkin.png",
			'icon_texture': "res://graphics/icons/pumpkin.png",
			'name':'Pumpkin',
			'h_frames': 3,
			'grow_speed': 0.2,
			'death_max': 3,
			'reward': Enum.Item.PUMPKIN},
		Enum.Seed.WHEAT: {
			'texture': "res://graphics/plants/wheat.png",
			'icon_texture': "res://graphics/icons/wheat.png",
			'name':'Wheat',
			'h_frames': 3,
			'grow_speed': 0.8,
			'death_max': 3,
			'reward': Enum.Item.WHEAT}
	},
}

const SEED_TEXTURES = {
	Enum.Seed.TOMATO: preload("res://graphics/icons/tomato.png"),
	Enum.Seed.CORN: preload("res://graphics/icons/corn.png"),
	Enum.Seed.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Seed.WHEAT: preload("res://graphics/icons/wheat.png")
	}

const HARVEST_SHAKE_ANGLE := 4.0
const HARVEST_SHAKE_DURATION := 0.2
const HARVEST_SHAKE_INTERVAL := 5
#endregion


#region Fish
const FISH_DATA = {
	Enum.Difficulty.EASY: {
		Enum.Fish.GRAY: {
			'icon_texture': "res://graphics/icons/grayfish.png",
			'name': "Gray Fish",
			'catch_speed': 20,
			'lose_speed': 10,
			'start_progress': 30,
			'frequency': "Common",
			'color': Color.PALE_GREEN},
		Enum.Fish.SILVER: {
			'icon_texture': "res://graphics/icons/silverfish.png",
			'name': "Silver Fish",
			'catch_speed': 15,
			'lose_speed': 15,
			'start_progress': 30,
			'frequency': "Rare",
			'color': Color.MEDIUM_PURPLE},
		Enum.Fish.GOLD: {
			'icon_texture': "res://graphics/icons/goldfish.png",
			'name': "Gold Fish",
			'catch_speed': 10,
			'lose_speed': 20,
			'start_progress': 30,
			'frequency': "Legendary",
			'color': Color.GOLDENROD}
	},
	Enum.Difficulty.NORMAL: {
		Enum.Fish.GRAY: {
			'icon_texture': "res://graphics/icons/grayfish.png",
			'name': "Gray Fish",
			'catch_speed': 20,
			'lose_speed': 10,
			'start_progress': 30,
			'frequency': "Common",
			'color': Color.PALE_GREEN},
		Enum.Fish.SILVER: {
			'icon_texture': "res://graphics/icons/silverfish.png",
			'name': "Silver Fish",
			'catch_speed': 15,
			'lose_speed': 15,
			'start_progress': 30,
			'frequency': "Rare",
			'color': Color.MEDIUM_PURPLE},
		Enum.Fish.GOLD: {
			'icon_texture': "res://graphics/icons/goldfish.png",
			'name': "Gold Fish",
			'catch_speed': 10,
			'lose_speed': 20,
			'start_progress': 30,
			'frequency': "Legendary",
			'color': Color.GOLDENROD}
	},
	Enum.Difficulty.HARD: {
		Enum.Fish.GRAY: {
			'icon_texture': "res://graphics/icons/grayfish.png",
			'name': "Gray Fish",
			'catch_speed': 20,
			'lose_speed': 10,
			'start_progress': 30,
			'frequency': "Common",
			'color': Color.PALE_GREEN},
		Enum.Fish.SILVER: {
			'icon_texture': "res://graphics/icons/silverfish.png",
			'name': "Silver Fish",
			'catch_speed': 15,
			'lose_speed': 15,
			'start_progress': 30,
			'frequency': "Rare",
			'color': Color.MEDIUM_PURPLE},
		Enum.Fish.GOLD: {
			'icon_texture': "res://graphics/icons/goldfish.png",
			'name': "Gold Fish",
			'catch_speed': 10,
			'lose_speed': 20,
			'start_progress': 30,
			'frequency': "Legendary",
			'color': Color.GOLDENROD}
	},
}
#endregion


#region Machines
const MACHINE_SCENE = {
	Enum.Machine.SPRINKLER : {
		"scene": preload("res://scenes/machines/sprinkler.tscn"),
		},
	Enum.Machine.FISHER : {
		"scene": preload("res://scenes/machines/fisherman.tscn"),
		},
	Enum.Machine.SCARECROW :{
		"scene":preload("res://scenes/machines/scare_crow.tscn"),
	} ,
	Enum.Machine.DELETE : {
		"scene":preload("res://scenes/machines/scare_crow.tscn"),
		}
	}

const MACHINE_PREVIEW_TEXTURES = {
	Enum.Machine.SPRINKLER: {'texture':preload("res://graphics/icons/sprinkler.png"), 'offset': Vector2i(2,0)},
	Enum.Machine.FISHER: {'texture':preload("res://graphics/icons/fisher.png"), 'offset': Vector2i(2,-8)},
	Enum.Machine.SCARECROW: {'texture':preload("res://graphics/icons/scarecrow.png"), 'offset': Vector2i(1,-10)},
	Enum.Machine.DELETE: {'texture':preload("res://graphics/icons/delete.png"), 'offset': Vector2i(-8,-8)}}	

const MACHINE_TEXTURES = {
	Enum.Machine.DELETE: preload("res://graphics/icons/delete.png"),
	Enum.Machine.SPRINKLER: preload("res://graphics/icons/sprinkler.png"),
	Enum.Machine.FISHER: preload("res://graphics/icons/fisher.png"),
	Enum.Machine.SCARECROW: preload("res://graphics/icons/scarecrow.png"),}	

const MACHINE_UPGRADE_COST = {
	Enum.Difficulty.EASY: {
		Enum.Machine.DELETE:{},
		Enum.Machine.SPRINKLER: {
			'name': 'Sprinkler',
			'cost' :{Enum.Item.TOMATO: 30, Enum.Item.WHEAT: 20},
			'icon': preload("res://graphics/icons/sprinkler.png"),
			'color': Color.SEA_GREEN},
		Enum.Machine.FISHER: {
			'name': 'Fisher',
			'cost' :{Enum.Item.WOOD: 25, Enum.Item.FISH: 15},
			'icon': preload("res://graphics/icons/fisher.png"),
			'color': Color.SLATE_GRAY},
		Enum.Machine.SCARECROW: {
			'name': 'Scarecrow',
			'cost' : {Enum.Item.PUMPKIN: 15, Enum.Item.CORN: 15},
			'icon': preload("res://graphics/icons/scarecrow.png"),
			'color': Color.BURLYWOOD}
	},
	Enum.Difficulty.NORMAL: {
		Enum.Machine.DELETE:{},
		Enum.Machine.SPRINKLER: {
			'name': 'Sprinkler',
			'cost' :{Enum.Item.TOMATO: 35, Enum.Item.WHEAT: 25},
			'icon': preload("res://graphics/icons/sprinkler.png"),
			'color': Color.SEA_GREEN},
		Enum.Machine.FISHER: {
			'name': 'Fisher',
			'cost' :{Enum.Item.WOOD: 30, Enum.Item.FISH: 20},
			'icon': preload("res://graphics/icons/fisher.png"),
			'color': Color.SLATE_GRAY},
		Enum.Machine.SCARECROW: {
			'name': 'Scarecrow',
			'cost' : {Enum.Item.PUMPKIN: 20, Enum.Item.CORN: 20},
			'icon': preload("res://graphics/icons/scarecrow.png"),
			'color': Color.BURLYWOOD}
	},
	Enum.Difficulty.HARD: {
		Enum.Machine.DELETE:{},
		Enum.Machine.SPRINKLER: {
			'name': 'Sprinkler',
			'cost' :{Enum.Item.TOMATO: 40, Enum.Item.WHEAT: 30},
			'icon': preload("res://graphics/icons/sprinkler.png"),
			'color': Color.SEA_GREEN},
		Enum.Machine.FISHER: {
			'name': 'Fisher',
			'cost' :{Enum.Item.WOOD: 35, Enum.Item.FISH: 20},
			'icon': preload("res://graphics/icons/fisher.png"),
			'color': Color.SLATE_GRAY},
		Enum.Machine.SCARECROW: {
			'name': 'Scarecrow',
			'cost' : {Enum.Item.PUMPKIN: 20, Enum.Item.CORN: 25},
			'icon': preload("res://graphics/icons/scarecrow.png"),
			'color': Color.BURLYWOOD}
	},
}


const MACHINE_LIMIT = {
	Enum.Difficulty.EASY : {
			Enum.Machine.SCARECROW : [4, 5, 6],
			Enum.Machine.SPRINKLER : [3, 4, 5],
			Enum.Machine.FISHER : [3, 4, 5],
		},
	Enum.Difficulty.NORMAL :{
			Enum.Machine.SCARECROW : [3, 4, 5],
			Enum.Machine.SPRINKLER : [2, 3, 4],
			Enum.Machine.FISHER : [2, 3, 4],
		},
	Enum.Difficulty.HARD : {
			Enum.Machine.SCARECROW : [2, 3, 4],
			Enum.Machine.SPRINKLER : [1, 2, 3],
			Enum.Machine.FISHER : [1, 2, 3],
		},
}

const REACH_LIMIT_COLOR = Color("ff245597")
const NO_LIMIT_COLOR = Color("ffffff97")


# Upgradable in future
# Scare Crow
const PROJECTILE_SPEED = {
	Enum.Difficulty.EASY : [200.0, 225.0, 250.0],
	Enum.Difficulty.NORMAL : [195.0, 220.0, 245.0],
	Enum.Difficulty.HARD : [190.0, 215.0, 240.0],
}
const SCARE_CROW_DETECTION_RANGE = {
	Enum.Difficulty.EASY : [175.0, 200.0, 225.0],
	Enum.Difficulty.NORMAL : [150.0, 175.0, 200.0],
	Enum.Difficulty.HARD : [125.0, 150.0, 175.0],
}

# Fisherman
const FISHING_TIMER_TIME = {
	Enum.Difficulty.EASY : [20.0, 17.5, 15.0],
	Enum.Difficulty.NORMAL : [30.0, 25.0, 20.0],
	Enum.Difficulty.HARD : [45.0, 35.0, 30.0],
}
#endregion
	
	
#region Tools
const TOOL_TEXTURES = {
	Enum.Tool.AXE: preload("res://graphics/icons/axe.png"),
	Enum.Tool.HOE: preload("res://graphics/icons/hoe.png"),
	Enum.Tool.WATER: preload("res://graphics/icons/water.png"),
	Enum.Tool.SWORD: preload("res://graphics/icons/sword.png"),
	Enum.Tool.FISH: preload("res://graphics/icons/fish.png"),
	Enum.Tool.SEED: preload("res://graphics/icons/wheat.png")
	}

const TOOL_STATE_ANIMATIONS = {
	Enum.Tool.HOE: 'Hoe',
	Enum.Tool.AXE: 'Axe',
	Enum.Tool.WATER: 'Water',
	Enum.Tool.SWORD: 'Sword',
	Enum.Tool.FISH: 'Fish',
	Enum.Tool.SEED: 'Seed',
	}
	
const TOOL_DAMAGE_AMOUNT = {
	Enum.Difficulty.EASY: {
		Enum.Tool.SWORD: [2.0, 3.0, 4.0],
		Enum.Tool.AXE: [1.0, 2.0, 3.0]
		},
	Enum.Difficulty.NORMAL: {
		Enum.Tool.SWORD: [1.5, 2.5, 3.5],
		Enum.Tool.AXE: [1.0, 2.0, 3.0]
		},
	Enum.Difficulty.HARD: {
		Enum.Tool.SWORD: [1.0, 1.5, 2.0],
		Enum.Tool.AXE: [1.0, 2.0, 3.0]
		},
}

const WoodAmount = {
	Enum.Difficulty.EASY: 3,
	Enum.Difficulty.NORMAL: 2,
	Enum.Difficulty.HARD: 1,
}
#endregion
	

#region Trees
const APPLE_TREE_HEALTH = {
	Enum.Difficulty.EASY: 5,
	Enum.Difficulty.NORMAL: 6,
	Enum.Difficulty.HARD: 8,
}

const APPLE_RANGE = {
	Enum.Difficulty.EASY: [3, 5],
	Enum.Difficulty.NORMAL: [2, 5],
	Enum.Difficulty.HARD: [1, 3],
}

const APPLE_TREE_SPRITES = [0, 1, 1, 3]
#endregion


#region Decorations

const DECO_TEXTURES := {
	0: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/01.png"),
	1: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/02.png"),
	2: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/03.png"),
	3: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/04.png"),
	4: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/05.png"),
	5: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/06.png"),
	6: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/07.png"),
	7: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/08.png"),
	8: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/09.png"),
	9: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/10.png"),
	10: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/11.png"),
	11: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/12.png"),
	12: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/13.png"),
	13: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/14.png"),
	14: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/15.png"),
	15: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/16.png"),
	16: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/17.png"),
	17: preload("res://graphics/Tiny Swords/Tiny Swords (Update 010)/Deco/18.png"),
}


# Decoration variants that should have collision.
const COLLISION_SIZES := [2, 5, 8, 11, 12, 15, 16, 17]

#endregion


#region Blob
const BLOB_ENEMY_HEALTH = {
	Enum.Difficulty.EASY: 3,
	Enum.Difficulty.NORMAL: 4,
	Enum.Difficulty.HARD: 5,
}
const BLOB_SPEED = {
	Enum.Difficulty.EASY: 26,
	Enum.Difficulty.NORMAL: 28,
	Enum.Difficulty.HARD: 30,
}
# Damage to Plants
const BLOB_DAMAGE = {
	Enum.Difficulty.EASY: 1,
	Enum.Difficulty.NORMAL: 2,
	Enum.Difficulty.HARD: 3,
} 

# ======== KNOCKBACK ========
const BLOB_KNOCKBACK_FORCE: float = 100.0
const BLOB_KNOCKBACK_DECAY: float = 500.0
const BLOB_KNOCKBACK_TIME: float = 0.5
#endregion


#region Player
const PLAYER_SPEED = {
	Enum.Difficulty.EASY: 75.0,
	Enum.Difficulty.NORMAL: 70.0,
	Enum.Difficulty.HARD: 65.0,
}
var target_highlighter: bool = false
#endregion


#region Player Style
const STYLE_TEXTURES ={
	Enum.Style.STRAW: preload("res://graphics/icons/straw.png"),
	Enum.Style.BASIC: null,
	Enum.Style.COWBOY: preload("res://graphics/icons/cowboy.png"),
	Enum.Style.ENGLISH: preload("res://graphics/icons/english.png"),
	Enum.Style.BASEBALL: preload("res://graphics/icons/blue.png"),
	Enum.Style.BEANIE: preload("res://graphics/icons/beanie.png"),
	Enum.Style.CAP: null,}
	
const PLAYER_SKINS = {
	Enum.Style.STRAW: preload("res://graphics/characters/main/main_straw.png"),
	Enum.Style.BASIC: preload("res://graphics/characters/main/main_basic.png"),
	Enum.Style.COWBOY: preload("res://graphics/characters/main/main_cowboy.png"),
	Enum.Style.ENGLISH: preload("res://graphics/characters/main/main_grey.png"),
	Enum.Style.BASEBALL: preload("res://graphics/characters/main/main_blue.png"),
	Enum.Style.BEANIE: preload("res://graphics/characters/main/main_red.png")}

const STYLE_UPGRADES = {
	Enum.Difficulty.EASY: {
		Enum.Style.BASIC: {
			'icon': null,},
		Enum.Style.COWBOY: {
			'name': 'Cowboy',
			'cost':{Enum.Item.WOOD: 8, Enum.Item.CORN: 6},
			'icon': preload("res://graphics/icons/cowboy.png"),
			'color': Color.SANDY_BROWN},
		Enum.Style.ENGLISH: {
			'name': 'Oldie',
			'cost':{Enum.Item.CORN: 8, Enum.Item.WHEAT: 6},
			'icon': preload("res://graphics/icons/english.png"),
			'color': Color.LIGHT_GRAY},
		Enum.Style.BASEBALL: {
			'name': 'Baseball',
			'cost':{Enum.Item.TOMATO: 8, Enum.Item.APPLE: 6},
			'icon': preload("res://graphics/icons/blue.png"),
			'color': Color.SKY_BLUE},
		Enum.Style.BEANIE: {
			'name': 'Beanie',
			'cost':{Enum.Item.PUMPKIN: 8, Enum.Item.WHEAT: 6},
			'icon': preload("res://graphics/icons/beanie.png"),
			'color': Color.INDIAN_RED},
		Enum.Style.STRAW: {
			'name': 'Straw',
			'cost':{Enum.Item.FISH: 8, Enum.Item.WOOD: 6},
			'icon': preload("res://graphics/icons/straw.png"),
			'color': Color.BURLYWOOD}
	},
	Enum.Difficulty.NORMAL: {
		Enum.Style.BASIC: {
			'icon': null,},
		Enum.Style.COWBOY: {
			'name': 'Cowboy',
			'cost':{Enum.Item.WOOD: 9, Enum.Item.CORN: 7},
			'icon': preload("res://graphics/icons/cowboy.png"),
			'color': Color.SANDY_BROWN},
		Enum.Style.ENGLISH: {
			'name': 'Oldie',
			'cost':{Enum.Item.CORN: 9, Enum.Item.WHEAT: 7},
			'icon': preload("res://graphics/icons/english.png"),
			'color': Color.LIGHT_GRAY},
		Enum.Style.BASEBALL: {
			'name': 'Baseball',
			'cost':{Enum.Item.TOMATO: 9, Enum.Item.APPLE: 7},
			'icon': preload("res://graphics/icons/blue.png"),
			'color': Color.SKY_BLUE},
		Enum.Style.BEANIE: {
			'name': 'Beanie',
			'cost':{Enum.Item.PUMPKIN: 9, Enum.Item.WHEAT: 7},
			'icon': preload("res://graphics/icons/beanie.png"),
			'color': Color.INDIAN_RED},
		Enum.Style.STRAW: {
			'name': 'Straw',
			'cost':{Enum.Item.FISH: 9, Enum.Item.WOOD: 7},
			'icon': preload("res://graphics/icons/straw.png"),
			'color': Color.BURLYWOOD}
	},
	Enum.Difficulty.HARD: {
		Enum.Style.BASIC: {
			'icon': null,},
		Enum.Style.COWBOY: {
			'name': 'Cowboy',
			'cost':{Enum.Item.WOOD: 10, Enum.Item.CORN: 9},
			'icon': preload("res://graphics/icons/cowboy.png"),
			'color': Color.SANDY_BROWN},
		Enum.Style.ENGLISH: {
			'name': 'Oldie',
			'cost':{Enum.Item.CORN: 10, Enum.Item.WHEAT: 9},
			'icon': preload("res://graphics/icons/english.png"),
			'color': Color.LIGHT_GRAY},
		Enum.Style.BASEBALL: {
			'name': 'Baseball',
			'cost':{Enum.Item.TOMATO: 10, Enum.Item.APPLE: 9},
			'icon': preload("res://graphics/icons/blue.png"),
			'color': Color.SKY_BLUE},
		Enum.Style.BEANIE: {
			'name': 'Beanie',
			'cost':{Enum.Item.PUMPKIN: 10, Enum.Item.WHEAT: 9},
			'icon': preload("res://graphics/icons/beanie.png"),
			'color': Color.INDIAN_RED},
		Enum.Style.STRAW: {
			'name': 'Straw',
			'cost':{Enum.Item.FISH: 10, Enum.Item.WOOD: 9},
			'icon': preload("res://graphics/icons/straw.png"),
			'color': Color.BURLYWOOD}
	},
}
#endregion


#region Shop
const ICON_PATHS = {
	Enum.Item.WOOD: "res://graphics/icons/wood.png",
	Enum.Item.FISH: "res://graphics/icons/goldfish.png",
	Enum.Item.APPLE: "res://graphics/icons/apple.png",
	Enum.Item.CORN: "res://graphics/icons/corn.png",
	Enum.Item.WHEAT: "res://graphics/icons/wheat.png",
	Enum.Item.PUMPKIN: "res://graphics/icons/pumpkin.png",
	Enum.Item.TOMATO: "res://graphics/icons/tomato.png"}

var unlocked_styles: Array[Enum.Style] = [Enum.Style.STRAW, Enum.Style.BASIC]
var unlocked_machines: Array[Enum.Machine] = [Enum.Machine.DELETE]

var shop_connection = {
	Enum.Shop.HAT: {'tracker': unlocked_styles, 'all': STYLE_UPGRADES[difficulty].keys()},
	Enum.Shop.MAIN: {'tracker': unlocked_machines,
					 'all': MACHINE_UPGRADE_COST[difficulty].keys()}
	}
#endregion


#region Hint HUD
var controller_connected = false

# item textures
const TEXTURES = {
	Enum.Item.WOOD: preload("res://graphics/icons/wood.png"),
	Enum.Item.APPLE: preload("res://graphics/icons/apple.png"),
	Enum.Item.FISH: preload("res://graphics/icons/goldfish.png"),
	Enum.Item.CORN: preload("res://graphics/icons/corn.png"),
	Enum.Item.TOMATO: preload("res://graphics/icons/tomato.png"),
	Enum.Item.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Item.WHEAT: preload("res://graphics/icons/wheat.png")}


var items_amount = {
	Enum.Difficulty.EASY: {
		Enum.Item.WOOD: 50,
		Enum.Item.APPLE: 50,
		Enum.Item.FISH: 50,
		Enum.Item.CORN: 50,
		Enum.Item.WHEAT: 50,
		Enum.Item.PUMPKIN: 50,
		Enum.Item.TOMATO: 50
	},
	Enum.Difficulty.NORMAL: {
		Enum.Item.WOOD: 40,
		Enum.Item.APPLE: 40,
		Enum.Item.FISH: 40,
		Enum.Item.CORN: 40,
		Enum.Item.WHEAT: 40,
		Enum.Item.PUMPKIN: 40,
		Enum.Item.TOMATO: 40
	},
	Enum.Difficulty.HARD: {
		Enum.Item.WOOD: 30,
		Enum.Item.APPLE: 30,
		Enum.Item.FISH: 30,
		Enum.Item.CORN: 30,
		Enum.Item.WHEAT: 30,
		Enum.Item.PUMPKIN: 30,
		Enum.Item.TOMATO: 30
	},
}


const SEED_TO_ITEM = {
	Enum.Seed.TOMATO: Enum.Item.TOMATO,
	Enum.Seed.CORN: Enum.Item.CORN,
	Enum.Seed.PUMPKIN: Enum.Item.PUMPKIN,
	Enum.Seed.WHEAT: Enum.Item.WHEAT
}


const KEYBOARD_KEYS = {
	Enum.Keyboard.CHANGE_HIGHLIGHT : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyH.png"),
	Enum.Keyboard.CHANGE_MODE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyM.png"),
	Enum.Keyboard.CHANGE_TOOL : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyE.png"),
	Enum.Keyboard.CHANGE_SEED : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyC.png"),
	Enum.Keyboard.CHANGE_STYLE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyT.png"),
	Enum.Keyboard.CHANGE_MACHINE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyE.png"),
	Enum.Keyboard.ACTION :preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/Space.png"),
	Enum.Keyboard.CHANGE_DAY :preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyTab.png"),
}

const KEYBOARD_CONTROLLER = {
	Enum.Keyboard.CHANGE_HIGHLIGHT : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonPlusDown.png"),
	Enum.Keyboard.CHANGE_MODE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonPlusLeft.png"),
	Enum.Keyboard.CHANGE_TOOL : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonRB.png"),
	Enum.Keyboard.CHANGE_SEED : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonRight.png"),
	Enum.Keyboard.CHANGE_STYLE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonUp.png"),
	Enum.Keyboard.CHANGE_MACHINE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonRB.png"),
	Enum.Keyboard.ACTION : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonDown.png"),
	Enum.Keyboard.CHANGE_DAY : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonPlusUp.png"),
}

const MODE_TEXTURE = {
	Enum.State.DEFAULT : preload("res://graphics/characters/farming_mode.png"),
	Enum.State.FISHING : preload("res://graphics/characters/farming_mode.png"),
	Enum.State.SHOP : preload("res://graphics/characters/farming_mode.png"),
	Enum.State.BUILDING : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Items/Tool/Hammer.png"),
	Enum.State.HOUSE : preload("res://graphics/characters/farming_mode.png")	
}

const KEYBOARD_TO_ICONS = {
	Enum.Keyboard.CHANGE_MODE: MODE_TEXTURE,
	Enum.Keyboard.CHANGE_TOOL: TOOL_TEXTURES,
	Enum.Keyboard.CHANGE_MACHINE: MACHINE_TEXTURES,	
	Enum.Keyboard.CHANGE_SEED: SEED_TEXTURES,
	Enum.Keyboard.CHANGE_STYLE: STYLE_TEXTURES,
	Enum.Keyboard.ACTION: {0: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Emote/emote21.png")},
	Enum.Keyboard.CHANGE_DAY: {0: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Skill Icon/Meteo/Moon.png")},
	Enum.Keyboard.CHANGE_HIGHLIGHT: {0: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Theme/Theme Wood/radio_unchecked.png"),
									 1: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Theme/Theme Wood/radio_checked.png")},	
} 
#endregion

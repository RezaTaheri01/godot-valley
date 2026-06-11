extends Node

const PLAYER_SKINS = {
	Enum.Style.BASIC: preload("res://graphics/characters/main/main_basic.png"),
	Enum.Style.BASEBALL: preload("res://graphics/characters/main/main_blue.png"),
	Enum.Style.COWBOY: preload("res://graphics/characters/main/main_cowboy.png"),
	Enum.Style.ENGLISH: preload("res://graphics/characters/main/main_grey.png"),
	Enum.Style.STRAW: preload("res://graphics/characters/main/main_straw.png"),
	Enum.Style.BEANIE: preload("res://graphics/characters/main/main_red.png")}
const TILE_SIZE = 16
const PLANT_DATA = {
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
		'reward': Enum.Item.WHEAT}}
const MACHINE_UPGRADE_COST = {
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
		'color': Color.BURLYWOOD}}
const HOUSE_COST = {
	1: {Enum.Item.WOOD: 30, Enum.Item.APPLE: 20},
	2: {Enum.Item.WOOD: 40, Enum.Item.APPLE: 30}}
const STYLE_UPGRADES = {
	Enum.Style.BASIC: {
		'icon': null,
	},
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
		'color': Color.BURLYWOOD}}
const TOOL_STATE_ANIMATIONS = {
	Enum.Tool.HOE: 'Hoe',
	Enum.Tool.AXE: 'Axe',
	Enum.Tool.WATER: 'Water',
	Enum.Tool.SWORD: 'Sword',
	Enum.Tool.FISH: 'Fish',
	Enum.Tool.SEED: 'Seed',
	}
const FISH_DATA = {
	Enum.Fish.GRAY: {
		'icon_texture': "res://graphics/icons/grayfish.png",
		'name': "Gray Fish",
		'catch_speed': 20,
		'lose_speed': 10,
		'start_progress': 30,
		'frequency': "Common",
		'color': Color.PALE_GREEN
	},
	Enum.Fish.SILVER: {
		'icon_texture': "res://graphics/icons/silverfish.png",
		'name': "Silver Fish",
		'catch_speed': 15,
		'lose_speed': 15,
		'start_progress': 30,
		'frequency': "Rare",
		'color': Color.MEDIUM_PURPLE
	},
	Enum.Fish.GOLD: {
		'icon_texture': "res://graphics/icons/goldfish.png",
		'name': "Gold Fish",
		'catch_speed': 10,
		'lose_speed': 20,
		'start_progress': 30,
		'frequency': "Legendary",
		'color': Color.GOLDENROD
	}
	}
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
	
	
const TOOL_TEXTURES = {
	Enum.Tool.AXE: preload("res://graphics/icons/axe.png"),
	Enum.Tool.HOE: preload("res://graphics/icons/hoe.png"),
	Enum.Tool.WATER: preload("res://graphics/icons/water.png"),
	Enum.Tool.SWORD: preload("res://graphics/icons/sword.png"),
	Enum.Tool.FISH: preload("res://graphics/icons/fish.png"),
	Enum.Tool.SEED: preload("res://graphics/icons/wheat.png")
	}
	
const SEED_TEXTURES = {
	Enum.Seed.TOMATO: preload("res://graphics/icons/tomato.png"),
	Enum.Seed.CORN: preload("res://graphics/icons/corn.png"),
	Enum.Seed.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Seed.WHEAT: preload("res://graphics/icons/wheat.png")
	}

const STYLE_TEXTURES ={
	Enum.Style.STRAW: preload("res://graphics/icons/straw.png"),
	Enum.Style.BASIC: null,
	Enum.Style.COWBOY: preload("res://graphics/icons/cowboy.png"),
	Enum.Style.ENGLISH: preload("res://graphics/icons/english.png"),
	Enum.Style.BASEBALL: preload("res://graphics/icons/blue.png"),
	Enum.Style.BEANIE: preload("res://graphics/icons/beanie.png"),
	Enum.Style.CAP: null,}
	
const MACHINE_TEXTURES = {
	Enum.Machine.DELETE: preload("res://graphics/icons/delete.png"),
	Enum.Machine.SPRINKLER: preload("res://graphics/icons/sprinkler.png"),
	Enum.Machine.FISHER: preload("res://graphics/icons/fisher.png"),
	Enum.Machine.SCARECROW: preload("res://graphics/icons/scarecrow.png"),
}
	
var TARGET_HIGHLIGHTER: bool = false

const APPLE_TREE_HEALTH = 4
const BLOB_ENEMY_HEALTH = 3
const BLOB_SPEED = 25.0
const PLAYER_SPEED = 70.0

# shop
const ICON_PATHS = {
	Enum.Item.WOOD: "res://graphics/icons/wood.png",
	Enum.Item.FISH: "res://graphics/icons/goldfish.png",
	Enum.Item.APPLE: "res://graphics/icons/apple.png",
	Enum.Item.CORN: "res://graphics/icons/corn.png",
	Enum.Item.WHEAT: "res://graphics/icons/wheat.png",
	Enum.Item.PUMPKIN: "res://graphics/icons/pumpkin.png",
	Enum.Item.TOMATO: "res://graphics/icons/tomato.png"}

var FORECAST_RAIN: bool

var unlocked_styles: Array[Enum.Style] = [Enum.Style.STRAW, Enum.Style.BASIC,  Enum.Style.ENGLISH]
var unlocked_machines: Array[Enum.Machine] = [Enum.Machine.DELETE]

var shop_connection = {
	Enum.Shop.HAT: {'tracker': unlocked_styles, 'all': STYLE_UPGRADES.keys()},
	Enum.Shop.MAIN: {'tracker': unlocked_machines,
					 'all': MACHINE_UPGRADE_COST.keys()}
	}

# item textures
const TEXTURES = {
	Enum.Item.WOOD: preload("res://graphics/icons/wood.png"),
	Enum.Item.APPLE: preload("res://graphics/icons/apple.png"),
	Enum.Item.FISH: preload("res://graphics/icons/goldfish.png"),
	Enum.Item.CORN: preload("res://graphics/icons/corn.png"),
	Enum.Item.TOMATO: preload("res://graphics/icons/tomato.png"),
	Enum.Item.PUMPKIN: preload("res://graphics/icons/pumpkin.png"),
	Enum.Item.WHEAT: preload("res://graphics/icons/wheat.png")}


var ITEMS_AMOUNT = {
	Enum.Item.WOOD: 50,
	Enum.Item.APPLE: 50,
	Enum.Item.FISH: 50,
	Enum.Item.CORN: 50,
	Enum.Item.WHEAT: 50,
	Enum.Item.PUMPKIN: 50,
	Enum.Item.TOMATO: 50}


var SEED_TO_ITEM = {
	Enum.Seed.TOMATO: Enum.Item.TOMATO,
	Enum.Seed.CORN: Enum.Item.CORN,
	Enum.Seed.PUMPKIN: Enum.Item.PUMPKIN,
	Enum.Seed.WHEAT: Enum.Item.WHEAT
}


var KEYBOARD_KEYS = {
	Enum.KEYBOARD.CHANGE_HIGHLIGHT : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyH.png"),
	Enum.KEYBOARD.CHANGE_MODE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyM.png"),
	Enum.KEYBOARD.CHANGE_TOOL : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyE.png"),
	Enum.KEYBOARD.CHANGE_SEED : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyC.png"),
	Enum.KEYBOARD.CHANGE_STYLE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyT.png"),
	Enum.KEYBOARD.CHANGE_MACHINE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyE.png"),
	Enum.KEYBOARD.ACTION :preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/Space.png"),
	Enum.KEYBOARD.CHANGE_DAY :preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Keyboard/KeyTab.png"),
}

var KEYBOARD_CONTROLLER = {
	Enum.KEYBOARD.CHANGE_HIGHLIGHT : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonPlusDown.png"),
	Enum.KEYBOARD.CHANGE_MODE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonPlusLeft.png"),
	Enum.KEYBOARD.CHANGE_TOOL : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonRB.png"),
	Enum.KEYBOARD.CHANGE_SEED : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonRight.png"),
	Enum.KEYBOARD.CHANGE_STYLE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonUp.png"),
	Enum.KEYBOARD.CHANGE_MACHINE : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonRB.png"),
	Enum.KEYBOARD.ACTION : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonDown.png"),
	Enum.KEYBOARD.CHANGE_DAY : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/ButtonPlusUp.png"),
}

var MODE_TEXTURE = {
	Enum.State.DEFAULT : preload("res://graphics/characters/farming_mode.png"),
	Enum.State.FISHING : preload("res://graphics/characters/farming_mode.png"),
	Enum.State.SHOP : preload("res://graphics/characters/farming_mode.png"),
	Enum.State.BUILDING : preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Items/Tool/Hammer.png"),
	Enum.State.HOUSE : preload("res://graphics/characters/farming_mode.png")
	
}


var KEYBOARD_TO_ICONS = {
	Enum.KEYBOARD.CHANGE_MODE: MODE_TEXTURE,
	Enum.KEYBOARD.CHANGE_TOOL: TOOL_TEXTURES,
	Enum.KEYBOARD.CHANGE_MACHINE: MACHINE_TEXTURES,	
	Enum.KEYBOARD.CHANGE_SEED: SEED_TEXTURES,
	Enum.KEYBOARD.CHANGE_STYLE: STYLE_TEXTURES,
	Enum.KEYBOARD.ACTION: {0: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Emote/emote21.png")},
	Enum.KEYBOARD.CHANGE_DAY: {0: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Skill Icon/Meteo/Moon.png")},
	Enum.KEYBOARD.CHANGE_HIGHLIGHT: {0: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Theme/Theme Wood/radio_unchecked.png"),
									 1: preload("res://graphics/Ninja Adventure - Asset Pack/Ninja Adventure - Asset Pack/Ui/Theme/Theme Wood/radio_checked.png")},
	
} 

var ControllerConnected = false

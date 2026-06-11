class_name PlantResource extends Resource

@export var texture: Texture2D
@export var icon_texture: Texture2D
@export var h_frames: int = 3

@export var grow_speed: float = 1.0
@export var death_max: float = 3.0
@export var plant_name: String

var age: float = 0.0
var death_count: int = 0

var curr_seed_enum: Enum.Seed

func setup(seed_enum: Enum.Seed):
	curr_seed_enum = seed_enum
	texture = load(Data.PLANT_DATA[seed_enum]["texture"])
	icon_texture = load(Data.PLANT_DATA[seed_enum]["icon_texture"])
	h_frames = Data.PLANT_DATA[seed_enum]["h_frames"] 
	grow_speed = Data.PLANT_DATA[seed_enum]["grow_speed"] 
	death_max = Data.PLANT_DATA[seed_enum]["death_max"] 
	plant_name = Data.PLANT_DATA[seed_enum]["name"]
	

func grow(sprite: Sprite2D):
	death_count = 0
	age = min(age + grow_speed, h_frames)
	sprite.frame = int(age)
	

func decay(plant: StaticBody2D):
	death_count += 1
	if death_count >= death_max:
		plant.queue_free()
		return true
	return false
	

func get_complete():
	return age >= h_frames

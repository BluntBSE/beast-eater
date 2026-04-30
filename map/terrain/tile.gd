class_name Tile
extends Node2D
@export var terrain:Terrain
@export var x_coord:int
@export var y_coord:int
static var TILE_HEIGHT := 64
static var TILE_WIDTH := 64

var occupants := [] #$ Entities

signal entity_entered
signal entity_left
signal mouse_entered
signal mouse_exited

var terrain_lib:TerrainLib = preload("res://map/terrain/terrains/terrain_lib.tres")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.

func unpack(x:int, y:int, terrain_key:String = "cave"):
    #$ Position is relative to the tile root, which will almost certainly be at 0,0 for now
    position = (Vector2(x*TILE_WIDTH, y*TILE_HEIGHT))
    x_coord = x
    y_coord = y
    load_terrain_data(terrain_key)
    #$ Todo: TerrainManager(?) looks up and applies the terrain type.

func load_terrain_data(key:String):
    match key:
        "cave":
            print("Got cave")
            terrain = terrain_lib.cave
            modulate = Color("00ff00")
        "_":
            pass
    %TerrainSprite.texture = terrain.sprite

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

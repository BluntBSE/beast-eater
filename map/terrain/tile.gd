class_name BETileData
extends RefCounted
@export var terrain:Terrain
@export var x_coord:int
@export var y_coord:int
static var TILE_HEIGHT := 32
static var TILE_WIDTH := 32

var occupants := [] #$ Entities

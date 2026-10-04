class_name BETileData
extends RefCounted
@export var terrain:Terrain
@export var x_coord:int
@export var y_coord:int
var is_spawn:bool = false
static var TILE_HEIGHT := 32
static var TILE_WIDTH := 32

var occupants := [] #$ Entities

func append_occupant(entity:Entity):
    #$ Do not permit multiple creatures to occupy the same space.
    for occupant in occupants:
        if occupant is Creature:
            push_error("Tried to append a second creature to a tile that already contains one.")
            return
            
    occupants.append(entity)
    
    pass

extends Node2D
class_name ActiveMap

static var MAP_WIDTH := 30
static var MAP_HEIGHT := 30
static var CELL_SIZE := 32

#$ Holds all the TileDatas.
var map_array := []
var _astar = AStarGrid2D.new()
@onready var tml:TileMapLayer = %TileMapLayer

signal hovered_tile

#$ Store a coordinate such that it is accessed by index in flat array.
func flatten(x:int, y:int, width:int):
    return (y * width) + x


func unflatten(index:int, width:int) -> Vector2i:
    return Vector2i(index % width, index / width)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    load_debug_map()
    TargetUtils.register_map(self)
    for tile:BETileData in map_array:
        if tile.terrain == BSPMapMaker.TERRAIN_LIB.spawn:
            spawn_entity(%Player, Vector2i(tile.x_coord, tile.y_coord)) #$ TODO: Move this debug stuff out
    
    var debug_enemy = preload("res://entities/creature.tscn").instantiate()
    add_child(debug_enemy)
    var enemy_tile = unflatten(pick_random_floor(), MAP_WIDTH)
    spawn_entity(debug_enemy, enemy_tile)
    
    _astar.region = Rect2i(0, 0, MAP_WIDTH, MAP_HEIGHT)
    _astar.cell_size = Vector2i(CELL_SIZE,CELL_SIZE)
    _astar.offset = Vector2i(CELL_SIZE, CELL_SIZE) * 0.5 #$ This means midpoint I think
    _astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    _astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    _astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
    _astar.update()  
      
    pass # Replace with function body.

func load_map(): #Takes in...What? A JSON?

    pass
    

func pick_random_floor():
    var idx :=  randi_range(0, map_array.size()-1)
    var tile:BETileData = map_array[idx]
    if tile.terrain.label == "floor":
        return idx
    else:
        return pick_random_floor()



func round_local_position(local_position:Vector2i):
    return tml.map_to_local(tml.local_to_map(local_position))

func load_debug_map():
    map_array = BSPMapMaker.generate_bsp_map(MAP_WIDTH, MAP_HEIGHT)
    render_map(map_array)

func render_map(tiles:Array)->void:
    for i in tiles.size():
        var coord := unflatten(i, MAP_WIDTH)
        var tile:BETileData = tiles[i]
        
        #$ Do I need a 'render_tile()'? Probably at some point
        tml.set_cell(coord, 1, tile.terrain.atlas_coordinates)
    pass


func get_be_tile_data(pos:Vector2i) -> BETileData: #$ Beast Eater TileData, because TileData is a native class.
    var index = flatten(pos.x, pos.y, MAP_WIDTH)
    var data = map_array[index]
    return data
    
func teleport_entity_to_position(entity:Entity, pos:Vector2i):
    pass
    
func teleport_camera_to_position():
    pass
    
func spawn_entity(entity:Entity, pos:Vector2i):
    var tile:BETileData = map_array[flatten(pos.x, pos.y, MAP_WIDTH)]
    tile.append_occupant(entity)
    entity.position = round_local_position(tml.map_to_local(Vector2i(pos.x, pos.y)))

func spawn_player(pos:Vector2i):
    #var player = Player.new()
    pass

func render_tile(coord:Vector2i):
    #$ Make sure the tile is the right terrain
    var tile:BETileData = map_array[flatten(coord.x, coord.y, MAP_WIDTH)]
    tml.set_cell(coord, 1, tile.terrain.atlas_coordinates)
    #$ If a non-creature entity is in the tile, render its sprite (by moving its node2D to the proper world space?)
    if not tile.occupants.is_empty():
        #$TODO fix for multiple occupants. Maybe just always have creatures be the top in a list? Can sort.
        #$ What can there be in a tile? A creature, an item. A corpse?
        var entity:Entity = tile.occupants[0]
        var target_pos = round_local_position(coord)
        entity.position = target_pos
        pass
    #$ If a creature is in the tile, render its sprite.
    pass


var _last_hovered_tile := Vector2i(-1, -1) #$ So we don't spam the console every frame

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var mouse_pos := get_global_mouse_position()
        var cell := tml.local_to_map(tml.to_local(mouse_pos))

        if cell.x < 0 or cell.x >= MAP_WIDTH or cell.y < 0 or cell.y >= MAP_HEIGHT:
            return #$ Mouse is off the edge of the map

        if cell != _last_hovered_tile:
            _last_hovered_tile = cell
            var tile := get_be_tile_data(cell)
            hovered_tile.emit(tile)
            print("Tile at ", cell, ": ", tile.terrain.label, " occupants=", tile.occupants)

func hover_tile():
    pass

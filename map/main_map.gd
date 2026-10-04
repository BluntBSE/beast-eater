extends Node2D
class_name ActiveMap

static var MAP_WIDTH := 30
static var MAP_HEIGHT := 30
static var CELL_SIZE := 32

#$ Holds all the TileDatas.
var map_array := []
var _astar = AStarGrid2D.new()
@onready var tml:TileMapLayer = %TileMapLayer

#$ Store a coordinate such that it is accessed by index in flat array.
func flatten(x:int, y:int, width:int):
    return (y * width) + x


func unflatten(index:int, width:int) -> Vector2i:
    return Vector2i(index % width, index / width)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    load_debug_map()
    TargetUtils.register_map(self)
  
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


func round_local_position(local_position):
    return tml.map_to_local(tml.local_to_map(local_position))

func load_debug_map():
    map_array = MapMaker.generate_bsp_map(MAP_WIDTH, MAP_HEIGHT)
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
    

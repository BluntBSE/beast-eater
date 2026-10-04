extends Node
#$ class_name MapMaker autoload
const TERRAIN_LIB: TerrainLib = preload("res://map/terrain/terrains/terrain_lib.tres")
#$ BSP Constants
const MIN_LEAF_SIZE := 6   #$ smallest a region can be and still be split further
const MAX_DEPTH := 5       #$ recursion depth cap
const ROOM_MARGIN := 1     #$ gap between a carved room and its partition's edge
const MIN_ROOM_SIZE := 3   #$ smallest allowed room dimension (x or y)

func flatten(x:int, y:int, width:int):
    return (y * width) + x

func unflatten(index:int, width:int):
    return Vector2i(index % width, index / width)

class BSPLeaf:
    var rect: Rect2i
    var left: BSPLeaf = null
    var right: BSPLeaf = null
    var room: Rect2i = Rect2i()
    var connection_point: Vector2i = Vector2i.ZERO

    func _init(p_rect: Rect2i) -> void:
        rect = p_rect

    func is_leaf() -> bool:
        return left == null and right == null


func generate_bsp_map(width, height) -> Array:
    var tiles := []
    tiles.resize(width*height)
    for i in tiles.size():
        var coord = unflatten(i, width)
        var tiledata = BETileData.new()
        tiledata.x_coord = coord.x
        tiledata.y_coord = coord.y
        tiledata.terrain = TERRAIN_LIB.wall
        tiles[i] = tiledata
        
    var root := BSPLeaf.new(Rect2i(0, 0, width, height))
    
    
    #$ Make everything a wall
    
    return tiles
    
func split_leaf(leaf: BSPLeaf, depth: int) -> void:
    if depth >= MAX_DEPTH:
        return

    var can_split_h := leaf.rect.size.y >= MIN_LEAF_SIZE * 2
    var can_split_v := leaf.rect.size.x >= MIN_LEAF_SIZE * 2

    if not can_split_h and not can_split_v:
        return #$ too small to split

    var split_horizontally: bool
    if can_split_h and can_split_v:
        split_horizontally = randf() < 0.5
    else:
        split_horizontally = can_split_h

    if split_horizontally:
        var split_y := randi_range(MIN_LEAF_SIZE, leaf.rect.size.y - MIN_LEAF_SIZE)
        var top_rect := Rect2i(leaf.rect.position, Vector2i(leaf.rect.size.x, split_y))
        var bottom_rect := Rect2i(
            leaf.rect.position + Vector2i(0, split_y),
            Vector2i(leaf.rect.size.x, leaf.rect.size.y - split_y)
        )
        leaf.left = BSPLeaf.new(top_rect)
        leaf.right = BSPLeaf.new(bottom_rect)
    else:
        var split_x := randi_range(MIN_LEAF_SIZE, leaf.rect.size.x - MIN_LEAF_SIZE)
        var left_rect := Rect2i(leaf.rect.position, Vector2i(split_x, leaf.rect.size.y))
        var right_rect := Rect2i(
            leaf.rect.position + Vector2i(split_x, 0),
            Vector2i(leaf.rect.size.x - split_x, leaf.rect.size.y)
        )
        leaf.left = BSPLeaf.new(left_rect)
        leaf.right = BSPLeaf.new(right_rect)

    split_leaf(leaf.left, depth + 1)
    split_leaf(leaf.right, depth + 1)

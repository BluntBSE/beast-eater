extends Node
#$ class_name BSPMapMaker autoload
const TERRAIN_LIB: TerrainLib = preload("res://map/terrain/terrains/terrain_lib.tres")
#$ BSP Constants
const MIN_LEAF_SIZE := 8   #$ smallest a region can be and still be split further
const MAX_DEPTH := 3       #$ recursion depth cap
const ROOM_MARGIN := 1     #$ gap between a carved room and its partition's edge
const MIN_ROOM_SIZE := 6   #$ smallest allowed room dimension (x or y)

func flatten(x:int, y:int, width:int) -> int:
    return (y * width) + x

func unflatten(index:int, width:int):
    return Vector2i(index % width, index / width)
    
func assign_spawn_point():
    pass

class BSPNode:
    var rect: Rect2i
    var left: BSPNode = null
    var right: BSPNode = null
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
        
    var root := BSPNode.new(Rect2i(0, 0, width, height))
    split_node(root, 0)
    
    var corridor_tiles := []
    var rooms := []
    process_node(root, corridor_tiles, rooms)
    
    paint_rooms(root, tiles, width)
    for coord in corridor_tiles:
        var index := flatten(coord.x, coord.y, width)
        tiles[index].terrain = TERRAIN_LIB.floor
    
    #$ Determine spawn from a random room.
    var idx = randi_range(0, rooms.size()-1)
    var spawn_node:BSPNode = rooms[idx]
    var coord := Vector2i(spawn_node.room.size / 2) #$ Dead center of room
    coord = coord + spawn_node.room.position #$ World position
    var spawn_tile:BETileData = tiles[flatten(coord.x, coord.y, width)]
    spawn_tile.terrain = TERRAIN_LIB.spawn
    return tiles    

    
func split_node(node: BSPNode, depth: int) -> void:
    if depth >= MAX_DEPTH:
        return

    var can_split_h := node.rect.size.y >= MIN_LEAF_SIZE * 2
    var can_split_v := node.rect.size.x >= MIN_LEAF_SIZE * 2

    if not can_split_h and not can_split_v:
        return #$ too small to split

    var split_horizontally: bool
    if can_split_h and can_split_v:
        split_horizontally = randf() < 0.5
    else:
        split_horizontally = can_split_h

    if split_horizontally:
        var split_y := randi_range(MIN_LEAF_SIZE, node.rect.size.y - MIN_LEAF_SIZE)
        var top_rect := Rect2i(node.rect.position, Vector2i(node.rect.size.x, split_y))
        var bottom_rect := Rect2i(
            node.rect.position + Vector2i(0, split_y),
            Vector2i(node.rect.size.x, node.rect.size.y - split_y)
        )
        node.left = BSPNode.new(top_rect)
        node.right = BSPNode.new(bottom_rect)
    else:
        var split_x := randi_range(MIN_LEAF_SIZE, node.rect.size.x - MIN_LEAF_SIZE)
        var left_rect := Rect2i(node.rect.position, Vector2i(split_x, node.rect.size.y))
        var right_rect := Rect2i(
            node.rect.position + Vector2i(split_x, 0),
            Vector2i(node.rect.size.x - split_x, node.rect.size.y)
        )
        node.left = BSPNode.new(left_rect)
        node.right = BSPNode.new(right_rect)

    split_node(node.left, depth + 1)
    split_node(node.right, depth + 1)
    

#$ Walks the tree carves rooms in final leaves, and connects
#$ siblings with a corridor as each pair of children finishes. Returns
#$ a point other leaves further up the tree can connect to.
func process_node(node: BSPNode, corridor_tiles: Array, rooms:Array) -> Vector2i:
    if node.is_leaf():
        carve_room(node)
        rooms.append(node)
        node.connection_point = node.room.position + node.room.size / 2
        return node.connection_point

    var point_a := process_node(node.left, corridor_tiles, rooms)
    var point_b := process_node(node.right, corridor_tiles, rooms)
    corridor_tiles.append_array(make_corridor(point_a, point_b))

    node.connection_point = point_a
    return point_a
    
#$ Picks a random room rectangle inside a final leaf, respecting margin + min size.
func carve_room(leaf: BSPNode) -> void:
    var max_width: int = max(leaf.rect.size.x - ROOM_MARGIN * 2, MIN_ROOM_SIZE)
    var max_height: int = max(leaf.rect.size.y - ROOM_MARGIN * 2, MIN_ROOM_SIZE)

    var room_width := randi_range(MIN_ROOM_SIZE, max_width)
    var room_height := randi_range(MIN_ROOM_SIZE, max_height)

    var max_offset_x: int = max(ROOM_MARGIN, leaf.rect.size.x - room_width - ROOM_MARGIN)
    var max_offset_y: int = max(ROOM_MARGIN, leaf.rect.size.y - room_height - ROOM_MARGIN)
    var offset_x := randi_range(ROOM_MARGIN, max_offset_x)
    var offset_y := randi_range(ROOM_MARGIN, max_offset_y)

    leaf.room = Rect2i(
        leaf.rect.position + Vector2i(offset_x, offset_y),
        Vector2i(room_width, room_height)
    )


#$ L-shaped corridor between two points (random bend direction).
func make_corridor(a: Vector2i, b: Vector2i) -> Array:
    var tiles := []
    if randf() < 0.5:
        tiles.append_array(horizontal_line(a.x, b.x, a.y))
        tiles.append_array(vertical_line(a.y, b.y, b.x))
    else:
        tiles.append_array(vertical_line(a.y, b.y, a.x))
        tiles.append_array(horizontal_line(a.x, b.x, b.y))
    return tiles

func horizontal_line(x1: int, x2: int, y: int) -> Array:
    var tiles := []
    for x in range(min(x1, x2), max(x1, x2) + 1):
        tiles.append(Vector2i(x, y))
    return tiles

func vertical_line(y1: int, y2: int, x: int) -> Array:
    var tiles := []
    for y in range(min(y1, y2), max(y1, y2) + 1):
        tiles.append(Vector2i(x, y))
    return tiles
    
    
#$ Paints every leaf's carved room as floor.
func paint_rooms(node: BSPNode, tiles: Array, width: int) -> void:
    if node.is_leaf(): 
        for x in range(node.room.position.x, node.room.position.x + node.room.size.x):
            for y in range(node.room.position.y, node.room.position.y + node.room.size.y):
                var index := flatten(x, y, width)
                tiles[index].terrain = TERRAIN_LIB.floor
    else:
        paint_rooms(node.left, tiles, width)
        paint_rooms(node.right, tiles, width)

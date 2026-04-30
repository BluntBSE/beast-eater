class_name PlayerCamera
extends Camera2D
#$ Phantom camera already has its own script, so we put custom camera stuff on this, even though we
#$ Delegate to PC for actual movement.
var x_coord:int
var y_coord:int

var phantom_camera:PhantomCamera2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    phantom_camera = %PlayerPhantomCamera
    go_to_tile(Vector2(10,10))
    update_limits(ActiveMap.map_width, ActiveMap.map_height, Tile.TILE_WIDTH)
    
    pass # Replace with function body.


func update_limits(cols:int, rows:int, width:int):
    phantom_camera.limit_bottom = (rows * width) + 128
    phantom_camera.limit_right = (rows * width) + 128
    phantom_camera.limit_left = -128
    phantom_camera.limit_top = -128

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    #$ Replace with stepwise later.
    if Input.is_action_just_released("move_up"):    
        go_to_tile(Vector2(x_coord, y_coord-1))
    if Input.is_action_just_released("move_down"):  
        go_to_tile(Vector2(x_coord, y_coord+1))
    if Input.is_action_just_released("move_left"):
        go_to_tile(Vector2(x_coord-1, y_coord))
    if Input.is_action_just_released("move_right"):
        go_to_tile(Vector2(x_coord+1, y_coord))


func go_to_tile(pos:Vector2):
    position = Vector2(pos.x *Tile.TILE_WIDTH, pos.y * Tile.TILE_WIDTH)
    if pos.x >= 0:
        x_coord = pos.x
    if pos.y >= 0:
        y_coord = pos.y

    phantom_camera.position = Vector2(x_coord * Tile.TILE_WIDTH, y_coord * Tile.TILE_WIDTH)
    print("PC Position", phantom_camera.position)

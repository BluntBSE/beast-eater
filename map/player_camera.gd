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
    update_limits(ActiveMap.MAP_WIDTH, ActiveMap.MAP_HEIGHT, 32)
    
    pass # Replace with function body.


func update_limits(cols:int, rows:int, width:int):
    phantom_camera.limit_bottom = (rows * width) + 32*8
    phantom_camera.limit_right = (rows * width) + 32*8
    phantom_camera.limit_left = -32*8
    phantom_camera.limit_top = -32*8

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
    position = Vector2(pos.x * 32, pos.y * 32)
    if pos.x >= 0:
        x_coord = pos.x
    if pos.y >= 0:
        y_coord = pos.y

    phantom_camera.position = Vector2(x_coord * 32, y_coord * 32)
    %CursorSprite.position = Vector2(x_coord * 32, y_coord * 32)
    print("PC Position", phantom_camera.position)

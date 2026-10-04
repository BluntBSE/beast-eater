class_name Terrain
extends Resource
@export var label:String = "default"
@export var label_key:String = "default_key"
@export var base_cost:int = 1
@export var atlas_coordinates:Vector2i
@export var needs_flying:bool = false #$ Chasm or similar
@export var is_blocking:bool = false #$ Wall or similar
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

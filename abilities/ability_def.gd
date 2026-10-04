extends RefCounted
class_name AbilityDef
#$ Shall we say an ability def is composed of...effects? Commands?
#$ A list of effects, either no targets or a target tile
#$ Probably needs to contain the information of the person executing it.

# Called when the node enters the scene tree for the first time.
enum target_type {SINGLE, SELF}
enum area {NONE, LINE, CONE, CIRCLE}
var origin:Entity
var target_tile: Vector2i
var target_entity: Entity

func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

extends Creature
class_name Player

@onready var camera = %Camera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    InputRouter.push_back(self)
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
    
    
func handle_input(): #$ Player is sort of the resting state for input, I guess.
    pass

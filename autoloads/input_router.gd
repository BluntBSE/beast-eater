extends Node
#$ class_name InputRouter, handled by AUtoload
var stack:Array = [] #$ Stack of input consumers
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
    
func push_back(consumer:Object) -> void:
    assert(consumer.has_method("handle_input"))
    stack.push_back(consumer)
    
func remove_last(consumer:Object) -> void:
    var idx:int = stack.rfind(consumer)
    if idx != -1:
        stack.remove_at(idx)

func _unhandled_input(event: InputEvent) -> void:
    if stack.is_empty():
        return
    var top:Object = stack.back()
    if top.handle_input(event): #$ Remember that this implies that a custom input handler called handle_input must be created.
        get_viewport().set_input_as_handled()
    
    

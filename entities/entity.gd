extends Node
class_name Entity

@export var might:int = 1
@export var fortitude:int = 1
@export var agility:int = 1
@export var will:int = 1
@export var speed:int = 1
@export var energy:int = 5000
@export var burn_rate:int = 10



var abilities:Array #Of AbilityDefs



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

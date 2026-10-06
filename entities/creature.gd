extends Entity
class_name Creature

@export var hp_max:int = 10
@export var current_hp:int = 10
@export var label:String = "Enemy creature"
@export var sprite: Texture2D
@export var might:int = 1
@export var fortitude:int = 1
@export var agility:int = 1
@export var will:int = 1
@export var speed:int = 100
@export var energy:int = 2500
@export var burn_rate:int = 10
@export var alive:bool = true
@export var friendly:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

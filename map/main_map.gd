extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    load_debug_map()
    pass # Replace with function body.

func load_map(): #Takes in...What? A JSON?

    pass

func load_debug_map():
    #$ Let's commit to "odd q" flat top alignment, which shoves odd columns down.
    var square_width:int = 128
    var cols := 32
    var rows := 32
    for col in cols:
        for row in rows:
            var tile:Tile = preload("res://map/terrain/tile.tscn").instantiate()
            %TileRoot.add_child(tile)
            tile.unpack(col, row)
    pass

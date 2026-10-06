extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    %MainMap.hovered_tile.connect(handle_hovered_tile)
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass
    
func handle_hovered_tile(data:BETileData):
    var has_creature  := false
    if not data.occupants.is_empty():
        for occupant in data.occupants:
            if occupant is Creature:
                has_creature = true
                %TargetPanelCreature.visible = true
                %TargetCreaturePortrait.visible = true

                render_creature_data(occupant)
                return
    
    if has_creature == false:
        %TargetPanelCreature.visible = false
        %TargetCreaturePortrait.visible = false

func render_creature_data(creature:Creature):
    %CreatureLabel.text = creature.label
    %CreatureHPLabel.text = "HP: %d/%d" % [creature.current_hp, creature.hp_max]
    %CreatureCalorieLabel.text = "Calories: %d MCal" % creature.energy
    %CreatureBurnLabel.text = "Burn Rate: %dMCal" % creature.burn_rate
    %CreatureMightLabel.text = "MI: %d" % creature.might
    %CreatureFortitudeLabel.text = "FOR: %d" % creature.fortitude
    %CreatureAgilityLabel.text = "AGI: %d" % creature.agility
    %CreatureWillLabel.text = "WIL: %d" % creature.will

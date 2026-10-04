extends Node
#$ class_name Scheduler | autoload
var waiting_for_player := true
var current_actor:Schedulable
var BASE_TIME := 100
var current_time := 0
var current_turn = 0
var schedule := []

class Schedulable:
    var time:int

class Actor extends Schedulable:
    var actor:Creature
    
class TurnEntity extends Schedulable: #$ Exists just to mark the passage of 'full turns'
    pass
    
class Event extends Schedulable: #$ In case I want to trigger something at a specific time
    var event

func compute_cost(actor:Schedulable, action:AbilityInstance):
    #$ TODO: Make this anything. While this is BASE_TIME, all actions are one turn.
    return BASE_TIME

func run() -> void:
    waiting_for_player = false
    while not waiting_for_player:
        schedule.sort_custom(func(a, b): return a.time < b.time)
        var entry = schedule[0]
        current_time = entry.time

        if entry is Actor:
            if entry.actor is Player:
                current_actor = entry
                waiting_for_player = true
                return
                
            var action = entry.actor.choose_ai_action()
            _resolve(entry, action)
            
        if entry is TurnEntity:
            current_turn += 1
            entry.time += 100

func _resolve(entry: Schedulable, action: AbilityInstance) -> void:
    entry.actor.perform(action)
    entry.time += compute_cost(entry.actor, action)

func resolve_player_action(action: AbilityInstance) -> void:
    _resolve(current_actor, action)
    current_actor = null
    run()
    

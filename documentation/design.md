# Design Overview

## Architecture

#GameManager
-Game manager mneed to track the state of what UI, if any, is open. It then needs to allow inputs to trickle down to the right spot (an inventory,or the game.)
-This sort of implies taking things like WASD and parsing them into "Game left/Game up" and "UI left/UI up". Is a state machine necessary, or overkill? Could I simply assign
-Multiple inputs (WASD) to Godot-defined inputs like "UI left/UI up" and let anything active consume that?...But then we still have the problem of tracking what's active.

#Randomness - Bag of Tokens

##UI

What needs to be shown?

FOR SURE:
    Health
    Kcal
    Loaded abilities
    
    
    Examining Enemies
    Name
    HP
    Might
    Fort
    Agi
    Will
    Tags
    Abilities
    -And all their tags
    -Description of tag?


Combat log
(pageable? Extended log?)

## Stats
MIGHT:
Damage = Might Directly?



FORTITUDE:
HP = 10x FORTITUDE
KCal Max = 250x FORTITUDE
Fort saves: d20 >= 11 (attacker_might, defender_fortitude)


AGILITY:
10 AGI vs 10 AGI = 50% hit chance
Hit if:  d20 + attacker_agility - defender_agility >= 11

Equivalently:  d20 >= 11 - (attacker_agility - defender_agility)

WILL:
5% faster cooldowns (rounded down) per point?...But if we're mostly using "Strike", does this actually help?
Perhaps 5% less kcal cost?
Will saves: d20 >= 11 (attacker_might, defender_will)


## Abilities

Abilities are a stack of effects that can accept between zero and one tiles as targets. (AOE will be handled as a function of choosing a single target still)

Abilities occur in two phases. Application and Resolution. Basically application will apply damage, status effects, etc.

Resolution checks like: "Will this creature die? Does this creature have status effects I care about? Did this character bump into a wall with forced movement? Etc."

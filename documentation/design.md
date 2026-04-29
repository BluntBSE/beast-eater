# Design Overview

## Hex Grid


## Stats
MIGHT:
Damage = Might Directly?



FORTITUDE:
HP = 10x FORTITUDE
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

# Map Architecture: Flattening, Storage, and Pathfinding

This document explains how to store the level grid efficiently as it scales toward
256x256, why that storage shape was chosen, and how the pieces (terrain, entities,
items, pathfinding, rendering) fit together on top of it.

---

## 1. The Core Problem

A naive approach gives every grid cell a live scene node (our current `Tile.tscn`,
which is a `Node2D` + `Sprite2D` + `Area2D` + `CollisionShape2D`). At 10x10 that's
fine. At 256x256, that's 65,536 cells x 4 nodes = **262,144 nodes**, a large chunk of
which are physics bodies the engine has to track every physics frame just so we can
detect mouse clicks.

The fix is to stop treating "the map" as a pile of scene nodes and start treating it
as **data first, nodes second** — nodes only get created for the (small) subset of
things that actually need to be interactive, animated, or rendered as a full sprite.

---

## 2. Theory: Why Flatten a 2D Grid Into a 1D Array

### 2.1 Cache locality

Modern CPUs pull data from RAM in chunks called cache lines, and it's *dramatically*
faster to read bytes that are next to each other in memory than to chase pointers
scattered across the heap (nested arrays, node trees, etc.). Robert Nystrom's
[Data Locality chapter](https://gameprogrammingpatterns.com/data-locality.html)
benchmarks this directly: the *same computation*, done via pointer-chasing vs. a flat
contiguous array, differed by **50x**.

A `Tile` scene node has to be reached via `get_child()`/tree traversal — that's
pointer chasing. A flat `PackedByteArray` is one contiguous block — that's cache-friendly.

### 2.2 Row-major flattening

To store a 2D grid in a 1D array, pick one axis to be "outer" and multiply by the
row width:

```gdscript
func flatten(x: int, y: int, width: int) -> int:
    return y * width + x
```

Row 0 occupies indices `0..width-1`, row 1 occupies `width..2*width-1`, and so on.
This is called **row-major order** — the same convention C, C++, and NumPy default to.
(See [Wikipedia: Row- and column-major order](https://en.wikipedia.org/wiki/Row-_and_column-major_order)
for the formal treatment, including the column-major mirror image used by Fortran/MATLAB.)

To go the other direction (index -> coordinate), which you need when iterating the
flat array during rendering or saving/loading:

```gdscript
func unflatten(index: int, width: int) -> Vector2i:
    return Vector2i(index % width, index / width)
```

### 2.3 Dense vs. sparse: pick storage per data type, not once for the whole map

This is the part that's easy to over-generalize. **Hashmaps are not universally
faster than arrays.** For dense data (every cell has a value), a flat array beats a
hashmap because array indexing is direct pointer arithmetic, while a hashmap has to
hash the key and walk into a bucket. Hashmaps only win when most of the space would
otherwise be wasted storing empty placeholders.

| Data | Density | Storage |
|---|---|---|
| Terrain (every cell has *some* floor/wall) | Dense | Flat array (`PackedByteArray`) |
| Creature occupancy (most cells empty) | Sparse | `Dictionary[Vector2i, Creature]` |
| Items on the ground | Sparse | `Dictionary[Vector2i, Array]` |

`Vector2i` is natively hashable in Godot, so it works directly as a `Dictionary` key —
no need to manually compute a combined integer key for the sparse cases, only the
dense flat array needs the `flatten()` math.

(Amit Patel's [Red Blob Games map storage guide](https://www.redblobgames.com/grids/hexagons/#map-storage)
covers this same dense/hash/array-of-arrays tradeoff in more depth, framed around hex
grids, but the reasoning transfers directly to square grids.)

---

## 3. The Data/Position Split (Why a Tile Isn't "Smart" About Its Own Coordinates)

The same tension shows up for terrain, creatures, and items: an object has
**permanent identity data** (what it *is*) and **positional context** (where it
currently *is*). Baking both into one object creates two sources of truth that can
desync — e.g. a creature's cached `x, y` disagreeing with the tile that thinks it owns
that creature.

The pattern used throughout this architecture is a two-part split:

- **Data object** — permanent, positionless, often shareable. A `Resource` in Godot
  terms. Example: `Terrain` (already exists in `map/terrain/`), or `CreatureData`
  (stats: might, fortitude, agility, etc.).
- **Positioned wrapper** — holds a reference to the data object *plus* exactly one
  record of where it is. Never duplicated, never cached in two places. Example:
  `Tile` (already exists — holds `@export var terrain: Terrain` plus `x_coord`/`y_coord`),
  or a `Creature` node holding `data: CreatureData` plus a single `tile: Tile` reference,
  updated only through one atomic `move_to()` function.

This is why `Tile` doesn't need "smart" bounds-checking logic of its own baked in —
that responsibility belongs to the `Level` (next section), which is the one place
that knows the grid's width/height and can validate coordinates before handing back
a `Tile` or `Terrain` reference.

---

## 4. The `Level` Class: Combining Dense Terrain + Sparse Occupants

`Level` owns all of the map's data and is the single source of truth for "what's at
this coordinate" — combining the dense terrain layer and the sparse occupancy layers
into one queryable interface.

```gdscript
class_name Level
extends RefCounted

var width: int
var height: int

var terrain_ids: PackedByteArray          # dense — one byte per cell
var terrain_lib: TerrainLib               # shared terrain definitions (sprites, movement cost, etc.)

var creature_occupancy: Dictionary = {}   # sparse — Vector2i -> Creature
var item_occupancy: Dictionary = {}       # sparse — Vector2i -> Array[Item]

func _init(_width: int, _height: int, _terrain_lib: TerrainLib) -> void:
    width = _width
    height = _height
    terrain_lib = _terrain_lib
    terrain_ids.resize(width * height)

func flatten(coord: Vector2i) -> int:
    return coord.y * width + coord.x

func in_bounds(coord: Vector2i) -> bool:
    return coord.x >= 0 and coord.x < width and coord.y >= 0 and coord.y < height

func get_terrain(coord: Vector2i) -> Terrain:
    return terrain_lib.get_by_id(terrain_ids[flatten(coord)])

func set_terrain(coord: Vector2i, terrain_id: int) -> void:
    terrain_ids[flatten(coord)] = terrain_id

func get_creature_at(coord: Vector2i) -> Creature:
    return creature_occupancy.get(coord)

func get_items_at(coord: Vector2i) -> Array:
    return item_occupancy.get(coord, [])
```

Every "what's here" question funnels through `Level`, whether the answer comes from
the dense array (terrain) or a sparse dictionary (creatures, items). Calling code
never needs to know which storage backs which answer.

### 4.1 Moving a creature (avoiding the desync bug)

All movement goes through one function so the occupancy dictionary and the
creature's own position record can never disagree:

```gdscript
func move_creature(creature: Creature, from: Vector2i, to: Vector2i) -> void:
    creature_occupancy.erase(from)
    creature_occupancy[to] = creature
    creature.coord = to
```

Nothing else is allowed to touch `creature_occupancy` directly — that discipline is
what prevents the classic "tile says one thing, creature says another" bug.

---

## 5. Pathfinding Over a Flattened Grid

Pathfinding algorithms (A*, Dijkstra, BFS) never scan the array in memory order —
they hop between coordinates by computing neighbors and looking each one up
individually. The flat array is a fast **lookup table**, not something walked
sequentially. Every pathfinding algorithm only needs two primitives:

```gdscript
const DIRECTIONS = [
    Vector2i(1, 0), Vector2i(-1, 0),
    Vector2i(0, 1), Vector2i(0, -1),
]

func get_neighbors(coord: Vector2i) -> Array:
    var result := []
    for dir in DIRECTIONS:
        var n = coord + dir
        if in_bounds(n) and not get_terrain(n).blocks_movement:
            result.append(n)
    return result

func get_move_cost(coord: Vector2i) -> float:
    return get_terrain(coord).movement_cost   # e.g. mud = 2.0, floor = 1.0
```

`get_neighbors` never touches the array except through `get_terrain`, which flattens
internally. The "2D-ness" of pathfinding only ever exists as `Vector2i` math on top
of an O(1) lookup — the grid being flat underneath is invisible to the algorithm.

### 5.1 Practical implementation: `AStarGrid2D`

Rather than hand-write a priority queue for a 256x256 map, build Godot's built-in
solver once from `terrain_ids`:

```gdscript
func build_astar_grid(level: Level) -> AStarGrid2D:
    var astar := AStarGrid2D.new()
    astar.region = Rect2i(0, 0, level.width, level.height)
    astar.cell_size = Vector2(1, 1)
    astar.update()

    for y in level.height:
        for x in level.width:
            var coord := Vector2i(x, y)
            var terrain := level.get_terrain(coord)
            if terrain.blocks_movement:
                astar.set_point_solid(coord)
            else:
                astar.set_point_weight_scale(coord, terrain.movement_cost)

    return astar
```

For **sparse** obstacles (a creature standing in the way), temporarily mark those
specific cells solid before pathing and clear them afterward — the dense terrain
grid handled by `AStarGrid2D` doesn't need to know about the sparse occupancy layer
at all:

```gdscript
func find_path_avoiding_creatures(astar: AStarGrid2D, level: Level, start: Vector2i, goal: Vector2i) -> PackedVector2Array:
    var temporarily_solid := []
    for coord in level.creature_occupancy.keys():
        if coord != start:
            astar.set_point_solid(coord, true)
            temporarily_solid.append(coord)

    var path := astar.get_point_path(start, goal)

    for coord in temporarily_solid:
        astar.set_point_solid(coord, false)

    return path
```

### 5.2 Variant: "nearest tile of type X"

Same two primitives, no fixed destination — expand outward (BFS/Dijkstra) and stop
as soon as you dequeue a cell whose terrain matches what you're looking for.

---

## 6. Rendering at Scale

Terrain is dense, so its natural renderer is a
[`TileMapLayer`](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html) —
Godot's purpose-built tool for large uniform grids. It stores cells in an optimized
internal format, batches draw calls, and automatically culls off-screen cells, instead
of one `Sprite2D` node (with its own transform/visibility overhead) per cell.

```gdscript
func sync_visual_layer(level: Level, tile_map_layer: TileMapLayer) -> void:
    for y in level.height:
        for x in level.width:
            var coord := Vector2i(x, y)
            var terrain := level.get_terrain(coord)
            tile_map_layer.set_cell(coord, terrain.tile_source_id, terrain.atlas_coords)
```

`Level.terrain_ids` remains the source of truth for game logic; the `TileMapLayer`
is purely a visual mirror of it, updated whenever a cell's terrain changes (e.g. a
door opening, a wall collapsing).

**Creatures and items stay as real scene nodes** — there are comparatively few of
them (dozens, not tens of thousands), and they need animation, signals, and
per-instance behavior that justifies full Node overhead.

---

## 7. Click Detection Without Per-Cell Physics Bodies

Because the grid is uniform, "which tile did I click" is pure math — no `Area2D`
or `CollisionShape2D` per cell required:

```gdscript
func get_tile_under_mouse(camera: Camera2D) -> Vector2i:
    var mouse_pos = camera.get_global_mouse_position()
    return Vector2i(
        int(floor(mouse_pos.x / Tile.TILE_WIDTH)),
        int(floor(mouse_pos.y / Tile.TILE_HEIGHT))
    )
```

This is O(1) regardless of map size and removes the single most expensive part of
the original per-tile-node design (65k physics bodies at 256x256). Reserve real
`Area2D`-based detection for things that genuinely need it — a moving creature
sprite the player can click on directly, for instance.

---

## 8. Summary: Mapping This Onto the Existing Codebase

| Concept | Where it lives | Density | Notes |
|---|---|---|---|
| Terrain definitions | `map/terrain/terrain.gd` (`Terrain` `Resource`) | Shared/immutable | Already exists |
| Terrain-per-cell | `Level.terrain_ids` (`PackedByteArray`) | Dense | New — replaces one `Tile` node per cell as the data source of truth |
| Terrain rendering | `TileMapLayer` | Dense | New — replaces `Tile.tscn`'s `Sprite2D` |
| Tile click detection | Math on mouse position | N/A | New — replaces `Tile.tscn`'s `Area2D`/`CollisionShape2D` |
| Creature stats | `CreatureData` (`Resource`) | N/A | New split-out from current `Creature` |
| Creature position | `Creature.coord` + `Level.creature_occupancy` | Sparse | Updated only via `Level.move_creature()` |
| Item position | `Level.item_occupancy` | Sparse | Same shape as creature occupancy |
| Pathfinding | `AStarGrid2D`, built from `Level.terrain_ids` | N/A | Rebuilt/patched when terrain or dense obstacles change |

This is a bigger refactor than the current `Tile`-node-per-cell setup, and is worth
doing deliberately rather than all at once — the terrain flattening (Section 4) and
the `AStarGrid2D` wiring (Section 5.1) are the two pieces most worth doing first,
since they're the ones that stop scaling gracefully past a few thousand cells.

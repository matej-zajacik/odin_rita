package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:slice"
import "vendor:raylib"
import "shared:queedo"



Actor_Proc  :: proc(actor: ^Actor)
Attack_Proc :: proc(actor: ^Actor, phase: int) -> bool
Impact_Proc :: proc(projectile: ^Actor, target: ^Actor, hit_point: Vector2, hit_normal: Vector2)



Actor_Id :: enum
{
    PLAYER,
    SPIDERLING,
}



Actor_Flag :: enum
{
    MOVED_THIS_FRAME,
    DAMAGEABLE,
    IN_PLAY,
    MOBILE,
    PAWN,
    PROJECTILE,
    TARGETABLE,
    WALKER,
}

Actor_Flags :: bit_set[Actor_Flag]



Actor_State :: enum
{
    DEFAULT,
    CHASE,
    ATTACK,
    DEATH,
}



Faction :: enum
{
    NEUTRAL,
    GOOD,
    EVIL,
}



Actor :: struct
{
    //
    // Identity
    //

    id: Actor_Id,

    // A pointer to the actor's blueprint.
    bp: ^Actor_Blueprint,

    // Current flags.
    flags: Actor_Flags,

    //
    // Maintenance
    //

    // An index in the global `actors` array.
    array_index: int,

    // The frame the actor was spawned on. This is to prevent it being ticked on the same frame it was spawned, and also to determine its current lifetime.
    spawn_frame: int,

    // The frame the actor is supposed to be automatically removed at. This is to automate removal of short-lived actors like explosions, impact effects, sounds, etc.
    removal_frame: int,

    //
    // Movement & physics
    //

    position:     Vector2,
    angle:        f32,
    desired_dir:  Vector2,
    speed:        Vector2,
    thrust_timer: int,
    sector:       ^Sector,

    //
    // Behavior
    //

    state:        Actor_State,
    tick_proc:    Actor_Proc,
    tick_phase:   int,
    tick_timer:   int,

    target:       ^Actor,
    attack_proc:  Attack_Proc,
    attack_phase: int,
    attack_timer: int,

    owner:        ^Actor,
    health:       int,
    faction:      Faction,
}



Pool_Item :: struct
{
    pooled_frame: int,
    actor:        ^Actor,
}



actors:             [MAX_ACTORS]^Actor
actor_count:        int
free_actor_indexes: [dynamic]int
actor_pool:         [Actor_Id][dynamic]Pool_Item
// targetable_actors: [Faction][dynamic]^Actor



init_actors :: proc()
{
    for i in 0..<MAX_ACTORS
    {
        append(&free_actor_indexes, MAX_ACTORS - 1 - i)
    }
}



get_actor_from_pool :: proc(id: Actor_Id) -> ^Actor
{
    arr := &actor_pool[id]

    if len(arr) == 0
    {
        return nil
    }

    // We iterate from the end, because it's cheap to remove items from an array's end and it's very likely that the actor is already re-usable.
    #reverse for &item, i in arr
    {
        // We can return a pooled actor only if it has been in the pool for at least 2 frames.
        if current_frame - item.pooled_frame > 1
        {
            item_actor := item.actor
            unordered_remove(arr, i)
            return item_actor
        }
    }

    return nil
}



put_actor_to_pool :: proc(actor: ^Actor)
{
    arr := &actor_pool[actor.id]

    item: Pool_Item
    item.pooled_frame = current_frame
    item.actor = actor

    append(arr, item)
}



make_actor :: proc(id: Actor_Id) -> ^Actor
{
    // fmt.println("Making actor", id)

    bp := &blueprints[id]

    if bp.flags == {}
    {
        log.panicf("no such blueprint id %v", id)
    }

    actor := new(Actor)

    actor.id = id
    actor.bp = bp

    if bp.make_proc != nil
    {
        bp.make_proc(actor)
    }

    return actor;
}



spawn_actor :: proc(id: Actor_Id, position: Vector2, angle: f32) -> ^Actor
{
    assert(actor_count < MAX_ACTORS)

    // Get an actor from the pool.
    actor := get_actor_from_pool(id)

    // If there is no ready actor in the pool, let's make it from scratch.
    if actor == nil
    {
        actor = make_actor(id)
    }

    //
    // Identity
    //

    bp := actor.bp

    // Reset our flags and add a flag denoting that we're in play now.
    actor.flags = bp.flags + {.IN_PLAY}

    //
    // Maintenance
    //

    // Assign a free array index and add it to the `actors` array.
    array_index := pop(&free_actor_indexes)
    actor.array_index = array_index
    actors[array_index] = actor

    // Set this frame as the frame we spawned. We need this to ensure we don't tick this very frame and also to measure our lifetime, potentially.
    actor.spawn_frame = current_frame

    // Make sure the game doesn't remove the actor automatically later on (unless told to specifically somewhere down the line).
    actor.removal_frame = -1

    //
    // Movement & physics
    //

    actor.desired_dir = {}
    actor.speed = {}
    actor.thrust_timer = 0
    actor.sector = nil

    //
    // Behavior
    //

    // actor.state = .DEFAULT
    // actor.tick_proc = bp.default_proc
    // actor.tick_phase = 0
    // actor.tick_timer = 0

    actor.target = nil
    actor.attack_proc = nil
    actor.attack_phase = 0
    actor.attack_timer = 0

    actor.owner = nil
    actor.health = bp.health
    actor.faction = bp.faction

    // Run a specialized spawn proc if we have one.
    if bp.spawn_proc != nil
    {
        bp.spawn_proc(actor)
    }

    // Link the actor to a sector.
    set_actor_position(actor, position)
    set_actor_angle(actor, angle)

    set_actor_state(actor, .DEFAULT)

    return actor
}



remove_actor :: proc(actor: ^Actor, delay: int = 0)
{
    if delay > 0
    {
        actor.removal_frame = current_frame + delay
        return
    }

    actors[actor.array_index] = nil
    actor.flags -= {.IN_PLAY}
    update_actor_sector(actor)
    put_actor_to_pool(actor)
}



tick_actors :: proc()
{
    mobile_actors := make([dynamic]^Actor, context.temp_allocator)

    for actor in actors
    {
        // No actor? No tick.
        if actor == nil do continue

        // If we just spawned, we don't tick.
        if actor.spawn_frame == current_frame
        {
            continue
        }

        // If our target is out of play, we need to remove it.
        if actor.target != nil && .IN_PLAY not_in actor.target.flags
        {
            actor.target = nil
        }

        // Is this our hour of doom?
        if actor.removal_frame == current_frame
        {
            remove_actor(actor)
            continue
        }

        if actor.tick_proc != nil
        {
            actor.tick_proc(actor)
        }

        if .MOBILE in actor.flags
        {
            append(&mobile_actors, actor)
            update_actor_speed(actor)
        }
    }

    //
    // Actors vs actors
    //

    for actor in mobile_actors
    {
        if actor.speed == {} && .MOVED_THIS_FRAME not_in actor.flags
        {
            continue
        }

        move_actor(actor, actor.speed)

        for other in actor.sector.actors
        {
            if other == actor do continue

            other_to_actor_vec := actor.position - other.position
            dist := linalg.length(other_to_actor_vec)
            radii := actor.bp.radius + other.bp.radius

            if dist < radii
            {
                dir := linalg.normalize(other_to_actor_vec)
                move_actor(actor, dir * (radii - dist))
            }
        }
    }

    //
    // Actors vs geometry
    //

    // We test against geometry only after all actor-vs-actor tests are done, because geometry has higher priority (must be solid and cannot be moved through).

    for actor in mobile_actors
    {
        c := Circle{actor.position.x, actor.position.y, actor.bp.radius}

        for rect in actor.sector.geo_colliders
        {
            if hit, dep := circle_intersects_rect(c, rect^); hit
            {
                move_actor(actor, dep)

                if dep.x != 0.0 do actor.speed.x = 0.0
                if dep.y != 0.0 do actor.speed.y = 0.0
            }
        }
    }


    //
    // Update sectors
    //

    for actor in mobile_actors
    {
        if .MOVED_THIS_FRAME not_in actor.flags do continue

        update_actor_sector(actor)
        actor.flags -= {.MOVED_THIS_FRAME}
    }



    move_actor :: proc(actor: ^Actor, delta: Vector2)
    {
        if delta == {} do return

        actor.position += delta
        actor.flags += {.MOVED_THIS_FRAME}
    }
}



// Calculates a new speed based on the actor's desired direction of movement.
update_actor_speed :: proc(actor: ^Actor)
{
    dir := actor.desired_dir

    // The rate of acceleration towards the target speed varies based on some conditions.
    acceleration_mult: f32
    target_speed:      Vector2

    speed := actor.speed

    if dir != {}
    {
        // If we have some direction given, let's set that as our new target speed.
        target_speed = dir * actor.bp.speed
        acceleration_mult = 1.0
    }
    else
    {
        // If no direction is given...

        // ...and we ain't even moving, there's nothing to do here.
        if speed == {} do return

        // ...then we want to stop, but a little slower.
        target_speed = {}
        acceleration_mult = 0.5
    }

    // If our current speed is higher than our max speed, likely due to getting "thrusted" previously, we slow down gradually until we're within our natural speed limits.
    if linalg.length(speed) > actor.bp.speed
    {
        speed *= OVERSPEED_DRAG
    }

    // If we have recently been thrusted, our ability to steer is significantly limited, but gradually comes back towards the end of the effect.
    if actor.thrust_timer > 0
    {
        acceleration_mult *= math.pow(1.0 - f32(actor.thrust_timer) / THRUST_DURATION, 3.0)
        actor.thrust_timer -= 1
    }

    // Now finally compute the new speed.
    actor.speed = move_towards(speed, target_speed, actor.bp.acceleration * acceleration_mult)
}



// Should be called when the actor's position is supposed to suddenly change (when spawned, teleported, and such).
// Standard movement code doesn't call this.
set_actor_position :: proc(actor: ^Actor, position: Vector2)
{
    actor.position = position
    update_actor_sector(actor)
}



set_actor_angle :: proc(actor: ^Actor, angle: f32)
{
    actor.angle = get_wrapped_angle(angle)
}



update_actor_sector :: proc(actor: ^Actor)
{
    // log.infof("update_actor_sector: actor %v", actor.id)

    sector: ^Sector

    if .IN_PLAY in actor.flags
    {
        // Find out which sector we belong to now.
        x, y := world_position_to_tile_position(actor.position)
        sector = get_sector(x, y);
        // log.infof("sector: %v (%v,%v)", sector, x, y)
    }

    // If it's the same sector that we already have, we don't need to do anything.
    if sector == actor.sector do return

    if actor.sector != nil
    {
        // If we already have a sector, we remove ourselves from it and its neighbors.
        unordered_remove_by_value(&actor.sector.actors, actor)

        for neighbor_sector in actor.sector.neighbors
        {
            unordered_remove_by_value(&neighbor_sector.actors, actor)
        }
    }

    if sector != nil
    {
        // log.infof("update_actor_sector: actor %v added to sector %v,%v", actor.id, sector.debug_tile_pos_x, sector.debug_tile_pos_y)

        // If we are ordered to set a sector (because we may be order to set nil), we add ourselves to it and its neighbors.
        append(&sector.actors, actor)

        for neighbor_sector in sector.neighbors
        {
            // log.infof("update_actor_sector: actor %v added to neighbor sector %v,%v", actor.id, neighbor_sector.debug_tile_pos_x, neighbor_sector.debug_tile_pos_y)
            append(&neighbor_sector.actors, actor)
        }
    }

    // And we set the new sector as our current sector.
    actor.sector = sector
}



set_actor_state :: proc(actor: ^Actor, new_state: Actor_State)
{
    old_state := actor.state

    switch new_state
    {
        case .DEFAULT:
            actor.tick_proc = actor.bp.default_proc

        case .CHASE:
            actor.tick_proc = actor.bp.chase_proc

        case .ATTACK:
            actor.tick_proc = actor.bp.attack_proc

        case .DEATH:
            actor.tick_proc = actor.bp.death_proc
    }

    actor.state = new_state
    actor.tick_phase = 0
    actor.tick_timer = 0
}
package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:slice"
import "vendor:raylib"



actor_proc_t  :: proc(actor: ^actor_t)
attack_proc_t :: proc(actor: ^actor_t, phase: int) -> bool
impact_proc_t :: proc(proj: ^actor_t, target: ^actor_t, hit_point: vec2_t, hit_normal: vec2_t)



actor_id_t :: enum
{
    PLAYER,
    PISTOL_PROJECTILE,
    SPIDERLING,
}



actor_flag_t :: enum
{
    DAMAGEABLE,
    IN_PLAY,
    MECHANICAL,
    MOBILE,
    MOVED_THIS_FRAME,
    PAWN,
    PROJECTILE,
    TARGETABLE,
    WALKER,
}

actor_flags_t :: bit_set[actor_flag_t]



actor_state_t :: enum
{
    DEFAULT,
    CHASE,
    ATTACK,
    DEATH,
}



faction_t :: enum
{
    NEUTRAL,
    GOOD,
    EVIL,
}



actor_t :: struct
{
    //
    // Identity
    //

    id: actor_id_t,

    // A pointer to the actor's blueprint.
    bp: ^actor_blueprint_t,

    // Current flags.
    flags: actor_flags_t,

    //
    // Maintenance
    //

    // The frame the actor was spawned on. This is to prevent it being ticked on the same frame it was spawned, and also to determine its current lifetime.
    spawn_frame: int,

    // The frame the actor is supposed to be automatically removed at. This is to automate removal of short-lived actors like explosions, impact effects, sounds, etc.
    removal_frame: int,

    //
    // Movement & physics
    //

    position:     vec2_t,
    angle:        f32,
    desired_dir:  vec2_t,
    speed:        vec2_t,
    thrust_timer: int,
    sector:       ^sector_t,

    //
    // Behavior
    //

    state:        actor_state_t,
    tick_proc:    actor_proc_t,
    tick_phase:   int,
    tick_timer:   int,

    target:       ^actor_t,
    attack_proc:  attack_proc_t,
    attack_phase: int,
    attack_timer: int,

    owner:        ^actor_t,
    health:       int,
    faction:      faction_t,
}



actors:             [MAX_ACTORS]actor_t
free_actor_indexes: [dynamic]int



spawn_actor :: proc(id: actor_id_t, position: vec2_t, angle: f32) -> ^actor_t
{
    array_index := get_index_from_array_of_free_indexes(&free_actor_indexes)
    actor := &actors[array_index]

    //
    // Identity
    //

    bp := &actor_blueprints[id]
    actor.id = id
    actor.bp = bp

    // Reset our flags and add a flag denoting that we're in play now.
    actor.flags = bp.flags + {.IN_PLAY}

    //
    // Maintenance
    //

    // Set this frame as the frame we spawned. We need this to ensure we don't tick this very frame and also to measure our lifetime, potentially.
    actor.spawn_frame = frame

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



remove_actor :: proc(actor: ^actor_t, delay: int = 0)
{
    if delay > 0
    {
        actor.removal_frame = frame + delay
        return
    }

    actor.flags -= {.IN_PLAY}
    update_actor_sector(actor)
}



tick_actors :: proc()
{
    mobile_actors := make([dynamic]^actor_t, context.temp_allocator)

    for &actor, index in actors
    {
        // If we're out of play and exactly two frames have passed since we got removed, we can now make this array slot available for reuse.
        if !actor_is_in_play(&actor)
        {
            if frame == actor.removal_frame + 2
            {
                put_index_to_array_of_free_indexes(&free_actor_indexes, index)
            }

            continue
        }

        // If we just spawned, we don't tick.
        if actor.spawn_frame == frame
        {
            continue
        }

        // If our target is out of play, we need to remove it.
        if actor.target != nil && !actor_is_in_play(actor.target)
        {
            actor.target = nil
        }

        // The same goes for our owner.
        if actor.owner != nil && !actor_is_in_play(actor.owner)
        {
            actor.owner = nil
        }

        // Is this our hour of doom?
        if actor.removal_frame == frame
        {
            remove_actor(&actor)
            continue
        }

        if actor.tick_proc != nil
        {
            actor.tick_proc(&actor)
        }

        if .MOBILE in actor.flags
        {
            append(&mobile_actors, &actor)
            update_actor_speed(&actor)
        }
    }

    move_actors(mobile_actors)
}



actor_is_in_play :: #force_inline proc(actor: ^actor_t) -> bool
{
    return .IN_PLAY in actor.flags
}



set_actor_state :: proc(actor: ^actor_t, new_state: actor_state_t)
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
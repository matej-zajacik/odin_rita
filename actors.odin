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
Impact_Proc :: proc(proj: ^Actor, target: ^Actor, hit_point: Vector2, hit_normal: Vector2)



Actor_Id :: enum
{
    PLAYER,
    PISTOL_PROJECTILE,
    SPIDERLING,
}



Actor_Flag :: enum
{
    DAMAGEABLE,
    IN_PLAY,
    MOBILE,
    MOVED_THIS_FRAME,
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



actors:             [MAX_ACTORS]Actor
free_actor_indexes: [dynamic]int



init_actors :: proc()
{
    for i in 0..<MAX_ACTORS
    {
        append(&free_actor_indexes, MAX_ACTORS - 1 - i)
    }
}



spawn_actor :: proc(id: Actor_Id, position: Vector2, angle: f32) -> ^Actor
{
    assert(len(free_actor_indexes) > 0)

    array_index := pop(&free_actor_indexes)
    actor := &actors[array_index]

    //
    // Identity
    //

    bp := &blueprints[id]
    actor.id = id
    actor.bp = bp

    // Reset our flags and add a flag denoting that we're in play now.
    actor.flags = bp.flags + {.IN_PLAY}

    //
    // Maintenance
    //

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

    actor.flags -= {.IN_PLAY}
    update_actor_sector(actor)
}



tick_actors :: proc()
{
    mobile_actors := make([dynamic]^Actor, context.temp_allocator)

    for &actor, index in actors
    {
        // If we're out of play and exactly two frames have passed since we got removed, we can now make this array slot available for reuse.
        if !actor_is_in_play(&actor)
        {
            if current_frame == actor.removal_frame + 2
            {
                append(&free_actor_indexes, index)
            }

            continue
        }

        // If we just spawned, we don't tick.
        if actor.spawn_frame == current_frame
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
        if actor.removal_frame == current_frame
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



actor_is_in_play :: #force_inline proc(actor: ^Actor) -> bool
{
    return .IN_PLAY in actor.flags
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
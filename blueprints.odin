package main



Actor_Blueprint :: struct
{
    //
    // Identity
    //

    id:    Actor_Id,
    flags: Actor_Flags,

    //
    // Movement & physics
    //

    speed:        f32,
    acceleration: f32,
    radius:       f32,
    mass:         f32,

    //
    // Behavior
    //

    health:  int,
    faction: Faction,

    // A proc to call when the actor is first constructed.
    make_proc: Actor_Proc,

    // A proc to call when the actor is spawned.
    spawn_proc: Actor_Proc,

    // A proc to call every frame after the actor spawns.
    default_proc: Actor_Proc,

    // A chase routine.
    chase_proc: Actor_Proc,

    // An attack routine.
    attack_proc: Actor_Proc,

    // Sub-attack routines.
    sub_attack_procs: []Attack_Proc,

    // A proc called while the actor is dying.
    death_proc: Actor_Proc,

    // A proc to call when a projectile hits something.
    impact_proc: Impact_Proc,
}



blueprints: [len(Actor_Id)]Actor_Blueprint



init_blueprints :: proc()
{
    load_blueprints()

    // Certain values need further processing.
    // At runtime, we want everything to be in "unit per frame", but JSON data is in "unit per tile" which is more natural for humans.
    for &bp in blueprints
    {
        bp.speed /= FRAME_RATE
        bp.acceleration /= FRAME_RATE
    }
}
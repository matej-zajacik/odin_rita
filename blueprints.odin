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

    health:    int,
    faction:   Faction,
    max_range: f32,

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



Sound_Blueprint :: struct
{
    id:        Sound_Id,
    files:     string,
    flags:     Sound_Flags,
    volume:    f32,
    pitch:     f32,
    min_range: f32,
    max_range: f32,
}



Emitter_Blueprint :: struct
{
    id:                     Emitter_Id,
    flags:                  Emitter_Flags,
    spawn_rate:             [2]f32,
    emission_angle:         f32,
    particle_speed:         [2]f32,
    particle_angular_speed: [2]f32,
    particle_size:          [2]f32,
    particle_drag:          [2]f32,
    particle_color:         [2]Color,
    particle_lifetime:      [2]int,
}



actor_blueprints: [len(Actor_Id)]Actor_Blueprint
sound_blueprints: [len(Sound_Id)]Sound_Blueprint
emitter_blueprints: [len(Emitter_Id)]Emitter_Blueprint



init_blueprints :: proc()
{
    // We load various blueprints here from the `generated.odin` file.
    // These basically just fill up arrays with fixed data.

    load_actor_blueprints()
    // load_sound_blueprints()
    load_emitter_blueprints()

    // Certain values need further processing.
    // At runtime, we want everything to be in "units per frame", but JSON data is in "units per second" which is more natural for humans.
    for &bp in actor_blueprints
    {
        bp.speed /= FRAME_RATE
        bp.acceleration /= FRAME_RATE
    }
}
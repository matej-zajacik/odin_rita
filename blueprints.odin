package main



actor_blueprint_t :: struct
{
    //
    // Identity
    //

    id:    actor_id_t,
    flags: actor_flags_t,

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
    faction:   faction_t,
    max_range: f32,

    // A proc to call when the actor is first constructed.
    make_proc: actor_proc_t,

    // A proc to call when the actor is spawned.
    spawn_proc: actor_proc_t,

    // A proc to call every frame after the actor spawns.
    default_proc: actor_proc_t,

    // A chase routine.
    chase_proc: actor_proc_t,

    // An attack routine.
    attack_proc: actor_proc_t,

    // Sub-attack routines.
    sub_attack_procs: []attack_proc_t,

    // A proc called while the actor is dying.
    death_proc: actor_proc_t,

    // A proc to call when a projectile hits something.
    impact_proc: impact_proc_t,
}



sound_blueprint_t :: struct
{
    id:        sound_id_t,
    files:     string,
    flags:     sound_flags_t,
    volume:    f32,
    pitch:     f32,
    min_range: f32,
    max_range: f32,
}



emitter_blueprint_t :: struct
{
    id:                     emitter_id_t,
    flags:                  emitter_flags_t,
    spawn_rate:             [2]f32,
    emission_angle:         f32,
    particle_speed:         [2]f32,
    particle_angular_speed: [2]f32,
    particle_size:          [2]f32,
    particle_drag:          [2]f32,
    particle_color:         [2]color_t,
    particle_lifetime:      [2]int,
}



actor_blueprints:   [len(actor_id_t)]actor_blueprint_t
sound_blueprints:   [len(sound_id_t)]sound_blueprint_t
emitter_blueprints: [len(emitter_id_t)]emitter_blueprint_t



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
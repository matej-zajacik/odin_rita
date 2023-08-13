package main



load_actor_blueprints :: proc()
{
    actor_blueprints[0] =
    {
        id               = .PLAYER,
        flags            = {.DAMAGEABLE, .MOBILE, .PAWN, .TARGETABLE},
        speed            = 5.000,
        acceleration     = 0.500,
        radius           = 0.500,
        mass             = 1.000,
        health           = 100,
        faction          = .GOOD,
        max_range        = 0.000,
        make_proc        = nil,
        spawn_proc       = nil,
        default_proc     = player_tick,
        chase_proc       = nil,
        attack_proc      = nil,
        sub_attack_procs = nil,
        death_proc       = nil,
        impact_proc      = nil,
    }
    actor_blueprints[1] =
    {
        id               = .PISTOL_PROJECTILE,
        flags            = {.MOBILE, .PROJECTILE},
        speed            = 15.000,
        acceleration     = 0.000,
        radius           = 0.100,
        mass             = 1.000,
        health           = 0,
        faction          = .NEUTRAL,
        max_range        = 8.000,
        make_proc        = nil,
        spawn_proc       = nil,
        default_proc     = nil,
        chase_proc       = nil,
        attack_proc      = nil,
        sub_attack_procs = nil,
        death_proc       = nil,
        impact_proc      = pistol_projectile_impact,
    }
    actor_blueprints[2] =
    {
        id               = .SPIDERLING,
        flags            = {.DAMAGEABLE, .MOBILE, .PAWN, .TARGETABLE},
        speed            = 3.750,
        acceleration     = 0.500,
        radius           = 0.375,
        mass             = 0.500,
        health           = 30,
        faction          = .EVIL,
        max_range        = 0.000,
        make_proc        = nil,
        spawn_proc       = nil,
        default_proc     = spiderling_tick,
        chase_proc       = nil,
        attack_proc      = nil,
        sub_attack_procs = nil,
        death_proc       = nil,
        impact_proc      = nil,
    }
}








load_emitter_blueprints :: proc()
{
    emitter_blueprints[0] =
    {
        id                     = .PISTOL_IMPACT,
        flags                  = {.FADE_OUT},
        spawn_rate             = {300.000, 480.000},
        emission_angle         = 0.500,
        particle_speed         = {0.050, 0.100},
        particle_angular_speed = {0.100, 0.300},
        particle_size          = {0.020, 0.030},
        particle_drag          = {0.950, 0.970},
        particle_color   = {{255, 255, 0, 255}, {255, 128, 0, 255}},
        particle_lifetime      = {30, 45},
    }
    emitter_blueprints[1] =
    {
        id                     = .FLESH_IMPACT,
        flags                  = {.FADE_OUT},
        spawn_rate             = {300.000, 480.000},
        emission_angle         = 0.500,
        particle_speed         = {0.025, 0.075},
        particle_angular_speed = {0.100, 0.300},
        particle_size          = {0.025, 0.050},
        particle_drag          = {0.990, 0.995},
        particle_color   = {{255, 0, 0, 255}, {255, 64, 0, 255}},
        particle_lifetime      = {45, 120},
    }
}

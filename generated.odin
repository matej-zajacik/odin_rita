package main



load_blueprints :: proc()
{
    blueprints[0] =
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
    blueprints[1] =
    {
        id               = .PISTOL_PROJECTILE,
        flags            = {.MOBILE, .PROJECTILE},
        speed            = 12.000,
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
    blueprints[2] =
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
        default_proc     = nil,
        chase_proc       = nil,
        attack_proc      = nil,
        sub_attack_procs = nil,
        death_proc       = nil,
        impact_proc      = nil,
    }
}

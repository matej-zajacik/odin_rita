package main



load_blueprints :: proc()
{
    blueprints[0] =
    {
        id               = .PLAYER,
        flags            = {.DAMAGEABLE, .MOBILE, .PAWN, .TARGETABLE},
        speed            = 5.000,
        acceleration     = 0.500,
        radius           = 32.000,
        mass             = 1.000,
        health           = 100,
        faction          = .GOOD,
        make_proc        = nil,
        spawn_proc       = nil,
        default_proc     = tick_player,
        chase_proc       = nil,
        attack_proc      = nil,
        sub_attack_procs = nil,
        death_proc       = nil,
        impact_proc      = nil,
    }
    blueprints[1] =
    {
        id               = .SPIDERLING,
        flags            = {.DAMAGEABLE, .MOBILE, .PAWN, .TARGETABLE},
        speed            = 3.750,
        acceleration     = 0.500,
        radius           = 24.000,
        mass             = 0.500,
        health           = 30,
        faction          = .EVIL,
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

package main

import "core:log"
import "core:math"



damage_flag_t :: enum
{
    PIERCE_ARMOR,
}

damage_flags_t :: bit_set[damage_flag_t]



damage_actor :: proc(source: ^actor_t, target: ^actor_t, damage: int, flags: damage_flags_t = nil)
{
    if .DAMAGEABLE not_in target.flags
    {
        log.errorf("damage_actor: actor %v cannot take damage", target.id)
        return
    }

    damage := damage

    if target == player
    {
        if game_options.difficulty == .EASY
        {
            mult_int(&damage, DIFFICULTY_DAMAGE_MODIFIER_EASY)
        }
        else if game_options.difficulty == .HARD
        {
            mult_int(&damage, DIFFICULTY_DAMAGE_MODIFIER_HARD)
        }

        if .PIERCE_ARMOR not_in flags
        {
            absorbed := min(mult_int(damage, ARMOR_MITIGATION), player_info.armor)
            player_info.armor -= absorbed
            damage -= absorbed
        }
    }

    target.health -= damage
    log.infof("%v took %v damage; it has %v health left", target.id, damage, target.health)

    if target.health < 1
    {
        kill_actor(target)
    }
}



kill_actor :: proc(actor: ^actor_t)
{
    if actor.bp.death_proc != nil
    {
        set_actor_state(actor, .DEATH)
    }
    else
    {
        remove_actor(actor)
    }
}
package main

import "core:log"
import "core:math"



Damage_Flag :: enum
{
    PIERCE_ARMOR,
}

Damage_Flags :: bit_set[Damage_Flag]



damage_actor :: proc(source: ^Actor, target: ^Actor, damage: int, flags: Damage_Flags = nil)
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
            mitigated := min(mult_int(damage, ARMOR_MITIGATION), player_info.armor)
            player_info.armor -= mitigated
            damage -= mitigated
        }
    }

    target.health -= damage
    log.infof("%v took %v damage; it has %v health left", target.id, damage, target.health)

    if target.health < 1
    {
        kill_actor(target)
    }
}



kill_actor :: proc(actor: ^Actor)
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
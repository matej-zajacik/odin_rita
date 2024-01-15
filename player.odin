package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"
import "core:slice"



ammo_id_t :: enum
{
    NONE,
    BULLET,
    SHELL,
}



gun_id_t :: enum
{
    NONE,
    WRENCH,
    PISTOL,
    SHOTGUN,
    RIFLE,
    GATLING,
}



gun_t :: struct
{
    id:           gun_id_t,
    ammo_id:      ammo_id_t,
    ammo_costs:   [2]int,
    attack_procs: [2]attack_proc_t,

    unlocked:     bool,
}



player_info_t :: struct
{
    armor: int,
    guns:  [gun_id_t]gun_t,
    ammo:  [ammo_id_t]int,

    pending_gun_id: gun_id_t,
    current_gun:    ^gun_t,
}



player:      ^actor_t
player_info: player_info_t



init_guns :: proc()
{
    gun: ^gun_t

    gun                 = &player_info.guns[.WRENCH]
    gun.id              = .WRENCH
    gun.attack_procs[0] = wrench_attack

    gun                 = &player_info.guns[.PISTOL]
    gun.id              = .PISTOL
    gun.ammo_id         = .BULLET
    gun.ammo_costs[0]   = 1
    gun.attack_procs[0] = pistol_attack
}



spawn_player :: proc(position: vec2_t, angle: f32)
{
    player = spawn_actor(.PLAYER, position, angle)
}



player_tick :: proc(player: ^actor_t)
{
    //
    // Angle
    //

    set_actor_angle(player, player.angle - mouse_delta.x * game_options.mouse_sensitivity * math.RAD_PER_DEG)
    // log.infof("player.angle: %v", player.angle)

    //
    // Movement
    //

    desired_dir: vec2_t

    if get_input_action(.MOVE_FORWARD)
    {
        desired_dir.y -= 1
    }
    if get_input_action(.MOVE_BACKWARD)
    {
        desired_dir.y += 1
    }
    if get_input_action(.MOVE_LEFT)
    {
        desired_dir.x -= 1
    }
    if get_input_action(.MOVE_RIGHT)
    {
        desired_dir.x += 1
    }

    if desired_dir != {}
    {
        rotate_vector(&desired_dir, -player.angle + math.PI / 2)
        player.desired_dir = desired_dir
    }
    else
    {
        player.desired_dir = {}
    }

    //
    // Guns
    //

    if get_input_action_down(.SELECT_WRENCH)
    {
        player_info.pending_gun_id = .WRENCH
    }
    else if get_input_action_down(.SELECT_PISTOL)
    {
        player_info.pending_gun_id = .PISTOL
    }
    else if get_input_action_down(.SELECT_SHOTGUN)
    {
        player_info.pending_gun_id = .SHOTGUN
    }

    // Did we request a gun switch?
    if player_info.pending_gun_id > .NONE
    {
        // try_switch_gun(player_info.pending_gun_id)
        switch_gun(player_info.pending_gun_id) // CHEAT
    }

    // Do we want to fire the current gun?
    if get_input_action(.USE_PRIMARY_ATTACK)
    {
        try_use_current_gun(0)
    }
    else if get_input_action(.USE_SECONDARY_ATTACK)
    {
        try_use_current_gun(1)
    }

    if player.attack_proc != nil
    {
        if (!player.attack_proc(player, player.attack_phase))
        {
            player.attack_proc = nil
        }
    }
}



try_switch_gun :: proc(id: gun_id_t) -> bool
{
    log.infof("try_switch_gun: trying to switch to gun %v", id)

    // If we're in the middle of an attack, we don't switch.
    if actor_is_attacking(player)
    {
        log.infof("try_switch_gun: can't switch because we're currently attacking")
        return false
    }

    target_gun := &player_info.guns[id]

    // If we don't have the gun... we ain't Copperfields.
    if !target_gun.unlocked
    {
        log.infof("try_switch_gun: can't switch because we don't have that gun")
        player_info.pending_gun_id = .NONE
        return false
    }

    // If we already have the weapon, nothing to do here.
    if player_info.current_gun == target_gun
    {
        log.infof("try_switch_gun: can't switch because we already have that gun equipped")
        player_info.pending_gun_id = .NONE
        return false
    }

    switch_gun(id)
    return true
}



switch_gun :: proc(id: gun_id_t)
{
    player_info.current_gun = &player_info.guns[id]
    player_info.pending_gun_id = .NONE
    log.infof("switch_gun: player switches to gun %v", id)
}



try_use_current_gun :: proc(attack_index: int) -> bool
{
    using player_info

    if current_gun == nil do return false

    if actor_is_attacking(player)
    {
        log.infof("try_use_current_gun: cannot use gun %v, as we are already attacking", current_gun.id)
        return false
    }

    gun_id    := current_gun.id
    ammo_id   := current_gun.ammo_id
    ammo_cost := current_gun.ammo_costs[attack_index]

    if !cheats[.UNLIMITED_AMMO] && ammo[ammo_id] < ammo_cost
    {
        log.infof("try_use_current_gun: gun %v requires %v %v ammo to fire, but we only have %v ammo", gun_id, ammo_cost, ammo_id, ammo[ammo_id])
        return false
    }

    use_current_gun(attack_index)
    return true
}



use_current_gun :: proc(attack_index: int)
{
    using player_info

    ammo[current_gun.ammo_id] -= current_gun.ammo_costs[attack_index]
    start_attack(player, current_gun.attack_procs[attack_index])
}



wrench_attack :: proc(player: ^actor_t, phase: int) -> bool
{
    player.attack_timer -= 1
    if player.attack_timer > 0 do return true

    switch phase
    {
        case 0:
            log.infof("wrench_attack: start")
            advance_attack(player, 15)

        case 1:
            log.infof("wrench_attack: damage point")
            target := get_closest_target_for_melee_attack(player, 1.5, math.to_radians_f32(45))
            if target != nil
            {
                log.infof("damage this dude %v", target.id)
                damage_actor(player, target, 10)
            }
            advance_attack(player, 15)

        case 2:
            log.infof("wrench_attack: end")
            return false
    }

    return true
}



pistol_attack :: proc(player: ^actor_t, phase: int) -> bool
{
    player.attack_timer -= 1
    if player.attack_timer > 0 do return true

    switch phase
    {
        case 0:
            spawn_projectile(player, .PISTOL_PROJECTILE, player.position + get_actor_forward(player) * 0.6, player.angle)
            advance_attack(player, 30)

        case 1:
            return false
    }

    return true
}



pistol_projectile_impact :: proc(proj: ^actor_t, target: ^actor_t, hit_point: vec2_t, hit_normal: vec2_t)
{
    if target == nil
    {
        em := spawn_emitter(.PISTOL_IMPACT, hit_point, vector_to_angle(hit_normal))
        remove_emitter(em, 1)
    }
    else
    {
        emitter_id := .MECHANICAL in target.flags ? emitter_id_t.PISTOL_IMPACT : emitter_id_t.FLESH_IMPACT
        em := spawn_emitter(emitter_id, hit_point, vector_to_angle(hit_normal))
        remove_emitter(em, 1)

        damage_actor(proj, target, 10)
    }
}
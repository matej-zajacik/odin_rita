package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"
import "core:slice"



Ammo_Id :: enum
{
    NONE,
    BULLET,
    SHELL,
}



Gun_Id :: enum
{
    NONE,
    WRENCH,
    PISTOL,
    SHOTGUN,
    RIFLE,
    GATLING,
}



Gun :: struct
{
    id:           Gun_Id,
    ammo_id:      Ammo_Id,
    ammo_costs:   [2]int,
    attack_procs: [2]Attack_Proc,

    unlocked:     bool,
}



Player_Info :: struct
{
    armor: int,
    guns:  [Gun_Id]Gun,
    ammo:  [Ammo_Id]int,

    pending_gun_id: Gun_Id,
    current_gun:    ^Gun,
}



player:      ^Actor
player_info: Player_Info



init_guns :: proc()
{
    gun: ^Gun

    gun                 = &player_info.guns[.WRENCH]
    gun.id              = .WRENCH
    gun.attack_procs[0] = wrench_attack

    gun                 = &player_info.guns[.PISTOL]
    gun.id              = .PISTOL
    gun.ammo_id         = .BULLET
    gun.ammo_costs[0]   = 1
    gun.attack_procs[0] = pistol_attack
}



spawn_player :: proc(position: Vector2, angle: f32)
{
    player = spawn_actor(.PLAYER, position, angle)
}



player_tick :: proc(player: ^Actor)
{
    //
    // Angle
    //

    set_actor_angle(player, player.angle - mouse_delta.x * game_options.mouse_sensitivity * math.RAD_PER_DEG)
    // log.infof("player.angle: %v", player.angle)

    //
    // Movement
    //

    desired_dir: Vector2

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



try_switch_gun :: proc(id: Gun_Id) -> bool
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



switch_gun :: proc(id: Gun_Id)
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



wrench_attack :: proc(player: ^Actor, phase: int) -> bool
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



pistol_attack :: proc(player: ^Actor, phase: int) -> bool
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



pistol_projectile_impact :: proc(proj: ^Actor, target: ^Actor, hit_point: Vector2, hit_normal: Vector2)
{
    if target == nil
    {
        em := spawn_emitter(.PISTOL_IMPACT, hit_point, vector_to_angle(hit_normal))
        remove_emitter(em, 1)
    }
    else
    {
        emitter_id := .MECHANICAL in target.flags ? Emitter_Id.PISTOL_IMPACT : Emitter_Id.FLESH_IMPACT
        em := spawn_emitter(emitter_id, hit_point, vector_to_angle(hit_normal))
        remove_emitter(em, 1)

        damage_actor(proj, target, 10)
    }
}
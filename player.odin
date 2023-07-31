package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:log"
import "core:slice"
import "shared:queedo"



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



spawn_player :: proc(position: Vector2, angle: f32)
{
    player = spawn_actor(.PLAYER, position, angle)

    //
    // Guns
    //

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



tick_player :: proc(player: ^Actor)
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

    if queedo.get_input_action(int(Input_Action.MOVE_FORWARD))
    {
        desired_dir.y -= 1
    }
    if queedo.get_input_action(int(Input_Action.MOVE_BACKWARD))
    {
        desired_dir.y += 1
    }
    if queedo.get_input_action(int(Input_Action.MOVE_LEFT))
    {
        desired_dir.x -= 1
    }
    if queedo.get_input_action(int(Input_Action.MOVE_RIGHT))
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

    if queedo.get_input_action_down(int(Input_Action.SELECT_GUN_WRENCH))
    {
        player_info.pending_gun_id = .WRENCH
    }
    else if queedo.get_input_action_down(int(Input_Action.SELECT_GUN_PISTOL))
    {
        player_info.pending_gun_id = .PISTOL
    }
    else if queedo.get_input_action_down(int(Input_Action.SELECT_GUN_SHOTGUN))
    {
        player_info.pending_gun_id = .SHOTGUN
    }

    // Did we request a gun switch?
    if player_info.pending_gun_id > .NONE
    {
        switch_gun(player_info.pending_gun_id)
    }

    // Do we want to fire the current gun?
    if queedo.get_input_action_down(int(Input_Action.USE_PRIMARY_ATTACK))
    {
        try_use_current_gun(0)
    }
    else if queedo.get_input_action_down(int(Input_Action.USE_SECONDARY_ATTACK))
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
    log.infof("switch_gun: trying to switch to gun %v", id)

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
        return false
    }

    // If we already have the weapon, nothing to do here.
    if player_info.current_gun == target_gun
    {
        log.infof("try_switch_gun: can't switch because we already have that gun equipped")
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

    if ammo[ammo_id] < ammo_cost
    {
        log.infof("try_use_current_gun: gun %v requires %v %v ammo to fire, but we only have %v ammo", current_gun.id, ammo_cost, current_gun.ammo_id, ammo[ammo_id])
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
            target := get_closest_target_for_melee_attack(player, 80, 45)
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
    return true
}
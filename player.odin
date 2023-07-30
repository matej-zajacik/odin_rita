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
    ammo_cost:    [2]int,
    attack_procs: [2]Attack_Proc,
}



Player_Info :: struct
{
    armor: int,
    guns:  [Gun_Id]Gun,
    ammo:  [Gun_Id]int,

    pending_gun_id: Gun_Id,
    current_gun:    ^Gun,
}



player: ^Actor
player_info: Player_Info



spawn_player :: proc(position: Vector2, angle: f32)
{
    player = spawn_actor(.PLAYER, position, angle)

    //
    // Guns
    //

    gun: ^Gun

    gun = &player_info.guns[.WRENCH]
    gun.id = .WRENCH
    gun.attack_procs[0] = wrench_attack

    gun = &player_info.guns[.PISTOL]
    gun.id = .PISTOL
    gun.ammo_id = .BULLET
    gun.ammo_cost[0] = 1
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
        rotate_vector2(&desired_dir, -player.angle + math.PI / 2)
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
        use_current_gun(0)
    }
    else if queedo.get_input_action_down(int(Input_Action.USE_SECONDARY_ATTACK))
    {
        use_current_gun(1)
    }

    if player.attack_proc != nil
    {
        if (!player.attack_proc(player, player.attack_phase))
        {
            player.attack_proc = nil
        }
    }
}



switch_gun :: proc(id: Gun_Id)
{
    log.infof("player tries to switch to gun %v", id)

    // If we're in the middle of an attack, we don't switch.
    if actor_is_attacking(player)
    {
        log.infof("can't switch because we're currently attacking")
    }

    target_gun := &player_info.guns[id]

    // If we already have the weapon, nothing to do here.
    if player_info.current_gun == target_gun
    {
        log.infof("can't switch because we already have the gun equipped")
    }

    player_info.current_gun = target_gun
    player_info.pending_gun_id = .NONE

    log.infof("player switches to gun %v", id)
}



use_current_gun :: proc(attack_index: int)
{
    using player_info

    if current_gun == nil do return

    if actor_is_attacking(player)
    {
        log.infof("cannot use gun %v, as we are already attacking", current_gun.id)
        return
    }

    gun_id := current_gun.id
    ammo_id := current_gun.ammo_id

    if ammo[gun_id] < current_gun.ammo_cost[attack_index]
    {
        log.infof("gun %v requires %v %v ammo to fire, but we only have %v ammo", current_gun.id, current_gun.ammo_id, current_gun.ammo_cost[attack_index], ammo[gun_id])
        return
    }

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
package main

import "core:log"
import "core:math"
import "core:math/linalg"
import "core:slice"



actor_is_attacking :: proc(actor: ^Actor) -> bool
{
    return actor.attack_proc != nil
}



start_attack :: proc(actor: ^Actor, attack_proc: Attack_Proc)
{
    actor.attack_proc = attack_proc
    actor.attack_phase = 0
    actor.attack_timer = 0
}



advance_attack :: proc(actor: ^Actor, delay: int, phase_delta: int = 1)
{
    actor.attack_timer = delay
    actor.attack_phase += phase_delta
}



get_closest_target_for_melee_attack :: proc(source: ^Actor, max_distance: f32, max_angle: f32) -> ^Actor
{
    targets := get_attack_targets(source, source.sector, source.position, source.angle, max_distance, max_angle)
    sort_actors_by_distance(source.position, targets)
    return len(targets) > 0 ? targets[0] : nil
}



get_attack_targets :: proc(ignored_actor: ^Actor, sector: ^Sector, position: Vector2, forward_angle: f32, max_distance: f32, max_angle: f32) -> []^Actor
{
    targets := make([dynamic]^Actor, context.temp_allocator)

    for target in sector.actors
    {
        if target == ignored_actor
        {
            log.infof("get_attack_targets: %v is ignored actor", target.id)
            continue
        }

        if .DAMAGEABLE not_in target.flags
        {
            log.infof("get_attack_targets: %v is not damageable", target.id)
            continue
        }

        dist := linalg.distance(position, target.position)
        log.infof("get_attack_targets: dist to %v is %v", target.id, dist)

        if dist > max_distance
        {
            log.infof("get_attack_targets: %v is %v far away which is above max distance of %v", target.id, dist, max_distance)
            continue
        }

        angle := get_angle_between_angle_and_vector(forward_angle, target.position - position)
        log.infof("get_attack_targets: angle to %v is %v", target.id, angle)

        if angle > max_angle
        {
            log.infof("get_attack_targets: angle between forward angle %v and %v is %v which is above max angle of %v", forward_angle, target.id, angle, max_angle)
            continue
        }

        log.infof("get_attack_targets: we have a valid target %v", target.id)
        append(&targets, target)
    }

    return targets[:]
}



@(private="file")
sort_actors_by_distance_position: Vector2

sort_actors_by_distance :: proc(position: Vector2, arr: []^Actor)
{
    sort_actors_by_distance_position = position

    slice.sort_by(arr, proc(a, b: ^Actor) -> bool
    {
        return linalg.distance(sort_actors_by_distance_position, a.position) < linalg.distance(sort_actors_by_distance_position, b.position)
    })
}
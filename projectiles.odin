package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:os"
import "core:runtime"
import "core:strings"
import "vendor:raylib"



spawn_projectile :: proc(source: ^Actor, id: Actor_Id, position: Vector2, angle: f32) -> ^Actor
{
    assert(.PROJECTILE in actor_blueprints[id].flags)

    proj := spawn_actor(id, position, angle)

    proj.desired_dir = angle_to_vector(angle)
    proj.speed = proj.desired_dir * proj.bp.speed
    proj.faction = source != nil ? source.faction : .NEUTRAL
    proj.owner = source

    remove_actor(proj, int(proj.bp.max_range / (proj.bp.speed * FRAME_RATE) * FRAME_RATE))

    return proj
}



projectile_did_hit_actor :: proc(proj: ^Actor, target: ^Actor, hit_point: Vector2, hit_normal: Vector2)
{
    draw_debug_line(false, hit_point, hit_point + hit_normal, ONE_PX_THICKNESS_SCALE, raylib.GREEN, 60)

    if proj.bp.impact_proc != nil
    {
        proj.bp.impact_proc(proj, target, hit_point, hit_normal)
    }

    remove_actor(proj)
}
package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:os"
import "core:runtime"
import "core:strings"
import "vendor:raylib"
import "shared:queedo"



spawn_projectile :: proc(source: ^Actor, id: Actor_Id, position: Vector2, angle: f32) -> ^Actor
{
    assert(.PROJECTILE in blueprints[id].flags)

    proj := spawn_actor(id, position, angle)

    proj.desired_dir = angle_to_vector(angle)
    proj.speed = proj.desired_dir * proj.bp.speed
    proj.faction = source != nil ? source.faction : .NEUTRAL
    proj.owner = source

    remove_actor(proj, int(proj.bp.max_range / (proj.bp.speed * FRAME_RATE) * FRAME_RATE))

    return proj
}



projectile_did_hit_actor :: proc(proj: ^Actor, target: ^Actor, point: Vector2, normal: Vector2)
{
    queedo.draw_debug_line(point, point + normal, ONE_PX_THICKNESS_SCALE, raylib.GREEN, 60)

    if proj.bp.impact_proc != nil
    {
        proj.bp.impact_proc(proj, target, point, normal)
    }

    remove_actor(proj)
}
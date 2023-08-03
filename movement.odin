package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:slice"
import "vendor:raylib"
import "shared:queedo"



// Should be called when the actor's position is supposed to suddenly change (when spawned, teleported, and such).
// Standard movement code doesn't call this.
set_actor_position :: proc(actor: ^Actor, position: Vector2)
{
    actor.position = position
    update_actor_sector(actor)
}



set_actor_angle :: proc(actor: ^Actor, angle: f32)
{
    actor.angle = get_wrapped_angle(angle)
}



get_actor_forward :: proc(actor: ^Actor) -> Vector2
{
    return angle_to_vector(actor.angle)
}



move_actors :: proc(mobile_actors: [dynamic]^Actor)
{
    for actor in mobile_actors
    {
        if actor.speed == {} do continue

        to_move := actor.speed
        iterations := 0

        for to_move != {}
        {
            iterations += 1
            step := clamp_vector_length(to_move, actor.bp.radius - 0.001)
            if !move_actor(actor, step) do break;
            to_move -= step
        }

        // log.infof("move_actors: %v did %v iterations", actor.id, iterations)
    }

    //
    // Update sectors
    //

    for actor in mobile_actors
    {
        if .MOVED_THIS_FRAME not_in actor.flags do continue

        update_actor_sector(actor)
        actor.flags -= {.MOVED_THIS_FRAME}
    }
}



move_actor :: proc(actor: ^Actor, delta: Vector2) -> bool
{
    actor.position += delta
    actor.flags += {.MOVED_THIS_FRAME}

    //
    // Actor vs actors
    //

    for other in actor.sector.actors
    {
        if other == actor do continue

        other_to_actor_vec := actor.position - other.position
        dist := linalg.length(other_to_actor_vec)
        radii := actor.bp.radius + other.bp.radius

        if dist < radii
        {
            dir := linalg.normalize(other_to_actor_vec)
            // move_actor(actor, dir * (radii - dist))
            actor.position += dir * (radii - dist)
        }
    }

    //
    // Actor vs geometry
    //

    c := Circle{actor.position.x, actor.position.y, actor.bp.radius}

    for rect in actor.sector.geo_colliders
    {
        if hit, dep := test_circle_vs_rect(c, rect^); hit
        {
            // move_actor(actor, dep)
            actor.position += dep

            if dep.x != 0.0 do actor.speed.x = 0.0
            if dep.y != 0.0 do actor.speed.y = 0.0
        }
    }

    return true
}



update_actor_sector :: proc(actor: ^Actor)
{
    // log.infof("update_actor_sector: actor %v", actor.id)

    sector: ^Sector

    if .IN_PLAY in actor.flags
    {
        // Find out which sector we belong to now.
        x, y := world_position_to_tile_position(actor.position)
        sector = get_sector(x, y);
        // log.infof("sector: %v (%v,%v)", sector, x, y)
    }

    // If it's the same sector that we already have, we don't need to do anything.
    if sector == actor.sector do return

    if actor.sector != nil
    {
        // If we already have a sector, we remove ourselves from it and its neighbors.
        unordered_remove_by_value(&actor.sector.actors, actor)

        for neighbor_sector in actor.sector.neighbors
        {
            unordered_remove_by_value(&neighbor_sector.actors, actor)
        }
    }

    if sector != nil
    {
        // log.infof("update_actor_sector: actor %v added to sector %v,%v", actor.id, sector.debug_tile_pos_x, sector.debug_tile_pos_y)

        // If we are ordered to set a sector (because we may be order to set nil), we add ourselves to it and its neighbors.
        append(&sector.actors, actor)

        for neighbor_sector in sector.neighbors
        {
            // log.infof("update_actor_sector: actor %v added to neighbor sector %v,%v", actor.id, neighbor_sector.debug_tile_pos_x, neighbor_sector.debug_tile_pos_y)
            append(&neighbor_sector.actors, actor)
        }
    }

    // And we set the new sector as our current sector.
    actor.sector = sector
}



// Calculates a new speed based on the actor's desired direction of movement.
update_actor_speed :: proc(actor: ^Actor)
{
    dir := actor.desired_dir

    // The rate of acceleration towards the target speed varies based on some conditions.
    acceleration_mult: f32
    target_speed:      Vector2

    speed := actor.speed

    if dir != {}
    {
        // If we have some direction given, let's set that as our new target speed.
        target_speed = dir * actor.bp.speed
        acceleration_mult = 1.0
    }
    else
    {
        // If no direction is given...

        // ...and we ain't even moving, there's nothing to do here.
        if speed == {} do return

        // ...then we want to stop, but a little slower.
        target_speed = {}
        acceleration_mult = 0.5
    }

    // If our current speed is higher than our max speed, likely due to getting "thrusted" previously, we slow down gradually until we're within our natural speed limits.
    if linalg.length(speed) > actor.bp.speed
    {
        speed *= OVERSPEED_DRAG
    }

    // If we have recently been thrusted, our ability to steer is significantly limited, but gradually comes back towards the end of the effect.
    if actor.thrust_timer > 0
    {
        acceleration_mult *= math.pow(1.0 - f32(actor.thrust_timer) / THRUST_DURATION, 3.0)
        actor.thrust_timer -= 1
    }

    // Now finally compute the new speed.
    actor.speed = move_towards(speed, target_speed, actor.bp.acceleration * acceleration_mult)
}



test_circle_vs_rect :: proc(c: Circle, r: Rect) -> (hit: bool, depenetration: Vector2)
{
    // Find the closest point to the rectangle.
    closest_x := math.clamp(c.x, get_rect_left(r), get_rect_right(r))
    closest_y := math.clamp(c.y, get_rect_top(r), get_rect_bottom(r))

    if closest_x == c.x && closest_y == c.y
    {
        log.errorf("test_circle_vs_rect: %v tunneled through %v", c, r)
    }

    // Calc the distance between the circle's center and the closest point.
    dist_x := c.x - closest_x
    dist_y := c.y - closest_y
    dist_sq := dist_x * dist_x + dist_y * dist_y

    // If the distance is less than the circle's radius, we have an intersection.
    hit = dist_sq < c.r * c.r

    if hit
    {
        if dist_x != 0.0
        {
            depenetration.x = (c.r - math.abs(dist_x)) * math.sign(dist_x)
        }

        if dist_y != 0.0
        {
            depenetration.y = (c.r - math.abs(dist_y)) * math.sign(dist_y)
        }
    }

    return
}
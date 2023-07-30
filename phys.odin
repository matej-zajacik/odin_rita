package main

import "core:math"
import "vendor:raylib"
import "core:log"



rects_intersect :: proc(a: Rect, b: Rect) -> bool
{
    return get_rect_left(a) < get_rect_right(b) &&
           get_rect_left(b) < get_rect_right(a) &&
           get_rect_top(a) < get_rect_bottom(b) &&
           get_rect_top(b) < get_rect_bottom(a)
}



circle_intersects_rect :: proc(c: Circle, r: Rect) -> (hit: bool, depenetration: Vector2)
{
    // log.infof("c: %v", c)

    // Find the closest point to the circle within the rectangle.
    closest_x := math.clamp(c.x, get_rect_left(r), get_rect_right(r))
    closest_y := math.clamp(c.y, get_rect_top(r), get_rect_bottom(r))

    // log.infof("closest: %v,%v", closest_x, closest_y)

    // Calc the distance between the circle's center and the closest point.
    dist_x := c.x - closest_x
    dist_y := c.y - closest_y

    // If the distance is less than the circle's radius, we have an intersection.
    dist_sq := dist_x * dist_x + dist_y * dist_y

    // log.infof("dist_sq / c.r_sq: %v / %v", dist_sq, c.r * c.r)

    hit = dist_sq < c.r * c.r

    if dist_x != 0.0
    {
        depenetration.x = (c.r - math.abs(dist_x)) * math.sign(dist_x)
    }

    if dist_y != 0.0
    {
        depenetration.y = (c.r - math.abs(dist_y)) * math.sign(dist_y)
    }

    if hit
    {
        // log.infof("dist: %v,%v", dist_x, dist_y)
        // log.infof("dep: %v", depenetration)
    }

    return
}



// circle_intersects_rect :: proc(c: Circle, r: Rect) -> bool
// {
//     dist_x := math.abs(c.x - r.x)
//     dist_y := math.abs(c.y - r.y)

//     if dist_x > r.width * 0.5 + c.r do return false
//     if dist_y > r.height * 0.5 + c.r do return false

//     if dist_x <= r.width * 0.5 do return true
//     if dist_y <= r.height * 0.5 do return true

//     x := dist_x - r.width * 0.5
//     y := dist_y - r.height * 0.5

//     corner_dist := x * x + y * y

//     return corner_dist <= c.r * c.r
// }
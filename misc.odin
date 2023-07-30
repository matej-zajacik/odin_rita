package main

import "core:encoding/json"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:os"
import "core:slice"
import "core:strings"



Circle :: struct
{
    x: f32,
    y: f32,
    r: f32,
}



get_rect_left :: #force_inline proc(r: Rect) -> f32
{
    return r.x
}



get_rect_right :: #force_inline proc(r: Rect) -> f32
{
    return r.x + r.width
}



get_rect_top :: #force_inline proc(r: Rect) -> f32
{
    return r.y
}



get_rect_bottom :: #force_inline proc(r: Rect) -> f32
{
    return r.y + r.height
}



f32_move_towards :: proc(src: f32, dst: f32, max_delta: f32) -> f32
{
    if src < dst
    {
        return min(src + max_delta, dst)
    }
    else if src > dst
    {
        return max(src - max_delta, dst)
    }
    else
    {
        return dst
    }
}



vector2_move_towards :: proc(src: Vector2, dst: Vector2, max_delta: f32) -> Vector2
{
    // Get the vector to the target point.
    v := dst - src

    // Get its length.
    len := linalg.length(v)

    // If we're closer than the maximum distance we can go, we either arrive at or we're already at the target point.
    if len <= max_delta || len == 0.0
    {
        return dst
    }

    // If not, then we first divide the vector by the length to get the normalized version.
    v /= len

    // Then we multiply that by the maximum distance we can go.
    v *= max_delta

    // And finally add that to our starting point, effectively moving towards the target point by the given max distance.
    v += src

    return v
}



move_towards :: proc
{
    f32_move_towards,
    vector2_move_towards,
}



rotate_vector2 :: proc(v: ^Vector2, angle: f32)
{
    sin := math.sin(angle)
    cos := math.cos(angle)
    x := v.x * cos - v.y * sin
    y := v.x * sin + v.y * cos
    v.x = x
    v.y = y
}



get_rotated_vector :: proc(v: Vector2, angle: f32) -> Vector2
{
    angle := math.to_radians(angle)
    sin := math.sin(angle)
    cos := math.cos(angle)
    return {v.x * cos - v.y * sin, v.x * sin + v.y * cos}
}



vector_to_angle :: proc(v: Vector2) -> f32
{
    return get_wrapped_angle(math.atan2(v.y, v.x))
}



angle_to_vector :: proc(angle: f32) -> Vector2
{
    return {math.cos(angle), -math.sin(angle)}
}



get_angle_between_angle_and_vector :: proc(angle: f32, vector: Vector2) -> f32
{
    // log.infof("get_angle_between_angle_and_vector: %v vs %v", angle, vector_to_angle(vector))
    // return math.abs(angle - vector_to_angle(vector))
    return math.angle_diff(angle, vector_to_angle(vector))
}



get_wrapped_angle :: proc(angle: f32) -> f32
{
    if angle > math.TAU
    {
        return angle - math.TAU
    }
    else if angle < 0
    {
        return angle + math.TAU
    }

    return angle
}



// get_angle_between_actor_forward_and_other_actor :: proc(a: ^Actor, b: ^Actor) -> f32
// {
//     b_angle := get_vector_angle(b.position - a.position)
//     return math.abs(a.angle - b_angle)
// }



unordered_remove_by_value :: proc(array: ^$D/[dynamic]$T, value: T)
{
    if index, found := slice.linear_search(array[:], value); found
    {
        unordered_remove(array, index)
    }
}



world_position_to_tile_position :: proc(world_position: Vector2) -> (x, y: int)
{
    x = int(world_position.x / (SECTOR_SIZE * TILE_SIZE))
    y = int(world_position.y / (SECTOR_SIZE * TILE_SIZE))
    return
}



mult_int_val :: proc(val: int, mult: f32) -> int
{
    return int(f32(val) * mult)
}



mult_int_ptr :: proc(val: ^int, mult: f32)
{
    val^ = int(f32(val^) * mult)
}


mult_int :: proc
{
    mult_int_val,
    mult_int_ptr,
}
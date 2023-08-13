package main

import "core:encoding/json"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:slice"
import "core:strings"
import "vendor:raylib"



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



move_towards_f32 :: proc(src: f32, dst: f32, max_delta: f32) -> f32
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



move_towards_vector2 :: proc(src: Vector2, dst: Vector2, max_delta: f32) -> Vector2
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
    move_towards_f32,
    move_towards_vector2,
}



clamp_vector_length :: proc(v: Vector2, max_length: f32) -> Vector2
{
    length := linalg.length(v)

    if length <= max_length
    {
        return v
    }

    return v * (max_length / length)
}



rotate_vector :: proc(v: ^Vector2, angle: f32)
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
    sin := math.sin(angle)
    cos := math.cos(angle)
    return {v.x * cos - v.y * sin, v.x * sin + v.y * cos}
}



vector_to_angle :: proc(v: Vector2) -> f32
{
    return get_wrapped_angle(math.atan2(-v.y, v.x))
}



angle_to_vector :: proc(angle: f32) -> Vector2
{
    return {math.cos(angle), -math.sin(angle)}
}



get_angle_between_angle_and_vector :: proc(angle: f32, vector: Vector2) -> f32
{
    // log.infof("get_angle_between_angle_and_vector: %v vs %v", angle, vector_to_angle(vector))
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



rects_intersect :: proc(a: Rect, b: Rect) -> bool
{
    return get_rect_left(a) < get_rect_right(b) &&
           get_rect_left(b) < get_rect_right(a) &&
           get_rect_top(a) < get_rect_bottom(b) &&
           get_rect_top(b) < get_rect_bottom(a)
}



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



draw_circle :: proc(center: Vector2, radius: f32, thick: f32, color: Color, segments: int = 16)
{
    step_angle := math.TAU / f32(segments)
    start := center + {math.cos(step_angle * f32(0)), math.sin(step_angle * f32(0))} * radius

    for i in 1..<segments + 1
    {
        end := center + {math.cos(step_angle * f32(i)), math.sin(step_angle * f32(i))} * radius
        raylib.DrawLineEx(start, end, thick, color)
        start = end
    }
}



get_random_byte :: proc(min, max: byte) -> byte
{
    return byte(get_random_int(int(min), int(max)))
}



get_random_int :: proc(min, max: int) -> int
{
    temp_min := math.min(min, max)
    temp_max := math.max(min, max)
    range := math.abs(temp_max - temp_min) + 1
    return temp_min + rand.int_max(range)
}



get_random_f32 :: proc(min, max: f32) -> f32
{
    return rand.float32_range(min, max)
}



init_array_of_free_indexes :: proc(arr: ^[dynamic]int, count: int)
{
    for i in 0..<count
    {
        append(arr, count - 1 - i)
    }
}



get_index_from_array_of_free_indexes :: proc(arr: ^[dynamic]int) -> int
{
    if len(arr) == 0
    {
        log.panic("get_index_from_array_of_free_indexes: array has no entries left")
    }

    return pop(arr)
}



put_index_to_array_of_free_indexes :: proc(arr: ^[dynamic]int, index: int)
{
    append(arr, index)
}
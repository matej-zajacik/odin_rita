package main

import "core:fmt"
import "core:log"
import "core:math"
import "vendor:raylib"



particle_t :: struct
{
    position:      vec2_t,
    rect:          rect_t,
    origin:        vec2_t,
    speed:         vec2_t,
    angle:         f32,
    angular_speed: f32,
    size:          f32,
    drag:          f32,
    color:         color_t,
    timer:         int,

    lifetime:      int,
    initial_alpha: byte,
}



emitter_id_t :: enum
{
    PISTOL_IMPACT,
    FLESH_IMPACT,
}



emitter_flag_t :: enum
{
    BEING_REMOVED,
    ENABLED,
    FADE_OUT,
    IN_PLAY,
}

emitter_flags_t :: bit_set[emitter_flag_t]



emitter_t :: struct
{
    bp:                 ^emitter_blueprint_t,
    flags:              emitter_flags_t,
    spawn_frame:        int,
    removal_frame:      int,
    position:           vec2_t,
    angle:              f32,
    spawn_rate:         f32,
    particles_to_spawn: f32,
    particles:          [dynamic]particle_t,
}



emitters:             [MAX_EMITTERS]emitter_t
free_emitter_indexes: [dynamic]int



spawn_emitter :: proc(id: emitter_id_t, position: vec2_t, angle: f32) -> ^emitter_t
{
    array_index := get_index_from_array_of_free_indexes(&free_emitter_indexes)
    emitter := &emitters[array_index]

    bp := &emitter_blueprints[id]
    emitter.bp = bp
    emitter.flags = bp.flags + {.ENABLED, .IN_PLAY}
    emitter.spawn_frame = frame
    emitter.removal_frame = -1
    emitter.position = position
    emitter.angle = angle
    emitter.spawn_rate = get_random_f32(bp.spawn_rate[0], bp.spawn_rate[1])
    emitter.particles_to_spawn = 0
    clear(&emitter.particles)

    return emitter
}



remove_emitter :: proc(emitter: ^emitter_t, delay: int = 0)
{
    emitter.removal_frame = frame + delay
}



remove_emitter_immediately :: proc(emitter: ^emitter_t)
{
    emitter.flags -= {.IN_PLAY}
}



tick_emitters :: proc()
{
    count := 0

    for &emitter in emitters
    {
        if .IN_PLAY not_in emitter.flags do continue

        if emitter.spawn_frame == frame do continue

        count += 1

        bp := emitter.bp

        if .ENABLED in emitter.flags
        {
            emitter.particles_to_spawn += emitter.spawn_rate * FIXED_DT

            particles_to_spawn := int(emitter.particles_to_spawn)

            for particles_to_spawn > 0
            {
                particles_to_spawn -= 1
                emitter.particles_to_spawn -= 1
                spawn_particle(&emitter)
            }
        }

        i := 0
        c := len(emitter.particles)
        for i < c
        {
            p := &emitter.particles[i]

            tick_particle(p, bp.flags)

            if p.timer == 0
            {
                unordered_remove(&emitter.particles, i)
                i -= 1
                c -= 1
            }

            i += 1
        }

        if emitter.removal_frame == frame
        {
            emitter.flags -= {.ENABLED}
            emitter.flags += {.BEING_REMOVED}
        }

        if .BEING_REMOVED in emitter.flags && len(emitter.particles) == 0
        {
            emitter.flags -= {.IN_PLAY}
        }
    }

    draw_debug_text(true, fmt.aprintf("emitters: %v", count), raylib.WHITE)

    spawn_particle :: #force_inline proc(emitter: ^emitter_t)
    {
        bp := emitter.bp

        temp: particle_t = ---
        append(&emitter.particles, temp)

        p := &emitter.particles[len(emitter.particles) - 1]
        p.position = emitter.position
        emission_angle := get_random_f32(-bp.emission_angle, bp.emission_angle) * 0.5
        p.speed = angle_to_vector(emitter.angle + emission_angle) * get_random_f32(bp.particle_speed[0], bp.particle_speed[1])
        p.angular_speed = get_random_f32(bp.particle_angular_speed[0], bp.particle_angular_speed[1])
        p.size = get_random_f32(bp.particle_size[0], bp.particle_size[1])
        p.rect.width = p.size * 2
        p.rect.height = p.size * 2
        p.origin = {p.size, p.size}
        p.lifetime = math.max(get_random_int(bp.particle_lifetime[0], bp.particle_lifetime[1]), 1)
        p.timer = p.lifetime
        p.drag = 0.95
        r := get_random_byte(bp.particle_color[0].r, bp.particle_color[1].r)
        g := get_random_byte(bp.particle_color[0].g, bp.particle_color[1].g)
        b := get_random_byte(bp.particle_color[0].b, bp.particle_color[1].b)
        a := get_random_byte(bp.particle_color[0].a, bp.particle_color[1].a)
        // log.info("pengo3")
        p.color = {r, g, b, a}
        p.initial_alpha = a
    }

    tick_particle :: #force_inline proc(p: ^particle_t, flags: emitter_flags_t) -> bool
    {
        p.timer -= 1
        p.position += p.speed
        p.rect.x = p.position.x
        p.rect.y = p.position.y
        p.speed *= p.drag
        p.angle += p.angular_speed

        if .FADE_OUT in flags
        {
            lifetime_point := f32(p.timer) / f32(p.lifetime)
            p.color.a = byte(f32(p.initial_alpha) * lifetime_point)
        }

        return true
    }
}



draw_emitters :: proc()
{
    for &emitter in emitters
    {
        if .IN_PLAY not_in emitter.flags do continue

        for &p, i in emitter.particles
        {
            raylib.DrawRectanglePro(p.rect, p.origin, math.to_degrees(p.angle), p.color)
        }
    }
}
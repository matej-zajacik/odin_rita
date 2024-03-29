package main

import "core:fmt"
import "core:math"
import "core:strings"
import "vendor:raylib"



scanline_tex: tex_t
font_tex:     tex_t



init_scanline_fx :: proc()
{
    w := raylib.GetScreenWidth()
    h := raylib.GetScreenHeight()

    scanline_img := raylib.GenImageColor(w, h, {})

    for i in 0..<h
    {
        if i & 2 == 0
        {
            y := f32(i)
            raylib.ImageDrawLineV(&scanline_img, {0, y}, {f32(w), y}, {80, 40, 0, 25})
        }
    }

    scanline_tex = raylib.LoadTextureFromImage(scanline_img)

    raylib.UnloadImage(scanline_img)
}



draw_game :: proc()
{
    raylib.ClearBackground({})

    raylib.BeginMode2D(main_cam)
    {
        raylib.DrawTextureEx(map_tex, {}, 0.0, 1.0 / TILE_SIZE, raylib.WHITE)

        for &actor in actors
        {
            if !actor_is_in_play(&actor) do continue

            // We don't draw actors yet.
        }

        draw_emitters()

        // We only draw debug colliders.
        draw_colliders()

        draw_debug_shapes(false)
    }
    raylib.EndMode2D()

    draw_debug_shapes(true)

    // text := strings.clone_to_cstring(fmt.tprintf("ang: %v (%v°)", player.angle, math.to_degrees(player.angle)), context.temp_allocator)
    // raylib.DrawText(text, 8, 8, 16, raylib.WHITE)

    raylib.DrawTexture(scanline_tex, 0, 0, raylib.WHITE)

    tick_tui()

    // raylib.DrawTextureEx(font_tex, {32, 32}, 0, 2, raylib.WHITE)
}
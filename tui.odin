package main

import "core:log"
import "core:fmt"
import "core:math"
import "vendor:raylib"



tui: struct
{
    phase: enum
    {
        LOGIC,
        RENDER,
    },

    mouse_pos: [2]int,
    cursor_pos: [2]int,
    buffer_size: [2]int,
    cols: int,
    rows: int,
    matrix_right: f64,
    matrix_top: f64,
}

FONT_WIDTH :: 8
FONT_HEIGHT :: 16



init_tui :: proc()
{
    using tui

    buffer_size.x = int(raylib.GetScreenWidth() / FONT_WIDTH)
    buffer_size.y = int(raylib.GetScreenHeight() / FONT_HEIGHT)
    log.infof("buffer_size: %v", buffer_size)
    cols = int(font_tex.width / FONT_WIDTH)
    rows = int(font_tex.height / FONT_HEIGHT)

    matrix_right = f64(buffer_size.x) / f64(raylib.GetScreenWidth()) * 2
    matrix_top = f64(buffer_size.y) / f64(raylib.GetScreenHeight()) * 2
}



tick_tui :: proc()
{
    using tui

    pos := raylib.GetMousePosition()
    mouse_pos.x = int(math.clamp(pos.x / FONT_WIDTH, 0, f32(buffer_size.x - 1)))
    mouse_pos.y = int(math.clamp(pos.y / FONT_HEIGHT, 0, f32(buffer_size.y - 1)))

    // tui.phase = .LOGIC
    // go()

    phase = .RENDER
    raylib.rlPushMatrix()
    raylib.rlLoadIdentity()
    raylib.rlOrtho(0, matrix_right, 0, matrix_top, -1, 100)
    go()
    raylib.rlPopMatrix()

    go :: proc()
    {
        // Status line.
        cursor_pos = {0, buffer_size.y - 1}
        draw_rect(buffer_size.x, 1, raylib.RAYWHITE)
        draw_text(" NOR   tui.odin   1:1", raylib.BLACK)

        // Draw mouse pos.
        cursor_pos = mouse_pos
        draw_rect(1, 1, raylib.YELLOW)
        cursor_pos += {2, 2}
        str := fmt.tprintf("mouse_pos: %v, %v", int(mouse_pos.x), int(mouse_pos.y))
        draw_rect(len(str) + 2, 3, raylib.DARKGRAY)
        cursor_pos += {1, 1}
        draw_text(str, raylib.LIGHTGRAY)
    }
}



draw_rect :: proc(w, h: int, color: Color)
{
    using tui

    x := f32(cursor_pos.x)
    y := f32(cursor_pos.y)

    raylib.DrawRectangleRec({x, y, f32(w), f32(h)}, color)
}



draw_text :: proc(text: string, color: Color)
{
    using tui

    src := Rect{0, 0, FONT_WIDTH, FONT_HEIGHT}
    dst := Rect{f32(cursor_pos.x), f32(cursor_pos.y), 1, 1}

    for r in text
    {
        index := int(r)
        x := index % cols;
        y := index / cols;
        src.x = f32(x * FONT_WIDTH)
        src.y = f32(y * FONT_HEIGHT)
        raylib.DrawTexturePro(font_tex, src, dst, {}, 0, color)
        dst.x += 1
        // log.infof("----\nrune: %v, index: %v\nx, y: %v, %v", r, index, x, y)
    }
}
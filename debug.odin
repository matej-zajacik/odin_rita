//
// A bunch of functions to draw debug shapes that can last any amount of time (or just a single frame).
// This is ticked automatically in every logical tick and drawn in every tick, as the very last thing.
//

package main

import "core:strings"
import "core:log"
import "vendor:raylib"



debug_shape_type_t :: enum
{
    LINE,
    TEXT,
}



debug_shape_t :: struct
{
    type:         debug_shape_type_t,
    screen_space: bool,
    start:        vec2_t,
    end:          vec2_t,
    angle:        f32,
    thickness:    f32,
    color:        color_t,
    lifetime:     int,
    text:         string,
}



debug_shapes: [dynamic]debug_shape_t



tick_debug_shapes :: proc()
{
    c := len(debug_shapes)

    for i := 0; i < c; i += 1
    {
        debug_shapes[i].lifetime -= 1

        if debug_shapes[i].lifetime < 1
        {
            delete(debug_shapes[i].text)
            unordered_remove(&debug_shapes, i)
            i -= 1
            c -= 1
        }
    }
}



draw_debug_shapes :: proc(screen_space: bool)
{
    text_y: i32 = 0
    // sb := strings.builder_make(context.temp_allocator)

    for &ds in debug_shapes
    {
        if ds.screen_space != screen_space do continue

        switch ds.type
        {
            case .LINE:
                raylib.DrawLineEx(ds.start, ds.end, ds.thickness, ds.color)

            case .TEXT:
                raylib.DrawText(strings.clone_to_cstring(ds.text, context.temp_allocator), 0, text_y, 16, ds.color)
                text_y += 16
        }
    }
}



draw_debug_line :: proc(screen_space: bool, start: vec2_t, end: vec2_t, thickness: f32, color: color_t, duration: int = 0)
{
    ds: debug_shape_t
    ds.type = .LINE
    ds.screen_space = screen_space
    ds.start = start
    ds.end = end
    ds.thickness = thickness
    ds.color = color
    ds.lifetime = duration
    append(&debug_shapes, ds)
}



draw_debug_text :: proc(screen_space: bool, text: string, color: color_t, duration: int = 0)
{
    ds: debug_shape_t
    ds.type = .TEXT
    ds.screen_space = screen_space
    ds.text = text
    ds.color = color
    ds.lifetime = duration
    append(&debug_shapes, ds)
}
//
// A bunch of functions to draw debug shapes that can last any amount of time (or just a single frame).
// This is ticked automatically in every logical tick and drawn in every tick, as the very last thing.
//

package main

import "vendor:raylib"



Debug_Shape_Type :: enum
{
    LINE,
}



Debug_Shape :: struct
{
    type:      Debug_Shape_Type,
    start:     Vector2,
    end:       Vector2,
    angle:     f32,
    thickness: f32,
    color:     Color,
    lifetime:  int,
}



debug_shapes: [dynamic]Debug_Shape



tick_debug_shapes :: proc()
{
    c := len(debug_shapes)

    for i := 0; i < c; i += 1
    {
        debug_shapes[i].lifetime -= 1

        if debug_shapes[i].lifetime < 1
        {
            unordered_remove(&debug_shapes, i)
            i -= 1
            c -= 1
        }
    }
}



draw_debug_shapes :: proc()
{
    for &ds in debug_shapes
    {
        switch ds.type
        {
            case .LINE:
                raylib.DrawLineEx(ds.start, ds.end, ds.thickness, ds.color)
        }
    }
}



draw_debug_line :: proc(start: Vector2, end: Vector2, thickness: f32, color: Color, duration: int = 0)
{
    ds: Debug_Shape
    ds.type = .LINE
    ds.start = start
    ds.end = end
    ds.thickness = thickness
    ds.color = color
    ds.lifetime = duration
    append(&debug_shapes, ds)
}
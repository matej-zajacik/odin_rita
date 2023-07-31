package main

import "vendor:raylib"



scanline_tex: raylib.Texture



init_scanline_fx :: proc()
{
    w := raylib.GetScreenWidth()
    h := raylib.GetScreenHeight()

    scanline_img := raylib.GenImageColor(w, h, {})
 
    for i in 0..<900
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
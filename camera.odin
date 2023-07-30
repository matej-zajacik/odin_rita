package main

import "core:math"
import "vendor:raylib"



main_cam: raylib.Camera2D



reset_camera :: proc()
{
    main_cam.offset = {f32(raylib.GetScreenWidth()) * 0.5, f32(raylib.GetScreenHeight()) * 0.5}
    main_cam.rotation = 0.0
    main_cam.target = {}
    main_cam.zoom = 1.0
}



tick_camera :: proc()
{
    main_cam.target = player.position
    main_cam.rotation = math.to_degrees(player.angle - math.PI / 2)
}
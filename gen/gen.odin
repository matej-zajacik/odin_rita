package main

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"
import "shared:codegen"
import "../util"



Blueprint_JSON :: struct
{
    actors: [dynamic]struct
    {
        id:               string,
        flags:            string,

        speed:            f32,
        acceleration:     f32,
        radius:           f32,
        mass:             f32,

        health:           int,
        faction:          string,
        max_range:        f32,

        make_proc:        string,
        spawn_proc:       string,
        default_proc:     string,
        chase_proc:       string,
        attack_proc:      string,
        sub_attack_procs: []string,
        death_proc:       string,
        impact_proc:      string,
    },

    sounds: [dynamic]struct
    {
        id:               string,
        flags:            string,
    },

    emitters: [dynamic]struct
    {
        id:                     string,
        flags:                  string,
        spawn_rate:             [2]f32,
        emission_angle:         f32,
        particle_speed:         [2]f32,
        particle_angular_speed: [2]f32,
        particle_size:          [2]f32,
        particle_drag:          [2]f32,
        particle_color:         [2][4]byte,
        particle_lifetime:      [2]int,
    },
}



main :: proc()
{
    util.set_file_current_dir(#file)

    src: Blueprint_JSON
    util.read_json_file_to_obj("../blueprints.json", &src)

    cg := codegen.make_codegen()
    defer codegen.free_codegen(cg)

    codegen.write(cg, "package main\n\n\n")

    //
    // Actor blueprints
    //

    codegen.write(cg, "load_actor_blueprints :: proc()")
    codegen.open_scope(cg)
    {
        for item, i in src.actors
        {
            codegen.writef(cg, "actor_blueprints[%v] =", i)
            codegen.open_scope(cg)
            {
                codegen.writef(cg, "id               = .%v,", item.id)
                codegen.writef(cg, "flags            = %v,", util.parse_bit_set(item.flags))
                codegen.writef(cg, "speed            = %v,", item.speed)
                codegen.writef(cg, "acceleration     = %v,", item.acceleration)
                codegen.writef(cg, "radius           = %v,", item.radius)
                codegen.writef(cg, "mass             = %v,", item.mass)
                codegen.writef(cg, "health           = %v,", item.health)
                codegen.writef(cg, "faction          = .%v,", item.faction == "" ? "NEUTRAL" : item.faction)
                codegen.writef(cg, "max_range        = %v,", item.max_range)
                codegen.writef(cg, "make_proc        = %v,", util.parse_proc(item.make_proc))
                codegen.writef(cg, "spawn_proc       = %v,", util.parse_proc(item.spawn_proc))
                codegen.writef(cg, "default_proc     = %v,", util.parse_proc(item.default_proc))
                codegen.writef(cg, "chase_proc       = %v,", util.parse_proc(item.chase_proc))
                codegen.writef(cg, "attack_proc      = %v,", util.parse_proc(item.attack_proc))
                if len(item.sub_attack_procs) > 0
                {
                    codegen.write(cg, "sub_attack_procs =")
                    codegen.open_scope(cg)
                    for sub in item.sub_attack_procs
                    {
                        codegen.writef(cg, "%v,", sub)
                    }
                    codegen.close_scope(cg, "},")
                }
                else
                {
                    codegen.write(cg, "sub_attack_procs = nil,")
                }
                codegen.writef(cg, "death_proc       = %v,", util.parse_proc(item.death_proc))
                codegen.writef(cg, "impact_proc      = %v,", util.parse_proc(item.impact_proc))
            }
            codegen.close_scope(cg)
        }
    }
    codegen.close_scope(cg)

    codegen.write(cg, "\n\n\n")

    //
    // Sound blueprints
    //

    // codegen.write(cg, "load_sound_blueprints :: proc()")
    // codegen.open_scope(cg)
    // {
    //     for item, i in src.sounds
    //     {
    //         codegen.writef(cg, "sound_blueprints[%v] =", i)
    //         codegen.open_scope(cg)
    //         {
    //             codegen.writef(cg, "id               = .%v,", item.id)
    //             codegen.writef(cg, "files            = %v,", util.parse_bit_set(item.flags))
    //             codegen.writef(cg, "speed            = %v,", item.speed)
    //             codegen.writef(cg, "acceleration     = %v,", item.acceleration)
    //             codegen.writef(cg, "radius           = %v,", item.radius)
    //             codegen.writef(cg, "mass             = %v,", item.mass)
    //             codegen.writef(cg, "health           = %v,", item.health)
    //             codegen.writef(cg, "faction          = .%v,", item.faction == "" ? "NEUTRAL" : item.faction)
    //             codegen.writef(cg, "max_range        = %v,", item.max_range)
    //             codegen.writef(cg, "make_proc        = %v,", util.parse_proc(item.make_proc))
    //             codegen.writef(cg, "spawn_proc       = %v,", util.parse_proc(item.spawn_proc))
    //             codegen.writef(cg, "default_proc     = %v,", util.parse_proc(item.default_proc))
    //             codegen.writef(cg, "chase_proc       = %v,", util.parse_proc(item.chase_proc))
    //             codegen.writef(cg, "attack_proc      = %v,", util.parse_proc(item.attack_proc))
    //             if len(item.sub_attack_procs) > 0
    //             {
    //                 codegen.write(cg, "sub_attack_procs =")
    //                 codegen.open_scope(cg)
    //                 for sub in item.sub_attack_procs
    //                 {
    //                     codegen.writef(cg, "%v,", sub)
    //                 }
    //                 codegen.close_scope(cg, "},")
    //             }
    //             else
    //             {
    //                 codegen.write(cg, "sub_attack_procs = nil,")
    //             }
    //             codegen.writef(cg, "death_proc       = %v,", util.parse_proc(item.death_proc))
    //             codegen.writef(cg, "impact_proc      = %v,", util.parse_proc(item.impact_proc))
    //         }
    //         codegen.close_scope(cg)
    //     }
    // }
    // codegen.close_scope(cg)

    codegen.write(cg, "\n\n\n")

    //
    // Emitter blueprints
    //

    codegen.write(cg, "load_emitter_blueprints :: proc()")
    codegen.open_scope(cg)
    {
        for item, i in src.emitters
        {
            codegen.writef(cg, "emitter_blueprints[%v] =", i)
            codegen.open_scope(cg)
            {
                codegen.writef(cg, "id                     = .%v,", item.id)
                codegen.writef(cg, "flags                  = %v,", util.parse_bit_set(item.flags))
                codegen.writef(cg, "spawn_rate             = %v,", util.parse_array( item.spawn_rate))
                codegen.writef(cg, "emission_angle         = %v,", item.emission_angle)
                codegen.writef(cg, "particle_speed         = %v,", util.parse_array(item.particle_speed))
                codegen.writef(cg, "particle_angular_speed = %v,", util.parse_array(item.particle_angular_speed))
                codegen.writef(cg, "particle_size          = %v,", util.parse_array(item.particle_size))
                codegen.writef(cg, "particle_drag          = %v,", util.parse_array(item.particle_drag))
                codegen.writef(cg, "particle_color   = {{%v, %v}},", util.parse_array(item.particle_color[0]), util.parse_array(item.particle_color[1]))
                codegen.writef(cg, "particle_lifetime      = %v,", util.parse_array(item.particle_lifetime))
            }
            codegen.close_scope(cg)
        }
    }
    codegen.close_scope(cg)

    os.write_entire_file("../generated.odin", codegen.to_bytes(cg))
}
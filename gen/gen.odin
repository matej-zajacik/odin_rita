package main

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"
import "shared:codegen"
import "shared:util"



Actor_Blueprint_JSON :: struct
{
    items: [dynamic]struct
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
}



main :: proc()
{
    util.set_file_current_dir(#file)

    src: Actor_Blueprint_JSON
    util.read_json_file_to_obj("../blueprints.json", &src)

    cg := codegen.make_codegen()
    defer codegen.free_codegen(cg)

    codegen.write(cg, "package main\n\n\n")
    codegen.write(cg, "load_blueprints :: proc()")
    codegen.open_scope(cg)
    {
        for item, i in src.items
        {
            codegen.writef(cg, "blueprints[%v] =", i)
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

    // fmt.println(codegen.to_string(cg))

    os.write_entire_file("../generated.odin", codegen.to_bytes(cg))
}
package util

import "core:encoding/json"
import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:strings"



set_file_current_dir :: proc(dir: string)
{
    new_dir, _ := filepath.split(dir)
    os.set_current_directory(new_dir)
}



read_json_bytes_to_obj :: proc(json_bytes: []byte, obj: ^$T)
{
    err := json.unmarshal(json_bytes, obj, .JSON, context.temp_allocator)

    if err != nil
    {
        log.panicf("can't parse json_bytes: %v", err)
    }
}



read_json_file_to_obj :: proc(file_name: string, obj: ^$T, can_fail := false)
{
    f, ok := os.read_entire_file_from_filename(file_name, context.temp_allocator)

    if !ok
    {
        if !can_fail
        {
            log.panicf("can't open file %v", file_name)
        }

        return
    }

    read_json_bytes_to_obj(f, obj)
}



write_obj_to_json_file :: proc(obj: ^$T, file_name: string)
{
    sb := strings.builder_make()
    defer strings.builder_destroy(&sb)

    opts: json.Marshal_Options
    opts.spec = .JSON
    opts.pretty = true
    opts.use_spaces = true
    opts.spaces = 4

    err := json.marshal_to_builder(&sb, obj^, &opts)

    if err != nil
    {
        log.panicf("JSON error: %v", err)
    }

    json_bytes := transmute([]u8)(strings.to_string(sb))
    os.write_entire_file(file_name, json_bytes, true)
}



parse_bit_set :: proc(str: string) -> string
{
    b: strings.Builder
    strings.builder_init(&b, context.temp_allocator)

    tokens, err := strings.split(str, ",", context.temp_allocator)
    fmt.assertf(err == nil, "%v", err)

    strings.builder_reset(&b)
    strings.write_string(&b, "{")

    for token, i in tokens
    {
        token := strings.trim_space(token)
        strings.write_string(&b, fmt.tprintf(".%v", token))

        if i < len(tokens) - 1
        {
            strings.write_string(&b, ", ")
        }
    }

    strings.write_string(&b, "}")

    return strings.to_string(b)
}



parse_proc :: proc(str: string) -> string
{
    return len(str) > 0 ? str : "nil"
}
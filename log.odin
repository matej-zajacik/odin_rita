package main

import "core:fmt"
import "core:strings"
import "core:runtime"
import "core:log"



get_logger :: proc() -> log.Logger
{
    logger := log.create_console_logger(opt = {.Level, .Terminal_Color})
    logger.procedure = logger_proc
    return logger
}



@(private="file")
logger_proc :: proc(data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location)
{
    level_str := strings.to_upper(fmt.tprint(level), context.temp_allocator)
    fmt.printf("[%v] %v:\n%v\n%v\n\n", frame, strings.to_upper(level_str, context.temp_allocator), location, text)
}
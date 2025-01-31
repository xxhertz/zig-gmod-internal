const std = @import("std");
const c_usercmd = @import("structs.zig").c_usercmd;
const globals = @import("globals.zig");
pub const create_move_t = *const fn (_: *anyopaque, _: f32, _: *c_usercmd) bool;
pub var create_move_o: create_move_t = undefined;

pub fn hk_create_move(this: *anyopaque, frametime: f32, cmd: *c_usercmd) bool {
    // local_player has always existed when createmove is called, caused no issues for me thus far
    // probably should check if it exists (they do it internally @create_move_o) but i don't think it's necessary in this engine
    const local_player = globals.get_local_player().?;

    // extremely easy to detect, no fakescrolls and no ladder checks, movetype impl later
    cmd.buttons.IN_JUMP = cmd.buttons.IN_JUMP and local_player.m_iFlags.FL_ONGROUND;

    return create_move_o(this, frametime, cmd);
}

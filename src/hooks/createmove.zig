const std = @import("std");
const math = @import("zlm");
const structs = @import("../structs.zig");
const c_usercmd = structs.c_usercmd;
const globals = @import("../globals.zig");

const autostrafe = @import("../features/autostrafe.zig");

pub var create_move_o: *const fn (_: *anyopaque, _: f32, _: *c_usercmd) bool = undefined;
pub const state = struct {
    pub var local_player: *structs.player = undefined;

    pub var last_viewangles: math.Vec3 = math.vec3(0, 0, 0);
    pub var last_networked_viewangles: math.Vec3 = math.vec3(0, 0, 0);

    pub var last_buttons: structs.user_buttons = .{};
    pub var last_networked_buttons: structs.user_buttons = .{};

    pub var last_flags: structs.flags = .{};
    pub var last_networked_flags: structs.flags = .{};
};

pub fn hk_create_move(this: *anyopaque, frametime: f32, cmd: *c_usercmd) bool {
    // local_player has always existed when createmove is called, caused no issues for me thus far
    // probably should check if it exists (they do it internally @create_move_o) but i don't think it's necessary in this engine
    const local_player = globals.get_local_player().?;
    state.local_player = local_player;

    if (cmd.buttons.IN_JUMP and local_player.m_MoveType == .MOVETYPE_WALK and local_player.m_iWaterLevel != .FULLY_SUBMERGED and local_player.m_iWaterLevel != .MOSTLY_SUBMERGED) {
        cmd.buttons.IN_JUMP = local_player.m_iFlags.FL_ONGROUND and !state.last_networked_buttons.IN_JUMP;

        if (cmd.command_number != 0) {
            if (state.local_player.m_iWaterLevel == .NOT_SUBMERGED and !cmd.buttons.IN_MOVELEFT and !cmd.buttons.IN_FORWARD and !cmd.buttons.IN_MOVERIGHT and !cmd.buttons.IN_BACK and !cmd.buttons.IN_USE) {
                autostrafe.rage_strafe(cmd);
            }

            // crouchfix
            if (state.last_networked_flags.FL_DUCKING and local_player.m_iFlags.FL_DUCKING and !cmd.buttons.IN_DUCK and local_player.m_iFlags.FL_ONGROUND) {
                cmd.buttons.IN_DUCK = true;
            }
        }
    }

    state.last_buttons = cmd.buttons;
    state.last_flags = local_player.m_iFlags;
    state.last_viewangles = cmd.viewangles;

    if (cmd.command_number != 0) {
        state.last_networked_buttons = cmd.buttons;
        state.last_networked_flags = local_player.m_iFlags;
        state.last_networked_viewangles = cmd.viewangles;
    }

    return create_move_o(this, frametime, cmd);
}

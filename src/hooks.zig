const std = @import("std");
const math = @import("zlm");
const structs = @import("structs.zig");
const c_usercmd = structs.c_usercmd;
const globals = @import("globals.zig");
pub const create_move_t = *const fn (_: *anyopaque, _: f32, _: *c_usercmd) bool;
pub var create_move_o: create_move_t = undefined;

fn set_move(cmd: *c_usercmd, direction: structs.direction) void {
    switch (direction) {
        .FORWARD => {
            cmd.buttons.IN_FORWARD = true;
            cmd.buttons.IN_BACK = false;
            cmd.forwardmove = 10000;
        },
        .BACK => {
            cmd.buttons.IN_FORWARD = true;
            cmd.buttons.IN_BACK = false;
            cmd.forwardmove = -10000;
        },
        .LEFT => {
            cmd.buttons.IN_MOVELEFT = true;
            cmd.buttons.IN_MOVERIGHT = false;
            cmd.sidemove = -10000;
        },
        .RIGHT => {
            cmd.buttons.IN_MOVERIGHT = true;
            cmd.buttons.IN_MOVELEFT = false;
            cmd.sidemove = 10000;
        },
        .NONE => {},
    }
}

const state = struct {
    var last_viewangles: math.Vec3 = math.vec3(0, 0, 0);
    var last_networked_viewangles: math.Vec3 = math.vec3(0, 0, 0);

    var last_buttons: structs.user_buttons = .{};
    var last_networked_buttons: structs.user_buttons = .{};

    var last_flags: structs.flags = .{};
    var last_networked_flags: structs.flags = .{};
};

pub fn hk_create_move(this: *anyopaque, frametime: f32, cmd: *c_usercmd) bool {
    // local_player has always existed when createmove is called, caused no issues for me thus far
    // probably should check if it exists (they do it internally @create_move_o) but i don't think it's necessary in this engine
    const local_player = globals.get_local_player().?;

    if (cmd.buttons.IN_JUMP and local_player.m_MoveType == .MOVETYPE_WALK and local_player.m_iWaterLevel != .FULLY_SUBMERGED and local_player.m_iWaterLevel != .MOSTLY_SUBMERGED) {
        cmd.buttons.IN_JUMP = local_player.m_iFlags.FL_ONGROUND and state.last_networked_buttons.IN_JUMP == false;

        // sprint in-air for better strafe strength
        cmd.buttons.IN_SPEED = true;

        const mouse_direction = state.last_viewangles.y - cmd.viewangles.y;

        const velocity = local_player.m_vecVelocity;
        const yaw = math.toRadians(cmd.viewangles.y);
        const relative_x = -@sin(yaw) * velocity.x + @cos(yaw) * velocity.y;
        const relative_y = @cos(yaw) * velocity.x + @sin(yaw) * velocity.y;
        const move_direction = math.vec2(relative_x, relative_y).normalize();
        var direction: structs.direction = .NONE;
        if (move_direction.length() != 0) {
            if (@abs(move_direction.x) > @abs(move_direction.y))
                direction = if (move_direction.x > 0) .LEFT else .RIGHT
            else
                direction = if (move_direction.y > 0) .FORWARD else .BACK;
        }

        // holding E disables autostrafer, letting go snaps into a good angle to continue autostrafing
        if (state.last_buttons.IN_USE and !cmd.buttons.IN_USE) {
            const move_direction_yaw: f32 = std.math.atan2(velocity.y, velocity.x) * std.math.deg_per_rad;
            switch (direction) {
                .FORWARD => cmd.viewangles.y = move_direction_yaw,
                .BACK => cmd.viewangles.y = move_direction_yaw - 180,

                .LEFT => cmd.viewangles.y = move_direction_yaw - 90,
                .RIGHT => cmd.viewangles.y = move_direction_yaw + 90,

                .NONE => {},
            }
        }

        if (local_player.m_iWaterLevel == .NOT_SUBMERGED and !cmd.buttons.IN_MOVELEFT and !cmd.buttons.IN_FORWARD and !cmd.buttons.IN_MOVERIGHT and !cmd.buttons.IN_BACK and !cmd.buttons.IN_USE) {
            const strafe_keys: [2]structs.direction = switch (direction) {
                .FORWARD => .{ .LEFT, .RIGHT },
                .BACK => .{ .RIGHT, .LEFT },

                .LEFT => .{ .BACK, .FORWARD },
                .RIGHT => .{ .FORWARD, .BACK },

                .NONE => .{ .NONE, .NONE },
            };

            if (direction != .NONE) {
                if (mouse_direction < 0)
                    set_move(cmd, strafe_keys[0])
                else if (mouse_direction > 0)
                    set_move(cmd, strafe_keys[1]);
            }
        }

        // crouchfix
        if (cmd.command_number != 0) {
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

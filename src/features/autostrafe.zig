const std = @import("std");
const structs = @import("../structs.zig");
const c_usercmd = structs.c_usercmd;
const state = @import("../hooks/createmove.zig").state;
const math = @import("zlm");

pub fn set_move_cardinal(cmd: *c_usercmd, direction: structs.direction) void {
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

pub inline fn legit_strafe(cmd: *c_usercmd) void {
    const mouse_direction = state.last_networked_viewangles.y - cmd.viewangles.y;
    const velocity = state.local_player.m_vecVelocity;

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

    const strafe_keys: [2]structs.direction = switch (direction) {
        .FORWARD => .{ .LEFT, .RIGHT },
        .BACK => .{ .RIGHT, .LEFT },

        .LEFT => .{ .BACK, .FORWARD },
        .RIGHT => .{ .FORWARD, .BACK },

        .NONE => .{ .NONE, .NONE },
    };

    if (direction != .NONE) {
        if (mouse_direction < 0)
            set_move_cardinal(cmd, strafe_keys[0])
        else if (mouse_direction > 0)
            set_move_cardinal(cmd, strafe_keys[1]);
    }
}

pub inline fn rage_strafe(cmd: *c_usercmd) void {
    if (!cmd.buttons.IN_USE) {
        const mouse_direction = state.last_networked_viewangles.y - cmd.viewangles.y;

        const velocity = state.local_player.m_vecVelocity;
        const velocity2d = math.vec2(velocity.x, velocity.y);

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
        if (state.last_buttons.IN_USE) {
            const move_direction_yaw: f32 = math.toDegrees(std.math.atan2(velocity.y, velocity.x));
            switch (direction) {
                .FORWARD => cmd.viewangles.y = move_direction_yaw,
                .BACK => cmd.viewangles.y = move_direction_yaw - 180,

                .LEFT => cmd.viewangles.y = move_direction_yaw - 90,
                .RIGHT => cmd.viewangles.y = move_direction_yaw + 90,

                .NONE => {},
            }
        }

        if (mouse_direction == 0) {
            const strafe_side: f32 = if (@mod(cmd.command_number, 2) == 0) -1 else 1;
            // logic for best_yaw_offset copied from supremacy-csgo
            const best_yaw_offset: f32 = if (velocity2d.length() == 0) 90 else math.toDegrees(15 / velocity2d.length());

            const direction_offset: f32 = switch (direction) {
                .BACK => -180,
                .FORWARD => 0,
                .LEFT => 90,
                .RIGHT => -90,
                .NONE => 0,
            };

            const ideal_yaw: f32 = best_yaw_offset * strafe_side + cmd.viewangles.y + direction_offset;

            const cos_rot = @cos(math.toRadians(cmd.viewangles.y - ideal_yaw));
            const sin_rot = @sin(math.toRadians(cmd.viewangles.y - ideal_yaw));

            cmd.forwardmove = -sin_rot * 10000 * strafe_side;
            cmd.sidemove = cos_rot * 10000 * strafe_side;
        } else {
            legit_strafe(cmd);
        }
    }
}

const std = @import("std");
const win32 = @import("zigwin32");
const interface = @import("get_interface.zig");
const trampoline = @import("trampoline.zig");
const structs = @import("structs.zig");
const hooks = @import("hooks.zig");
const globals = @import("globals.zig");
const win = std.os.windows;

pub export fn DllMain(hInst: win.HINSTANCE, dwReason: win.DWORD, _: win.LPVOID) win.BOOL {
    switch (dwReason) {
        win32.system.system_services.DLL_PROCESS_ATTACH => {
            _ = win32.system.library_loader.DisableThreadLibraryCalls(hInst);
            const thread = win32.system.threading.CreateThread(null, 0, main_thread, hInst, win32.system.threading.THREAD_CREATE_RUN_IMMEDIATELY, null);
            if (thread == null)
                return win.FALSE; // failed

            _ = win32.foundation.CloseHandle(thread);
        },
        else => {},
    }
    return win.TRUE;
}

fn unload(hInst: ?*anyopaque) u32 {
    // unload by pressing enter in console (no idea why this is called readByte)
    _ = std.io.getStdIn().reader().readByte() catch unreachable;
    trampoline.global_hooks_states.deinit();
    _ = win32.system.console.FreeConsole();
    win32.system.library_loader.FreeLibraryAndExitThread(@as(?win.HINSTANCE, @ptrCast(hInst)), 0);

    return 0;
}

fn main_thread(hInst: ?*anyopaque) callconv(.winapi) u32 {
    _ = hInst orelse unreachable;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    _ = win32.system.console.AllocConsole();

    // CHLClient
    const g_pClient = interface.get_interface(*[*]usize, "client.dll", "VClient017").?.*;
    std.log.debug("CHLClient: {*}", .{g_pClient});

    const hud_process_input = g_pClient[10];
    std.log.debug("CHLClient->HudProcessInput: {X}", .{hud_process_input});

    // ... lol
    const g_pClientMode: [*]align(1) usize = @as(*align(1) *align(1) [*]align(1) usize, @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(hud_process_input + 7)) + @as(*align(1) i32, @ptrFromInt(hud_process_input + 3)).*)))).*.*;
    std.log.debug("g_pClientMode: {*}", .{g_pClientMode});

    const create_move = g_pClientMode[21];
    std.log.debug("g_pClientMode->CreateMove: {X}", .{create_move});

    globals.get_local_player = @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(create_move + 22)) + @as(*align(1) i32, @ptrFromInt(create_move + 18)).*))); //@ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(create_move + 22)) + @as(isize, @ptrFromInt(create_move + 18)))));
    std.log.debug("get_local_player: {*}", .{globals.get_local_player});

    trampoline.global_hooks_states.init(allocator);
    hooks.create_move_o = @ptrFromInt(trampoline.virtual_hook(g_pClientMode, 21, @intFromPtr(&hooks.hk_create_move)));

    return unload(hInst);
}

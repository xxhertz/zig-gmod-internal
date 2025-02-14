const std = @import("std");
const win32 = @import("zigwin32");
const interface = @import("get_interface.zig");
const hooking = @import("vmthook");
const structs = @import("structs.zig");
const hooks = @import("hooks/createmove.zig");
const globals = @import("globals.zig");
const win = std.os.windows;

pub export fn DllMain(hInstance: win.HINSTANCE, dwReason: win.DWORD, _: win.LPVOID) win.BOOL {
    switch (dwReason) {
        win32.system.system_services.DLL_PROCESS_ATTACH => {
            _ = win32.system.library_loader.DisableThreadLibraryCalls(hInstance);
            const thread = win32.system.threading.CreateThread(null, 0, main_thread, hInstance, win32.system.threading.THREAD_CREATE_RUN_IMMEDIATELY, null);
            if (thread == null)
                return win.FALSE; // failed

            _ = win32.foundation.CloseHandle(thread);
        },
        else => {},
    }
    return win.TRUE;
}

fn main_thread(hInstance: ?*anyopaque) callconv(.winapi) u32 {
    const instance: win.HINSTANCE = @ptrCast(hInstance orelse unreachable);
    defer win32.system.library_loader.FreeLibraryAndExitThread(instance, 0);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    _ = win32.system.console.AllocConsole();
    defer _ = win32.system.console.FreeConsole();

    // CHLClient
    const g_pClient = interface.get_interface(*[*]usize, "client.dll", "VClient017").?.*;
    std.log.debug("CHLClient: {*}", .{g_pClient});

    const hud_process_input = g_pClient[10];
    std.log.debug("CHLClient->HudProcessInput: {x}", .{hud_process_input});

    // calculate relative address
    const g_pClientMode: [*]usize = @as(*align(1) *[*]usize, @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(hud_process_input + 7)) + @as(*align(1) i32, @ptrFromInt(hud_process_input + 3)).*)))).*.*;
    std.log.debug("g_pClientMode: {*}", .{g_pClientMode});

    const create_move = g_pClientMode[21];
    std.log.debug("g_pClientMode->CreateMove: {x}", .{create_move});

    globals.get_local_player = @ptrFromInt(@as(usize, @intCast(@as(isize, @intCast(create_move + 22)) + @as(*align(1) i32, @ptrFromInt(create_move + 18)).*)));
    std.log.debug("C_BasePlayer->GetLocalPlayer: {*}", .{globals.get_local_player});

    hooking.init(allocator);
    defer hooking.deinit();

    hooks.create_move_o = @ptrCast(hooking.virtual_hook(g_pClientMode, 21, &hooks.hk_create_move));

    _ = std.io.getStdIn().reader().readByte() catch std.log.err("cannot 'readByte', possibly exiting early", .{});
    return 0;
}

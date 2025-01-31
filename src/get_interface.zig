const std = @import("std");
const lib = @import("zigwin32").system.library_loader;

pub fn get_interface(comptime T: type, mod: ?[*:0]const u8, interface_name: [*:0]const u8) ?T {
    const create_interface: *const fn (module: [*:0]const u8, ret: ?*c_int) ?T = @ptrCast(lib.GetProcAddress(lib.GetModuleHandleA(mod), "CreateInterface"));
    return create_interface(interface_name, null);
}

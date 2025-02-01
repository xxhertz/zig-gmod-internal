pub const hook_state = struct {
    original_ptr: usize,
    vtable: [*]align(1) usize,
    index: u32,
};

pub const c_usercmd = struct {
    command_number: c_int,
    tick_count: c_int,
    viewangles: vec3,
    forwardmove: f32,
    sidemove: f32,
    upmove: f32,
    buttons: user_buttons,
    impulse: c_char,
    weaponselect: c_int,
    weaponsubtype: c_int,
    random_seed: c_int,
    mousedx: c_short,
    mousedy: c_short,
    hasbeenpredicted: bool,
};

// https://wiki.facepunch.com/gmod/Enums/IN
pub const user_buttons = packed struct(u25) {
    IN_ATTACK: bool = false,
    IN_JUMP: bool = false,
    IN_DUCK: bool = false,
    IN_FORWARD: bool = false,
    IN_BACK: bool = false,
    IN_USE: bool = false,
    IN_CANCEL: bool = false,
    IN_LEFT: bool = false,
    IN_RIGHT: bool = false,
    IN_MOVELEFT: bool = false,
    IN_MOVERIGHT: bool = false,
    IN_ATTACK2: bool = false,
    IN_RUN: bool = false,
    IN_RELOAD: bool = false,
    IN_ALT1: bool = false,
    IN_ALT2: bool = false,
    IN_SCORE: bool = false,
    IN_SPEED: bool = false,
    IN_WALK: bool = false,
    IN_ZOOM: bool = false,
    IN_WEAPON1: bool = false,
    IN_WEAPON2: bool = false,
    IN_BULLRUSH: bool = false,
    IN_GRENADE1: bool = false,
    IN_GRENADE2: bool = false,
};

// https://wiki.facepunch.com/gmod/Enums/FL
pub const flags = packed struct(u32) {
    FL_ONGROUND: bool = false,
    FL_DUCKING: bool = false,
    FL_ANIMDUCKING: bool = false,
    FL_WATERJUMP: bool = false,
    FL_ONTRAIN: bool = false,
    FL_INRAIN: bool = false,
    FL_FROZEN: bool = false,
    FL_ATCONTROLS: bool = false,
    FL_CLIENT: bool = false,
    FL_FAKECLIENT: bool = false,
    FL_INWATER: bool = false,
    FL_FLY: bool = false,
    FL_SWIM: bool = false,
    FL_CONVEYOR: bool = false,
    FL_NPC: bool = false,
    FL_GODMODE: bool = false,
    FL_NOTARGET: bool = false,
    FL_AIMTARGET: bool = false,
    FL_PARTIALGROUND: bool = false,
    FL_STATICPROP: bool = false,
    FL_GRAPHED: bool = false,
    FL_GRENADE: bool = false,
    FL_STEPMOVEMENT: bool = false,
    FL_DONTTOUCH: bool = false,
    FL_BASEVELOCITY: bool = false,
    FL_WORLDBRUSH: bool = false,
    FL_OBJECT: bool = false,
    FL_KILLME: bool = false,
    FL_ONFIRE: bool = false,
    FL_DISSOLVING: bool = false,
    FL_TRANSRAGDOLL: bool = false,
    FL_UNBLOCKABLE_BY_PLAYER: bool = false,
};

const movetype = enum(c_char) {
    MOVETYPE_NONE,
    MOVETYPE_ISOMETRIC,
    MOVETYPE_WALK,
    MOVETYPE_STEP,
    MOVETYPE_FLY,
    MOVETYPE_FLYGRAVITY,
    MOVETYPE_VPHYSICS,
    MOVETYPE_PUSH,
    MOVETYPE_NOCLIP,
    MOVETYPE_LADDER,
    MOVETYPE_OBSERVER0,
    MOVETYPE_CUSTOM1,
};

const waterlevel = enum(c_char) {
    NOT_SUBMERGED,
    PARTIALLY_SUBMERGED,
    MOSTLY_SUBMERGED,
    FULLY_SUBMERGED,
};

pub const player = extern struct {
    _1: [0x1F4]u8,
    m_MoveType: movetype, // 0x1F4
    _2: [0x3]u8,
    m_iWaterLevel: waterlevel, // 0x1F8
    _3: [0x247]u8,
    m_iFlags: flags,
};

pub const vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

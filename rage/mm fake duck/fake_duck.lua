local hook = require("hooking library")

local __thiscall = function(func, this)
    return function(...)
        return func(this, ...)
    end
end
local vtable_bind = function(module, interface, index, typedef)
    local addr = ffi.cast("void***", memory.create_interface(module, interface)) or error(interface .. " is nil.")
    return __thiscall(ffi.cast(typedef, addr[0][index]), addr)
end
local interface_ptr = ffi.typeof("void***")
local vtable_entry = function(instance, i, ct)
    return ffi.cast(ct, ffi.cast(interface_ptr, instance)[0][i])
end
local vtable_thunk = function(i, ct)
    local t = ffi.typeof(ct)
    return function(instance, ...)
        return vtable_entry(instance, i, t)(instance, ...)
    end
end

ffi.cdef[[
    typedef struct{
        float x;
        float y;
        float z;
    } Vector;
    typedef struct{
        char _0x0000[16];
        __int32 x; //0x0010 
        __int32 x_old; //0x0014 
        __int32 y; //0x0018 
        __int32 y_old; //0x001C
        __int32 width; //0x0020
        __int32 width_old; //0x0024
        __int32 height; //0x0028
        __int32 height_old; //0x002C
        char _0x0030[128];
        float fov; //0x00B0 
        float fovViewmodel; //0x00B4 
        Vector origin; //0x00B8 
        Vector angles; //0x00C4
        float zNear; //0x00D0 
        float zFar; //0x00D4 
        float zNearViewmodel; //0x00D8 
        float zFarViewmodel; //0x00DC 
        float m_flAspectRatio; //0x00E0 
        float m_flNearBlurDepth; //0x00E4 
        float m_flNearFocusDepth; //0x00E8 
        float m_flFarFocusDepth; //0x00EC 
        float m_flFarBlurDepth; //0x00F0 
        float m_flNearBlurRadius; //0x00F4 
        float m_flFarBlurRadius; //0x00F8 
        float m_nDoFQuality; //0x00FC 
        __int32 m_nMotionBlurMode; //0x0100 
        char _0x0104[68];
        __int32 m_EdgeBlur; //0x0148 
    } CViewSetup;
]]

local stupid_ref = menu.add_text("Visualize hitscan", "Matchmaking fake duck")
local fake_duck_ref = stupid_ref:add_keybind("mmfd key")

local function degree_to_radian(degree)
    return (math.pi / 180) * degree
end

local function angle_to_vector (angle)
    local pitch = degree_to_radian(angle.x)
    local yaw = degree_to_radian(angle.y)
    return vec3_t(math.cos(pitch) * math.cos(yaw), math.cos(pitch) * math.sin(yaw), -math.sin(pitch))
end

local function getCameraPositionInaccurate(force)
    local local_player = entity_list.get_local_player()
    local eye_pos = local_player:get_eye_position()
    if force then
        eye_pos.z = local_player:get_prop("m_vecOrigin[2]")+64
    end
    if not client.is_in_thirdperson() then
        return eye_pos
    end
    local local_angle = angle_to_vector(engine.get_view_angles())
    local camera_pos = vec3_t(local_angle.x * -130 + eye_pos.x, local_angle.y * -130 + eye_pos.y, local_angle.z * -130 + eye_pos.z)
    local trace_result = trace.line(eye_pos, camera_pos, local_player)
    local camera_pos = vec3_t(local_angle.x * -128 * trace_result.fraction + eye_pos.x, local_angle.y * -128 * trace_result.fraction + eye_pos.y, local_angle.z * -128 * trace_result.fraction + eye_pos.z)
    return camera_pos
end

local function RenderViewHook(originalFunction)
    local originalFunction = originalFunction
    return function(this, hudViewSetup, nClearFlags, whatToDraw, someRandomBullshitThatGotAdded)
        if not fake_duck_ref:get() or game_rules.get_prop("m_bIsValveDS")==0 then return originalFunction(this, hudViewSetup, nClearFlags, whatToDraw, someRandomBullshitThatGotAdded) end
        local local_player = entity_list.get_local_player()
        if not local_player:is_alive() then
            return originalFunction(this, hudViewSetup, nClearFlags, whatToDraw, someRandomBullshitThatGotAdded)
        end
        local camera_pos = getCameraPositionInaccurate(true)
        hudViewSetup.origin.x=camera_pos.x
        hudViewSetup.origin.y=camera_pos.y
        hudViewSetup.origin.z=camera_pos.z
        originalFunction(this, hudViewSetup, nClearFlags, whatToDraw, someRandomBullshitThatGotAdded)
    end
end

local CViewRender=hook.jmp.new("void(__thiscall*)(void*, CViewSetup*, int, int, void*)",RenderViewHook,ffi.cast("intptr_t****",memory.find_pattern("client.dll","8B 0D ? ? ? ? FF 75 0C 8B 45 08")+2)[0][0][0][6], 6, true)

local function on_shutdown()
    if CViewRender~=nil then CViewRender.stop() end
end

callbacks.add(e_callbacks.SHUTDOWN, on_shutdown)

local button = bit.lshift(1,2)

local function on_setup_command(cmd)
    if not fake_duck_ref:get() or game_rules.get_prop("m_bIsValveDS")==0 then return end
    local local_player = entity_list.get_local_player()
    if local_player:get_prop("m_flDuckAmount")>0.8 then
        button=bit.lshift(1,22)
    elseif local_player:get_prop("m_flDuckAmount")<=0.2 then
        button=bit.lshift(1,2)
    end
    cmd:add_button(button)
end

callbacks.add(e_callbacks.SETUP_COMMAND,on_setup_command)

local function on_antiaim(ctx)
    if not fake_duck_ref:get() or game_rules.get_prop("m_bIsValveDS")==0 then return end
    local local_player = entity_list.get_local_player()
    if local_player:get_prop("m_flDuckAmount")>0.6 and local_player:get_prop("m_flDuckAmount")<0.80 then
        ctx:set_fakelag(false)
    else
        ctx:set_fakelag(true)
    end
end

callbacks.add(e_callbacks.ANTIAIM, on_antiaim)

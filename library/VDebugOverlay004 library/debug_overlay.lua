--xD
require("vector")

local __thiscall = function(func, this)
    return function(...)
        return func(this, ...)
    end
end
local vtable_bind = function(module, interface, index, typedef)
    local addr = ffi.cast("void***", memory.create_interface(module, interface)) or safe_error(interface .. " is nil.")
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

-- unsigned char* = Color struct
-- float* = matrix3x4_t struct
-- int* = vColorTable struct

matrix3x4_t = ffi.typeof("float*")
vColorTable = ffi.typeof("int*")
Color = ffi.typeof("unsigned char*")

ffi.cdef [[
  typedef struct{
    int id;
    int version;
    int checksum;
    char name[64];
    int length;
    Vector eyePosition;
    Vector illumPosition;
    Vector hullMin;
    Vector hullMax;
    Vector bbMin;
    Vector bbMax;
    int flags;
    int numBones;
    int boneIndex;
    int numBoneControllers;
    int boneControllerIndex;
    int numHitboxSets;
    int hitboxSetIndex;
  } StudioHdr;

  typedef struct{
    int nameIndex;
    int numHitboxes;
    int hitboxIndex;
  } StudioHitboxSet;

  typedef struct {
    int bone;
    int group;
    Vector bbMin;
    Vector bbMax;
    int hitboxNameIndex;
    Vector offsetOrientation;
    float capsuleRadius;
    int unused[4];
  } StudioBbox;
]]

local StudioHdr = ffi.typeof("StudioHdr*")
local StudioHitboxSet = ffi.typeof("StudioHitboxSet*")
local StudioBbox = ffi.typeof("StudioBbox*")

local nativeGetClientEntity = vtable_bind("client.dll", "VClientEntityList003", 3, "uintptr_t(__thiscall*)(void*, int)")

local nativeGetModel = vtable_bind('engine.dll', 'VModelInfoClient004', 1, 'void*(__thiscall*)(void*, int)')
local nativeGetStudioModel = vtable_bind('engine.dll', 'VModelInfoClient004', 32, 'StudioHdr*(__thiscall*)(void*, void*)')

local nativeAddEntityTextOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 0, 'void(__cdecl*)(void*, int, int, float, int, int, int, int, const char*, ...)') -- E9 ? ? ? ? 83 E9 04 E9 ? ? ? ? 83 6C 24 ? ? E9 ? ? ? ? 83 6C 24 ? ?
local nativeAddBoxOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 1, 'void(__thiscall*)(void*, const Vector&, const Vector&, const Vector&, const Vector&, int, int, int, int, float)') -- E9 ? ? ? ? 83 6C 24 ? ? E9 ? ? ? ? 83 E9 04 E9 ? ? ? ? 83 E9 04
local nativeAddSphereOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 2, 'void(__thiscall*)(void*, const Vector&, float, int, int, int, int, int, int, float)') -- 55 8B EC F3 0F 10 45 ? 8B 55 10
local nativeAddTriangleOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 3, 'void(__thiscall*)(void*, const Vector&, const Vector&, const Vector&, int, int, int, int, bool, float)') -- E9 ? ? ? ? 83 6C 24 ? ? E9 ? ? ? ? 83 6C 24 ? ?
local nativeAddWeirdBoxOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 4, 'void(__thiscall*)(void*, const Vector&, const Vector&, int, int, int, int, float, float)') -- 55 8B EC 83 EC 30 8B 45 0C
local nativeAddLineOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 5, 'void(__thiscall*)(void*, const Vector&, const Vector&, int, int, int, bool, float)') -- E9 ? ? ? ? 83 E9 04 E9 ? ? ? ? 83 6C 24 ? ? E9 ? ? ? ? 83 E9 04 E9 ? ? ? ? 83 E9 04
local nativeAddTextOverlayOffset = vtable_bind('engine.dll', 'VDebugOverlay004', 6, 'void(__cdecl*)(void*, const Vector&, int, float, const char*, ...)') -- 55 8B EC 56 57 8B 7D 08 8D 45 1C
local nativeAddTextOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 7, 'void(__cdecl*)(void*, const Vector&, float, const char*, ...)') -- E9 ? ? ? ? 83 6C 24 ? ? E9 ? ? ? ? CC
local nativeAddScreenTextOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 8, 'void(__thiscall*)(void*, float, float, float, int, int, int, int, const char*)') -- 55 8B EC FF 75 24
local nativeAddSweptBoxOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 9, 'void(__thiscall*)(void*, const Vector&, const Vector&, const Vector&, const Vector&, const Vector&, int, int, int, int, float)') -- 55 8B EC F3 0F 10 45 ? 8B 55 0C 51 8B 4D 08 F3 0F 11 04 24 FF 75 28
local nativeAddGridOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 10, 'void(__thiscall*)(void*, const Vector&)') -- 55 8B EC 8B 4D 08 E8 ? ? ? ? 5D C2 04 00 CC 55 8B EC 8B 55 10
local nativeAddCoordFrameOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 11, 'void(__thiscall*)(void*, float*, float, int*)') -- 55 8B EC 8B 55 10 F3 0F 10 4D ?
local nativeScreenPositionVector = vtable_bind('engine.dll', 'VDebugOverlay004', 13, 'int(__thiscall*)(void*, const Vector&, const Vector&)') -- 55 8B EC 8B 55 0C 8B 4D 08 E8 ? ? ? ? 5D C2 08 00 CC CC CC CC CC CC CC CC CC CC CC CC CC CC 55 8B EC 8B 4D 10
local nativeScreenPosition = vtable_bind('engine.dll', 'VDebugOverlay004', 12, 'int(__thiscall*)(void*, float, float, const Vector&)') -- 55 8B EC 8B 4D 10 F3 0F 10 4D ? 
local nativeGetFirst = vtable_bind('engine.dll', 'VDebugOverlay004', 14, 'void*(__thiscall*)(void*)') -- A1 ? ? ? ? C3 CC CC CC CC CC CC CC CC CC CC 55 8B EC 8B 45 08 8B 80 ? ? ? ?
local nativeGetNext = vtable_bind('engine.dll', 'VDebugOverlay004', 15, 'void*(__thiscall*)(void*, void*)') -- 55 8B EC 8B 45 08 8B 80 ? ? ? ? 5D
local nativeClearDeadOverlays = vtable_bind('engine.dll', 'VDebugOverlay004', 16, 'void(__thiscall*)(void*)') -- E9 ? ? ? ? CC CC CC CC CC CC CC CC CC CC CC E9 ? ? ? ? CC CC CC CC CC CC CC CC CC CC CC 55 8B EC F3 0F 10 45 ?
local nativeClearAllOverlays = vtable_bind('engine.dll', 'VDebugOverlay004', 17, 'void(__thiscall*)(void*)') -- E9 ? ? ? ? CC CC CC CC CC CC CC CC CC CC CC 55 8B EC F3 0F 10 45 ? 8B 55 0C 51
local nativeAddTextOverlayRGBFloat = vtable_bind('engine.dll', 'VDebugOverlay004', 18, 'void(__cdecl*)(void*, const Vector&, int, float, float, float, float, float, const char*, ...)') -- E9 ? ? ? ? 83 E9 04 E9 ? ? ? ? 83 E9 04 E9 ? ? ? ? 83 6C 24 ? ?
local nativeAddTextOverlayRGB = vtable_bind('engine.dll', 'VDebugOverlay004', 19, 'void(__cdecl*)(void*, const Vector&, int, float, int, int, int, int, const char*, ...)') -- 55 8B EC 56 57 8B 7D 08 8D 45 2C 50 51 FF 75 28 8D 77 08 89 87 ? ? ? ? BA ? ? ? ? 8B CE E8 ? ? ? ? 83 C4 0C 85 C0 78 07 3D ? ? ? ? 7C 07 C6 86 ? ? ? ? ? 66 0F 6E 45 ?
local nativeAddLineOverlayAlpha = vtable_bind('engine.dll', 'VDebugOverlay004', 20, 'void(__thiscall*)(void*, const Vector&, const Vector&, int, int, int, int, bool, float)') -- 55 8B EC F3 0F 10 45 ? 8B 55 0C 51 8B 4D 08 F3 0F 11 04 24 FF 75 20
local nativeAddBoxOverlayRetarded = vtable_bind('engine.dll', 'VDebugOverlay004', 21, 'void(__thiscall*)(void*, const Vector&, const Vector&, const Vector&, const Vector&, unsigned char*, unsigned char*, float)') -- 55 8B EC F3 0F 10 45 ? 8B 55 0C 51 8B 4D 08 F3 0F 11 04 24 FF 75 1C FF 75 18
local nativeAddLineOverlayWithAdjustableWidth = vtable_bind('engine.dll', 'VDebugOverlay004', 4, 'void(__thiscall*)(void*, const Vector&, const Vector&, int, int, int, int, float, float)') -- 55 8B EC 83 EC 30 8B 45 0C
local nativePurgeTextOverlays = vtable_bind('engine.dll', 'VDebugOverlay004', 22, 'void(__thiscall*)(void*)') -- E9 ? ? ? ? CC CC CC CC CC CC CC CC CC CC CC 55 8B EC F3 0F 10 45 ? 8B 55 0C 6A 00
local nativeAddCapsuleOverlay = vtable_bind('engine.dll', 'VDebugOverlay004', 23, 'void(__thiscall*)(void*,const Vector&, const Vector&, const float&, int, int, int, int, float)') -- 55 8B EC FF 75 2C
local nativeDrawPill = vtable_bind('engine.dll', 'VDebugOverlay004', 24, 'void(__thiscall*)(void*,const Vector&, const Vector&, const float&, int, int, int, int, float)') -- 55 8B EC F3 0F 10 45 ? 8B 55 0C 6A 00

local function vectorTransform(vec, matrix)
    return Vector(
            vec.x * matrix[0] + vec.y * matrix[1] + vec.z * matrix[2] + matrix[3],
            vec.x * matrix[4] + vec.y * matrix[5] + vec.z * matrix[6] + matrix[7],
            vec.x * matrix[8] + vec.y * matrix[9] + vec.z * matrix[10] + matrix[11]
    )
end

local function matrixAngles(matrix)
    local flDist = math.sqrt(matrix[0] * matrix[0] + matrix[4] * matrix[4])
    if flDist > 0.001 then
        return Vector(
                math.atan2(-matrix[8], flDist) * (180 / math.pi),
                math.atan2(matrix[4], matrix[0]) * (180 / math.pi),
                math.atan2(matrix[9], matrix[10]) * (180 / math.pi)
        )
    else
        return Vector(
                math.atan2(-matrix[8], flDist) * (180 / math.pi),
                math.atan2(-matrix[1], matrix[5]) * (180 / math.pi),
                0
        )
    end
end

local function getPlayerBoneMatrix(entIndex, boneIndex)
    local player = type(entIndex) == "number" and entity_list.get_entity(entIndex) or entIndex
    if player == nil then
        return
    end
    local pEntity = nativeGetClientEntity(player:get_index())
    local boneMatrix = ffi.cast(matrix3x4_t, ffi.cast("uintptr_t*", pEntity + 0x26A8)[0] + 0x30 * boneIndex)
    return boneMatrix
end

local function getPlayerHitboxStudioBbox(entIndex, hitboxes)
    -- UNSAFE! make sure that you have a valid player entity & valid hitboxes before calling this function!!!!!!!!!
    local player = type(entIndex) == "number" and entity_list.get_entity(entIndex) or entIndex
    if player == nil then
        return
    end
    local m_nModelIndex = player:get_prop("m_nModelIndex")
    local pModel = nativeGetModel(m_nModelIndex)
    if pModel == nil then
        return
    end
    local pStudioHdr = nativeGetStudioModel(pModel)
    if pStudioHdr == nil then
        return
    end
    local m_nHitboxSet = player:get_prop("m_nHitboxSet")
    local pHitboxSet = ffi.cast(StudioHitboxSet, ffi.cast("uintptr_t", pStudioHdr) + pStudioHdr.hitboxSetIndex) + m_nHitboxSet
    local ret = {}
    for _, v in ipairs(hitboxes) do
        ret[v % pHitboxSet.numHitboxes] = ffi.cast(StudioBbox, ffi.cast("uintptr_t", pHitboxSet) + pHitboxSet.hitboxIndex) + v % pHitboxSet.numHitboxes
    end
    return ret
end

local DebugOverlay
DebugOverlay = {
    AddEntityTextOverlay = function(iEntityIndex, iLineOffset, flDuration, r, g, b, a, fmt, ...)
        if type(iEntityIndex) == "userdata" then
            iEntityIndex = iEntityIndex:get_index()
        end
        nativeAddEntityTextOverlay(iEntityIndex, iLineOffset, flDuration, r, g, b, a, fmt, ...)
    end,
    AddBoxOverlay = function(vecOrigin, vecAbsMin, vecAbsMax, angOrientation, r, g, b, a, flDuration)
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        if type(vecAbsMin) ~= "cdata" then
            vecAbsMin = ffi.new("Vector", vecAbsMin)
        end
        if type(vecAbsMax) ~= "cdata" then
            vecAbsMax = ffi.new("Vector", vecAbsMax)
        end
        if type(angOrientation) ~= "cdata" then
            angOrientation = ffi.new("Vector", angOrientation)
        end
        nativeAddBoxOverlay(vecOrigin, vecAbsMin, vecAbsMax, angOrientation, r, g, b, a, flDuration)
    end,
    AddSphereOverlay = function(vecOrigin, flRadius, nTheta, nPhi, r, g, b, a, flDuration)
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        nativeAddSphereOverlay(vecOrigin, flRadius, nTheta, nPhi, r, g, b, a, flDuration)
    end,
    AddTriangleOverlay = function(p1, p2, p3, r, g, b, a, bNoDepthTest, flDuration)
        if type(p1) ~= "cdata" then
            p1 = ffi.new("Vector", p1)
        end
        if type(p2) ~= "cdata" then
            p2 = ffi.new("Vector", p2)
        end
        if type(p3) ~= "cdata" then
            p3 = ffi.new("Vector", p3)
        end
        nativeAddTriangleOverlay(p1, p2, p3, r, g, b, a, bNoDepthTest, flDuration)
    end,
    AddWeirdBoxOverlay = function(vecOrigin, vecDest, r, g, b, a, flThickness, flDuration)
        -- AKA AddLineOverlayWithAdjustableWidth
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        if type(vecDest) ~= "cdata" then
            vecDest = ffi.new("Vector", vecDest)
        end
        nativeAddWeirdBoxOverlay(vecOrigin, vecDest, r, g, b, a, flThickness, flDuration)
    end,
    AddLineOverlay = function(vecOrigin, vecDest, r, g, b, bNoDepthTest, flDuration)
        -- do not use this unless you are retarded
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        if type(vecDest) ~= "cdata" then
            vecDest = ffi.new("Vector", vecDest)
        end
        nativeAddLineOverlay(vecOrigin, vecDest, r, g, b, bNoDepthTest, flDuration)
    end,
    AddTextOverlayOffset = function(vecOrigin, iLineOffset, flDuration, fmt, ...)
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        nativeAddTextOverlayOffset(vecOrigin, iLineOffset, flDuration, fmt, ...)
    end,
    AddTextOverlay = function(vecOrigin, flDuration, fmt, ...)
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        nativeAddTextOverlay(vecOrigin, flDuration, fmt, ...)
    end,
    AddScreenTextOverlay = function(flXPos, flYPos, flDuration, r, g, b, a, szText)
        -- why will you ever want to use this?????
        -- [0-1]!!!!!!!!!
        nativeAddScreenTextOverlay(flXPos, flYPos, flDuration, r, g, b, a, szText)
    end,
    AddSweptBoxOverlay = function(vecStart, vecEnd, vecMin, vecMax, angles, r, g, b, a, flDuration)
        --untested
        if type(vecStart) ~= "cdata" then
            vecStart = ffi.new("Vector", vecStart)
        end
        if type(vecEnd) ~= "cdata" then
            vecEnd = ffi.new("Vector", vecEnd)
        end
        if type(vecMin) ~= "cdata" then
            vecMin = ffi.new("Vector", vecMin)
        end
        if type(vecMax) ~= "cdata" then
            vecMax = ffi.new("Vector", vecMax)
        end
        if type(angles) ~= "cdata" then
            angles = ffi.new("Vector", angles)
        end
        nativeAddSweptBoxOverlay(vecStart, vecEnd, vecMin, vecMax, angles, r, g, b, a, flDuration)
    end,
    AddGridOverlay = function(vecOrigin)
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        nativeAddGridOverlay(vecOrigin)
    end,
    AddCoordFrameOverlay = function(matFrame, flScale, vColorTable)
        --untested
        nativeAddCoordFrameOverlay(matFrame, flScale, vColorTable)
    end,
    ScreenPositionVector = function(vecPoint)
        local vecResult = ffi.new("Vector")
        if type(vecPoint) ~= "cdata" then
            vecPoint = ffi.new("Vector", vecPoint)
        end
        return nativeScreenPositionVector(vecPoint, vecResult), vecResult
    end,
    ScreenPosition = function(flXPos, flYPos)
        -- do not use this unless you are retarded
        local vecResult = ffi.new("Vector")
        return nativeScreenPosition(flXPos, flYPos, vecResult), vecResult
    end,
    GetFirst = function()
        return nativeGetFirst()
    end,
    GetNext = function(pCurrent)
        return nativeGetNext(pCurrent)
    end,
    ClearDeadOverlays = function()
        nativeClearDeadOverlays()
    end,
    ClearAllOverlays = function()
        nativeClearAllOverlays()
    end,
    AddTextOverlayRGBFloat = function(vecOrigin, iLineOffset, flDuration, r, g, b, a, fmt, ...)
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        nativeAddTextOverlayRGBFloat(vecOrigin, iLineOffset, flDuration, r, g, b, a, fmt, ...)
    end,
    AddTextOverlayRGB = function(vecOrigin, iLineOffset, flDuration, r, g, b, a, fmt, ...)
        -- the native function did not work for some reason xD
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        nativeAddTextOverlayRGBFloat(vecOrigin, iLineOffset, flDuration, r * 0.0039215689, g * 0.0039215689, b * 0.0039215689, a * 0.0039215689, fmt, ...)
    end,
    AddLineOverlayAlpha = function(vecOrigin, vecDest, r, g, b, a, bNoDepthTest, flDuration)
        -- this is why you should never ever fucking use AddLineOverlay
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        if type(vecDest) ~= "cdata" then
            vecDest = ffi.new("Vector", vecDest)
        end
        nativeAddLineOverlayAlpha(vecOrigin, vecDest, r, g, b, a, bNoDepthTest, flDuration)
    end,
    AddBoxOverlayRetarded = function(vecOrigin, vecAbsMin, vecAbsMax, angOrientation, faceColor, edgeColor, flDuration)
        -- did not test cuz it's retarded
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        if type(vecAbsMin) ~= "cdata" then
            vecAbsMin = ffi.new("Vector", vecAbsMin)
        end
        if type(vecAbsMax) ~= "cdata" then
            vecAbsMax = ffi.new("Vector", vecAbsMax)
        end
        if type(angOrientation) ~= "cdata" then
            angOrientation = ffi.new("Vector", angOrientation)
        end
        nativeAddBoxOverlayRetarded(vecOrigin, vecAbsMin, vecAbsMax, angOrientation, faceColor, edgeColor, flDuration)
    end,
    AddLineOverlayWithAdjustableWidth = function(vecOrigin, vecDest, r, g, b, a, flThickness, flDuration)
        -- AKA AddWeirdBoxOverlay, THEY ARE THE EXACT SAME, it got moved from index 22 to index 4 afaik
        if type(vecOrigin) ~= "cdata" then
            vecOrigin = ffi.new("Vector", vecOrigin)
        end
        if type(vecDest) ~= "cdata" then
            vecDest = ffi.new("Vector", vecDest)
        end
        nativeAddLineOverlayWithAdjustableWidth(vecOrigin, vecDest, r, g, b, a, flThickness, flDuration)
    end,
    PurgeTextOverlays = function()
        nativePurgeTextOverlays()
    end,
    AddCapsuleOverlay = function(vecAbsMin, vecAbsMax, flRadius, r, g, b, a, flDuration)
        -- AddCapsuleOverlay draws thru walls
        if type(vecAbsMin) ~= "cdata" then
            vecAbsMin = ffi.new("Vector", vecAbsMin)
        end
        if type(vecAbsMax) ~= "cdata" then
            vecAbsMax = ffi.new("Vector", vecAbsMax)
        end
        if type(flRadius) == "number" then
            flRadius = ffi.new("float[1]", flRadius)
        end
        nativeAddCapsuleOverlay(vecAbsMin, vecAbsMax, flRadius, r, g, b, a, flDuration)
    end,
    DrawPill = function(vecAbsMin, vecAbsMax, flRadius, r, g, b, a, flDuration)
        -- DrawPill does not
        if type(vecAbsMin) ~= "cdata" then
            vecAbsMin = ffi.new("Vector", vecAbsMin)
        end
        if type(vecAbsMax) ~= "cdata" then
            vecAbsMax = ffi.new("Vector", vecAbsMax)
        end
        if type(flRadius) == "number" then
            flRadius = ffi.new("float[1]", flRadius)
        end
        nativeDrawPill(vecAbsMin, vecAbsMax, flRadius, r, g, b, a, flDuration)
    end,
    Utils = {
        VectorTransform = function(vec, matrix)
            return vectorTransform(vec, matrix)
        end,
        MatrixAngles = function(matrix)
            return matrixAngles(matrix)
        end,
        GetPlayerBoneMatrix = function(entIndex, boneIndex)
            return getPlayerBoneMatrix(entIndex, boneIndex)
        end,
        getPlayerHitboxStudioBbox = function(entIndex, hitboxes)
            return getPlayerHitboxStudioBbox(entIndex, hitboxes)
        end
    },
    DrawHitboxes = function(entIndex, hitboxes, r, g, b, a, duration)
        local hitboxes = getPlayerHitboxStudioBbox(entIndex, hitboxes)
        if hitboxes == nil then
            return
        end
        for i, v in pairs(hitboxes) do
            local boneMatrix = getPlayerBoneMatrix(entIndex, v.bone)
            if boneMatrix ~= nil then
                if v.capsuleRadius == -1 then
                    DebugOverlay.AddBoxOverlay(Vector(boneMatrix[3], boneMatrix[7], boneMatrix[11]), v.bbMin, v.bbMax, matrixAngles(boneMatrix), r, g, b, a, duration)
                else
                    DebugOverlay.AddCapsuleOverlay(vectorTransform(v.bbMin, boneMatrix), vectorTransform(v.bbMax, boneMatrix), v.capsuleRadius, r, g, b, a, duration)
                end
            end
        end

    end
}

return DebugOverlay
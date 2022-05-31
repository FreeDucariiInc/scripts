local ffi = require("ffi")

ffi.cdef[[

	void XMScalarSinCos(float *pSin,float *pCos,float Value);
	float XMConvertToRadians(float fDegrees);
	float XMConvertToDegrees(float fRadians);
	
	typedef struct 
	{
		float x,y,z;
	} Vector;
	
	typedef struct 
	{
		Vector v;
		float w;
	} VectorAligned;
	
	typedef struct 
	{
		Vector normal;
		float dist;
		uint8_t type;   // for fast side tests
		uint8_t signbits;  // signx + (signy<<1) + (signz<<1)
		uint8_t pad[2];

	} cplane_t;
	
	typedef struct 
	{
		const char     *name;
		short          surfaceProps;
		unsigned short flags;         // BUGBUG: These are declared per surface, not per material, but this database is per-material now
	} csurface_t;

	typedef struct 
	{


		// these members are aligned!!
		Vector         startpos;            // start position
		Vector         endpos;              // final position
		cplane_t       plane;               // surface normal at impact

		float          fraction;            // time completed, 1.0 = didn't hit anything
		int            contents;            // contents on other side of surface hit
		uint16_t dispFlags;           // displacement flags for marking surfaces with data

		bool           allsolid;            // if true, plane is not valid
		bool           startsolid;          // if true, the initial point was in a solid area
	} CBaseTrace;
	
	
	typedef struct 
	{
		CBaseTrace 			BaseTrace;
		float               fractionleftsolid;  // time we left a solid, only valid if we started in solid
		csurface_t          surface;            // surface hit (impact surface)
		int                 hitgroup;           // 0 == generic, non-zero is specific body part
		short               physicsbone;        // physics bone hit by trace in studio
		uint16_t     		worldSurfaceIndex;  // Index of the msurface2_t, if applicable
		uint32_t      		hit_entity;
		int                 hitbox;                       // box hit by trace in studio
	} CGameTrace;
	
	typedef struct 
	{
		VectorAligned  m_Start;  // starting point, centered within the extents
		VectorAligned  m_Delta;  // direction + length of the ray
		VectorAligned  m_StartOffset; // Add this to m_Start to Get the actual ray start
		VectorAligned  m_Extents;     // Describes an axis aligned box extruded along a ray
		uint32_t m_pWorldAxisTransform;
		bool m_IsRay;  // are the extents zero?
		bool m_IsSwept;     // is delta != 0?
	
	} Ray_t;
]]

local IEngineTrace = memory.create_interface("engine.dll","EngineTraceClient004")
local ClipRayToEntity = ffi.cast("void(__thiscall*)(uint32_t thisptr,const Ray_t &ray, uint32_t fMask, uint32_t EntityAddress, CGameTrace *pTrace)",memory.get_vfunc(IEngineTrace , 3))


local IUniformRandomStream = memory.create_interface("engine.dll","VEngineRandom001")
local SetSeed = ffi.cast("void(__thiscall*)(uint32_t,int iSeed)",memory.get_vfunc(IUniformRandomStream , 0))
local RandomFloat = ffi.cast("float(__thiscall*)(uint32_t,float flMinVal, float flMaxVal)",memory.get_vfunc(IUniformRandomStream , 1))
local RandomInt = ffi.cast("int(__thiscall*)(uint32_t,int flMinVal, int flMaxVal)",memory.get_vfunc(IUniformRandomStream , 2))

local UpdateAccuracyPenalty = ffi.cast("void(__thiscall*)(uint32_t)",memory.find_pattern("client.dll","55 8B EC 83 E4 F8 83 EC 18 56 57 8B F9 8B 8F 40 32 00 00 83 F9 FF 74 27"))

local M_PI = 3.14159265358979323846
local PI_2 = M_PI * 2.0

local enable = menu.add_checkbox("Legitbot", "Enable")
local enable_bind = enable:add_keybind("Legitbot")
local fov = menu.add_slider("Legitbot", "Field of view", 1.0, 180.0)
local smooth = menu.add_slider("Legitbot", "Smoothness", 1.0, 100.0)
local hit_chance = menu.add_slider("Legitbot", "Hitchance", 1.0, 100.0)
local prefer_baim = menu.add_checkbox("Legitbot", "Prefer Body Aim")

local trace_mask = 0x46004003
local recoil_scale = 2.0
local Computed_Seeds = { }
-- local function GetVFunction(instance,index)
	-- local pVTable = ffi.cast("int* ",ffi.cast("int**",instance))
-- end

local function DumpTable(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. DumpTable(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local Hitboxes_Normal = {
	e_hitboxes.HEAD			    ,
	e_hitboxes.NECK	            ,
	
	e_hitboxes.UPPER_CHEST	    ,
	e_hitboxes.CHEST	        ,
	e_hitboxes.THORAX	        ,
	e_hitboxes.BODY	            ,
	e_hitboxes.PELVIS	        
}

local Hitboxes_BodyAim = {
	
	e_hitboxes.UPPER_CHEST	    ,
	e_hitboxes.CHEST	        ,
	e_hitboxes.THORAX	        ,
	e_hitboxes.BODY	            ,
	e_hitboxes.PELVIS	        ,
	
	e_hitboxes.NECK	            ,
	e_hitboxes.HEAD			    
	
}

local function VectorSubstract(Vec1,Vec2) -- Vector
	local NewVector = ffi.new("Vector",{})
	NewVector.x = Vec1.x - Vec2.x
	NewVector.y = Vec1.y - Vec2.y
	NewVector.z = Vec1.z - Vec2.z
	return NewVector
end

local function VectorSubstract2(Vec1,Vec2) -- VectorAligned
	local NewVector = ffi.new("VectorAligned",{})
	NewVector.v.x = Vec1.x - Vec2.x
	NewVector.v.y = Vec1.y - Vec2.y
	NewVector.v.z = Vec1.z - Vec2.z
	
	return NewVector
end



local function VectorLengthSqr(Vector) -- float
	return (Vector.x * Vector.x + Vector.y * Vector.y + Vector.z * Vector.z)
end

local function VectorLengthSqr2(Vector) -- float
	return (Vector.v.x * Vector.v.x + Vector.v.y * Vector.v.y + Vector.v.z * Vector.v.z)
end

local function InitializeRay(Ray,VecStart,VecEnd)
		Ray.m_Delta = VectorSubstract2(VecEnd,VecStart)
        Ray.m_IsSwept = (VectorLengthSqr2(Ray.m_Delta) ~= 0)

        -- m_Extents.Init();
		local extents = Ray.m_Extents.v
		extents.x = 0.0
		extents.y = 0.0
		extents.z = 0.0
		
        Ray.m_pWorldAxisTransform = 0
        Ray.m_IsRay = true

        -- // Offset m_Start to be in the center of the box...
		
		local startoffset = Ray.m_StartOffset.v
		startoffset.x = 0.0
		startoffset.y = 0.0
		startoffset.z = 0.0

        Ray.m_Start.v = ffi.new("Vector",{VecStart.x,VecStart.y,VecStart.z})
end

local function BuiltInVecToCustom(BuiltInVec)
	local NewVector = ffi.new("Vector",{})
	NewVector.x = BuiltInVec.x
	NewVector.y = BuiltInVec.y
	NewVector.z = BuiltInVec.z
	return NewVector
end

local function AngleVectors(Angle) 
	local sr = ffi.new("float[1]",{})
	local sp = ffi.new("float[1]",{})
	local sy = ffi.new("float[1]",{})
	
	local cr = ffi.new("float[1]",{})
	local cp = ffi.new("float[1]",{})
	local cy = ffi.new("float[1]",{})
	
	local forward = ffi.new("Vector",{})
	local right = ffi.new("Vector",{})
	local up = ffi.new("Vector",{})
	
	sp[0] = math.sin(math.rad(Angle.x))
	cp[0] = math.cos(math.rad(Angle.x))
	
	sy[0] = math.sin(math.rad(Angle.y))
	cy[0] = math.cos(math.rad(Angle.y))
	
	sr[0] = math.sin(math.rad(Angle.z))
	cr[0] = math.cos(math.rad(Angle.z))
	
	forward.x = (cp[0] * cy[0])
	forward.y = (cp[0] * sy[0])
	forward.z = (-sp[0])
	right.x = (-1 * sr[0] * sp[0] * cy[0] + -1 * cr[0] * -sy[0])
	right.y = (-1 * sr[0] * sp[0] * sy[0] + -1 * cr[0] *  cy[0])
	right.z = (-1 * sr[0] * cp[0])
	up.x = (cr[0] * sp[0] * cy[0] + -sr[0]*-sy[0])
	up.y = (cr[0] * sp[0] * sy[0] + -sr[0]*cy[0])
	up.z = (cr[0] * cp[0])
	
	return { forward, right, up }
end

local function AngleVectorsForward(Angle) 
	local sr = ffi.new("float[1]",{})
	local sp = ffi.new("float[1]",{})
	local sy = ffi.new("float[1]",{})
	
	local cr = ffi.new("float[1]",{})
	local cp = ffi.new("float[1]",{})
	local cy = ffi.new("float[1]",{})
	
	local forward = ffi.new("Vector",{})

	sp[0] = math.sin(math.rad(Angle.x))
	cp[0] = math.cos(math.rad(Angle.x))
	
	sy[0] = math.sin(math.rad(Angle.y))
	cy[0] = math.cos(math.rad(Angle.y))
	
	sr[0] = math.sin(math.rad(Angle.z))
	cr[0] = math.cos(math.rad(Angle.z))
	
	forward.x = (cp[0] * cy[0])
	forward.y = (cp[0] * sy[0])
	forward.z = (-sp[0])

	return forward
end

local function NormalizeVector(Vector)
	local NewVector = ffi.new("Vector",{Vector.x,Vector.y,Vector.z})
	local l = math.sqrt(NewVector.x * NewVector.x + NewVector.y * NewVector.y + NewVector.z * NewVector.z)
	
	if l ~= 0.0 then
		NewVector.x = NewVector.x / l
		NewVector.y = NewVector.y / l
		NewVector.z = NewVector.z / l
	else
		NewVector.x = 0.0
		NewVector.y = 0.0
		NewVector.z = 0.0
	end
	return NewVector
end

local function NormalizeAngles(Angle)

	while (Angle.x > 89.0) do
		Angle.x = Angle.x - 180.0;
  end
  
	while (Angle.x < -89.0) do
		Angle.x = Angle.x + 180.0;
  end
  
	while (Angle.y  > 180.0) do
		Angle.y = Angle.y - 360.0;
  end
  
	while (Angle.y  < -180.0) do
		Angle.y = Angle.y + 360.0;
  end
  
	Angle.z = 0.0;
		
	return ffi.new("Vector",{Angle.x,Angle.y,Angle.z})
end

local function SmoothAngle( from , to , percent )
	local VecDelta = ffi.new("Vector",VectorSubstract(from,to))
	VecDelta = NormalizeAngles(VecDelta)
	VecDelta.x = VecDelta.x * ( percent / 100.0 )
	VecDelta.y = VecDelta.y * ( percent / 100.0 )
	
	return ffi.new("Vector",VectorSubstract(from,VecDelta))
end

local function CalcAngle(src,dst)
	local vAngle = ffi.new("Vector",{})
	local delta  = ffi.new("Vector",{src.x - dst.x,src.y - dst.y,src.z - dst.z})
	local hyp	 = math.sqrt(delta.x*delta.x + delta.y * delta.y)
	
	vAngle.x = math.atan(delta.z / hyp) * 57.295779513082
	vAngle.y = math.atan(delta.y / delta.x) * 57.295779513082
	vAngle.z = 0.0
	
	if (delta.x >= 0.0) then
		vAngle.y = vAngle.y + 180.0
	end
	
	vAngle = NormalizeAngles(vAngle)
	return vAngle
end

local function GetFOV(viewAngle,aimAngle)
	local aim = ffi.new("Vector",AngleVectorsForward(viewAngle))
	local ang = ffi.new("Vector",AngleVectorsForward(aimAngle))
	
	local res = math.deg(math.acos((aim.x * ang.x + aim.y * ang.y + aim.z * ang.z )/(aim.x * aim.x + aim.y * aim.y + aim.z * aim.z)))

	if res ~= res then
		res = 0.0
	end
	return res
end

local function IsValidHitGroup(index)

	if ((index >= 0 and index <= 7) or index == 10) then
		return true
	end
	
	return false
end

local function CalculateSpread(weapon,seed,inaccuracy,spread)
	local r1, r2, r3, r4, s1, c1, s2, c2;
	
	-- print("Bullets ",weapon:get_weapon_data().bullets)
	
	if not weapon or not weapon:get_weapon_data().bullets then -- no spread
		return ffi.new("Vector",{})
	end
	
	-- SetSeed(IUniformRandomStream , ffi.new("int",bit.band(seed,0xff) + 1))
	
	-- r1 = RandomFloat(IUniformRandomStream , 0.0,1.0)
	-- r2 = RandomFloat(IUniformRandomStream , 0.0,PI_2)
	-- r3 = RandomFloat(IUniformRandomStream , 0.0,1.0)
	-- r4 = RandomFloat(IUniformRandomStream , 0.0,PI_2)
	
	-- print(DumpTable(Computed_Seeds))
	
	r1 = Computed_Seeds[seed+1][1]
	r2 = Computed_Seeds[seed+1][2]
	r3 = Computed_Seeds[seed+1][3]
	r4 = Computed_Seeds[seed+1][4]
	
	
	
	-- print("random nums:",r1,r2,r3,r4)
	
	c1 = math.cos(r2)
	c2 = math.cos(r4)
	s1 = math.sin(r2)
	s2 = math.sin(r4)
	
	return ffi.new("Vector",{
		(c1 * (r1 * inaccuracy)) + (c2 * (r3 * spread)),
		(s1 * (r1 * inaccuracy)) + (s2 * (r3 * spread)),
		0.0
	})
end

local HITCHANCE_MAX = 100.0
local SEED_MAX		= 255

local function CheckHitchance(cmd,targetPlayer,hitbox_id)
	local lp 		= entity_list.get_local_player()
	local lp_weapon = lp:get_active_weapon()
	local lp_eyepos = lp:get_eye_position()
	
	local va 		= cmd.viewangles
	local Vectors 	= AngleVectors(ffi.new("Vector",{va.x,va.y,va.z})) --forward,right,up
	
	if lp_weapon:get_address() then
		UpdateAccuracyPenalty(lp_weapon:get_address())
	end
	
	local inaccuracy 	= lp_weapon:get_weapon_inaccuracy()
	local spread 		= lp_weapon:get_weapon_spread()
	
	-- print(DumpTable(Vectors))
	
	local total_hits = 0
	local needed_hits = math.ceil((hit_chance:get() * SEED_MAX)/HITCHANCE_MAX)
	for seed=0,SEED_MAX do
		
		local wep_spread = CalculateSpread(lp_weapon,seed,inaccuracy,spread)
		local dir = NormalizeVector(ffi.new("Vector",
		{
			Vectors[1].x + (Vectors[2].x * wep_spread.x) + (Vectors[3].x * wep_spread.y),
			Vectors[1].y + (Vectors[2].y * wep_spread.x) + (Vectors[3].y * wep_spread.y),
			Vectors[1].z + (Vectors[2].z * wep_spread.x) + (Vectors[3].z * wep_spread.y)
		}))
		
		local EndVec = ffi.new("Vector",
		{
			lp_eyepos.x + (dir.x * 8192.0),
			lp_eyepos.y + (dir.y * 8192.0),
			lp_eyepos.z + (dir.z * 8192.0)
		})
		local Ray = ffi.new("Ray_t",{})
		local Trace = ffi.new("CGameTrace[1]",{})
		
		InitializeRay(Ray,lp_eyepos,EndVec)
		ClipRayToEntity(IEngineTrace,Ray,trace_mask,targetPlayer:get_address(),Trace)
		-- print("Trace Hitbox",Trace[0].hitbox)
		-- print("hitbox_id",hitbox_id)
		if Trace[0].hit_entity == targetPlayer:get_address() and IsValidHitGroup(Trace[0].hitgroup) then
			total_hits = total_hits + 1
		end
		
		--we made it.
		if (total_hits >= needed_hits) then
			return true
		end
		
		-- we cant make it anymore.
		if ((SEED_MAX - seed + total_hits) < needed_hits) then
			return false
		end	
	end
	
	return false
end

local function FindVisibleHitbox(localplayer,targetPlayer)
	local Hitbox_Order
	local eye_pos = localplayer:get_eye_position()
	if not prefer_baim:get() then
		Hitbox_Order = Hitboxes_Normal
	else
		Hitbox_Order = Hitboxes_BodyAim
	end
	
	for _,hitbox in pairs(Hitbox_Order) do 
		local Hitbox_Pos = targetPlayer:get_hitbox_pos(hitbox)
		
		local trace_result = trace.line(eye_pos, Hitbox_Pos, localplayer,trace_mask)
		-- print(trace_result.fraction)
		if trace_result.entity == targetPlayer or trace_result.fraction > 0.97 then
			return { Hitbox_Pos , hitbox }
		end
	end
end

local function GetNearestEnemyToFOV()
	local enemies_only = entity_list.get_players(true)
	local local_player = entity_list.get_local_player()
	local local_eyepos = local_player:get_eye_position()
	local engine_angle = engine.get_view_angles()
  
  local AngBetEnt = 180.0
  
	local nearest_entity
	
	for _,player in pairs(enemies_only) do
		(
			function()
				if not player:is_alive() or player:is_dormant() or not FindVisibleHitbox(local_player,player) then
					return
				end
				
				local enemy_eyepos = player:get_eye_position()
				
				local angleToTarget = CalcAngle(local_eyepos,enemy_eyepos)
				local TempAngle = GetFOV(engine_angle,angleToTarget)
        
				if ( TempAngle <= fov:get() and TempAngle <= AngBetEnt) then
					AngBetEnt = TempAngle
					nearest_entity = player
				end
        
			end
		)()
	end
  return nearest_entity
end


local function Triggerbot(cmd,target,hitbox_id)
	if client.can_fire() then
		if CheckHitchance(cmd,target,hitbox_id) then
			cmd:add_button(e_cmd_buttons.ATTACK)
		else
		
		end
	end
end

local function RunAimbot(cmd)
	local local_player = entity_list.get_local_player()
	
	if not local_player or not engine.is_in_game() or not engine.is_connected() or not local_player:is_alive() or not enable:get() or not enable_bind:get() then
		return
	end
  
  local target = GetNearestEnemyToFOV()
  
  if not target then
    return
  end
  
  local target_hitbox = FindVisibleHitbox(local_player,target)
  local hitbox_id = target_hitbox[2]
  local engine_angle = engine.get_view_angles()
  local target_angle = CalcAngle(local_player:get_eye_position(),target_hitbox[1])
  
  
  local m_aimPunchAngle = ffi.cast("Vector*",ffi.cast("uint32_t",local_player:get_address() + 0x303C))[0]
  -- print("m_aimPunchAngle.x" , m_aimPunchAngle.x)
  -- print("m_aimPunchAngle.y" , m_aimPunchAngle.y)
  target_angle.x = target_angle.x - ( m_aimPunchAngle.x * recoil_scale )
  target_angle.y = target_angle.y - ( m_aimPunchAngle.y * recoil_scale )
  
  target_angle = SmoothAngle(engine_angle,target_angle,math.abs(smooth:get() - 101.0))
  
  cmd.viewangles = angle_t(target_angle.x,target_angle.y,target_angle.z)  
  engine.set_view_angles(angle_t(target_angle.x,target_angle.y,target_angle.z))
  
  Triggerbot(cmd,target,hitbox_id)
end

local function PrecomputeSeed()
	
	
	for seed=0,SEED_MAX do
	
		local random_values = { }
	
		SetSeed(IUniformRandomStream , ffi.new("int",bit.band(seed,0xff) + 1))
	
		table.insert(random_values,RandomFloat(IUniformRandomStream , 0.0,1.0))
		table.insert(random_values,RandomFloat(IUniformRandomStream , 0.0,PI_2))
		table.insert(random_values,RandomFloat(IUniformRandomStream , 0.0,1.0))
		table.insert(random_values,RandomFloat(IUniformRandomStream , 0.0,PI_2))
		
		
		table.insert(Computed_Seeds,random_values)
	end
	
end

local function on_event(event)
	if event.name == "round_start" then
		print("[Legitbot] Getting recoil scale")
		recoil_scale = cvars.weapon_recoil_scale:get_float()
	end
end


PrecomputeSeed()
callbacks.add(e_callbacks.SETUP_COMMAND, RunAimbot)
callbacks.add(e_callbacks.EVENT, on_event) -- community servers?

local stupid_ref,fake_duck_ref = unpack(menu.find("antiaim", "main", "general", "fake duck"))

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
    if local_player:get_prop("m_flDuckAmount")>0.6 then
        ctx:set_fakelag(false)
    else
        ctx:set_fakelag(true)
    end
end

callbacks.add(e_callbacks.ANTIAIM, on_antiaim)
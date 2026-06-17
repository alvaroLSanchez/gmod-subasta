
util.AddNetworkString("set_third_person")
util.AddNetworkString("add_effect")
util.AddNetworkString("remove_effect")
util.AddNetworkString("set_frozen")
util.AddNetworkString("set_ragdoll")
util.AddNetworkString("ragdoll_position")

local initial_grados = {[1] = 40, [2] = 40}

local grados

function get_grados()
  return grados
end

function init_grados()
  grados = {[1] = 40, [2] = 40}
end

local applied_effects = {} -- key: SteamID64. value: seq Table ({effect = Player Efect, data = Effect Data})

function get_applied_effects()
  return applied_effects
end

function random_timing_effect(ply, interval, timer_prefix, effect_function)
  timer.Create(timer_prefix .. ply:SteamID64(), interval, 0, effect_function)
end

function cleanup_random_timing_effect(ply, timer_prefix)
  timer.Remove(timer_prefix .. ply:SteamID64())
end

function ragdoll_player(ply, duration)
  if not IsValid(ply) or not ply:Alive() then return end
  
  -- 1. Create the ragdoll and hide the player
  ply:CreateRagdoll()
  ply:SetNoDraw(true)
  ply:SetNotSolid(true)
  ply:GodEnable(true) -- Prevents the player from dying to world damage while limp
  ply:Freeze(true)

  net.Start("set_ragdoll")
  net.WriteBool(true)
  net.Send(ply)

  local rag = ply:GetRagdollEntity()
  -- 2. Restore the player after the duration
  timer.Create("ragdoll_timer" .. ply:SteamID64(), duration, 1, function()
    if IsValid(ply) and IsValid(rag) then
      -- Teleport player to the ragdoll's location
      --ply:SetPos(rag:GetPos())
      
      -- Remove ragdoll and unhide player
      rag:Remove()
      ply:SetNoDraw(false)
      ply:SetNotSolid(false)
      ply:GodDisable(false)
      
      net.Start("set_ragdoll")
      net.WriteBool(false)
      net.Send(ply)
    end
  end)
end

net.Receive("ragdoll_position", function(len, ply)
  local position = net.ReadVector()
  ply:SetPos(position)
  ply:Freeze(false)
end)

function ragdoll_function(ply, data)

  local chance = 1/1
  
  random_timing_effect(ply, 10, "ragdoll_chance_timer", function()
    local dice_roll = math.random()
    if dice_roll <= chance then
      ragdoll_player(ply, 3) -- Ragdoll for 3 seconds
    end
  end)
end

function ragdoll_cleanup(ply, data)
  cleanup_random_timing_effect(ply, "ragdoll_chance_timer")
end

function apply_frostbite(ply, duration)

  local ent = ents.Create("ice_cube")

  -- Sets the position of the entity
  ent:SetPos(ply:GetPos() + Vector(0,0,48))
  -- Sets the angle of the entity
  --ent:SetAngles(Angle(0.0, 90.0, 0.0)) 
  -- Spawns the entity on all clients
  --ent:SetParent(ply)
  ent:SetNWEntity("frozen_player", ply)
  ent:Spawn()
  net.Start("set_frozen")
  net.WriteBool(true)
  net.Send(ply)
  ply:SetFriction(0)
  ply:Freeze(true)
  timer.Create("frostbite_timer" .. ply:SteamID64(), duration, 1, function()
    if IsValid(ply) then
      ent:Remove()
      net.Start("set_frozen")
      net.WriteBool(false)
      net.Send(ply)
      ply:SetFriction(1)
      ply:Freeze(false)
    end
  end)
end

function frostbite_function(ply, data)

  local chance = 1/1
  
  random_timing_effect(ply, 10, "frostbite_chance_timer", function()
    local dice_roll = math.random()
    if dice_roll <= chance then
      apply_frostbite(ply, 3) -- Frostbite for 3 seconds
    end
  end)
end

function frostbite_cleanup(ply, data)
  cleanup_random_timing_effect(ply, "frostbite_chance_timer")
end

function low_grav_function(ply, data)
  data.old_gravity = ply:GetGravity()
  ply:SetGravity(0.5)
end

function low_grav_cleanup(ply, data)
  ply:SetGravity(data.old_gravity or 1)
end

function high_grav_function(ply, data)
  data.old_gravity = ply:GetGravity()
  ply:SetGravity(1.3)
end

function high_grav_cleanup(ply, data)
  ply:SetGravity(data.old_gravity or 1)
  ply:SetGravity(1)
end


function speedup_function(ply, data)
  data.old_walk_speed = ply:GetWalkSpeed()
  data.old_slow_walk_speed = ply:GetSlowWalkSpeed()
  data.old_run_speed = ply:GetRunSpeed()
  ply:SetWalkSpeed(data.old_walk_speed*1.15)
  ply:SetRunSpeed(data.old_run_speed*1.15)
  ply:SetSlowWalkSpeed(data.old_slow_walk_speed*1.15)
end

function speedup_cleanup(ply, data)
  ply:SetWalkSpeed(data.old_walk_speed or 200)
  ply:SetRunSpeed(data.old_run_speed or 500)
  ply:SetSlowWalkSpeed(data.old_slow_walk_speed or 100)
end


local player_effects = {
  golpe_de_calor = {
    display_name = "Golpe de calor",
    run = ragdoll_function,
    clean_up = ragdoll_cleanup
  },
  frostbite = {
    display_name = "Frostbite",
    run = frostbite_function,
    clean_up = frostbite_cleanup
  },
  corrientes_mediterraneas = {
    display_name = "Corrientes mediterráneas",
    run = low_grav_function,
    clean_up = low_grav_cleanup
  },
  nieve_pesada = {
    display_name = "Nieve pesada",
    run = high_grav_function,
    clean_up = high_grav_cleanup
  },
  brisa_fresca = {
    display_name = "Brisa fresca",
    run = speedup_function,
    clean_up = speedup_cleanup
  },
  sangre_caliente = {
    display_name = "Sangre caliente",
    run = speedup_function,
    clean_up = speedup_cleanup
  }
}

function get_effects()
  return player_effects
end

local cards = {
  desmayo = {
    display_name = "Desmayo",
    description_verano = "Los jugadores se caerán al suelo aleatoriamente",
    id_verano = "golpe_de_calor",
    description_invierno = "Los jugadores se congelarán aleatoriamente, deslizandose por el suelo",
    id_invierno = "frostbite",
    kind = "curse"
  },
  gravedad_rara = {
    display_name = "Gravedad Rara",
    description_verano = "El equipo Verano tendrá gravedad reducida!",
    id_verano = "corrientes_mediterraneas",
    description_invierno = "El equipo Invierno tendrá gravedad aumentada!",
    id_invierno = "nieve_pesada",
    kind = "curse"
  },
  brio = {
    display_name = "Brío",
    description_verano = "El equipo verano será 1.15x más rápido hasta la próxima subasta",
    id_verano = "brisa_fresca",
    description_invierno = "El equipo invierno será 1.15x más rápido hasta la próxima subasta",
    id_invierno = "sangre_caliente",
    kind = "blessing"
  }
}

function get_cards()
  return cards
end

function apply_effect(ply, effect)
  local effect_data = {} -- Per-player, per-effect table to store arbitrary state.

  if get_applied_effects()[ply:SteamID64()] == nil then
    get_applied_effects()[ply:SteamID64()] = {}
  end
  local ply_applied_effects = get_applied_effects()[ply:SteamID64()]
  
  if ply_applied_effects then 
    for k, v in pairs(ply_applied_effects) do
      if effect == v.effect then
        error("Tried to apply duplicate effect!")
        return
      end
    end
  end

  table.insert(ply_applied_effects, {effect = effect, data = effect_data})
  print(dump(get_applied_effects()))
  effect.run(ply, effect_data)
end

function remove_effect(ply, effect)
  print(dump(get_applied_effects()))
  local ply_applied_effects = get_applied_effects()[ply:SteamID64()]
  if ply_applied_effects then 
    for k, v in pairs(ply_applied_effects) do
      print(v.data)
      if effect == v.effect then
        if effect.clean_up then effect.clean_up(ply, v.data) end
        ply_applied_effects[k] = nil
      end
    end
  end
end



gameevent.Listen( "player_say" )
hook.Add( "player_say", "apply effect", function( data ) 
	local priority = SERVER and data.Priority or 1 	// Priority ??
	local id = data.userid				// Same as Player:UserID() for the speaker
	local text = data.text				// The written text.
  if string.StartsWith(text,"/apply_effect ") and get_round_status() == 1 then
    local effect_name = string.Split(text, " ")[2]
    print(effect_name)
    local ply = Player(id)
    apply_effect(ply, player_effects[effect_name])
  end
end)

hook.Add( "player_say", "remove effect", function( data ) 
	local priority = SERVER and data.Priority or 1 	// Priority ??
	local id = data.userid				// Same as Player:UserID() for the speaker
	local text = data.text				// The written text.
  if string.StartsWith(text,"/remove_effect ") and get_round_status() == 1 then
    local effect_name = string.Split(text, " ")[2]
    local ply = Player(id)
    print("HUH", player_effects[effect_name].display_name)
    remove_effect(ply, player_effects[effect_name])
  end
end)

hook.Add("player_say", "end round", function( data ) 
	local priority = SERVER and data.Priority or 1 	// Priority ??
	local id = data.userid				// Same as Player:UserID() for the speaker
	local text = data.text				// The written text.
  if string.StartsWith(text,"/end_round ") and get_round_status() == 1 then
    end_round()
  end
end)



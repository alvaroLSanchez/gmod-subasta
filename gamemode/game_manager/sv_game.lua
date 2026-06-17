
util.AddNetworkString("set_third_person")
util.AddNetworkString("add_effect")
util.AddNetworkString("remove_effect")
util.AddNetworkString("set_frozen")
util.AddNetworkString("set_ragdoll")
util.AddNetworkString("ragdoll_position")


local grados = {[1] = 40, [2] = 40}

local applied_effects = {} -- key: userid. value: seq Table (player_effect)

function get_applied_effects()
  return applied_effects
end

function get_grados()
  return grados
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
  timer.Create("ragdoll_timer" .. ply:UserID(), duration, 1, function()
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

function ragdoll_function(ply)

  local chance = 1/30
  
  random_timing_effect(ply, 10, "ragdoll_chance_timer", function()
    local dice_roll = math.random()
    if dice_roll <= chance then
      ragdoll_player(ply, 3) -- Ragdoll for 3 seconds
    end
  end)
end

function ragdoll_cleanup(ply)
  cleanup_random_timing_effect(ply, "ragdoll_chance_timer")
end

function apply_frostbite(ply)
  local duration = 3

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
  timer.Create("frostbite_timer" .. ply:UserID(), duration, 1, function()
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

function frostbite_function(ply)

  local chance = 1/30
  
  random_timing_effect(ply, 10, "frostbite_chance_timer", function()
    local dice_roll = math.random()
    if dice_roll <= chance then
      ragdoll_player(ply, 3) -- Ragdoll for 3 seconds
    end
  end)
end

function low_grav_function(ply)
  local old_gravity = ply:GetGravity()
  ply:SetGravity(0.5)
end

function low_grav_cleanup(ply)
  ply:SetGravity(1)
end
function high_grav_cleanup(ply)
  ply:SetGravity(1)
end

function high_grav_function(ply)
  local old_gravity = ply:GetGravity()
  ply:SetGravity(1.3)
end


local player_effects = {
  golpe_de_calor = {
    display_name = "Golpe de calor",
    run = ragdoll_function
  },
  frostbite = {
    display_name = "frostbite",
    run = frostbite_function
  },
  corrientes_mediterraneas = {
    display_name = "Corrientes Mediterráneas",
    run = low_grav_function,
    clean_up = low_grav_cleanup
  },
  nieve_pesada = {
    display_name = "Nieve Pesada",
    run = high_grav_function,
    clean_up = high_grav_cleanup,
  }
}

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
  }
}

function get_cards()
  return cards
end

function get_effects()
  return player_effects
end


gameevent.Listen( "player_say" )
hook.Add( "player_say", "apply_effect", function( data ) 
	local priority = SERVER and data.Priority or 1 	// Priority ??
	local id = data.userid				// Same as Player:UserID() for the speaker
	local text = data.text				// The written text.
  if string.StartsWith(text,"/apply_effect ") and get_round_status() == 1 then
    local effect_name = string.Split(text, " ")[2]
    print(effect_name)
    local ply = Player(id)
    player_effects[effect_name].run(ply)
  end
end)

hook.Add( "player_say", "remove_effect", function( data ) 
	local priority = SERVER and data.Priority or 1 	// Priority ??
	local id = data.userid				// Same as Player:UserID() for the speaker
	local text = data.text				// The written text.
  if string.StartsWith(text,"/remove_effect ") and get_round_status() == 1 then
    local effect_name = string.Split(text, " ")[2]
    local ply = Player(id)
    if player_effects[effect_name].clean_up then
      player_effects[effect_name].clean_up(ply)
    end
  end
end)



AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("util/shared_debug_id.lua")

-- Include Other Scripts

AddCSLuaFile("round_controller/cl_round_controller.lua")
include("round_controller/sv_round_controller.lua")

AddCSLuaFile("lobby_manager/cl_lobby.lua")
include("lobby_manager/sv_lobby.lua")

AddCSLuaFile("game_manager/cl_game.lua")
include("game_manager/sv_game.lua")

AddCSLuaFile("auction_manager/cl_auction.lua")
include("auction_manager/sv_auction.lua")

include("shared.lua")

util.AddNetworkString("client_ready")

local start_weapons = {
  "weapon_fists"
}

local PlayerMeta = FindMetaTable("Player")

local ready_players = {} --key: steamID64, value: true

function PlayerMeta:give_loadout()
  for k, v in pairs(start_weapons) do
    self:Give(v)
  end
end

function PlayerMeta:is_spectator()
  local ply_team = self:Team()
  return ply_team != 1 and ply_team != 2
end

function GM:PlayerConnect(name, ip)
  print("Player "..name.. " connected with IP ("..ip..")")
end

function player_spawn(ply)
  print("Player " ..ply:Nick() .. " has spawned.")
  if get_round_status() == 1 and not ply:is_espectator() then
    ply:give_loadout()
  end
end

-- Player has spawned for the first time and is ready.
function player_initial_spawn(ply)
  --print("Player " ..ply:Nick() .. " has spawned.")
  ply:SetTeam(0)
  if get_round_status() == 0 then
    open_lobby(ply)
  end

  player_spawn(ply)
end

net.Receive("client_ready", function(len, ply)
  ready_players[ply:SteamID64()] = true
  player_initial_spawn(ply)
end)



function GM:PlayerSetModel( ply )
  --TODO: Model selection
  ply:SetModel( "models/player/odessa.mdl" )
end
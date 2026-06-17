AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

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

function PlayerMeta:GiveLoadout()
  for k, v in pairs(start_weapons) do
    self:Give(v)
  end
end

function GM:PlayerConnect(name, ip)
  print("Player "..name.. " connected with IP ("..ip..")")
end

function GM:PlayerInitialSpawn(ply)
  print("Player " ..ply:Nick() .. " has spawned.")
end

function GM:PlayerSetModel( ply )
   ply:SetModel( "models/player/odessa.mdl" )
end
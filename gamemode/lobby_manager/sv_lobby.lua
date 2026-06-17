util.AddNetworkString("open_lobby")
util.AddNetworkString("start_game")
util.AddNetworkString("lobby_join_team")
util.AddNetworkString("broadcast_teams")
util.AddNetworkString("lobby_ready")
util.AddNetworkString("broadcast_ready")

function open_lobby(ply)
  net.Start("open_lobby")
  net.Send(ply)
end

local ready_players = {} -- SteamID64 as the key, boolean as the value

local team_1_players = {}
local team_2_players = {}

net.Receive("lobby_join_team", function(len, ply)
  local team = net.ReadInt(32)

  if team == 1 or team == 2 then
    print(team)
    ply:SetTeam(team)
    --ply:Kill()
    ply:Spawn()
  end

  team_1_players = {}
  team_2_players = {}
  for k, _ply in pairs(player.GetAll()) do
    if _ply:Team() == 1 then table.insert(team_1_players, _ply) end
    if _ply:Team() == 2 then table.insert(team_2_players, _ply) end
  end

  net.Start("broadcast_teams")
  net.WriteTable(team_1_players)
  net.WriteTable(team_2_players)
  net.Broadcast()
end)

net.Receive("lobby_ready", function(len, ply)
  local is_ready = net.ReadBool()
  print(is_ready)
  local steam_id = ply:SteamID64()
  if is_ready then
    ready_players[steam_id] = true
  else
    ready_players[steam_id] = nil 
  end

  net.Start("broadcast_ready")
  net.WriteTable(ready_players)
  net.Broadcast()
end)

gameevent.Listen( "player_say" )
hook.Add( "player_say", "player_say_example", function( data ) 
	local priority = SERVER and data.Priority or 1 	// Priority ??
	local id = data.userid				// Same as Player:UserID() for the speaker
	local text = data.text				// The written text.

  local ready_count = 0
  local total_count = 0
  for k, v in pairs(ready_players) do
    ready_count = ready_count + 1
  end

  for k, v in pairs(team_1_players) do
    total_count = total_count + 1
  end

  for k, v in pairs(team_2_players) do
    total_count = total_count + 1
  end

  --print(ready_count, total_count)

  --TODO: Count only players that are in a team for the player count
  if text == "/startgame" and ready_count == total_count and ready_count != 0 then
    init_grados()
    net.Start("start_game")
    net.WriteTable(get_grados())
    net.Broadcast()
    begin_round()
  end
end )

util.AddNetworkString("start_auction")
util.AddNetworkString("make_offer")
util.AddNetworkString("update_offers")
util.AddNetworkString("end_auction")

local all_offers
function init_offers()
  all_offers = {
  [1] = {},
  [2] = {}
  } --key: team id, value: table(key: SteamID64, value: offer value)
end

local curr_card = nil


net.Receive("make_offer", function(len, ply)
  local offer = net.ReadInt(32)
  local id = ply:SteamID64()
  local ply_team = ply:Team()
  all_offers[ply_team][id] = offer
  
  local team_players = {}
  for k, v in pairs(player.GetAll()) do
    if v:Team() == ply_team then
      table.insert(team_players, v)
    end
  end
  net.Start("update_offers")
  net.WriteTable(all_offers[ply_team])
  net.Send(team_players)
end)

function end_auction()
  max_offers = {[1] = 0, [2] = 0}

  for k, v in pairs(all_offers[1]) do
    max_offers[1] = max_offers[1] < v and v or max_offers[1]
  end

  for k, v in pairs(all_offers[2]) do
    max_offers[2] = max_offers[2] < v and v or max_offers[2]
  end

  local winning_team = 0 -- 0 means tie

  print(max_offers[1], max_offers[2])

  if max_offers[1] > max_offers[2] then
    print("team 1 wins")
    winning_team = 1
  elseif max_offers[2] > max_offers[1] then
    print("team 2 wins")
    winning_team = 2
  end

  local grados = get_grados()
  if winning_team != 0 then
    local winning_offer = max_offers[winning_team]
    grados[winning_team] = grados[winning_team] - winning_offer
  end

  net.Start("end_auction")
  net.WriteInt(winning_team, 32)
  net.WriteTable(max_offers)
  net.WriteTable(grados)
  net.Broadcast()

  print(winning_team)

  if winning_team == 0 then return end

  local team_key = winning_team == 1 and "id_verano" or "id_invierno" -- key for the winning team (blessing)
  local effect_target_team = winning_team
  if curr_card.kind == "curse" then
    team_key = team_key == "id_verano" and "id_invierno" or "id_verano" -- swap key for curses (get losing team's effect)
    effect_target_team = winning_team == 1 and 2 or 1 -- swap target team for curses
  end

  local effect_key = curr_card[team_key]
  local effect = get_effects()[effect_key]

  print (effect.display_name)

  for k, v in pairs(player.GetAll()) do
    if v:Team() == effect_target_team then
      apply_effect(ply, effect)
    end
  end
end



function start_auction()
  init_offers()
  local MAX_TIME = 30

  local all_cards = get_cards()
  local random_card_value, random_card_key = table.Random(all_cards)
  curr_card = random_card_value
  
  local all_effects = get_effects()
  print(random_card_key)
  local name_verano = all_effects[random_card_value.id_verano].display_name
  local name_invierno = all_effects[random_card_value.id_invierno].display_name

  local final_card = {
    card_name = random_card_value.display_name,
    name_verano = name_verano,
    name_invierno = name_invierno,
    description_verano = random_card_value.description_verano,
    description_invierno = random_card_value.description_invierno,
    max_time = MAX_TIME
  }

  for k,v in pairs(final_card) do
    print(k, v)
  end

  net.Start("start_auction")
  net.WriteTable(final_card)
  net.Broadcast()

  timer.Create("auction_timer", MAX_TIME, 1, end_auction)
end


hook.Add( "player_say", "start_auction", function( data ) 
	local priority = SERVER and data.Priority or 1 	// Priority ??
	local id = data.userid				// Same as Player:UserID() for the speaker
	local text = data.text				// The written text.
  if string.StartsWith(text,"/start_auction") and get_round_status() == 1 then
    start_auction()    
  end
end)
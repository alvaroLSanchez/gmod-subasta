
---- Custom invisible panel. (Can't remove a Panel's background)
local TeamPanel = {}

function TeamPanel:Paint( w, h )
    --draw.RoundedBox( 5, 0, 0, w, h, Color(67,67,67) )
end

vgui.Register( "TeamPanel", TeamPanel, "Panel" )
----

local frame = nil -- Frame for the join teams menu
local FRAME_WIDTH = 600
local FRAME_HEIGHT = 500

local team_1_players = {}
local team_2_players = {}
local team_menu_toggle = true

-- Container panels for all the player panels
local team_panels = {}

local team_1_btn = nil
local team_2_btn = nil

local ready_label = nil
local is_ready = false
local ready_players = {}

function toggle_menu(toggle)
  if IsValid(frame) then
    frame:SetVisible(toggle)
  end
  gui.EnableScreenClicker(toggle)
end

function update_team(team_number)
  --local team_panel = team == 1 and team_1_panel or team_2_panel
  print(team_number, team_1_btn, team_2_btn)
  local team_btn = team_number == 1 and team_1_btn or team_2_btn
  local players_table = team_number == 1 and team_1_players or team_2_players

  local TEAM_PANEL_WIDTH = 250
  local PLAYER_PANEL_HEIGHT = 50
  local PFP_MARGIN = 8
  local PFP_SIZE = 32
  local btn_x, btn_y, btn_width, btn_height = team_btn:GetBounds()
  local team_panel_x = btn_x + (btn_width/2) - (TEAM_PANEL_WIDTH/2)
  local team_panel_y = btn_y + btn_height + 10
  local TEAM_PANEL_HEIGHT = FRAME_HEIGHT - team_panel_y - 8

  if team_panels[team_number] != nil then
    team_panels[team_number]:Remove() -- Remove and recreate the panel to clean everything up
  end
  team_panel = vgui.Create("TeamPanel", frame)
  team_panel:SetPos(team_panel_x, team_panel_y)
  team_panel:SetSize(TEAM_PANEL_WIDTH, TEAM_PANEL_HEIGHT)
  team_panel:SetPaintBackgroundEnabled(true)
  team_panel:SetBGColor(Color(67,67,67))
  team_panels[team_number] = team_panel

  for index, ply in pairs(players_table) do
    local margin = index == 0 and 8 or 0
    local player_panel = vgui.Create("Panel", team_panel)
    player_panel:SetPos(0, (index-1) * PLAYER_PANEL_HEIGHT + margin)
    player_panel:SetSize(TEAM_PANEL_WIDTH, PLAYER_PANEL_HEIGHT)

    local player_name = vgui.Create("DLabel", player_panel)
    --player_name:SetText("afgdsfgsd")
    player_name:SetText(ply:Nick())
    player_name:SetColor(team.GetColor(team_number))
    player_name:SetPos(PFP_SIZE/2 + PFP_MARGIN/2, 0)
    player_name:SetSize(TEAM_PANEL_WIDTH, PLAYER_PANEL_HEIGHT)
    player_name:SetContentAlignment(5)

    local player_pfp = vgui.Create("AvatarImage", player_panel)
    player_pfp:SetSize(PFP_SIZE, PFP_SIZE)
    player_pfp:SetPos(TEAM_PANEL_WIDTH/2 - player_name:GetTextSize()/2 - (PFP_MARGIN/2) - PFP_SIZE/2, (PLAYER_PANEL_HEIGHT/2) - (PFP_SIZE/2))
    player_pfp:SetPlayer(ply, PFP_SIZE)
  end
end

function update_ready()
  local players = player.GetAll()

  -- Get count of players that already have a team.
  local total_count = 0

  for k, v in pairs(team_1_players) do
    total_count = total_count + 1
  end

  for k, v in pairs(team_2_players) do
    total_count = total_count + 1
  end
  --
  
  -- Get count of ready players
  local ready_count = 0
  for k, v in pairs(ready_players) do
    ready_count = ready_count + 1
  end
  --

  ready_label:SetText(ready_count .. "/" .. total_count)
end

function update_teams()
  update_team(1)
  update_team(2)
end

-- Receive of teams from the server
net.Receive("broadcast_teams", function()
  team_1_players = net.ReadTable()
  team_2_players = net.ReadTable()
  update_teams()
  update_ready()
end)

net.Receive("broadcast_ready", function()
  ready_players = net.ReadTable()
  update_ready()
end)

net.Receive("start_game", function()
  local grados = net.ReadTable()
  set_team_grados(grados[LocalPlayer():Team()])
  toggle_menu(false)
  begin_round()
end)

function create_lobby_frame()
  print("1?")
  if IsValid(frame) then frame:Remove() end
  frame = vgui.Create("DFrame")
  print("2?")
  frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
  frame:Center()
  frame:SetVisible(false)
  frame:SetTitle("Elección de equipo")
  frame:ShowCloseButton(false)
  frame:SetDraggable(false)
  gui.EnableScreenClicker(true)

  /*
  frame.OnClose = function()
    team_menu_toggle = false
    frame:SetVisible(false)
  end
  */

  local choose_your_team_label = vgui.Create("DLabel", frame)
  choose_your_team_label:SetPos(0, 30)
  choose_your_team_label:SetSize(FRAME_WIDTH, 20)
  choose_your_team_label:SetContentAlignment(5)
  choose_your_team_label:SetText("Elige tu equipo")

  team_1_btn = vgui.Create("DButton", frame)
  team_1_btn:SetText("Verano")
  team_1_btn:SetPos((FRAME_WIDTH*2/5)-(team_1_btn:GetWide()*2), 50)
  print("BTN 1")
  
  team_2_btn = vgui.Create("DButton", frame)
  team_2_btn:SetText("Invierno")
  team_2_btn:SetPos((FRAME_WIDTH*3/5)+(team_2_btn:GetWide()), 50)
  print("BTN 2")
  
  ready_btn = vgui.Create("DButton", frame)
  ready_btn:SetText("Listo")
  ready_btn:SetPos((FRAME_WIDTH/2)-(ready_btn:GetWide()/2), FRAME_HEIGHT - ready_btn:GetTall() - 8)

  local ready_x, ready_y, ready_w, ready_h = ready_btn:GetBounds()

  ready_label = vgui.Create("DLabel", frame)
  local _, ready_label_height = ready_label:GetTextSize()
  ready_label:SetText("Elige tu equipo")
  ready_label:SetPos(0, ready_y - ready_label_height - 8)
  ready_label:SetSize(FRAME_WIDTH, ready_label_height)
  ready_label:SetContentAlignment(5)

  team_1_btn.DoClick = function()
    net.Start("lobby_join_team")
    net.WriteInt(1,32)
    net.SendToServer()
  end

  team_2_btn.DoClick = function()
    net.Start("lobby_join_team")
    net.WriteInt(2,32)
    net.SendToServer()
  end

  ready_btn.DoClick = function()
    if LocalPlayer():Team() != 1 and LocalPlayer():Team() != 2 then return end
    is_ready = not is_ready
    net.Start("lobby_ready")
    net.WriteBool(is_ready)
    net.SendToServer()
  end
end

for k, ply in pairs(player.GetAll()) do
  if ply:Team() == 1 then
    table.insert(team_1_players, ply)
  elseif ply:Team() == 2 then
    table.insert(team_2_players, ply)
  end
end

hook.Add( "KeyPress", "menu_toggle", function( ply, key )
  if get_round_status() != 0 then return end
	if ( key == IN_USE ) then
		team_menu_toggle = not team_menu_toggle
    toggle_menu(team_menu_toggle)
	end
end )

function get_team_name() 
  if LocalPlayer():Team() == 1 then
    return "Verano"
  elseif LocalPlayer():Team() == 2 then
    return "Invierno"
  else
    return "Espectador"
  end
end

net.Receive("open_lobby", function()
  end_round()
  create_lobby_frame()
  toggle_menu(true)
  update_teams()
  update_ready()
end)

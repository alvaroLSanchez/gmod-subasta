function get_numbers_from_text(txt)
local str = ""
string.gsub(txt,"%d+",function(e)
 str = str .. e
end)
return str;
end

function is_number(txt)
  return not string.match(txt, "[^0-9]")
end

function get_seconds(num)
  return math.floor(num)..""
end

function get_frac(num)
    local decimals = string.format("%.2f", num - math.floor(num)):sub(3)
    return decimals
end


local AuctionPanel = {}

function AuctionPanel:Paint( w, h )
    --draw.RoundedBox( 5, 0, 0, w, h, Color(67,67,67) )
end

vgui.Register( "AuctionPanel", AuctionPanel, "Panel" )

surface.CreateFont( "BigFont", {
	font = "Arial", -- On Windows/macOS, use the font-name which is shown to you by your operating system Font Viewer. On Linux, the font-name *may* work, but using the file name is more reliable
	extended = false,
	size = 24,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )


local auction_active = false

local frame = nil -- Frame for the join teams menu
local FRAME_WIDTH = 600
local FRAME_HEIGHT = 600
local card_panel = nil
local offers_panel = nil
local card = nil

local offers = {} -- key: userid, value: offer value or nil

function create_card_panel(card)
  if IsValid(card_panel) then card_panel:Remove() end

  card_panel = vgui.Create("DFrame")
  card_panel:SetSize(FRAME_WIDTH, 250-20)
  card_panel:SetTitle(card.kind == "curse" and "Maldición" or " Bendición")
  card_panel:SetPos(ScrW()/2 -FRAME_WIDTH/2, 10)
  card_panel:SetDraggable(true)
  card_panel:ShowCloseButton(false)

  local card_name_label = vgui.Create("DLabel", card_panel)
  card_name_label:SetText(card.card_name)
  card_name_label:SetPos(0,30)
  card_name_label:SetSize(FRAME_WIDTH, 24)
  card_name_label:SetContentAlignment(5)
  card_name_label:SetFont("BigFont")
  
  local verano_label = vgui.Create("DLabel", card_panel)
  verano_label:SetText("Verano")
  verano_label:SetPos(0, 60)
  verano_label:SetSize(FRAME_WIDTH*3/7, 24)
  verano_label:SetContentAlignment(5)
  verano_label:SetFont("BigFont")

  local invierno_label = vgui.Create("DLabel", card_panel)
  invierno_label:SetText("Invierno")
  invierno_label:SetPos(FRAME_WIDTH*4/7, 60)
  invierno_label:SetSize(FRAME_WIDTH*3/7, 24)
  invierno_label:SetContentAlignment(5)
  invierno_label:SetFont("BigFont")

  local verano_effect_name = vgui.Create("DLabel", card_panel)
  verano_effect_name:SetText(card.name_verano)
  verano_effect_name:SetPos(0, 90)
  verano_effect_name:SetSize(FRAME_WIDTH*3/7, 24)
  verano_effect_name:SetContentAlignment(5)
  invierno_label:SetFont("BigFont")

  local invierno_effect_name = vgui.Create("DLabel", card_panel)
  invierno_effect_name:SetText(card.name_invierno)
  invierno_effect_name:SetPos(FRAME_WIDTH*4/7, 90)
  invierno_effect_name:SetSize(FRAME_WIDTH*3/7, 24)
  invierno_effect_name:SetContentAlignment(5)
  invierno_label:SetFont("BigFont")

  local verano_effect_description = vgui.Create("DLabel", card_panel)
  verano_effect_description:SetText(card.description_verano)
  verano_effect_description:SetWrap(true)
  verano_effect_description:SetPos(0, 120)
  verano_effect_description:SetSize(FRAME_WIDTH*3/7, 72)
  verano_effect_description:SetContentAlignment(7)

  local invierno_effect_description = vgui.Create("DLabel", card_panel)
  invierno_effect_description:SetWrap(true)
  invierno_effect_description:SetText(card.description_invierno)
  invierno_effect_description:SetPos(FRAME_WIDTH*4/7, 120)
  invierno_effect_description:SetSize(FRAME_WIDTH*3/7, 72)
  invierno_effect_description:SetContentAlignment(7)
end

function create_offers_panel(card)
  if IsValid(offers_panel) then offers_panel:Remove() end

  offers_panel = vgui.Create("Panel", frame)
  offers_panel:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
  offers_panel:SetPos(30,130)

  local team_players = {}

  for index, ply in pairs(player.GetAll()) do
    if ply:Team() == LocalPlayer():Team() then
      table.insert(team_players, ply)
    end
  end

  local TEAM_PANEL_WIDTH = 250
  local PLAYER_PANEL_HEIGHT = 64
  local PFP_MARGIN = 8
  local PFP_SIZE = 32

  for index, ply in pairs(team_players) do
    local margin = index == 0 and 8 or 0
    local player_panel = vgui.Create("Panel", offers_panel)
    player_panel:SetPos(0, (index-1) * PLAYER_PANEL_HEIGHT + margin)
    player_panel:SetSize(TEAM_PANEL_WIDTH, PLAYER_PANEL_HEIGHT)

    local player_name = vgui.Create("DLabel", player_panel)
    --player_name:SetText("afgdsfgsd")
    player_name:SetText(ply:Nick())
    player_name:SetColor(team.GetColor(ply:Team()))
    player_name:SetPos(PFP_SIZE + PFP_MARGIN, 0)
    player_name:SetSize(TEAM_PANEL_WIDTH, PLAYER_PANEL_HEIGHT)
    player_name:SetContentAlignment(4)

    local player_pfp = vgui.Create("AvatarImage", player_panel)
    player_pfp:SetSize(PFP_SIZE, PFP_SIZE)
    player_pfp:SetPos(0, PFP_SIZE/2)
    player_pfp:SetPlayer(ply, PFP_SIZE)

    local offer_value = offers[ply:UserID()]
    local player_name_width = player_name:GetTextSize()
    local player_name_x = player_name:GetPos()

    local player_offer = vgui.Create("DLabel", player_panel)
    --player_name:SetText("afgdsfgsd")
    player_offer:SetText(offer_value or "")
    player_offer:SetColor(Color(0,255,0))
    player_offer:SetPos(player_name_x + player_name_width + 12, 0)
    player_offer:SetSize(TEAM_PANEL_WIDTH, PLAYER_PANEL_HEIGHT)
    player_offer:SetContentAlignment(4)
  end
end

local start_time = nil

function create_frame()

  frame = vgui.Create("DFrame")

  frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
  frame:Center()
  frame:SetVisible(false)
  frame:SetTitle("Subasta")
  frame:ShowCloseButton(false)

  local timer_label = vgui.Create("DLabel", frame)
  timer_label:SetPos(0, 30)
  timer_label:SetSize(FRAME_WIDTH, 20)
  timer_label:SetContentAlignment(5)
  timer_label:SetText("")
  timer_label:SetFont("BigFont")

  hook.Add("Think", "timer_think", function()
    if start_time == nil then return end
    if card == nil then return end
    if not IsValid(frame) then return end
    local time_left = card.max_time-(os.clock()-start_time)
    time_left = time_left < 0 and 0 or time_left
    local seconds = get_seconds(time_left)
    local frac = get_frac(time_left)
    timer_label:SetText(" "..seconds..":"..frac)
  end)

  local offer_label = vgui.Create("DLabel", frame)
  offer_label:SetPos(0, 70)
  offer_label:SetSize(FRAME_WIDTH, 20)
  offer_label:SetContentAlignment(5)
  offer_label:SetText("Haz tu puja! Cuando acabe el tiempo, tu equipo pujará la cantidad más grande")

  local offer_prev_text = ""
  local offer_input = vgui.Create("DTextEntry", frame)
  offer_input:SetPos(FRAME_WIDTH/2 - 50, 100)
  offer_input:SetText("")
  --local _, text_height = offer_input:GetTextSize()
  offer_input:SetSize(100, 20)
  offer_input:SetContentAlignment(4)
  offer_input.OnChange = function()
    local new_text = offer_input:GetText()
    if not is_number(new_text) then 
      offer_input:SetText(offer_prev_text)
      return false
    end
    offer_prev_text = new_text
  end

  change_offer_btn = vgui.Create("DButton", frame)
  change_offer_btn:SetText("Cambiar puja")
  change_offer_btn:SetPos(FRAME_WIDTH/2 - 50 + offer_input:GetWide() + 10, 100)
  change_offer_btn:SetSize(80, 20)
  change_offer_btn:SetContentAlignment(5)

  change_offer_btn.DoClick = function()
    if not is_number(offer_prev_text) then return end
    local offer = offer_prev_text + 0
    if offer == 0 then return end
    if offer > get_team_grados() then return end
    net.Start("make_offer")
    net.WriteInt(offer,32)
    net.SendToServer()
  end

end



net.Receive("start_auction", function()
  card = net.ReadTable()
  auction_active = true

  create_frame()
  create_card_panel(card)
  create_offers_panel()
  frame:SetVisible(true)
  frame:MakePopup()
  start_time = os.clock()
end)

net.Receive("update_offers", function()
  offers = net.ReadTable()
  create_offers_panel()
end)

net.Receive("end_auction", function()
  net.ReadInt(32)
  net.ReadTable()
  local grados = net.ReadTable()
  set_team_grados(grados[LocalPlayer():Team()])

  frame:SetMouseInputEnabled(false)
  frame:SetKeyboardInputEnabled(false)
  gui.EnableScreenClicker(false)
  frame:SetVisible(false)
  frame:Remove()

  card_panel:SetVisible(false)
  card_panel:Remove()

  hook.Remove("Think", "timer_think")
end)

/*
local RagmodEnabled
for k, v in pairs(engine.GetAddons()) do
    if v.wsid == "2817879135" and v.mounted == true then
        -- Ragmod Reworked exists! Add the module
        RagmodEnabled = true
        require("ragmod") 
        break
    end
end

-- Stop if ragmod wasn't found
if not RagmodEnabled then return end
*/


surface.CreateFont( "CreditsFont", {
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

local grados = 40

function get_team_grados()
  return grados
end

function set_team_grados(num)
  grados = num
end

hook.Add("HUDPaint", "DrawCredits", function()
  if get_round_status() != 1 then return end
  draw.SimpleText("Equipo " .. get_team_name(), "CreditsFont",0, 0, team.GetColor(LocalPlayer():Team()))
  draw.SimpleText("Grados: ".. grados .. "º", "CreditsFont",0,50,team.GetColor(LocalPlayer():Team()))
end)

hook.Add("RM_CanAction", "no_actions", function(ply, action)
  return false 
end)

local third_person = false
local frozen = false
local ragdoll = false

-- Define the target entity you want the camera to follow
local target_entity = NULL -- Assign your entity here

-- Camera distance and height offsets
local camDistance = 300
local camHeight = 100

net.Receive("set_frozen", function()
  frozen = net.ReadBool()
  third_person = frozen
  --if third_person then
  --  target_entity = LocalPlayer()  
  --else 
  --  target_entity = nil
  --end
end)

net.Receive("set_ragdoll", function()
  ragdoll = net.ReadBool()
  --third_person = ragdoll
  if ragdoll == true then
    --print("TRUERS!")
    print("Ragdoll")
    --target_entity = LocalPlayer():GetRagdollEntity()
  else
    local ragdoll_entity = LocalPlayer():GetRagdollEntity()
    if IsValid(ragdoll_entity) then
      net.Start("ragdoll_position")
      net.WriteVector(ragdoll_entity:GetPos())
      net.SendToServer()
    end
  end

end)

hook.Add( "CreateClientsideRagdoll", "set_target", function( entity, ragdoll_entity )
  if entity:IsPlayer() and entity:SteamID64() == LocalPlayer():SteamID64() then
	  target_entity = ragdoll_entity
  end
end )

hook.Add("CalcView", "ThirdPersonView", function(ply, pos, angles, fov)
    if not third_person then return end
    if not ply:Alive() then return end
    
    -- Calculate the camera position behind the player
    local view = {}
    local distance = 100 -- Distance behind the player
    local offset = Vector(0, 0, 10) -- Height offset
    
    -- Trace to prevent the camera from clipping through walls
    local traceData = {}
    traceData.start = pos + offset
    traceData.endpos = pos + offset - (angles:Forward() * distance)
    traceData.filter = ply
    
    local trace = util.TraceLine(traceData)
    
    view.origin = trace.HitPos + (trace.HitNormal * 5)
    view.angles = angles
    view.fov = fov
    view.drawviewer = true -- This forces the player's model to render
    
    return view
end)

-- Camera offset and angles
local CamOffset = Vector(-150, 0, 70) -- Distance behind (X), side (Y), and height (Z)
local CamDistance = 150
local CamHeight = 70

-- CalcView Hook
hook.Add("CalcView", "FollowEntityCamera", function(ply, pos, angles, fov)
    -- Check if the target entity is valid
    if not IsValid(target_entity) then return end

    -- Get target's position and forward direction
    local targetPos = target_entity:GetPos()
    local targetAng = target_entity:GetAngles()

    -- Calculate the ideal camera position
    local idealPos = targetPos + (targetAng:Forward() * -CamOffset.x) + (targetAng:Right() * CamOffset.y) + Vector(0, 0, CamHeight)

    -- Optional: Trace to prevent the camera from clipping through walls
    local trace = util.TraceLine({
        start = targetPos + Vector(0, 0, 50),
        endpos = idealPos,
        filter = { ply, target_entity }
    })
    
    -- Use the trace hit position if it hit a wall, otherwise use the ideal position
    local finalPos = trace.HitPos

    -- Look at the target
    local finalAngles = (targetPos - finalPos):Angle()

    -- Construct the view table
    local view = {}
    view.origin = finalPos
    view.angles = finalAngles
    view.fov = fov
    view.drawviewer = true -- Ensures the player model is rendered

    return view
end)
// Workaround to avoid identical steam IDs when testing on LAN. 
// Avoids using UserIDs instead, which are not persistent between player disconnections and map changes.
// These fake SteamIDs are not persistent either, but they allow testing.

// Taken from: https://github.com/Facepunch/garrysmod-requests/issues/991

//////////
///  FOR DEBUGGING
if SERVER then
	SetGlobalBool("IsLanServer", GetConVarNumber("sv_lan") != 0)
end

if GetGlobalBool("IsLanServer") != 0 then -- sv_lan is not replicated
	FSI = FSI or {}
	FSI.PlayerMetatable = FindMetaTable("Player")
	FSI.OldPlayerMetatableSteamID = FSI.OldPlayerMetatableSteamID or FSI.PlayerMetatable.SteamID
	FSI.OldPlayerMetatableSteamID64 = FSI.OldPlayerMetatableSteamID64 or FSI.PlayerMetatable.SteamID64

	if SERVER then
		hook.Add("PlayerInitialSpawn", "FSI.PlayerInitialSpawn", function(ply)
			-- If this is a duplicate player, assign a unique SteamID (for this session).
			if FSI.OldPlayerMetatableSteamID(ply) == "STEAM_0:0:0" then
				local userId = ply:UserID() -- User ID is unique for the current session.
				local fakeSteamID = "STEAM_0:0:" .. tostring(userId)
				ply:SetNetworkedString("FakeSteamID", fakeSteamID)
				print("Duplicate player from " .. ply:IPAddress() .. ". Assigned SteamID: " .. fakeSteamID)
			end
		end)
	end

	function FSI.PlayerMetatable.SteamID(self)
		local fakeSteamID = self:GetNetworkedString("FakeSteamID")
		if fakeSteamID == "" then
			return FSI.OldPlayerMetatableSteamID(self)
		end
		
		return fakeSteamID
	end

	function FSI.PlayerMetatable.SteamID64(self)
		-- Since SteamID64() returns a string, and that number can't accurately be represented by a double anyway, just return SteamID().
		return self:SteamID()
	end
end
///  FOR DEBUGGING
//////////
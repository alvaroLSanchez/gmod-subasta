include("shared.lua")

include("round_controller/cl_round_controller.lua")
include("lobby_manager/cl_lobby.lua")
include("game_manager/cl_game.lua")
include("auction_manager/cl_auction.lua")

-- Notify the server that the client is ready
hook.Add( "InitPostEntity", "Ready", function()
	net.Start("client_ready")
	net.SendToServer()
end )
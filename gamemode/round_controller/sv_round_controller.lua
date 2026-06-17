util.AddNetworkString("update_round_status")

local round_status = 0 --0=end, 1=active

function begin_round()
  round_status = 1
  update_clients_round_status()
  for k, v in pairs(player.GetAll()) do
    if v:Team() == 1 or v:Team() == 2 then
      v:GiveLoadout()
    end
  end
end

function end_round()
  round_status = 0
  update_clients_round_status()
end

function get_round_status()
  return round_status
end

function update_clients_round_status()
  net.Start("update_round_status")
  net.WriteInt(round_status, 4)
  net.Broadcast()
end

function update_client_round_status(ply)
  net.Start("update_round_status")
  net.WriteInt(round_status, 4)
  net.Send(ply)
end
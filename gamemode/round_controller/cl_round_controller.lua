local round_status = 0

net.Receive("update_round_status", function()
  local status = net.ReadInt(4)
  if round_status == 0 then
    end_round()
  elseif round_status == 1 then
    begin_round()
  end
end)

function end_round()
  round_status = 0
end

function begin_round()
  round_status = 1
end

function get_round_status()
  return round_status
end


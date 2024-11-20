local M = {}

-- Format: HH:MM:SS.mmm
local function get_timestamp()
  local datetime = os.date("*t")
  local ms = math.floor((os.clock() % 1) * 1000)
  return string.format("%02d:%02d:%02d.%03d",
    datetime.hour,
    datetime.min,
    datetime.sec,
    ms)
end

function M.log(...)
  if vim.g.debug == 1 then
    local args = { ... }
    local timestamp = get_timestamp()
    local message = table.concat(args, " ")
    print(timestamp .. "> " .. message)
  end
end

return M

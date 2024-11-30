local l = require("llm_flow.logger")

local M = {
  debug = false,
  provider = "nebius",
  model = "Qwen/Qwen2.5-Coder-7B-fast",
  extensions = { "c", "cpp",
    "lua", "py", "js", "ts", "go", "svelte", "rs", "json", "md", "toml" },
}

M.update = function(opts)
  l.log("Updating config", vim.inspect(opts))
  return vim.tbl_deep_extend("force", M, opts)
end

return M

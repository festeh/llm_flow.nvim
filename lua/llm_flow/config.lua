local l = require("llm_flow.logger")

local M = {
  debug = false,
  provider = "huggingface",
  model = "codellama/CodeLlama-7b-hf",
  extensions = { "c", "cpp",
    "lua", "py", "js", "ts", "go", "svelte", "rs", "json", "md", "toml" },
}

M.update = function(opts)
  l.log("Updating config", vim.inspect(opts))
  return vim.tbl_deep_extend("force", M, opts)
end

return M

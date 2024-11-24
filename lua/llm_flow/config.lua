local M = {
  provider = "huggingface",
  model = "codellama/CodeLlama-7b-hf",
  extensions = { "c", "lua", "py", "js", "ts", "go", "svelte", "rs", "json", "md", "toml" },
}

M.update = function(opts)
  vim.table.deep_extend("force", M, opts)
end

return M

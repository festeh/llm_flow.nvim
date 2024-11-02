local M = {}

function M.find_lsp_client()
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  for _, client in pairs(clients) do
    if client.name == "llm-flow" then
      return client
    end
  end
  return nil
end

--- Send a prediction request using the specified model
--- @param params table The parameters for the prediction
--- @param model string The model to use for prediction
function M.predict_with_model(params, model)
    local client = M.find_lsp_client()
    if not client then
        vim.notify("No llm-flow LSP client found", vim.log.levels.ERROR)
        return
    end
    
    local request_params = vim.tbl_extend("force", params, {model = model})
    client.request("llm-flow/predict", request_params, function(err, result)
        if err then
            vim.notify("Prediction failed: " .. err.message, vim.log.levels.ERROR)
            return
        end
        return result
    end)
end

--- Send a prediction request using the default model
--- @param params table The parameters for the prediction
function M.predict(params)
    return M.predict_with_model(params, "default")
end

function M.check_directory_exists(path)
  local ok, stat = pcall(vim.loop.fs_stat, path)
  if not ok or not stat then
    return false
  end
  -- Directory already exists
  return true
end

function M.git_clone(repo, path)
  local cmd = string.format("git clone https://github.com/%s %s", repo, path)
  vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

function M.check_executable_exists(path)
  local ok, stat = pcall(vim.loop.fs_stat, path)
  if not ok or not stat then
    return false
  end
  return true
end

function M.build_go_executable(dir)
  local cmd = string.format("cd %s && go build -o bin/lsp-server cmd/lsp-server/main.go", dir)
  vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

return M

local utils = require('llm_flow.utils')
local completion = require('llm_flow.completion')
local Client = require('llm_flow.client')
local config = require('llm_flow.config')

local lsp = vim.lsp
local api = vim.api

local M = {}


local function ensure_install()
  local data_path = vim.fn.stdpath('data')
  local llm_flow_path = data_path .. '/llm_flow'
  local executable_path = llm_flow_path .. '/bin/lsp-server'

  -- Step 1: Ensure repository exists
  if not utils.check_directory_exists(llm_flow_path) then
    if not utils.git_clone('festeh/llm_flow', llm_flow_path) then
      vim.notify('Failed to clone llm_flow repository', vim.log.levels.ERROR)
      return false
    end
  end

  -- Step 2: Check and build executable if needed
  if not utils.check_executable_exists(executable_path) then
    -- Ensure bin directory exists
    vim.fn.mkdir(llm_flow_path .. '/bin', 'p')

    if not utils.build_go_executable(llm_flow_path) then
      vim.notify('Failed to build lsp-server executable', vim.log.levels.ERROR)
      return false
    end
    vim.notify('Successfully built lsp-server executable', vim.log.levels.INFO)
  end
end

local function is_supported(current_buf)
  local bufname = vim.api.nvim_buf_get_name(current_buf)
  for _, ext in ipairs(config.extensions) do
    if bufname:match("%." .. ext .. "$") then
      return true
    end
  end
  return false
end

local function notify_did_open(client, buf)
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
  client.notify('textDocument/didOpen', {
    textDocument = {
      uri = vim.uri_from_bufnr(buf),
      languageId = vim.bo[buf].filetype,
      version = 0,
      text = text
    }
  })
end

local function notify_set_config(client)
  client.notify('set_config', {
    provider = config.provider,
    model = config.model
  })
end


local function init_client(client_id)
  -- Send didOpen for current buffer if it matches
  local current_buf = vim.api.nvim_get_current_buf()
  if not is_supported(current_buf) then
    return
  end
  lsp.buf_attach_client(current_buf, client_id)
  local client = Client.get()
  if client == nil then
    return
  end
  notify_did_open(client, current_buf)
  notify_set_config(client)
end

M.setup = function()
  ensure_install()
  local client_id = Client.start()
  if client_id == nil then
    vim.notify('Failed to start llm_flow language server', vim.log.levels.ERROR)
    return false
  end

  init_client(client_id)

  local extension_pattern = "*." .. table.concat(config.extensions, ",*.")
  local augroup = "llm-flow"
  api.nvim_create_augroup(augroup, { clear = true })
  api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    pattern = { extension_pattern },
    callback = function(ev)
      if not lsp.buf_is_attached(ev.buf, client_id) then
        lsp.buf_attach_client(ev.buf, client_id)
      end
    end,
  })
  M.client_id = client_id

  -- TODO: restore
  -- api.nvim_create_autocmd("VimLeavePre", {
  --   group = augroup,
  --   callback = function()
  --     lsp.stop_client(client_id)
  --   end,
  -- })
  --
  completion.setup()
  return true
end

return M

local M = {}

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

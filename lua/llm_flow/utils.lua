local M = {}

function M.ensure_directory_exists(path)
    local stat = vim.loop.fs_stat(path)
    if not stat then
        vim.fn.mkdir(path, "p")
        return false
    end
    return true
end

function M.git_clone(repo, path)
    local cmd = string.format("git clone https://github.com/%s %s", repo, path)
    vim.fn.system(cmd)
    return vim.v.shell_error == 0
end

return M

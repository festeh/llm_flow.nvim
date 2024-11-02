local M = {}

function M.ensure_directory_exists(path)
    local ok, stat = pcall(vim.loop.fs_stat, path)
    if not ok or not stat then
        local success = vim.fn.mkdir(path, "p")
        if success == 0 then
            vim.notify('Failed to create directory: ' .. path, vim.log.levels.ERROR)
            return false
        end
        -- Directory was created successfully
        return true
    end
    -- Directory already exists
    return true
end

function M.git_clone(repo, path)
    local cmd = string.format("git clone https://github.com/%s %s", repo, path)
    vim.fn.system(cmd)
    return vim.v.shell_error == 0
end

return M

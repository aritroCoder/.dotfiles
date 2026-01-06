package.preload["nvchad.nvdash"] = function()
    return dofile(vim.fn.stdpath("config") .. "/lua/nvchad/nvdash/init.lua")
end

local original_notify = vim.notify
vim.notify = function(msg, level, opts)
    if msg:match("position_encoding param is required") then
        return
    end
    return original_notify(msg, level, opts)
end

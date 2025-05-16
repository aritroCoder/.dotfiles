local M = {}

M.general = {
    n = {
        ["<C-h>"] = { "<cmd> TmuxNavigateLeft<CR>", "window left" },
        ["<C-l>"] = { "<cmd> TmuxNavigateRight<CR>", "window right" },
        ["<C-j>"] = { "<cmd> TmuxNavigateDown<CR>", "window down" },
        ["<C-k>"] = { "<cmd> TmuxNavigateUp<CR>", "window up" },
        -- Disable arrow keys
        ["<Up>"] = { "<Nop>", "disable up" },
        ["<Down>"] = { "<Nop>", "disable down" },
        ["<Left>"] = { "<Nop>", "disable left" },
        ["<Right>"] = { "<Nop>", "disable right" },
    },
}
return M

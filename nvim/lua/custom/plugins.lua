local plugins = {
    {
        "mhartington/formatter.nvim",
        event = "VeryLazy",
        cmd = { "Format", "FormatWriteLock" },
        opts = function()
            return require "custom.configs.formatter"
        end,
    },
    {
        "mfussenegger/nvim-lint",
        event = "VeryLazy",
        config = function()
            require "custom.configs.lint"
        end,
    },
    {
        "christoomey/vim-tmux-navigator",
        lazy = false,
    },
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({
                suggestion = {
                    enabled = true,
                    auto_trigger = true,
                    debounce = 75,
                    keymap = {
                        accept = false,
                        accept_word = false,
                        accept_line = false,
                        next = "<M-]>",
                        prev = "<M-[>",
                        dismiss = "<Esc>",
                    },
                },
                panel = { enabled = false },
                filetypes = {
                    yaml = true,
                    markdown = true,
                    gitcommit = true,
                    ["*"] = true,
                },
            })
        end,
    },
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                "eslint-lsp",
                "prettier",
                "typescript-language-server",
                "clangd",
                "clang-format",
                "tailwindcss-language-server",
                "gopls",
                "mypy",
                "ruff",
                "black",
                "pyright",
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            require "plugins.configs.lspconfig"
            require "custom.configs.lspconfig"
        end,
    },
    {
        "olexsmir/gopher.nvim",
        ft = "go",
        config = function(_, opts)
            require("gopher").setup(opts)
        end,
        build = function()
            vim.cmd [[silent! GoInstallDeps]]
        end,
    },
}

return plugins

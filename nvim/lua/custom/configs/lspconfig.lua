local config = require("plugins.configs.lspconfig")
local on_attach = config.on_attach
local capabilities = config.capabilities

vim.lsp.config("ts_ls", {
    on_attach = on_attach,
    capabilities = capabilities,
    init_options = {
        preferences = {
            disableSuggestions = true,
        },
    },
    commands = {
        OrganizeImports = {
            function()
                vim.lsp.buf.execute_command({
                    command = "_typescript.organizeImports",
                    arguments = { vim.api.nvim_buf_get_name(0) },
                })
            end,
            description = "Organize Imports",
        },
    },
})

vim.lsp.config("clangd", {
    on_attach = function(client, bufnr)
        client.server_capabilities.signatureHelpProvider = false
        on_attach(client, bufnr)
    end,
    capabilities = capabilities,
})

vim.lsp.config("tailwindcss", {
    on_attach = on_attach,
    capabilities = capabilities,
})

vim.lsp.config("gopls", {
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
    settings = {
        gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
                unusedparams = true,
            },
        },
    },
})

vim.lsp.config("pyright", {
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "python" },
})

vim.lsp.enable({ "ts_ls", "clangd", "tailwindcss", "gopls", "pyright" })

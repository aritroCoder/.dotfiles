local util = require "formatter.util"

-- local patch_clangformat_bug = function(f)
--   local o = f()
--   if o.args and type(o.args) == 'table' then
--     local new_args = {}
--     local skip = false
--     for i, v in ipairs(o.args) do
--       if skip then
--         skip = false
--       elseif v == '-assume-filename'
--         and (o.args[i + 1] == "''" or o.args[i + 1] == '""')
--       then
--         skip = true
--       elseif type(v) ~= 'string' or not v:find('^-style=') then
--         table.insert(new_args, v)
--       end
--     end
--     o.args = new_args
--   end
--   return o
-- end

local M = {
    filetype = {
        javascript = {
            function()
                print(util.get_cwd() .. "/.prettierrc")
                return {
                    exe = "prettier",
                    args = {
                        "--config-precedence",
                        "prefer-file",
                        "--config",
                        util.get_cwd() .. "/.prettierrc",
                        "--write",
                    },
                }
            end,
        },

        javascriptreact = {
            function()
                return {
                    exe = "prettier",
                    args = {
                        "--config-precedence",
                        "prefer-file",
                        "--config",
                        util.get_cwd() .. "/.prettierrc",
                        "--write",
                    },
                }
            end,
        },

        typescript = {
            require("formatter.filetypes.typescript").prettier,
        },

        typescriptreact = {
            require("formatter.filetypes.typescript").prettier,
        },

        ["*"] = {
            require("formatter.filetypes.any").remove_trailing_whitespace,
        },

        cpp = {
            function()
                return {
                    exe = "clang-format",
                    args = {
                        "--assume-filename=" .. vim.fn.shellescape(vim.api.nvim_buf_get_name(0)),
                        '-style="{BasedOnStyle: google, IndentWidth: 4, BreakBeforeBraces: Attach}"',
                    },
                    stdin = true,
                    cwd = vim.fn.expand "%:p:h",
                }
            end,
        },

        c = {
            function()
                return {
                    exe = "clang-format",
                    args = {
                        "--assume-filename=" .. vim.fn.shellescape(vim.api.nvim_buf_get_name(0)),
                        '-style="{BasedOnStyle: google, IndentWidth: 4, BreakBeforeBraces: Attach}"',
                    },
                    stdin = true,
                    cwd = vim.fn.expand "%:p:h",
                }
            end,
        },

        go = {
            function()
                return {
                    exe = "gofmt",
                    args = { "-w", vim.api.nvim_buf_get_name(0) },
                    stdin = false,
                    cwd = vim.fn.expand "%:p:h",
                }
            end,
        },

        python = {
            function()
                return {
                    exe = "black",
                    args = { vim.api.nvim_buf_get_name(0) },
                    stdin = false,
                    cwd = vim.fn.expand "%:p:h",
                }
            end,
        },
        lua = {
            function()
                return {
                    exe = "stylua",
                    args = {
                        "--search-parent-directories", -- to find nearest .stylua.toml
                        "--stdin-filepath",
                        vim.fn.shellescape(vim.api.nvim_buf_get_name(0)),
                        "--",
                        "-",
                    },
                    stdin = true,
                }
            end,
        },
    },
}

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    command = "FormatWriteLock",
})

return M

local ts_parsers = require "nvim-treesitter.parsers"
local options = {
    ensure_installed = { "lua", "bash", "yaml" },
    highlight = {
        enable = true,
        disable = function(lang, buf)
            return ts_parsers.get_parser_configs()[lang] == nil
        end,
        use_languagetree = true,
    },
    indent = { enable = true },
}
return options

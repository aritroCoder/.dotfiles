# AGENTS.md - Neovim Configuration

NvChad v2.0-based config with fork-less overlay pattern.

## STRUCTURE

```
nvim/
├── init.lua                    # Bootstrap entry (loads lazy.nvim)
├── .stylua.toml                # Lua formatter config
├── lazy-lock.json              # Plugin version lock
├── lua/
│   ├── core/                   # NvChad base (DO NOT modify)
│   │   ├── init.lua            # Options, autocmds, commands
│   │   ├── bootstrap.lua       # Lazy.nvim bootstrap + theme compile
│   │   ├── mappings.lua        # Default keybindings
│   │   └── utils.lua           # Utilities (load_config, etc.)
│   ├── plugins/                # Default plugin configs
│   │   └── configs/            # cmp, lsp, telescope, treesitter, etc.
│   └── custom/                 # YOUR CHANGES GO HERE
│       ├── chadrc.lua          # Theme, statusline, plugin pointer
│       ├── plugins.lua         # Custom plugin specs (lazy.nvim)
│       ├── mappings.lua        # Custom keybindings
│       └── configs/            # Plugin-specific overrides
│           ├── lspconfig.lua   # LSP server setup
│           ├── formatter.lua   # Formatter settings
│           ├── lint.lua        # Linter settings
│           └── copilot.lua     # Copilot config
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add plugin | `lua/custom/plugins.lua` |
| Override keybinding | `lua/custom/mappings.lua` |
| Change theme | `lua/custom/chadrc.lua` → `M.ui.theme` |
| Configure LSP | `lua/custom/configs/lspconfig.lua` |
| Add formatter | `lua/custom/configs/formatter.lua` |
| Add linter | `lua/custom/configs/lint.lua` |

## OVERLAY PATTERN

**Never modify `lua/core/` or `lua/plugins/`** - these are NvChad base.

Custom overrides in `lua/custom/` are merged automatically:
- `chadrc.lua` → Points to `"custom.plugins"` and `require "custom.mappings"`
- Plugins in `custom/plugins.lua` are added to default plugins
- Mappings in `custom/mappings.lua` override defaults with same keys

## KEY BINDINGS

Leader: `<Space>`

| Key | Action | Source |
|-----|--------|--------|
| `<Tab>` (normal) | Accept Copilot NES | copilot-lsp |
| `<Esc>` | Clear Copilot / highlights | copilot-lsp |
| `<C-h/j/k/l>` | tmux-aware window nav | `custom/mappings.lua` |
| `<leader>ff` | Find files | telescope |
| `<leader>fw` | Live grep | telescope |
| `<leader>e` | File tree focus | nvimtree |
| `<C-n>` | Toggle file tree | nvimtree |
| `gd` | Go to definition | LSP |
| `gr` | Find references | LSP |
| `<leader>ca` | Code actions | LSP |
| `<leader>fm` | Format file | LSP |
| `<M-l>` | Accept Copilot | copilot |
| `<A-i>` | Toggle float term | nvterm |

Arrow keys disabled in normal mode (use hjkl).

## PLUGIN SPEC FORMAT

```lua
-- lua/custom/plugins.lua
local plugins = {
    {
        "author/plugin-name",
        event = "VeryLazy",              -- Lazy load trigger
        cmd = { "Command" },             -- Or load on command
        ft = "go",                       -- Or load on filetype
        opts = function()
            return require "custom.configs.plugin"
        end,
        config = function()
            require("plugin").setup {}
        end,
    },
}
return plugins
```

## LSP SERVERS

Configured in `custom/configs/lspconfig.lua`. Mason-installed:
- `typescript-language-server`, `eslint-lsp`, `tailwindcss-language-server`
- `pyright`, `ruff`, `mypy`, `black`
- `gopls`, `clangd`, `clang-format`

## CONVENTIONS

- **Indent:** 4 spaces (stylua enforced)
- **Quotes:** Double (`"string"`)
- **Line width:** 120 chars
- **Module pattern:** `local M = {}` → `return M`
- **Imports:** `local x = require "module.path"` (space before string)

## COMMANDS

```bash
stylua nvim/                          # Format
luacheck nvim/lua/ --no-unused-args   # Lint
nvim --headless "+Lazy! sync" +qa     # Sync plugins
```

## GOTCHAS

1. **First run:** lazy.nvim auto-installs plugins, may take a minute
2. **Theme compile:** Base46 compiles themes to bytecode on bootstrap
3. **Mason binaries:** Added to PATH automatically (`~/.local/share/nvim/mason/bin`)
4. **Copilot LSP:** Requires authentication - run `:Copilot auth` on first use

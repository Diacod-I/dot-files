-- ============================================================
--  init.lua  —  lazy.nvim + LSP + treesitter (Neovim 0.12)
-- ============================================================

-- Per-command colors on the git interactive-rebase screen
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitrebase",
  callback = function()
    local cmds = {
      { "RebasePick",   "#9ece6a", "\\v^(p|pick)>" },        -- green:  keep
      { "RebaseReword", "#7aa2f7", "\\v^(r|reword)>" },      -- blue:   edit message
      { "RebaseEdit",   "#e0af68", "\\v^(e|edit)>" },        -- yellow: pause to amend
      { "RebaseSquash", "#bb9af7", "\\v^(s|squash)>" },      -- purple: fold up, keep msg
      { "RebaseFixup",  "#9aa5ce", "\\v^(f|fixup)>" },       -- grey:   fold up, drop msg
      { "RebaseDrop",   "#f7768e", "\\v^(d|drop)>" },        -- red:    delete
      { "RebaseExec",   "#ff9e64", "\\v^(x|exec|b|break)>" },-- orange: run / stop
    }
    for _, c in ipairs(cmds) do
      vim.api.nvim_set_hl(0, c[1], { fg = c[2], bold = true })
      vim.fn.matchadd(c[1], c[3], 200)   -- priority 200 beats treesitter's 100
    end
  end,
})

-- Disable unused providers (fewer checkhealth warnings, faster startup)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- basic settings
vim.opt.number = true
vim.opt.autoindent = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 300
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 8
vim.opt.undofile = true

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    keys = { { "<leader>e", ":Neotree toggle<CR>", desc = "File explorer" } },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    opts = {},
  },

  -- Telescope (+ native fzf). Preview treesitter off to dodge the 0.12 languagetree crash.
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Search keymaps" },
      { "<leader>fr", "<cmd>Telescope lsp_references<cr>", desc = "References" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Symbols" },
    },
    config = function()
      require("telescope").setup({ defaults = { preview = { treesitter = false } } })
      pcall(require("telescope").load_extension, "fzf")
    end,
  },

  -- Treesitter (main branch — required for Neovim 0.12; injection parsers included)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "lua", "luadoc", "python", "javascript", "jsdoc", "typescript",
        "c", "cpp", "rust", "go", "bash", "json", "yaml", "toml",
        "markdown", "markdown_inline", "comment", "regex",
        "git_rebase", "gitcommit", "diff",
      })
      vim.treesitter.language.register("git_rebase", "gitrebase")
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if not lang then return end
          if pcall(vim.treesitter.get_parser, args.buf, lang) then
            pcall(vim.treesitter.start, args.buf, lang)
          end
        end,
      })
    end,
  },

  -- Merge conflict resolution
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "BufReadPre",
    config = function() require("git-conflict").setup() end,
  },

  -- LSP + completion + snippets (pyright = types, ruff = lint/format)
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/nvim-cmp", "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path",
      { "L3MON4D3/LuaSnip", build = "make install_jsregexp" }, "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = { { name = "nvim_lsp" }, { name = "luasnip" }, { name = "buffer" }, { name = "path" } },
      })
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      for _, server in ipairs({ "pyright", "ruff", "ts_ls", "solidity_ls" }) do
        vim.lsp.config(server, { capabilities = capabilities })
        vim.lsp.enable(server)
      end
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Definition" })
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Declaration" })
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Implementation" })
      vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "References" })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
      vim.diagnostic.config({ virtual_text = true, signs = true, underline = true, update_in_insert = false })
    end,
  },

  -- Fast file switching
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>A", function() require("harpoon"):list():add() end, desc = "Harpoon add" },
      { "<leader>h", function() local h = require("harpoon"); h.ui:toggle_quick_menu(h:list()) end, desc = "Harpoon menu" },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
    },
    config = function() require("harpoon"):setup() end,
  },

  { "folke/flash.nvim", event = "VeryLazy", opts = {} },              -- press `s` to jump
  { "christoomey/vim-tmux-navigator", event = "VeryLazy" },           -- C-h/j/k/l across nvim+tmux

  -- Format (and ruff-fix) on save
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
      formatters_by_ft = { python = { "ruff_fix", "ruff_format" }, lua = { "stylua" } },
    },
  },

  { "nvim-lualine/lualine.nvim", event = "VeryLazy",
    opts = { sections = { lualine_c = { { "filename", path = 1 } } } } },

  -- Git
  { "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" }, opts = {} },
  { "sindrets/diffview.nvim", cmd = { "DiffviewOpen", "DiffviewFileHistory" } },
  { "rhysd/git-messenger.vim", cmd = "GitMessenger" },

  -- Editing
  { "tpope/vim-surround", event = "VeryLazy" },
  { "tpope/vim-commentary", event = "VeryLazy" },
  { "terryma/vim-multiple-cursors", event = "VeryLazy" },

  { "brenoprata10/nvim-highlight-colors", event = "VeryLazy", opts = {} },
  "nvim-tree/nvim-web-devicons",
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
}, {
  rocks = { enabled = false },
  change_detection = { notify = false },
})

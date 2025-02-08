-- local lsp_zero = require('lsp-zero')
--
-- lsp_zero.on_attach(function(client, bufnr)
--   local opts = {buffer = bufnr, remap = false}
--
--   vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
--   vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
--   vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
--   vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
--   vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
--   vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
--   vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
--   vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
--   vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
--   vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
-- end)
--
-- require('mason').setup({})
-- require('mason-lspconfig').setup({
--   -- ensure_installed = {'pyright'},
--     -- irasyti savo setup veliau
--   handlers = {
--     lsp_zero.default_setup,
--     lua_ls = function()
--       local lua_opts = lsp_zero.nvim_lua_ls()
--       require('lspconfig').lua_ls.setup(lua_opts)
--     end,
--   }
-- })
--
-- local cmp = require('cmp')
-- local cmp_select = {behavior = cmp.SelectBehavior.Select}
--
-- cmp.setup({
--   sources = {
--     {name = 'path'},
--     {name = 'nvim_lsp'},
--     {name = 'nvim_lua'},
--   },
--   formatting = lsp_zero.cmp_format(),
--   mapping = cmp.mapping.preset.insert({
--     ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
--     ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
--     ['<C-y>'] = cmp.mapping.confirm({ select = true }),
-- --    ['<CR>'] = cmd.mapping.confirm({ select = false }),
--     ['<C-Space>'] = cmp.mapping.complete(),
--   }),
-- })
--

local lspconfig = require("lspconfig")

-- Enable LSP servers
local servers = { "lua_ls", "clangd", "rust_analyzer", "pyright" }
for _, server in ipairs(servers) do
  lspconfig[server].setup({
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
  })
end

-- Keybindings for LSP
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename Symbol" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

local cmp = require("cmp")
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = {
    { name = "nvim_lsp" },
  },
})

vim.keymap.set("n", "gr", require('telescope.builtin').lsp_references, {})

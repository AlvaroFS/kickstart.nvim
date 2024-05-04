-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', { desc = 'NeoTree reveal' } },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
  init = function()
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('load_neo_tree', {}),
      desc = 'Loads neo-tree when openning a directory',
      callback = function(args)
        local stats = vim.uv.fs_stat(args.file)

        if not stats or stats.type ~= 'directory' then
          return
        end

        require 'neo-tree'

        return true
      end,
    })
  end,
}

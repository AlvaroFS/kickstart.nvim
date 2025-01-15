return {
  'akinsho/bufferline.nvim',
  event = 'VeryLazy',
  keys = {
    { '<leader>vp', '<Cmd>BufferLineTogglePin<CR>', desc = 'Toggle Pin' },
    { '<leader>vP', '<Cmd>BufferLineGroupClose ungrouped<CR>', desc = 'Delete Non-Pinned Buffers' },
    { '<leader>vo', '<Cmd>BufferLineCloseOthers<CR>', desc = 'Delete Other Buffers' },
    { '<leader>vr', '<Cmd>BufferLineCloseRight<CR>', desc = 'Delete Buffers to the Right' },
    { '<leader>vl', '<Cmd>BufferLineCloseLeft<CR>', desc = 'Delete Buffers to the Left' },
    { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev Buffer' },
    { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next Buffer' },
    { '<CS-h>', '<cmd>BufferLineMovePrev<cr>', desc = 'Move Buffer to the Left' },
    { '<CS-l>', '<cmd>BufferLineMoveNext<cr>', desc = 'Move Buffer to the Right' },
    { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev Buffer' },
    { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Next Buffer' },
  },
  opts = {
    options = {
      -- stylua: ignore
      close_command = function(n) require("mini.bufremove").delete(n, false) end,
      -- stylua: ignore
      middle_mouse_command = function(n) require("mini.bufremove").delete(n, false) end,
      diagnostics = 'nvim_lsp',
      always_show_bufferline = false,
      diagnostics_indicator = function(_, _, diag)
        local icons = {
          Error = ' ',
          Warn = ' ',
          Hint = ' ',
          Info = ' ',
        }
        local ret = (diag.error and icons.Error .. diag.error .. ' ' or '') .. (diag.warning and icons.Warn .. diag.warning or '')
        return vim.trim(ret)
      end,
      offsets = {
        {
          filetype = 'neo-tree',
          text = 'Neo-tree',
          highlight = 'Directory',
          text_align = 'center',
        },
      },
      groups = {
        options = {
          toggle_hidden_on_enter = true, -- when you re-enter a hidden group this options re-opens that group so the buffer is visible
        },
        items = {
          {
            name = 'Odin', -- Mandatory
            auto_close = false, -- whether or not close this group if it doesn't contain the current buffer
            priority = 1, -- determines where it will appear relative to other groups (Optional)
            matcher = function(buf) -- Mandatory
              return buf.path:match '%.odin'
            end,
          },
          {
            name = 'Shaders', -- Mandatory
            auto_close = false, -- whether or not close this group if it doesn't contain the current buffer
            priority = 2, -- determines where it will appear relative to other groups (Optional)
            matcher = function(buf) -- Mandatory
              return buf.path:match '%.glsl'
            end,
          },
          {
            name = 'Docs',
            auto_close = true, -- whether or not close this group if it doesn't contain the current buffer
            priority = 3, -- determines where it will appear relative to other groups (Optional)
            matcher = function(buf)
              return buf.path:match '%.md' or buf.path:match '%.txt'
            end,
          },
        },
      },
    },
  },
  config = function(_, opts)
    require('bufferline').setup(opts)
    -- Fix bufferline when restoring a session
    vim.api.nvim_create_autocmd('BufAdd', {
      callback = function()
        vim.schedule(function()
          pcall(nvim_bufferline)
        end)
      end,
    })
  end,
}

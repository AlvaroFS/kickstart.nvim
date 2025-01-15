-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    'theHamsta/nvim-dap-virtual-text',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F4>',
      function()
        require('dap').terminate()
      end,
      desc = 'Debug: Terminate',
    },
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F6>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F10>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F11>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
      },
    }

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<F4>', dap.terminate, { desc = 'Debug: Terminate' })
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F6>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F10>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F11>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font
        and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    dap.adapters.gdb = {
      type = 'executable',
      command = '/usr/bin/gdb', -- adjust as needed
      name = 'gdb',
      args = { '--quiet', '--interpreter=dap' },
    }
    dap.adapters.lldb = {
      type = 'executable',
      command = '/usr/bin/lldb-dap', -- adjust as needed
      name = 'lldb',
    }

    prompt_program = function()
      local path = vim.fn.input {
        prompt = 'Path to executable: ',
        default = vim.fn.getcwd() .. '/',
        completion = 'file',
      }
      return (path and path ~= '') and path or dap.ABORT
    end

    prompt_args = function()
      local argument_string = vim.fn.input 'Program arguments: '
      return vim.fn.split(argument_string, ' ', true)
    end
    -- predefine configs to change the working directory from program prompt
    local gdb_janga_project
    local gdb_liquigen
    local gdb_launch
    local gdb_attach
    local lldb_liquigen
    local lldb_launch
    local lldb_attach

    gdb_janga_project = {
      name = '(GDB)  Launch JangaFX project',
      type = 'gdb', -- matches the adapter
      request = 'launch', -- could also attach to a currently running process
      program = function()
        local project_name = vim.fn.input 'Project name: '
        local path = vim.fn.getcwd()
        path = path .. '/'
        path = path .. project_name

        gdb_janga_project.cwd = path

        path = path .. '/'
        path = path .. project_name
        return path
      end,
      stopOnEntry = false,
      args = {},
      runInTerminal = false,
    }
    gdb_liquigen = {
      name = '(GDB)  Launch LG',
      type = 'gdb',
      request = 'launch',
      program = function()
        return '${workspaceFolder}/liquigen/liquigen'
      end,
      cwd = '${workspaceFolder}/liquigen',
      stopOnEntry = false,
      runInTerminal = false,
    }
    gdb_launch = {
      name = '(GDB)  Launch...',
      type = 'gdb',
      request = 'launch',
      program = prompt_program,
      args = prompt_args,
      -- TODO: set cwd
      stopOnEntry = false,
      runInTerminal = false,
    }
    gdb_attach = {
      name = '(GDB)  Attach to process',
      type = 'gdb',
      request = 'attach',
      pid = require('dap.utils').pick_process,
      -- TODO: set cwd
      program = prompt_program,
    }

    lldb_liquigen = {
      name = '(LLDB) Launch LG',
      type = 'lldb',
      request = 'launch',
      program = function()
        return '${workspaceFolder}/liquigen/liquigen'
      end,
      cwd = '${workspaceFolder}/liquigen',
      stopOnEntry = false,
      runInTerminal = false,
    }
    lldb_launch = {
      name = '(LLDB) Launch...',
      type = 'lldb',
      request = 'launch',
      program = prompt_program,
      args = prompt_args,
      -- TODO: set cwd
      stopOnEntry = false,
      runInTerminal = false,
    }
    lldb_attach = {
      name = '(LLDB) Attach to process',
      type = 'lldb',
      request = 'attach',
      pid = require('dap.utils').pick_process,
      -- TODO: set cwd
      program = prompt_program,
    }

    dap.configurations.odin = {
      gdb_janga_project,
      gdb_liquigen,
      lldb_liquigen,
      gdb_launch,
      gdb_attach,
      lldb_launch,
      lldb_attach,
    }
    require('nvim-dap-virtual-text').setup {
      enabled = true,
      all_frames = false,
      highlight_changed_variables = true,
      only_first_definition = true,
      virt_text_win_col = 80,
      virt_text_pos = vim.fn.has 'nvim-0.10' == 1 and 'inline' or 'eol',
      show_stop_reason = true,
    }
  end,
}

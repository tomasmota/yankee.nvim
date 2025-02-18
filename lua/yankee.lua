local M = {}

-- Default options
local default_opts = {
  keymaps = {
    yank_file = "<leader>yy",
    yank_multiple = "<leader>ym"
  }
}

-- Store the original formatting function
local function format_single_file(filename, content, lang)
  return string.format(
    "Filename: %s\n```%s\n%s\n```",
    filename,
    lang,
    content
  )
end

-- Function to get the relative path of a file
local function get_relative_path(full_path)
  local cwd = vim.fn.getcwd()
  return full_path:sub(#cwd + 2)
end

-- Function to get file extension
local function get_file_extension(filename)
  return filename:match("%.([^%.]+)$") or ""
end

-- Function to determine the appropriate markdown language identifier
local function get_language_identifier(filename)
  local ext_to_lang = {
    lua = 'lua',
    py = 'python',
    js = 'javascript',
    jsx = 'javascript',
    ts = 'typescript',
    tsx = 'typescript',
    rs = 'rust',
    go = 'go',
    cpp = 'cpp',
    c = 'c',
    h = 'c',
    hpp = 'cpp',
    java = 'java',
    rb = 'ruby',
    php = 'php',
    html = 'html',
    css = 'css',
    scss = 'scss',
    md = 'markdown',
    json = 'json',
    yaml = 'yaml',
    yml = 'yaml',
    sh = 'bash',
    bash = 'bash',
    vim = 'vim',
    nix = 'nix',
  }
  local ext = get_file_extension(filename)
  return ext_to_lang[ext] or ext
end

-- Function to read file content
local function read_file_content(filepath)
  local file = io.open(filepath, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  return content
end

-- Function to format multiple files
local function format_multiple_files(files)
  local parts = {}

  for _, file in ipairs(files) do
    local relative_path = get_relative_path(file)
    local content = read_file_content(file)
    if content then
      local lang = get_language_identifier(file)
      table.insert(parts, format_single_file(relative_path, content, lang))
      table.insert(parts, "\n") -- Add separator between files
    end
  end

  return table.concat(parts, "\n")
end

-- Main function to yank single file content
function M.yank_for_llm()
  local filename = get_relative_path(vim.fn.expand('%:p'))
  local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  local lang = get_language_identifier(filename)

  local formatted_content = format_single_file(filename, content, lang)
  vim.fn.setreg('+', formatted_content)
  vim.notify('File content yanked for LLM with formatting', vim.log.levels.INFO)
end

-- Function to handle multiple file selection and yanking
function M.yank_multiple()
  -- Check if telescope is available
  local has_telescope, telescope = pcall(require, 'telescope.builtin')
  if not has_telescope then
    vim.notify('Telescope is required for multi-file selection', vim.log.levels.ERROR)
    return
  end

  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  telescope.find_files({
    attach_mappings = function(prompt_bufnr, map)
      -- Add a custom mapping for selecting/deselecting items
      map('i', '<tab>', function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        local entry = action_state.get_selected_entry()

        if entry then
          if vim.tbl_contains(selections, entry) then
            actions.remove_selection(prompt_bufnr)
          else
            actions.add_selection(prompt_bufnr)
          end
        end
      end)

      -- Add custom mapping for completing selection
      map('i', '<cr>', function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()

        if #selections > 0 then
          actions.close(prompt_bufnr)

          -- Format and yank the selected files
          local files = vim.tbl_map(function(selection)
            return selection.path
          end, selections)

          local formatted_content = format_multiple_files(files)
          vim.fn.setreg('+', formatted_content)

          vim.notify(string.format('Yanked %d files with formatting', #files), vim.log.levels.INFO)
        else
          -- If no files are selected, act as normal selection
          actions.select_default(prompt_bufnr)
        end
      end)

      return true
    end,
  })
end

-- Setup function
function M.setup(opts)
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  -- Set up keymaps
  if opts.keymaps.yank_file then
    vim.keymap.set('n', opts.keymaps.yank_file, M.yank_for_llm, {
      desc = "Yank current file with LLM formatting",
      silent = true
    })
  end

  if opts.keymaps.yank_multiple then
    vim.keymap.set('n', opts.keymaps.yank_multiple, M.yank_multiple, {
      desc = "Select and yank multiple files with LLM formatting",
      silent = true
    })
  end

  -- Create commands
  vim.api.nvim_create_user_command('Yankee', M.yank_for_llm, {})
  vim.api.nvim_create_user_command('YankeeMulti', M.yank_multiple, {})
end

return M


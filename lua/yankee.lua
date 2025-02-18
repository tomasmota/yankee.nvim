local M = {}

-- Default options
local default_opts = {
  keymaps = {
    yank_file = "<leader>yy"
  }
}

-- Function to get the relative path of the current file
local function get_relative_path()
  local full_path = vim.fn.expand('%:p')
  local cwd = vim.fn.getcwd()
  local relative_path = full_path:sub(#cwd + 2) -- +2 to account for the trailing slash
  return relative_path
end

-- Function to get the file extension
local function get_file_extension()
  local filename = vim.fn.expand('%:t')
  local ext = filename:match("%.([^%.]+)$")
  return ext or ""
end

-- Function to determine the appropriate markdown language identifier
local function get_language_identifier()
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

  local ext = get_file_extension()
  return ext_to_lang[ext] or ext
end

-- Main function to yank file content with metadata
function M.yank_for_llm()
  local filename = get_relative_path()
  local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  local lang = get_language_identifier()

  -- Format the content with filename and code blocks
  local formatted_content = string.format(
    "Filename: %s\n\n```%s\n%s\n```",
    filename,
    lang,
    content
  )

  -- Yank to system clipboard
  vim.fn.setreg('+', formatted_content)

  -- Show notification
  vim.notify('File content yanked for LLM with formatting', vim.log.levels.INFO)
end

-- Setup function to create the command
function M.setup(opts)
  -- Merge user options with defaults
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  -- Set up keymaps
  if opts.keymaps.yank_file then
    vim.keymap.set('n', opts.keymaps.yank_file, M.yank_for_llm, {
      desc = "Yank file content with LLM formatting",
      silent = true
    })
  end

  vim.api.nvim_create_user_command('Yankee', function()
    M.yank_for_llm()
  end, {})
end

return M


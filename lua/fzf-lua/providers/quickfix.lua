local core = require "fzf-lua.core"
local utils = require "fzf-lua.utils"
local config = require "fzf-lua.config"

local M = {}

local quickfix_run = function(opts, cfg, locations)
  if not locations then return {} end
  local results = {}

  opts = config.normalize_opts(opts, cfg)
  if not opts then return end

  if not opts.cwd then opts.cwd = vim.loop.cwd() end

  for _, entry in ipairs(locations) do
    table.insert(results, core.make_entry_lcol(opts, entry))
  end

  local contents = function(cb)
    for _, x in ipairs(results) do
      x = core.make_entry_file(opts, x)
      if x then
        cb(x, function(err)
          if err then return end
            -- close the pipe to fzf, this
            -- removes the loading indicator in fzf
            cb(nil, function() end)
        end)
      end
    end
    utils.delayed_cb(cb)
  end

  opts = core.set_fzf_field_index(opts)
  return core.fzf_files(opts, contents)
end

M.quickfix = function(opts)
  local locations = vim.fn.getqflist()
  if vim.tbl_isempty(locations) then
    utils.info("Quickfix list is empty.")
    return
  end

  return quickfix_run(opts, config.globals.quickfix, locations)
end

M.loclist = function(opts)
  local locations = vim.fn.getloclist(0)

  for _, value in pairs(locations) do
    value.filename = vim.api.nvim_buf_get_name(value.bufnr)
  end

  if vim.tbl_isempty(locations) then
    utils.info("Location list is empty.")
    return
  end

  return quickfix_run(opts, config.globals.loclist, locations)
end

return M

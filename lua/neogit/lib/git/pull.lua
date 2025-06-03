local git = require("neogit.lib.git")
local util = require("neogit.lib.util")
local logger = require("neogit.logger")

---@class NeogitGitPull
local M = {}

function M.pull_interactive(remote, branch, args)
  local client = require("neogit.client")
  local envs = client.get_envs_git_editor()
  return git.cli.pull.env(envs).args(remote or "", branch or "").arg_list(args).call { pty = true }
end

local function update_unpulled(state)
  local function elapsed_time(start_time)
    return (vim.loop.hrtime() - start_time) / 1e6
  end

  local total_start = vim.loop.hrtime()
  local last_time = total_start

  logger.debug("[update_unpulled]: begin")

  local status = git.branch.status()
  local current = vim.loop.hrtime()
  logger.debug(("[update_unpulled]: git.branch.status() complete (%.2fms)"):format(elapsed_time(last_time)))
  last_time = current

  state.upstream.unpulled.items = {}
  state.pushRemote.unpulled.items = {}

  if status.detached then
    return
  end

  logger.debug("[update_unpulled]: status.upstream start")
  if status.upstream then
    state.upstream.unpulled.items =
      util.filter_map(git.log.list({ "..@{upstream}" }, nil, {}, true), git.log.present_commit)
  end
  current = vim.loop.hrtime()
  logger.debug(("[update_unpulled]: status.upstream complete (%.2fms)"):format(elapsed_time(last_time)))
  last_time = current

  logger.debug("[update_unpulled]: pushRemote_ref() start")
  local pushRemote = git.branch.pushRemote_ref()
  current = vim.loop.hrtime()
  logger.debug(("[update_unpulled]: pushRemote_ref() complete (%.2fms)"):format(elapsed_time(last_time)))
  last_time = current

  logger.debug("[update_unpulled]: pushRemote start")
  if pushRemote then
    state.pushRemote.unpulled.items = util.filter_map(
      git.log.list({ string.format("..%s", pushRemote) }, nil, {}, true),
      git.log.present_commit
    )
  end
  current = vim.loop.hrtime()
  logger.debug(("[update_unpulled]: pushRemote complete (%.2fms)"):format(elapsed_time(last_time)))
  logger.debug(("[update_unpulled]: complete (%.2fms total)"):format(elapsed_time(total_start)))
end

function M.register(meta)
  meta.update_unpulled = update_unpulled
end

return M

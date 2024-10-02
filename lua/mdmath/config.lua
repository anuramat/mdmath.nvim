local default_opts = {
    enabled_filetypes = 'markdown'
}

local _opts = nil

local mt = {
    __newindex = function()
        error 'Attempt to modify read-only mdmath.nvim opts'
    end,
}
local M = {
    _validated = false,
}

function M.validate()
    if M._validated then
        return
    end

    -- TODO: validate _opts

    M._validated = true
end

function M._set(opts)
    if _opts then
        error 'Attempt to configure mdmath.nvim opts multiple times (how did you even do that?)'
    end

    _opts = vim.tbl_extend('force', default_opts, opts or {})
    mt.__index = function(_, key)
        M.validate() -- validate on first access

        mt.__index = _opts -- no need to validate anymore
        return _opts[key]
    end
end

setmetatable(M, mt)
return M

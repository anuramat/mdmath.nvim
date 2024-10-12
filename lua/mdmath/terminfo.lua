local api = vim.api

local M = {}

local winsize = nil

function M.size()
    if winsize == nil then
        winsize, err = require'mdmath.terminfo._system'.request_size()
        if not winsize then
            error('Failed to get terminal size: code ' .. err)
        end
    end
    
    return winsize
end

function M.cell_size()
    local size = M.size()

    local width = size.xpixel / size.col
    local height = size.ypixel / size.row

    return width, height
end

function M.refresh()
    winsize = nil
end

local function create_autocmd()
    api.nvim_create_autocmd('VimResized', {
        callback = function()
            M.refresh()
        end
    })
end

if vim.in_fast_event() then
    vim.schedule(create_autocmd)
else
    create_autocmd()
end

return M

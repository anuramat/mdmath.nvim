local M = {}

local winsize = nil

function M.size()
    if winsize == nil then
        winsize, err = require'md-math.terminfo._system'.request_size()
        if not winsize then
            error('failed to get terminal size: code ' .. err)
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

return M

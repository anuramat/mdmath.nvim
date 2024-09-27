local ffi = require'ffi'

local M = {}

-- TODO: is this magic number portable?
local TIOCGWINSZ = 0x5413

ffi.cdef[[
struct mdmath_winsize
{
    unsigned short int ws_row;
    unsigned short int ws_col;
    unsigned short int ws_xpixel;
    unsigned short int ws_ypixel;
};

int ioctl(int fd, unsigned long op, ...);
]]

function M.request_size()
    local ws = ffi.new 'struct mdmath_winsize'
    if ffi.C.ioctl(0, TIOCGWINSZ, ws) < 0 then
        return nil, ffi.errno()
    end

    return {
        row = ws.ws_row,
        col = ws.ws_col,
        xpixel = ws.ws_xpixel,
        ypixel = ws.ws_ypixel
    }
end

return M

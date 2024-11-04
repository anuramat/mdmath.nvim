local ffi = require'ffi'

local M = {}

local TIOCGWINSZ

-- Based on hologram.nvim
if vim.fn.has('linux') == 1 then
    TIOCGWINSZ = 0x5413
elseif vim.fn.has('mac') == 1 then
    TIOCGWINSZ = 0x40087468
elseif vim.fn.has('bsd') == 1 then
    TIOCGWINSZ = 0x40087468
else
    error('mdmath.nvim: Unsupported platform, please report this issue')
end

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
    if ffi.C.ioctl(1, TIOCGWINSZ, ws) < 0 then
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

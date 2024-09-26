local uv = vim.loop
local util = require'md-math.util'
local diacritics = require'md-math.Image.diacritics'

local stdout = uv.new_tty(1, false)
if not stdout then
    error('failed to open stdout')
end

local _id = 1
local function pop_id()
    local id = _id
    _id = _id + 1
    return id
end

local function kitty_send(params, payload)
    local tbl = {}
    for k, v in pairs(params) do
        tbl[#tbl + 1] = tostring(k) .. '=' .. tostring(v)
    end
    -- tbl[#tbl + 1] = 'q=2'
    tbl[#tbl + 1] = 'q=1'

    params = table.concat(tbl, ',')

    local message
    if payload ~= nil then
        message = string.format('\x1b_G%s;%s\x1b\\', params, vim.base64.encode(payload))
    else
        message = string.format('\x1b_G%s\x1b\\', params)
    end

    stdout:write(message)
end

local Image = util.new_class('Image')

function Image:__tostring()
    return string.format('<Image id=%d>', self.id)
end

function Image:_init(rows, cols, payload)
    local id = pop_id()
    if self.id then
        self:close()
    end

    self.id = id
    self.rows = rows
    self.cols = cols

    kitty_send({i = id, f = 100, t = 'f'}, payload)
    kitty_send({i = id, U = 1, a = 'p', r = rows, c = cols})
end

function Image.unicode_at(row, col)
    return '\u{10EEEE}' .. diacritics[row] .. diacritics[col]
end

function Image:text()
    local text = {}
    for row = 1, self.rows do
        local T = {}
        for col = 1, self.cols do
            T[#T + 1] = Image.unicode_at(row, col)
        end
        text[#text + 1] = table.concat(T)
    end
    return text
end

function Image:color()
    return self.id -- Color is represented by the id
end

function Image:close()
    if not self.id then
        return
    end

    -- TODO: close image
    self.id = nil
end

return Image

if (not SILE.outputters) then SILE.outputters = {} end

local cursorX = 0
local cursorY = 0


local lastFont
local outfile
local writeline = function (...)
	local args = table.pack(...)
	for i = 1, #args do
		outfile:write(args[i])
		if i < #args then outfile:write("\t") end
	end
	outfile:write("\n")
end

local _deprecationCheck = function (caller)
  if type(caller) ~= "table" or type(caller.debugHbox) ~= "function" then
    SU.deprecated("SILE.outputter.*", "SILE.outputter:*", "0.10.9", "0.10.10")
  end
end

local function _round (input)
  return string.format("%.4f", input)
end

SILE.outputters.debug = {

  init = function (self)
    _deprecationCheck(self)
    outfile = io.open(SILE.outputFilename, "w+")
    writeline("Set paper size ", SILE.documentState.paperSize[1], SILE.documentState.paperSize[2])
    writeline("Begin page")
  end,

  newPage = function (self)
    _deprecationCheck(self)
    writeline("New page")
  end,

  finish = function (self)
    _deprecationCheck(self)
    if SILE.status.unsupported then writeline("UNSUPPORTED") end
    writeline("End page")
    writeline("Finish")
    outfile:close()
  end,

  cursor = function (self)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:cursor", "SILE.outputter:getCursor", "0.10.10", "0.11.0")
    return self:getCursor()
  end,

  getCursor = function (self)
    _deprecationCheck(self)
    return cursorX, cursorY
  end,

  moveTo = function (self, x, y)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:moveTo", "SILE.outputter:setCursor", "0.10.10", "0.11.0")
    return self:setCursor(x, y)
  end,

  setCursor = function (self, x, y, relative)
    _deprecationCheck(self)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    local oldx, oldy = self:getCursor()
    local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
    cursorX = offset.x + x
    cursorY = offset.y - y
    if _round(oldx) ~= _round(cursorX) then writeline("Mx ", _round(x)) end
    if _round(oldy) ~= _round(cursorY) then writeline("My ", _round(y)) end
  end,

  setColor = function (self, color)
    _deprecationCheck(self)
    writeline("Set color", color.r, color.g, color.b)
  end,

  pushColor = function (self, color)
    _deprecationCheck(self)
    writeline("Push color", _round(color.r), _round(color.g), _round(color.b))
  end,

  popColor = function (self)
    _deprecationCheck(self)
    writeline("Pop color")
  end,

  outputHbox = function (self, value, width)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:outputHbox", "SILE.outputter:drawHbox", "0.10.10", "0.11.0")
    return self:drawHbox(value, width)
  end,

  drawHbox = function (self, value, _)
    _deprecationCheck(self)
    local buf = {}
    for i=1, #(value.glyphString) do
      buf[#buf+1] = value.glyphString[i]
    end
    buf = table.concat(buf, " ")
    writeline("T", buf, "("..value.text..")")
  end,

  setFont = function (self, options)
    _deprecationCheck(self)
    local font = SILE.font._key(options)
    if lastFont ~= font then
      writeline("Set font ", SILE.font._key(options))
      lastFont = font
    end
  end,

  drawImage = function (self, src, x, y, width, height)
    _deprecationCheck(self)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    width = SU.cast("number", width)
    height = SU.cast("number", height)
    writeline("Draw image", src, _round(x), _round(y), _round(width), _round(height))
  end,

  imageSize = function (self, src)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:imageSize", "SILE.outputter:getImageSize", "0.10.10", "0.11.0")
    return self:getImageSize(src)
  end,

  getImageSize = function (self, src)
    _deprecationCheck(self)
    local pdf = require("justenoughlibtexpdf")
    local llx, lly, urx, ury = pdf.imagebbox(src)
    return (urx-llx), (ury-lly)
  end,

  drawSVG = function (self, figure, _, x, y, width, height, scalefactor)
    _deprecationCheck(self)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    width = SU.cast("number", width)
    height = SU.cast("number", height)
    writeline("Draw SVG", _round(x), _round(y), _round(width), _round(height), figure, scalefactor)
  end,

  rule = function (self, x, y, width, depth)
    _deprecationCheck(self)
    SU.deprecated("SILE.outputter:rule", "SILE.outputter:drawRule", "0.10.10", "0.11.0")
    return self:drawRule(x, y, width, depth)
  end,

  drawRule = function (self, x, y, width, depth)
    _deprecationCheck(self)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    width = SU.cast("number", width)
    depth = SU.cast("number", depth)
    writeline("Draw line", _round(x), _round(y), _round(width), _round(depth))
  end,

  debugFrame = function (self, _, _)
    _deprecationCheck(self)
  end,

  debugHbox = function (self, _, _, _)
    _deprecationCheck(self)
  end

}

SILE.outputter = SILE.outputters.debug

if not SILE.outputFilename and SILE.masterFilename then
  SILE.outputFilename = SILE.masterFilename..".debug"
end

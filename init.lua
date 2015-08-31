--- === hs._asm.text ===
---
--- Text related functions and such, ultimately for use with hs.drawing

--- === hs._asm.text.attributes ===
---
--- Build up a font attribute table for use in hs.drawing

local drawing     = require("hs.drawing") -- make sure drawing classes are available for linking
local module      = require("hs._asm.text.internal")
module.font       = require("hs._asm.text.font")
module.attributes = require("hs._asm.text.attributes")

-- private variables and methods -----------------------------------------

-- Public interface ------------------------------------------------------

-- Return Module Object --------------------------------------------------

return module

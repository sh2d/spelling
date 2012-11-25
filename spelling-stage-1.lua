--- spelling-stage-1.lua
--- Copyright 2012 Stephan Hennig
--
-- This work may be distributed and/or modified under the conditions of
-- the LaTeX Project Public License, either version 1.3 of this license
-- or (at your option) any later version.  The latest version of this
-- license is in http://www.latex-project.org/lppl.txt
-- and version 1.3 or later is part of all distributions of LaTeX
-- version 2005/12/01 or later.
--
-- See file README for more information.
--


--- Read list(s) of bad strings.
--
-- @author Stephan Hennig
-- @copyright 2012 Stephan Hennig
-- @release version 0.1
--
-- @trick Prevent LuaDoc from looking past here for module description.
--[[ Trick LuaDoc into entering 'module' mode without using that command.
module(...)
--]]


-- Module table.
local M = {}


-- Function short-cuts.


-- Declare local variables to store references to resources that are
-- provided by external code.
--
-- Table of known bad strings.
local __is_bad


--- Set module resources.
-- Make various resources, that are provided by external code, available
-- to this module.
--
-- @param res  Ressource table.
local function set_resources(res)
  __is_bad = res.is_bad
end
M.set_resources = set_resources


--- Read a list of bad strings from a file.
-- All strings read from the given file (words with known incorrect
-- spelling) are mapped to the boolean value `true` in table `__is_bad`.
-- The format of the file is simple: one string per file.
--
-- @param fname  Name of file containing bad strings.  If an empty string
-- is provided, strings are read from file `<jobname>.bad`.
local function read_bad_strings(fname)
  local total_c = 0
  -- If file name is empty, set default file name.
  if fname == '' then
    fname = tex.jobname .. '.bad'
  end
  local f, msg = io.open(fname, 'r')
  if f then
    -- Iterate line-wise through file.
    for l in f:lines() do
      -- Map string to boolean value `true`.
      __is_bad[l] = true
      total_c = total_c + 1
    end
  else
    texio.write_nl('package spelling: Warning! Could not open file: ' .. msg)
  end
  texio.write_nl('package spelling: ' .. total_c .. ' bad strings read from file \'' .. fname .. '\'.')
end
M.read_bad_strings = read_bad_strings


-- Return module table.
return M

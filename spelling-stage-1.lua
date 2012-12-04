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


--- Read lists of bad and good strings.
--
-- @author Stephan Hennig
-- @copyright 2012 Stephan Hennig
-- @release version 0.2
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
--
-- Table of known good strings.
local __is_good


--- Set module resources.
-- Make various resources, that are provided by external code, available
-- to this module.
--
-- @param res  Ressource table.
local function set_resources(res)
  __is_bad = res.is_bad
  __is_good = res.is_good
end
M.set_resources = set_resources


--- Generic function for parsing a plain list of strings read from a
--- file.
-- All strings found are mapped to the boolean value `true`.  The format
-- of the input file is one string per line.
--
-- @param fname  File name.
-- @param t  Table that maps strings to the value `true`.
-- @return Number of total and new strings found.
local function __parse_plain_list_file(fname, t)
  local f, err = io.open(fname, 'r')
  if not f then
    texio.write_nl('package spelling: Error! Can\'t parse plain word list: file ' .. fname)
    error(err)
  end
  -- Read complete plain file into string, to speed-up file operations.
  local s = f:read('*all')
  f:close()
  local total_c = 0
  local new_c = 0
  -- Iterate line-wise through file.
  for l in s:gmatch('[^\r\n]+') do
    -- Map string to boolean value `true`.
    if not t[l] then
      t[l] = true
      new_c = new_c + 1
    end
    total_c = total_c + 1
  end
  return total_c, new_c
end


--- Parse a plain list of bad strings read from a file.
-- All strings found (words with known incorrect spelling) are mapped to
-- the boolean value `true` in table `__is_bad`.  The format of the
-- input file is one string per line.
--
-- @param fname  File name.
local function parse_bad_plain_list_file(fname)
  local total, new = __parse_plain_list_file(fname, __is_bad)
  texio.write_nl('package spelling: ' .. total .. ' bad strings ('
                 .. new .. ' new) read from file \'' .. fname .. '\'.')
end
M.parse_bad_plain_list_file = parse_bad_plain_list_file


--- Parse a plain list of good strings read from a file.
-- All strings found (words with known correct spelling) are mapped to
-- the boolean value `true` in table `__is_good`.  The format of the
-- input file is one string per line.
--
-- @param fname  File name.
local function parse_good_plain_list_file(fname)
  local total, new = __parse_plain_list_file(fname, __is_good)
  texio.write_nl('package spelling: ' .. total .. ' good strings ('
                 .. new .. ' new) read from file \'' .. fname .. '\'.')
end
M.parse_good_plain_list_file = parse_good_plain_list_file


--- Parse default sources for bad and good strings.
-- All strings found in default sources for words with known incorrect
-- spelling are mapped to the boolean value `true` in table `__is_bad`.
-- All strings found in default sources for words with known correct
-- spelling are mapped to the boolean value `true` in table `__is_good`.
-- Default sources for bad spellings are file `<jobname>.spb`.  Default
-- sources for good spellings are file `<jobname>.spg`.
local function parse_default_bad_and_good()
  local fname, f
  -- Try to read bad spellings from plain list file '<jobname>.spb'.
  fname = tex.jobname .. '.spb'
  f = io.open(fname, 'r')
  if f then
     f:close()
     parse_bad_plain_list_file(fname)
  end
  -- Try to read good spellings from plain list file '<jobname>.spg'.
  fname = tex.jobname .. '.spg'
  f = io.open(fname, 'r')
  if f then
     f:close()
     parse_good_plain_list_file(fname)
  end
end
M.parse_default_bad_and_good = parse_default_bad_and_good


-- Return module table.
return M

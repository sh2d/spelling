--- spelling-stage-1.lua
--- Copyright 2012, 2013 Stephan Hennig
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


--- Parse sources of bad and good strings.
--
-- @author Stephan Hennig
-- @copyright 2012, 2013 Stephan Hennig
-- @release version 0.3
--
-- @trick Prevent LuaDoc from looking past here for module description.
--[[ Trick LuaDoc into entering 'module' mode without using that command.
module(...)
--]]


-- Module table.
local M = {}


-- Import external modules.
local unicode = require('unicode')
local xml = require('luaxml-mod-xml')


-- Function short-cuts.
local Ufind = unicode.utf8.find
local Ugmatch = unicode.utf8.gmatch
local Usub = unicode.utf8.sub


-- Declare local variables to store references to resources that are
-- provided by external code.
--
-- Table of known bad strings.
local __is_bad
--
-- Table of known good strings.
local __is_good


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
  for l in Ugmatch(s, '[^\r\n]+') do
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


--- Parse LanguageTool XML data.
-- Currently, XML data is only scanned for incorrect spellings.  All
-- strings found in the given XML data (words with known incorrect
-- spelling) are mapped to the boolean value `true` in table `__is_bad`.
--
-- @param s  String containing XML data.  XML data is checked for being
-- created by LanguageTool (via attribute <code>software</code> in tag
-- <code>matches</code>) and otherwise ignored.
-- @return Number of total and new incorrect spellings parsed.
local function __parse_XML_LanguageTool(s)
  local total_c = 0
  local new_c = 0

  -- Some flags for checking validity of XML data.  LanguageTool XML
  -- data must declare as being UTF-8 encoded and advertise as being
  -- created by LanguageTool.
  local is_XML_encoding_UTF_8 = false
  local is_XML_creator_LanguageTool = false
  local is_XML_valid = false

  --- Handler object for parsing LanguageTool XML data.
  -- This table contains call-backs used by LuaXML when parsing XML
  -- data.
  --
  -- @class table
  -- @name XML_handler
  -- @field decl  Handle XML declaration.
  -- @field starttag  Handle all relevant tags.
  -- @field endtag  Not used, but mandatory.
  local XML_handler = {

    decl = function(self, text, attr)
      -- Check XML encoding declaration.
      if attr.encoding == 'UTF-8' then
        is_XML_encoding_UTF_8 = true
        is_XML_valid = is_XML_encoding_UTF_8 and is_XML_creator_LanguageTool
      else
        error('package spelling: Error! XML data not in the UTF-8 encoding.')
      end
    end,

    starttag = function(self, text, attr)
      -- Process <matches> tag.
      if text == 'matches' then
        -- Check XML creator is LanguageTool.
        if attr and attr.software == 'LanguageTool' then
          is_XML_creator_LanguageTool = true
          is_XML_valid = is_XML_encoding_UTF_8 and is_XML_creator_LanguageTool
        end
      -- Check XML data is valid.
      elseif not is_XML_valid then
        error('package spelling: Error! No valid LanguageTool XML data.')
      -- Process <error> tags.
      elseif text == 'error' then
        local ruleid = attr.ruleid
        if ruleid == 'HUNSPELL_RULE'
          or ruleid == 'HUNSPELL_NO_SUGGEST_RULE'
          or ruleid == 'GERMAN_SPELLER_RULE'
          or Ufind(ruleid, '^MORFOLOGIK_RULE_')
        then
          -- Extract misspelled word from context attribute.
          local word = Usub(attr.context, attr.contextoffset + 1, attr.contextoffset + attr.errorlength)
          if not __is_bad[word] then
            __is_bad[word] = true
            new_c = new_c + 1
          end
          total_c = total_c + 1
        end
      end
    end,

    endtag = function(self, text)
    end,

  }

  -- Create custom XML parser.
  local x = xml.xmlParser(XML_handler)
  -- Parse XML data.
  x:parse(s)
  return total_c, new_c
end


--- Parse LanguageTool XML data read from a file.
-- All strings found in the file (words with known incorrect spelling)
-- are mapped to the boolean value `true` in table `__is_bad`.
--
-- @param fname  File name.
local function parse_XML_LanguageTool_file(fname)
  local f, err = io.open(fname, 'r')
  if not f then
    texio.write_nl('package spelling: Error! Can\'t parse LanguageTool XML error report: file ' .. fname)
    error(err)
  end
  -- Read complete XML file into string, since LuaXML has no streaming
  -- file reader.
  local s = f:read('*all')
  f:close()
  local success, total, new = pcall(__parse_XML_LanguageTool, s)
  if not success then
    texio.write_nl('package spelling: Error! Can\'t parse LanguageTool XML error report: file ' .. fname)
    error(total)
  end
  texio.write_nl('package spelling: ' .. total .. ' bad strings ('
                 .. new .. ' new) read from file \'' .. fname .. '\'.')
end
M.parse_XML_LanguageTool_file = parse_XML_LanguageTool_file


--- Parse default sources for bad and good strings.
-- All strings found in default sources for words with known incorrect
-- spelling are mapped to the boolean value `true` in table `__is_bad`.
-- All strings found in default sources for words with known correct
-- spelling are mapped to the boolean value `true` in table `__is_good`.
-- Default sources for bad spellings are file `<jobname>.spell.bad` (a
-- plain list file).  Default sources for good spellings are file
-- `<jobname>.spell.good` (a plain list file).
local function parse_default_bad_and_good()
  local fname, f
  -- Try to read bad spellings from plain list file
  -- '<jobname>.spell.bad'.
  fname = tex.jobname .. '.spell.bad'
  f = io.open(fname, 'r')
  if f then
     f:close()
     parse_bad_plain_list_file(fname)
  end
  -- Try to read bad spellings from LanguageTool XML file
  -- '<jobname>.spell.xml'.
  fname = tex.jobname .. '.spell.xml'
  f = io.open(fname, 'r')
  if f then
     f:close()
     parse_XML_LanguageTool_file(fname)
  end
  -- Try to read good spellings from plain list file
  -- '<jobname>.spell.good'.
  fname = tex.jobname .. '.spell.good'
  f = io.open(fname, 'r')
  if f then
     f:close()
     parse_good_plain_list_file(fname)
  end
end
M.parse_default_bad_and_good = parse_default_bad_and_good


--- Module initialisation.
--
local function __init()
  -- Get local references to package ressources.
  __is_bad = PKG_spelling.res.is_bad
  __is_good = PKG_spelling.res.is_good
end


-- Initialize module.
__init()


-- Return module table.
return M

--- spelling-stage-3.lua
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


--- Store the text of a LuaTeX document in a text document data
--- structure.
-- This module provides means to extract text from a LuaTeX document and
-- to store it in a text document data structure.
--
-- In the text document, words are stored as UTF-8 encoded strings.  A
-- mapping mechanism is provided by which, during word recognition,
-- individual code-points, e.g., of glyph nodes, can be translated to
-- arbitrary UTF-8 strings, e.g., ligatures to single letters.
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
local tabconcat = table.concat
local tabinsert = table.insert
local utf8char = unicode.utf8.char


-- Short-cuts for constants.
local DISC = node.id('disc')
local GLYPH = node.id('glyph')
local HLIST = node.id('hlist')
local KERN = node.id('kern')
local PUNCT = node.id('punct')
local VLIST = node.id('vlist')
local WHATSIT = node.id('whatsit')


-- Declare local variables to store references to resources that are
-- provided by external code.
--
-- Text document data structure.
local __text_document


--- Set module resources.
-- Make various resources, that are provided by external code, available
-- to this module.
--
-- @param res  Ressource table.
local function set_resources(res)
  __text_document = res.text_document
end
M.set_resources = set_resources


--- Convert a Unicode code point to a regular UTF-8 encoded string.
-- This function can be used as an `__index` meta method.
--
-- @param t  original table
-- @param cp  originl key, a Unicode code point
-- @return UTF-8 encoded string corresponding to the Unicode code point.
local function __meta_cp2utf8(t, cp)
  return utf8char(cp)
end


--- Table of Unicode code point mappings.
-- This table maps Unicode code point to strings.  The mappings are used
-- during text extraction to translate certain Unicode code points to an
-- arbitrary string instead of the corresponding UTF-8 encoded
-- character.<br />
--
-- As an example, by adding an appropriate entry to this table, the
-- single Unicode code point U-fb00 (LATIN SMALL LIGATURE FF) can be
-- resolved into the multi character string 'ff' instead of being
-- converted to the single character string 'ﬀ' ('&#xfb00;').<br />
--
-- Keys are Unicode code points.  Values must be strings in the UTF-8
-- encoding.  If a key is not present in this table, the regular UTF-8
-- character is returned by means of a meta table.<br />
--
-- @class table
-- @name __codepoint_map
local __codepoint_map = {

  [0x0132] = 'IJ',-- LATIN CAPITAL LIGATURE IJ
  [0x0133] = 'ij',-- LATIN SMALL LIGATURE IJ
  [0x0152] = 'OE',-- LATIN CAPITAL LIGATURE OE
  [0x0153] = 'oe',-- LATIN SMALL LIGATURE OE
  [0x017f] = 's',-- LATIN SMALL LETTER LONG S

  [0x1e9e] = 'SS',-- LATIN CAPITAL LETTER SHARP S

  [0xfb00] = 'ff',-- LATIN SMALL LIGATURE FF
  [0xfb01] = 'fi',-- LATIN SMALL LIGATURE FI
  [0xfb02] = 'fl',-- LATIN SMALL LIGATURE FL
  [0xfb03] = 'ffi',-- LATIN SMALL LIGATURE FFI
  [0xfb04] = 'ffl',-- LATIN SMALL LIGATURE FFL
  [0xfb05] = 'st',-- LATIN SMALL LIGATURE LONG S T
  [0xfb06] = 'st',-- LATIN SMALL LIGATURE ST

}


--- Meta table for code point mapping table.
--
-- @class table
-- @name __meta_codepoint_map
-- @field __index  Index operator.
local __meta_codepoint_map = {
   __index = __meta_cp2utf8,
}


-- Set meta table for code point mapping table.
setmetatable(__codepoint_map, __meta_codepoint_map)


--- Clear all code point mappings.
-- After calling this function, there are no known code point mappings
-- and no code point mapping takes place during text extraction.
local function clear_all_mappings()
  __codepoint_map = {}
  setmetatable(__codepoint_map, __meta_codepoint_map)
end
M.clear_all_mappings = clear_all_mappings


--- Manage Unicode code point mappings.
-- This function can be used to set-up code point mappings.  First
-- argument must be a number, second argument must be a string in the
-- UTF-8 encoding or `nil`.<br />
--
-- If the second argument is a string, after calling this function, the
-- Unicode code point given as first argument, when found in a node list
-- during text extraction, is mapped to the string given as second
-- argument instead of being converted to a UTF-8 encoded character
-- corresponding to the code point.<br />
--
-- If the second argument is `nil`, a mapping for the given code point,
-- if existing, is deleted.
--
-- @param cp A Unicode code point, e.g., 0xfb00 for the code point LATIN
-- SMALL LIGATURE FF.
-- @param newt  New target string to map the code point to or `nil`.
-- @return Old target string the code point was mapped to before
-- (possibly `nil`).  If any arguments are invalid, return value is
-- `false`.  Arguments are invalid if code point is not of type `number`
-- or not in the range 0 to 0x10ffff or if new target string is neither
-- of type `string` nor `nil`).
local function set_mapping(cp, newt)
  -- Prevent from invalid entries in mapping table.
  if (type(cp) ~= 'number') or
     (cp < 0) or
     (cp > 0x10ffff) or
     ((type(newt) ~= 'string') and (type(newt) ~= 'nil')) then
    return false
  end
  -- Retrieve old mapping.
  local oldt = rawget(__codepoint_map, cp)
  -- Set new mapping.
  __codepoint_map[cp] = newt
  -- Return old mapping.
  return oldt
end
M.set_mapping = set_mapping


--- Data structure that stores the word strings found in a node list.
--
-- @class table
-- @name __curr_paragraph
local __curr_paragraph


--- Data structure that stores the characters of a word string.
-- The current word data structure is an ordered list (an array) of the
-- characters of the word.  The characters are collected while scanning
-- a node list.  They are concatenated to a single string only after the
-- end of a word is detected, before inserting the current word into the
-- current paragraph data structure.
--
-- @class table
-- @name __curr_word
local __curr_word


--- Finish current word.
-- If the current word contains visible characters, store the current
-- word in the current paragraph.
local function __finish_current_word()
  -- Finish a word?
  if __curr_word then
    -- Provide new empty paragraph, if necessary.
    if not __curr_paragraph then
      __curr_paragraph = {}
    end
    -- Append current word to current paragraph.
    tabinsert(__curr_paragraph, tabconcat(__curr_word))
    __curr_word = nil
  end
end


--- Finish current paragraph.
-- If the current paragraph contains words, store the current paragraph
-- in the text document.
local function __finish_current_paragraph()
  -- Finish current word.
  __finish_current_word()
  -- Finish a paragraph?
  if __curr_paragraph then
    -- Append current paragraph to document structure.
    tabinsert(__text_document, __curr_paragraph)
    __curr_paragraph = nil
  end
end


--- Scan a node list for text and append that to the document structure.
-- The given node list is scanned for chaines of nodes representing a
-- word.  These words are stored in the current paragraph.
--
-- @param head  Node list.
local function __scan_nodelist_for_text(head)
  for n in node.traverse(head) do
    local nid = n.id
    -- Test for vlist node.
    if nid == VLIST then
      -- Recurse into vlist, ending the current paragraph before and
      -- after.  Possible improvement: If the vlist is empty or contains
      -- a single hlist only, don't end the current paragraph.  A bad
      -- hack, but it would help with the \LaTeX logo.
      __finish_current_paragraph()
      __scan_nodelist_for_text(n.head)
      __finish_current_paragraph()
    -- Test for hlist node.
    elseif nid == HLIST then
      -- Seamlessly recurse into hlist as if it were non-existent.
      __scan_nodelist_for_text(n.head)
    -- Test for glyph node.
    elseif nid == GLYPH then
      -- Provide new empty word, if necessary.
      if not __curr_word then
        __curr_word = {}
      end
      -- Append character to current word.
      tabinsert(__curr_word, __codepoint_map[n.char])
    -- Test for other word component nodes.
    elseif (nid == DISC) or (nid == KERN) or (nid == PUNCT) then
      -- We're still within the current word.  Do nothing.
    else
      -- End of current word detected.
      __finish_current_word()
    end
  end
end


--- Scan a node list for text, starting a new paragraph before and
--- after.
--
-- @param head  Node list.
local function __nodelist_to_text(head)
  __scan_nodelist_for_text(head)
  __finish_current_paragraph()
end


--- Call-back function that processes the node list.
-- The node list is not manipulated.
--
-- @param head  Node list.
-- @return true
local function __cb_pre_linebreak_filter_pkg_spelling(head)
  __nodelist_to_text(head)
  return true
end


-- Call-back status.
local __is_active_storage


--- Start extracting text.
-- After calling this function, text is extracted from a LuaTeX
-- document.
local function enable_text_storage()
  if not __is_active_storage then
    -- Register call-back: Before LuaTeX breaks a paragraph into lines,
    -- extract the text of the paragraph and store it in memory.
    luatexbase.add_to_callback('pre_linebreak_filter', __cb_pre_linebreak_filter_pkg_spelling, '__cb_pre_linebreak_filter_pkg_spelling')
    __is_active_storage = true
  end
end
M.enable_text_storage = enable_text_storage


--- Stop extracting text.
-- After calling this function, no more text is extracted from a LuaTeX
-- document.
local function disable_text_storage()
  if __is_active_storage then
    -- Un-register callback.
    luatexbase.remove_from_callback('pre_linebreak_filter', '__cb_pre_linebreak_filter_pkg_spelling')
    __is_active_storage = false
  end
end
M.disable_text_storage = disable_text_storage


--- Module initialisation.
--
local function __init()
  -- Remember call-back status.
  __is_active_storage = false
end


-- Initialize module.
__init()


-- Return module table.
return M

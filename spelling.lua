--- spelling.lua
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


-- Function short-cuts.
local tabconcat = table.concat
local tabinsert = table.insert
local utf8char = unicode.utf8.char
local utf8len = unicode.utf8.len


-- Short-cuts for constants.
local DISC = node.id('disc')
local GLYPH = node.id('glyph')
local HLIST = node.id('hlist')
local KERN = node.id('kern')
local PUNCT = node.id('punct')
local VLIST = node.id('vlist')
local WHATSIT = node.id('whatsit')


-- With this table it is possible to translate Unicode code points to
-- arbitrary strings.  As an example, the single Unicode code point
-- U-fb00 (LATIN SMALL LIGATURE FF) can be resolved into the multi
-- character string 'ff' instead of being converted to the single
-- character string 'ﬀ'.  The resulting string must be in the UTF-8
-- encoding.
local transl_codepoint = {

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

  -- Meta table for ourselves.
  mt = {
     --- Retrieve regular UTF-8 character as a fall-back.
     __index = function(t, cp)
                  return utf8char(cp)
               end
  }

}
-- Set meta table for code point translation table.
setmetatable(transl_codepoint, transl_codepoint.mt)


-- This table represents the document.  It contains all text of the
-- type-set document as an array of paragraphs.  A paragraph is an array
-- of single words.  At the end of the LuaTeX run, all paragraphs of the
-- document are broken into lines of a fixed length and the lines are
-- then written to a file.  Here's the rationale of this approach:
--
-- * It saves space.  In Lua strings are internalized.  Since, in
--   general, in texts the same words are used over and over again,
--   relatively few strings are actually stored in memory.
--
-- * It reduces file access during the LuaTeX run.
--
-- * It allows for pre-processing the document text before writing it to
--   a file.
--
-- Create an empty document.
local text_document = {}


-- The current paragraph (an array of words).  This non-local variable
-- is used while searching a node list for text in function
-- `scan_nodelist_for_text`.
local curr_paragraph = {}
-- The current word (an array of UTF-8 encoded strings).  This non-local
-- variable is used while searching a node list for text in function
-- `scan_nodelist_for_text`.
local curr_word = {}


--- Finish current paragraph and start a new one.
-- The current paragraph is finished: The current word, if non-empty is
-- appended to the current paragraph, which in turn, if non-empty, is
-- appended to the document structure.  After calling this function, the
-- current word and current paragraph are empty.
local function start_text_paragraph()
  -- Insert non-empty current word into current paragraph.
  if #curr_word > 0 then
    tabinsert(curr_paragraph, tabconcat(curr_word))
    curr_word = {}
  end
  -- Insert non-empty current paragraph into document structure.
  if #curr_paragraph > 0 then
    tabinsert(text_document, curr_paragraph)
    curr_paragraph = {}
  end
end


--- Scan a node list for text and append that to the document structure.
-- The given node list is scanned for chaines of nodes representing a
-- word.  These words are stored as a list of UTF-8 encoded strings.
--
-- @param head  Node list.
local function scan_nodelist_for_text(head)
  for n in node.traverse(head) do
    local nid = n.id
    -- Test for vlist node.
    if nid == VLIST then
      -- Recurse into vlist, starting a new paragraph before and after.
      -- Possible improvement: If the vlist is empty or contains a
      -- single hlist only, don't start a new paragraph.  A bad hack,
      -- but it would help with the \LaTeX logo.
      start_text_paragraph()
      scan_nodelist_for_text(n.head)
      start_text_paragraph()
    -- Test for hlist node.
    elseif nid == HLIST then
      -- Recurse into hlist.
      scan_nodelist_for_text(n.head)
    -- Test for glyph node.
    elseif nid == GLYPH then
      -- Append character to current word.
      tabinsert(curr_word, transl_codepoint[n.char])
    -- Test for other word component nodes.
    elseif (nid == DISC) or (nid == KERN) or (nid == PUNCT) then
      -- Do nothing.
    else
      -- End of current word detected.  If non-empty, append current
      -- word to current paragraph, converting it from table to string
      -- representation first.
      if #curr_word > 0 then
        tabinsert(curr_paragraph, tabconcat(curr_word))
        -- Start new current word.
        curr_word = {}
      end
    end
  end
end


--- Scan a node list for text, starting a new paragraph before and
--- after.
--
-- @param head  Node list.
local function nodelist_to_text(head)
  start_text_paragraph()
  scan_nodelist_for_text(head)
  start_text_paragraph()
end


--- Callback function that scans a node list for text and stores that in
--- the document structure.
-- The node list is not manipulated.
--
-- @param head  Node list.
-- @return true
local function cb_plf_pkg_spelling(head)
  nodelist_to_text(head)
  return true
end


--- Break a paragraph into lines of a fixed length and write the lines
--- to a file.
--
-- @param par  A text paragraph (an array of words).
-- @param f  A file handle.
-- @param maxlinelength  Maximum line length in output.
local function write_text_paragraph(par, f, maxlinelength)
  -- Index of first word on current line.  Initialize current line with
  -- first word of paragraph.
  local lstart = 1
  -- Track current line length.
  local llen = utf8len(par[1])
  -- Iterate over remaining words in paragraph.
  for i = 2,#par do
    local wlen = utf8len(par[i])
    -- Does word fit onto current line?
    if llen + 1 + wlen <= maxlinelength then
      -- Append word to current line.
      llen = llen + 1 + wlen
    else
      -- Write the current line up to the preceeding word to file (words
      -- separated by spaces and with a trailing newline).
      f:write(tabconcat(par, ' ', lstart, i-1), '\n')
      -- Initialize new current line.
      lstart = i
      llen = wlen
    end
  end
  -- Write last line of paragraph.
  f:write(tabconcat(par, ' ', lstart), '\n')
end


--- Write all text stored in the document structure to a file.
local function write_text_document()
  -- Open output file.
  local f = assert(io.open(tex.jobname .. '.txt', 'wb'))
  -- Iterate through document paragraphs.
  for _,par in ipairs(text_document) do
    -- Separate paragraphs by a blank line.
    f:write('\n')
    -- Write paragraph to file.
    write_text_paragraph(par, f, 72)
    -- Delete written paragraph.
    par = nil
  end
  -- Close output file.
  f:close()
end


--- Callback function that writes all document text into a file.
local function cb_stopr_pkg_spelling()
  write_text_document()
end


-- Register callback functions.
luatexbase.add_to_callback('pre_linebreak_filter', cb_plf_pkg_spelling, 'cb_plf_pkg_spelling')
luatexbase.add_to_callback('stop_run', cb_stopr_pkg_spelling, 'cb_stopr_pkg_spelling')

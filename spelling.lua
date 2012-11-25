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


fd = io.open(tex.jobname .. '.txt','wb')


-- Function short-cuts.
local tabconcat = table.concat
local tabinsert = table.insert
local utf8char = unicode.utf8.char
local utf8len = unicode.utf8.len


-- Short-cuts for constants.
local DISC = node.id('disc')
local GLYPH = node.id('glyph')
local KERN = node.id('kern')
local PUNCT = node.id('punct')


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


--- Scan a node list for words.
-- The given node list is scanned for chaines of nodes representing a
-- word.  These words are stored as a list of UTF-8 encoded strings.
--
-- @param head  Node list.
-- @return A list of UTF-8 encoded strings.
local function build_text_paragraph(head)
  -- A paragraph is a list of UTF-8 encoded strings.
  local curr_paragraph = {}
  -- For efficiency, the characters of a word are stored in a list and
  -- only later concatenated via `table.concat`.
  local curr_word = {}
  --Iterate over node list.
  for n in node.traverse(head) do
    local nid = n.id
    -- Test for glyph node.
    if nid == GLYPH then
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
  return curr_paragraph
end


--- Write the text of a node list to a file.
-- The node list is not manipulated.
--
-- @param head  Node list.
local function nodelist_to_text(head)
  local par = build_text_paragraph(head)
  write_paragraph(fd, 72, par)
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


--- Callback function that scans a node list for text and stores that in
--- the document structure.
-- The node list is not manipulated.
--
-- @param head  Node list.
-- @return true
local function cb_hf_pkg_spelling(head)
  nodelist_to_text(head)
  return true
end


--- Write the words of a paragraph to a file with a fixed line length.
-- @param f  A file handle.
-- @param maxlinelength  Maximum line length in output.
-- @param par  A list of strings.
write_paragraph = function(f, maxlinelength, par)
  -- A line is a list of strings.
  local line = {}
  -- Set current line length to maximum to trigger a blank line before
  -- writing the paragraph.
  local llen = maxlinelength
  -- Iterate over words in paragraph.
  for _, word in ipairs(par) do
    local wlen = utf8len(word)
    -- Does word fit onto current line?
    if llen + 1 + wlen <= maxlinelength then
      -- Append word to current line.
      tabinsert(line, ' ')
      tabinsert(line, word)
      llen = llen + 1 + wlen
    else
      -- Output current line.
      f:write(tabconcat(line), '\n')
      -- Store word on new current line.
      line = { word }
      llen = wlen
    end
  end
  -- If non-empty, output last line of paragraph.
  if #line > 0 then
    f:write(tabconcat(line), '\n')
  end
end


-- Register callback functions.
luatexbase.add_to_callback('pre_linebreak_filter', cb_plf_pkg_spelling, 'cb_plf_pkg_spelling')
luatexbase.add_to_callback('hpack_filter', cb_hf_pkg_spelling, 'cb_hf_pkg_spelling')


--~ fd:close()

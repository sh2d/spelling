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


--- Convert Unicode code points to UTF-8.
-- This function converts Unicode code points to UTF-8 characters.  It
-- is modelled after the following table taken from the UTF-8 and
-- Unicode FAQ for Unix/Linux found at
-- <URL:http://www.cl.cam.ac.uk/~mgk25/unicode.html#utf-8>:
--
-- U-00000000 – U-0000007F:  0xxxxxxx
-- U-00000080 – U-000007FF:  110xxxxx 10xxxxxx
-- U-00000800 – U-0000FFFF:  1110xxxx 10xxxxxx 10xxxxxx
-- U-00010000 – U-001FFFFF:  11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
-- U-00200000 – U-03FFFFFF:  111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
-- U-04000000 – U-7FFFFFFF:  1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
--
-- @param cp  A Unicode code point.
-- @return  A string representing a UTF-8 encoded character.
cp2utf8 = function(cp)
  -- range U-00000000 – U-0000007F:  0xxxxxxx
  if cp < 0x80 then
    local one = cp
    return string.char(one)
  end
  -- range U-00000080 – U-000007FF:  110xxxxx 10xxxxxx
  if cp < 0x0800 then
    local two = cp % 64
    cp = math.floor(cp / 64)
    local one = cp
    return string.char(128 + 64 + one) .. string.char(128 + two)
  end
  -- range U-00000800 – U-0000FFFF:  1110xxxx 10xxxxxx 10xxxxxx
  if cp < 0x00010000 then
    local three = cp % 64
    cp = math.floor(cp / 64)
    local two = cp % 64
    cp = math.floor(cp / 64)
    local one = cp
    return string.char(128 + 64 + 32 + one) .. string.char(128 + two) .. string.char(128 + three)
  end
  -- range U-00010000 – U-001FFFFF:  11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
  if cp < 0x00200000 then
    local four = cp % 64
    cp = math.floor(cp / 64)
    local three = cp % 64
    cp = math.floor(cp / 64)
    local two = cp % 64
    cp = math.floor(cp / 64)
    local one = cp
    return string.char(128 + 64 + 32 + 16 + one) .. string.char(128 + two) .. string.char(128 + three) .. string.char(128 + four)
  end
  -- range U-00200000 – U-03FFFFFF:  111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
  if cp < 0x04000000 then
    local five = cp % 64
    cp = math.floor(cp / 64)
    local four = cp % 64
    cp = math.floor(cp / 64)
    local three = cp % 64
    cp = math.floor(cp / 64)
    local two = cp % 64
    cp = math.floor(cp / 64)
    local one = cp
    return string.char(128 + 64 + 32 + 16 + 8 + one) .. string.char(128 + two) .. string.char(128 + three) .. string.char(128 + four) .. string.char(128 + five)
  end
  -- range U-04000000 – U-7FFFFFFF:  1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
  local six = cp % 64
  cp = math.floor(cp / 64)
  local five = cp % 64
  cp = math.floor(cp / 64)
  local four = cp % 64
  cp = math.floor(cp / 64)
  local three = cp % 64
  cp = math.floor(cp / 64)
  local two = cp % 64
  cp = math.floor(cp / 64)
  local one = cp
  return string.char(128 + 64 + 32 + 16 + 8 + 4 + one) .. string.char(128 + two) .. string.char(128 + three) .. string.char(128 + four) .. string.char(128 + five) .. string.char(128 + six)
end


--- Scan a node list for words.
-- The given node list is scanned for chaines of nodes representing a
-- word.  These words are stored as a list of UTF-8 encoded strings.
-- @param head  Node list.
-- @return A list of UTF-8 encoded strings.
build_paragraph = function(head)
  -- Flag, if we're processing a word (word mode) or if we're searching
  -- for the beginning of a new word (whitespace mode).
  local withinword = false
  -- A paragraph is a list of UTF-8 encoded strings.
  local paragraph = {}
  -- For efficiency, the characters of a word are stored in a list and
  -- only later concatenated via `table.concat`.
  local word
  --Iterate over node list.
  for n in node.traverse(head) do
    -- Whitespace mode?
    if not withinword then
      -- Search for beginning of a word.
      if n.id == 37 then
        withinword = true
        word = {}
      end
    end
    -- Word mode?
    if withinword then
      -- Store the characters of the current word.
      if n.id == 37 then
        table.insert(word, cp2utf8(n.char))
      end
      -- Search for the end of the current word.
      -- This definition of a word fails on '\LaTeX'!
      if not ((n.id == 37) or (n.id == 7) or (n.id == 22) or (n.id == 11)) then
        withinword = false
        -- Convert word from table to string representation.
        table.insert(paragraph, table.concat(word))
      end
    end
  end
  return paragraph
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
    local wlen = unicode.utf8.len(word)
    -- Does word fit onto current line?
    if llen + 1 + wlen <= maxlinelength then
      -- Append word to current line.
      table.insert(line, ' ')
      table.insert(line, word)
      llen = llen + 1 + wlen
    else
      -- Output current line.
      f:write(table.concat(line), '\n')
      -- Store word on new current line.
      line = { word }
      llen = wlen
    end
  end
  -- If non-empty, output last line of paragraph.
  if #line > 0 then
    f:write(table.concat(line), '\n')
  end
end


--- Callback function that writes the words of a node list to a file.
-- The node list is not manipulated.
-- @param head  Node list.
-- @return true
totext = function(head)
  local par = build_paragraph(head)
  write_paragraph(fd, 72, par)
  return true
end


-- Register callback function.
luatexbase.add_to_callback("pre_linebreak_filter", totext, "totext")
luatexbase.add_to_callback("hpack_filter", totext, "totext")


--~ fd:close()

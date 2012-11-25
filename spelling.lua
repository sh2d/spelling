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


line = ''
llen = 0

output_word = function(start, stop)
  local n = start
  local nlen = node.length(start, stop)
--~ 	fd:write('Länge: ', len, '  ')
  local i = 1
  local s = ''
  local slen = 0
  while (i <= nlen) do
    if n.id == 37 then
      s = s .. cp2utf8(n.char)
      slen = slen + 1
--~     elseif n.id == 7 then
--~       s = s .. '_'
--~     elseif n.id == 11 then
--~       s = s .. '|'
--~     elseif n.id == 22 then
--~       s = s .. '_22_'
    end
    n = node.next(n)
    i = i + 1
  end
  if llen + 1 + slen > 72 then
    fd:write(line, '\n')
    line = s
    llen = slen
  else
    if llen == 0 then
      line = s
      llen = slen
    else
      line = line .. ' ' .. s
      llen = llen + 1 + slen
    end
  end
end


totext = function(head)
  local wordstart = nil
  --Iterate over paragraph.
  for i in node.traverse(head) do
    -- Search for beginning of a word.
    if not wordstart then
      if i.id == 37 then
        wordstart = i
      end
    end
    -- Search for end of current word.
    if wordstart then
      if not ((i.id == 37) or (i.id == 7) or (i.id == 22) or (i.id == 11)) then
        output_word(wordstart, i)
        wordstart = nil
      end
    end
  end
  if llen > 0 then
    fd:write(line, '\n\n')
    line = ''
    llen = 0
  end
  return true
end


luatexbase.add_to_callback("pre_linebreak_filter", totext, "totext")
luatexbase.add_to_callback("hpack_filter", totext, "totext")


--~ fd:close()

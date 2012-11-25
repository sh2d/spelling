--- spelling-stage-4.lua
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


--- At the end of a LuaTeX run, write the text stored in a text document
--- data structure to a file.
-- This module provides means to write the text stored in a text
-- document data structure to a file at the end of a LuaTeX run.
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
local utf8len = unicode.utf8.len


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


--- Module options.
-- This table contains all module options.  User functions to set
-- options are provided.
--
-- @class table
-- @name __opts
-- @field output_eol  End-of-line  character in output.
-- @field output_file_name  Output file name.
-- @field output_line_length  Line length in output.
local __opts = {
  output_eol,
  output_file_name,
  output_line_lenght,
}


--- Set output EOL character.
-- Text output will be written with the given end-of-line character.
--
-- @param eol  New output EOL character.
local function set_output_eol(eol)
  __opts.output_eol = eol
end
M.set_output_eol = set_output_eol


--- Set output file name.
-- Text output will be written to a file with the given name.
--
-- @param name  New output file name.
local function set_output_file_name(name)
  __opts.output_file_name = name
end
M.set_output_file_name = set_output_file_name


--- Set output line length.
-- Set the number of columns in text output.  Text output will be
-- wrapped at spaces so that lines don't contain more than the specified
-- number of characters per line.  There's one exception: if a word is
-- longer than the specified number of characters, the word is put on
-- its own line and that line will be overfull.
--
-- @param cols  New line length in output.  If the argument is smaller
-- than 1, lines aren't wrapped, i.e., all text of a paragraph is put on
-- a single line.
local function set_output_line_length(cols)
  __opts.output_line_length = cols
end
M.set_output_line_length = set_output_line_length


--- Break a paragraph into lines of a fixed length and write the lines
--- to a file.
--
-- @param par  A text paragraph (an array of words).
-- @param f  A file handle.
-- @param maxlinelength  Maximum line length in output.
local function __write_text_paragraph(par, f, maxlinelength)
  local eol = __opts.output_eol
  -- Index of first word on current line.  Initialize current line with
  -- first word of paragraph.
  local lstart = 1
  -- Track current line length.
  local llen = utf8len(par[1])
  -- Iterate over remaining words in paragraph.
  for i = 2,#par do
    local wlen = utf8len(par[i])
    -- Does word fit onto current line?
    if (llen + 1 + wlen <= maxlinelength) or (maxlinelength < 1) then
      -- Append word to current line.
      llen = llen + 1 + wlen
    else
      -- Write the current line up to the preceeding word to file (words
      -- separated by spaces and with a trailing newline).
      f:write(tabconcat(par, ' ', lstart, i-1), eol)
      -- Initialize new current line.
      lstart = i
      llen = wlen
    end
  end
  -- Write last line of paragraph.
  f:write(tabconcat(par, ' ', lstart), eol)
end


--- Write all text stored in the text document to a file.
--
local function __write_text_document()
  -- Open output file.
  local f = assert(io.open(__opts.output_file_name, 'wb'))
  -- Iterate through document paragraphs.
  for _,par in ipairs(__text_document) do
    -- Separate paragraphs by a blank line.
    f:write(__opts.output_eol)
    -- Write paragraph to file.
    __write_text_paragraph(par, f, __opts.output_line_length)
    -- Delete paragraph from memory.
    par = nil
  end
  -- Close output file.
  f:close()
end


--- Callback function that writes all document text into a file.
local function __cb_stopr_pkg_spelling()
  __write_text_document()
end


-- Call-back status.
local __is_active_output


--- Enable text document output.
-- Registers call-back `stop_run` to output the text stored in the text
-- document at the end of the LuaTeX run.
local function enable_text_output()
  if not __is_active_output then
    -- Register call-back: At the end of the LuaTeX run, output all text
    -- stored in the text document.
    luatexbase.add_to_callback('stop_run', __write_text_document, '__cb_stop_run_pkg_spelling')
    __is_active_output = true
  end
end
M.enable_text_output = enable_text_output


--- Disable text document output.
-- De-registers call-back `stop_run`.
local function disable_text_output()
  if __is_active_output then
    -- De-register call-back.
    luatexbase.remove_from_callback('stop_run', '__cb_stop_run_pkg_spelling')
    __is_active_output = false
  end
end
M.disable_text_output = disable_text_output


--- Module initialisation.
--
local function __init()
  -- Set default output file name.
  set_output_file_name(tex.jobname .. '.txt')
  -- Set default output line length.
  set_output_line_length(72)
  -- Set default output EOL character.
  if (os.type == 'windows') or (os.type == 'msdos') then
    set_output_eol('\r\n')
  else
    set_output_eol('\n')
  end
  -- Remember call-back status.
  __is_active_output = false
end


-- Initialize module.
__init()


-- Return module table.
return M

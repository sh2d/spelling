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


--- Global table of modules.
-- The work of the spelling package can be separated into four
-- stages:<br />
--
-- <dl>
--
-- <dt>Stage 1</dt>
--   <dd><ul>
--     <li>Load list(s) of bad strings.</li>
--   </ul></dd>
--
-- <dt>Stage 2  (call-back <code>pre_linebreak_filter</code>)</dt>
--   <dd><ul>
--     <li>Tag word strings in node lists before paragraph breaking
--         takes place.</li>
--     <li>Check spelling of strings.</li>
--     <li>Highlight strings with known incorrect spelling in PDF
--         output.</li>
--   </ul></dd>
--
-- <dt>Stage 3  (<code>\AtBeginShipout</code>)</dt>
--   <dd><ul>
--     <li>Store all strings found on built page via tag nodes in text
--         document data structure.</li>
--   </ul></dd>
--
-- <dt>Stage 4  (call-back <code>stop_run</code>)</dt>
--   <dd><ul>
--     <li>Output text stored in text document data structure to a
--         file.</li>
--   </ul></dd>
--
-- </dl>
--
-- The code of the spelling package is organized in modules reflecting
-- these stages.  References to modules are made available in a global
-- table so that module's public functions are accessible from within
-- external code.  Table indices correspond to the stages as shown
-- above.<br />
--
-- <i>Note, as node tagging, spell-checking and bad string highlighting
-- are not yet implemented, all current code of stages 1, 2 and 3 is
-- collected in one module.  That is, there are currently only two
-- modules available:</i>
--
-- <ul>
--   <li><code>spelling-stage-3.lua : pkg_spelling_stage[3]</code></li>
--   <li><code>spelling-stage-4.lua : pkg_spelling_stage[4]</code></li>
-- </ul>
--
-- @class table
-- @name pkg_spelling_stage
pkg_spelling_stage = {

  -- text storage
  [3] = require 'spelling-stage-3',
  -- text output
  [4] = require 'spelling-stage-4',

}


--- Table of package-wide resources that are shared among several
--- modules.
--
-- @class table
-- @name res
--
-- @field text_document  Table.<br />
--
-- Data structure that stores the text of a document.  The text document
-- data structure stores the text of a document.  The data structure is
-- quite simple.  A text document is an ordered list (an array) of
-- paragraphs.  A paragraph is an ordered list (an array) of words.  A
-- word is a single UTF-8 encoded string.<br />
--
-- During the LuTeX run, node lists are scanned for strings before
-- hyphenation takes place.  The strings found in a node list are stored
-- in the current paragraph.  After finishing scanning a node list, the
-- current paragraph is inserted into the text document.  At the end of
-- the LuaTeX run, all paragraphs of the text document are broken into
-- lines of a fixed length and the lines are written to a file.<br />
--
-- Here's the rationale of this approach:
--
-- <ul>
--
-- <li> It reduces file access <i>during</i> the LuaTeX run by delaying
--   write operations until the end.
--
-- <li> It saves space.  In Lua, strings are internalized.  Since in a
--   document, the same words are used over and over again, relatively
--   few strings are actually stored in memory.
--
-- <li> It allows for pre-processing the text document before writing it
--   to a file.
--
-- </ul>
--
local res = {

  text_document,

}


--- Package initialisation.
--
local function __init()
  -- Create resources.
  res.text_document = {}
  -- Make resources available to modules.
  pkg_spelling_stage[3].set_resources(res)
  pkg_spelling_stage[4].set_resources(res)
  -- Enable text storage.
  pkg_spelling_stage[3].enable_text_storage()
end


-- Initialize package.
__init()

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


-- Load text extraction module.
local extract = require 'spelling-extracttext'

-- Enable text storage.
extract.enable_text_storage()

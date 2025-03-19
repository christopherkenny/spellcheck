-- lua filter for spell checking
-- Copyright (C) 2017-2020 John MacFarlane, released under MIT license
-- Altered to use hunspell and work with Quarto by Christopher T. Kenny

-- pandoc.utils.stringify works on MetaValue elements since pandoc 2.1
if PANDOC_VERSION == nil then -- if pandoc_version < 2.1
  error("ERROR: pandoc >= 2.1 required for spellcheck.lua filter")
end

--local text = require('text')
local words = {}
local words_to_drop = {"Doi"}
local deflang

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

local function write_words(tbl, path)
  file = io.open(path, "w")
  for i, wrd in ipairs(tbl) do
    file:write(wrd, '\n')
  end
  file:close()
  return file
end

local function in_table(tbl, value)
    if tbl == nil then
        return false
    end
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function add_to_dict(lang, t)
  if not words[lang] then
    words[lang] = {}
  end
  if not words[lang][t] then
    words[lang][t] = (words[lang][t] or 0) + 1
  end
end

local function get_deflang(meta)
  deflang = (meta['spellcheck-lang'] and pandoc.utils.stringify(meta['spellcheck-lang'])) or 'en_US'
  return nil
end

local function run_spellcheck(lang)

  -- Check if Hunspell is installed before proceeding
  local status = os.execute('hunspell -v > /dev/null 2>&1')
  if status ~= 0 then
    print("Warning: Hunspell is not installed. Skipping spell check for '" .. lang .. "'.")
    return -- Gracefully skip spell checking if Hunspell is not available
  end

  -- Prepare list of collected words for Hunspell
  local keys = {}
  local wordlist = words[lang]

  --print(dump(words_to_drop))
  for k,_ in pairs(wordlist) do
    --if not in_table(words_to_drop, k) then
        keys[#keys + 1] = k
    --end
  end

  --print(dump(keys))

  local f = '.spellcheck.txt' --os.tmpname()
  write_words(words_to_drop, f)

  local inp = table.concat(keys, '\n')
  local outp = pandoc.pipe('hunspell', { '-l', '-d', lang, '-p', f}, inp)
  print('Possibly misspelled words:')
  print('--------------------------')
  io.write(outp)
  print('--------------------------\n')
  os.remove(f)
end

local function results(el)
  pandoc.walk_block(pandoc.Div(el.blocks), {Str = function(e) add_to_dict(deflang, e.text) end})
  for lang,_ in pairs(words) do
    run_spellcheck(lang)
  end
  --os.exit(0)
end

local function checkstr(el)
  add_to_dict(deflang, el.text)
end

local function checkspan(el)
  local lang = el.attributes.lang
  if not lang then return nil end
  pandoc.walk_inline(el, {Str = function(e) add_to_dict(lang, e.text) end})
  return nil
end

local function checkdiv(el)
  local lang = el.attributes.lang
  if not lang then return nil end
  pandoc.walk_block(el, {Str = function(e) add_to_dict(lang, e.text) end})
  return nil
end

local function read_ignore_words(meta)
  local env = meta['spellcheck-ignore']
  if env ~= nil then
    for _, v in ipairs(env) do
      local value = pandoc.utils.stringify(v)
      words_to_drop[#words_to_drop + 1] = value
    end
  end
end

return {
  {Meta = get_deflang},
  {Meta = read_ignore_words},
  {Div = checkdiv, Span = checkspan},
  {
    Str = function(e) add_to_dict(deflang, e.text) end,
    Pandoc = results
  }
}

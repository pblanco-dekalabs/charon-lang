--[[
MIT License

Copyright (c) 2020 Pablo Blanco Celdrán

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
--[[
  Charon language standard library runtime.
]]
local charon = {}

-- Unit type
charon.Unit = setmetatable({}, {
  __tostring = function() return 'Unit'; end,
  __concat = function(this, other) return tostring(this) .. other; end
})
charon.True = true
charon.False = false

local Symbol = {
  __tostring = function(self) return ':' .. self.value; end,
  __concat = function(this, other) return tostring(this) .. other; end
};
local symbols = {};

function charon.symbol(value)
  if symbols[value] ~= nil then return symbols[value]; end
  local symbol = setmetatable({ value = value }, Symbol);
  symbols[value] = symbol;
  return symbol;
end

function charon.some(value)
  return value ~= nil and value ~= charon.Unit;
end

local atom = {}

function charon.atom(value)
  return setmetatable({ value = value }, Atom);
end

local Vector = {
  __tostring = function(self)
    local list = ''
    for i=1, (#self - 1) do
      list = list .. tostring(self[i]) .. ', ';
    end
    return '[' .. list .. tostring(self[#self]) .. ']'
  end
}

function charon.vector(tbl)
  return setmetatable(tbl, Vector)
end

function charon.vector_get(tbl, key)
  assert(getmetatable(tbl) == Vector, "vector/get only accepts vectors.");
  assert(type(key) == 'number', "vector/get key can only be numeric.");
  local field = tbl[key];
  if field == nil then return charon.Unit; end
  return field;
end

function charon.vector_merge(left, right)
  assert(getmetatable(left) == Vector, "vector/merge only accepts vectors.");
  assert(getmetatable(right) == Vector, "vector/merge only accepts vectors.");
  local vec = charon.vector{};
  for _, v in pairs(left) do
    vec[#vec + 1] = v;
  end
  for _, v in pairs(right) do
    vec[#vec + 1] = v;
  end
  return tbl;
end

function charon.vector_len(left)
  assert(getmetatable(left) == Vector, "vector/add only accepts vectors.");
  return #left;
end

function charon.vector_add(left, ...)
  assert(getmetatable(left) == Vector, "vector/add only accepts vectors.");
  local vec = charon.vector{};
  for _, v in pairs(left) do
    vec[#vec + 1] = v;
  end
  for _, v in pairs{...} do
    vec[#vec + 1] = v;
  end
  return vec;
end

function charon.vector_drop(left, n)
  assert(getmetatable(left) == Vector, "vector/drop only accepts vectors.");
  assert(type(n) == 'number', "vector/drop second argument must be a number.");
  local vec = charon.vector{};
  local min = math.min(#left, n);
  for i=1, min do
    vec[i] = left[i];
  end
  return vec;
end

function charon.vector_drop_left(left, n)
  assert(getmetatable(left) == Vector, "vector/drop-left only accepts vectors.");
  assert(type(n) == 'number', "vector/drop-left second argument must be a number.");
  local vec = charon.vector{};
  local min = math.min(#left, n);
  for i=min, #left do
    vec[i] = left[i];
  end
  return vec;
end

function charon.vector_map(tbl, mapper)
  assert(getmetatable(tbl) == Vector, "vector/map only accepts vectors.");
  local vec = charon.vector{};
  for k, v in pairs(tbl) do
    vec[#vec + 1] = mapper(v, k);
  end
  return vec;
end

function charon.vector_filter(tbl, filter)
  assert(getmetatable(tbl) == Vector, "vector/map only accepts vectors.");
  local vec = charon.vector{};
  for k, v in pairs(tbl) do
    if filter(v, k) then
      vec[#vec + 1] = v;
    end
  end
  return vec;
end

function charon.vector_each(tbl, consumer)
  assert(getmetatable(tbl) == Vector, "vector/each only accepts vectors.");
  for k, v in pairs(tbl) do
    consumer(v, k);
  end
  return charon.Unit;
end

local Table = {}

function charon.table(tbl)
  return setmetatable(tbl, Table)
end

function charon.println(...)
  print(...);
end

function charon.print(...)
  for _, v in pairs{...} do
    io.write(v);
  end
end

function charon.atom_get(atom)
  return atom.value;
end

function charon.atom_set(atom, value)
  atom.value = value;
end

function charon.atom_apply(atom, func, ...)
  atom.value = func(atom.value, ...);
end

function charon.table_get(key, tbl)
  assert(getmetatable(tbl) == Table, "table/get only accepts tables.");
  local field = tbl[key];
  if field == nil then return charon.Unit; end
  return field;
end

function charon.table_merge(left, right)
  assert(getmetatable(left) == Table, "table/merge only accepts tables.");
  assert(getmetatable(right) == Table, "table/merge only accepts tables.");
  local tbl = charon.table{};
  for k, v in pairs(left) do
    tbl[k] = v;
  end
  for k, v in pairs(right) do
    tbl[k] = v;
  end
  return tbl;
end

function charon.table_remove(tbl, ...)
  assert(getmetatable(tbl) == Table, "table/remove only accepts tables.");
  local keys = {};
  for _, key in pairs{...} do
    keys[key] = key;
  end
  local out = charon.table{};
  for k, v in pairs(tbl) do
    if keys[k] ~= nil then
      out[k] = v;
    end
  end
  return out;
end

function charon.object_new_raw(proto)
  local tbl = {};
  for k, v in pairs(proto) do
    if type(v) == 'table' then
      tbl[k] = charon.object_new_raw(v);
    else
      tbl[k] = v;
    end
  end
  return tbl;
end

function charon.object_new(proto)
  local tbl = {};
  for k, v in pairs(proto) do
    local key = k;
    if type(key) == 'table' and getmetatable(key) == Symbol then
      key = tostring(key);
    end
    if type(v) == 'table' then
      tbl[key] = charon.object_new(v);
    else
      tbl[key] = v;
    end
  end
  return tbl;
end

function charon.object_get(object, key)
  local field = object[key];
  if field == nil then return charon.Unit; end
  return field;
end

function charon.object_set(object, key, value)
  if getmetatable(key) == Table then
    for k, v in pairs(key) do
      if getmetatable(k) == Symbol then
        object[k.value] = v
      else
        object[k] = v
      end
    end
  else
    object[key] = value;
  end
end

function charon.call(fn, ...)
  if fn == charon.Unit then
    error('Unit is not callable!');
  end
  return fn(...);
end

function charon.opaque_call(fn)
  if fn == charon.Unit then
    error('Unit is not callable!');
  end
  fn();
  return charon.Unit;
end

function charon.file_open(file, mode)
  return io.open(file, mode) or charon.Unit;
end

function charon.file_close(file)
  io.close(file);
end

function charon.file_write(file, what)
  file:write(what);
end

function charon.file_read(file)
  return file:read(what);
end

function charon.compose(a, b)
  return function(...)
    return b(a(...));
  end
end

function charon.or_coalesce(test, val)
  if test == nil or test == charon.Unit then
    return val;
  end
  return test;
end

function charon.str(...)
  local out = '';
  for _, v in pairs{...} do
    out = out .. tostring(v);
  end
  return out;
end

function charon.range(from, to, inc)
  assert(type(from) == 'number' and type(to) == 'number'
    , 'Range function expects numeric input only!')
  assert(inc == nil or type(inc) == 'number'
    , 'Range\'s third argument can only be a number or not provided. Saw ' .. tostring(inc) .. ' instead.')
  if inc == nil then inc = 1; end
  local p = {};
  local j = 1;
  if from > to then
    for i=from, to, -inc do
      p[j] = i;
      j = j + 1;
    end
  elseif from == to then
    return p;
  else
    for i=from, to, inc do
      p[j] = i;
      j = j + 1;
    end
  end
  return p;
end

return charon;

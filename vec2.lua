
-- 2D vector library.
-- all vec functions have an inplace and copying variant. 
-- the copied variant always ends with the -ed suffix. 
-- for example `project` works in place; `projected` copies.
-- there are a few cases where this doesn't make much sense but whatever.

-- an s suffix is used for some standard functions if they accept a scalar.
-- for example `mul` multiplies two vectors in place. `muls` multiplies a vector componentwise by 
--  a scalar and does so in place.

-- inplace variants are meant to be chained together, for example this;
-- slope = (contact - position):normalize()

-- would be rewritten like this to avoid copies;
-- slope:set(contact):sub(position):normalize()

-- implemented operators;
-- __index    so vector objects all share the same methods.
-- __tostring converts the vector into a printable string.
-- < <=       componentwise less, and less than equal comparison.
-- > >=       componentwise more, and more than equal comparison.
-- - + * /    componentwise subtraction, addition, multiplication, and division.
-- -          unary minus will negate the vector.

-- ==         works on `near` componentwise comparison using an epsilon.
-- %          will perform a dot product when given a vector or a multiply when given a scalar.

-- individual components may be accessed with `.x` and `.y`

local math = require(((...):gsub('vec2', '')) .. 'math')

local sqrt  = math.sqrt
local atan2 = math.atan2
local sin   = math.sin
local cos   = math.cos
local floor = math.floor
local ceil  = math.ceil
local abs   = math.abs
local min   = math.min
local max   = math.max

local sign  = math.sign
local lerp  = math.lerp
local near  = math.near
local pi    = math.pi

local winding2D = math.winding2D

local vec = {}
vec.__index = vec
vec.__pool  = {}
vec.__limit = 64 -- sets the pool limit. set to 0 to disable pooling.

-- initialize a new vector.
-- (~float x, ~float y) -> vec
local function new(self, x, y)
  return setmetatable({x = x or 0, y = y or 0}, vec) 
end
setmetatable(vec, {__call = new})

-- initialized a new vector from polar coordinates.
-- (float angle, float radius) -> vec
function vec.polar(angle, radius)
  return vec(cos(angle) * radius, sin(angle) * radius)
end

-- pull a vec from the pool. creates one if the pool is empty.
-- (float x, float y) -> vec
function vec.pool(x, y)
  local index = #vec.__pool
  if index > 0 then
    local v = vec.__pool[index]
    vec.__pool[index] = nil
    v.x = x
    v.y = y
    return v
  end
  return vec(x, y)
end

-- pull a vec from the pool. creates one if the pool is empty.
-- assigns its components from SELF.
-- () -> vec
function vec:pooled()
  local index = #vec.__pool
  if index > 0 then
    local v = vec.__pool[index]
    vec.__pool[index] = nil
    v.x = self.x
    v.y = self.y
    return v
  end
  return vec(self.x, self.y)
end

-- release a vec back into the pool. the vec need not be created with POOL to use this.
-- this returns SELF so that it may be used as the very last method on a pooled vector.
-- if you're careful this allows chains like; a:set(b:pooled():mul(c):release())
-- a reference to the pooled vector is never retained so it is not leaked.
-- () -> self
function vec:release()
  local index = #vec.__pool
  if index < vec.__limit then
    vec.__pool[index + 1] = self
  end
  return self
end

-- check if V is a vec type.
-- (value) -> bool
function vec.is(v)
  return getmetatable(v) == vec
end

-- check if SELF is nan.
-- (value) -> bool
function vec:nan()
  return (self.x ~= self.x) or (self.y ~= self.y)
end

-- exact component equality.
-- (vec v) -> bool
function vec:equal(v)
  return self.x == v.x and self.y == v.y
end

-- check if a vector is nearly equal to V.
-- (vec v) -> bool
function vec:near(v)
  return near(self.x, v.x) and near(self.y, v.y)
end

-- check if a vector is nearly equal to S.
-- (float s) -> bool
function vec:almost(s)
  return near(self.x, s) and near(self.y, s)
end

-- unpacks a vecs components into an argument list.
-- () -> float x, float y
function vec:unpack()
  return self.x, self.y
end

-- copies V into SELF.
-- (vec v) -> self
function vec:copy(v)
  self.x = v.x
  self.y = v.y
  return self
end

-- copies SELF into a new vec.
-- () -> vec
function vec:clone()
  return vec(self.x, self.y)
end

-- zeros out a vec.
-- () -> self
function vec:zero()
  self.x = 0.0
  self.y = 0.0
  return self
end

-- returns a new zeroed vec.
-- () -> vec
function vec:zeroed()
  return vec(0.0, 0.0)
end

-- the length of the vec.
-- () -> float
function vec:length()
  return sqrt(self.x * self.x + self.y * self.y)
end

-- normalizes the vec.
-- handles zero length vectors gracefully.
-- () -> self
function vec:normalize()
  local length = self:length()
  if length == 0.0 then
    self.x = 0.0
    self.y = 0.0
  else
    self.x = self.x / length
    self.y = self.y / length
  end
  return self
end

-- normalized copy of SELF.
-- () -> vec
function vec:normalized()
  local length = self:length()
  if length == 0.0 then
    return vec(0.0, 0.0)
  end
  return vec(self.x / length, self.y / length)
end

-- find the normal of a linesegment between SELF and V.
-- (vec v) -> self
function vec:normal(v)
  local x = -(v.y - self.y)
  local y =  (v.x - self.x)
  self.x = x
  self.y = y
  self:normalize()
  return self
end

-- copy of the normal of a linesegment between SELF and V.
-- (vec v) -> self
function vec:normaled(v)
  return self:clone():normal(v)
end

-- calculates the angle between SELF and V assuming both are locations.
-- (vec v) -> float 
function vec:direction(v)
  local angle = atan2(v.y - self.y, v.x - self.x)
  if angle < 0 then 
    return angle + 2 * pi
  end
  return angle
end

-- rotates SELF to face V using ORIGIN as the location for SELF. assumes V is a location.
-- (vec origin, vec v) -> self
function vec:face(origin, v)
  return self:rotate(origin:direction(v))
end

-- returns SELF as an angle. in radians.
-- () -> float
function vec:angle()
  local angle = atan2(self.y, self.x)
  if angle < 0 then 
    return angle + 2 * pi
  end
  return angle
end

-- rotates SELF by ANGLE. in radians.
-- (float angle) -> self
function vec:rotate(angle)
  local x = self.x
  local y = self.y
  self.x = x * cos(angle) - y * sin(angle)
  self.y = x * sin(angle) + y * cos(angle)
  return self
end

-- rotated copy of SELF.
-- (float angle) -> vec
function vec:rotated(angle)
  return vec(self.x * cos(angle) - self.y * sin(angle), 
             self.x * sin(angle) + self.y * cos(angle))
end


-- distance between SELF and V. assumes both are locations.
-- (vec v) -> float
function vec:distance(v)
  return sqrt((self.x - v.x) ^ 2 + (self.y - v.y) ^ 2)
end

-- squared distance between SELF and V. assumes both are locations.
-- (vec v) -> float
function vec:distanceSquared(v)
  return (self.x - v.x) ^ 2 + (self.y - v.y) ^ 2
end

-- determin winding side of a point SELF relative to a linesegment A B. ie which side the point is on.
-- -1 left side.
-- +1 right side.
--  0 center.
-- (vec a, vec b) -> float
function vec:winding(a, b)
  return sign((self.x - a.x) * (b.y - a.y) - (self.y - a.y) * (b.x - a.x))
end 

-- component wise sign inversion.
-- () -> self
function vec:invert()
  self.x = -self.x
  self.y = -self.y
  return self
end

-- inverted copy of SELF.
-- () -> vec
function vec:inverted()
  return vec(-self.x, -self.y)
end

-- dot product between SELF and V.
-- (vec v) -> float
function vec:dot(v)
  return self.x * v.x + self.y * v.y
end

-- cross product between SELF and V.
-- (vec v) -> float 
function vec:cross(v)
  return self.x * v.y - self.y * v.x
end

-- component wise floor.
-- () -> self
function vec:floor()
  self.x = floor(self.x)
  self.y = floor(self.y)
  return self
end

-- floored copy of SELF.
-- () -> vec
function vec:floored()
  return vec(floor(self.x), floor(self.y))
end

-- component wise ceiling.
-- () -> self
function vec:ceiling()
  self.x = ceil(self.x)
  self.y = ceil(self.y)
  return self
end

-- ceilinged copy of SELF.
-- () -> vec
function vec:ceilinged()
  return vec(ceil(self.x), ceil(self.y))
end

-- component wise minimum. V may be a vec or float.
-- (vec | float v) -> self
function vec:min(v)
  if self.is(v) then
    self.x = min(self.x, v.x)
    self.y = min(self.y, v.y)
    return self
  end
  self.x = min(self.x, v)
  self.y = min(self.y, v)
  return self
end

-- minimumed copy of SELF.
-- (vec | float v) -> vec
function vec:mined(v)
  if self.is(v) then
    return vec(min(self.x, v.x), min(self.y, v.y))
  end
  return vec(min(self.x, v), min(self.y, v))
end

-- component wise maximum. V may be a vec or float.
-- (vec | float v) -> self
function vec:max(v)
  if self.is(v) then
    self.x = max(self.x, v.x)
    self.y = max(self.y, v.y)
    return self
  end
  self.x = max(self.x, v)
  self.y = max(self.y, v)
  return self
end

-- maximumed copy of SELF.
-- (vec | float v) -> vec
function vec:maxed(v)
  if self.is(vmax) then
    return vec(max(self.x, v.x), max(self.y, v.y))
  end
  return vec(max(self.x, v), max(self.y, v))
end

-- clamps SELF between VMIN and VMAX. VMIN and VMAX can be either vec or float.
-- (vec | float vmin, vec | float vmax) -> self
function vec:clamp(vmin, vmax)
  if self.is(vmax) then
    self.x = min(max(vmin.x, self.x), vmax.x)
    self.y = min(max(vmin.y, self.y), vmax.y)
    return self
  end
  self.x = min(max(vmin, self.x), vmax)
  self.y = min(max(vmin, self.y), vmax)
  return self
end

-- clamped copy of SELF.
-- (vec | float vmin, vec | float vmax) -> vec
function vec:clamped(vmin, vmax)
  if self.is(vmax) then
    return vec(min(max(vmin.x, self.x), vmax.x), 
               min(max(vmin.y, self.y), vmax.y))
  end
  return vec(min(max(vmin, self.x), vmax), 
             min(max(vmin, self.y), vmax))
end

-- component wise absolute.
-- () -> self
function vec:absolute()
  self.x = abs(self.x)
  self.y = abs(self.y)
  return self
end

-- absoluted copy of SELF.
-- () -> vec
function vec:absoluted()
  return vec(abs(self.x), abs(self.y))
end

-- component wise sign. components will be either 0, 1 or -1.
-- () -> self
function vec:sign()
  self.x = sign(self.x)
  self.y = sign(self.y)
  return self
end

-- signed copy of SELF.
-- () -> vec
function vec:signed()
  return vec(sign(self.x), sign(self.y))
end

-- component wise lerp.
-- if TIME is a vector the X and Y components are used.
-- (vec first, vec final, vec | float time) -> self
function vec:lerp(first, final, time)
  first = first or self
  if vec.is(time) then
    self.x = lerp(first.x, final.x, time.x)
    self.y = lerp(first.y, final.y, time.y)
  else
    self.x = lerp(first.x, final.x, time)
    self.y = lerp(first.y, final.y, time)
  end
  return self
end

-- lerped copy of SELF.
-- (vec final, float time) -> vec
function vec:lerped(final, time)
  return vec(lerp(self.x, final.x, time), lerp(self.y, final.y, time))
end

-- sets SELF to a vec that orbits ORIGIN with OFFSET distance and ANGLE.
-- a VEC may be passed as OFFSET. if a number is passed as OFFSET it is applied to the X axis.
-- (vec origin, vec | float offset, float angle) -> self
function vec:orbit(origin, offset, angle)
  local x = 0
  local y = 0

  if vec.is(offset) then
    x = offset.x
    y = offset.y
  else
    x = offset
  end

  self.x = (x * cos(angle) - y * sin(angle)) + origin.x
  self.y = (x * sin(angle) + y * cos(angle)) + origin.y
  return self
end

-- orbited copy of SELF.
-- (vec origin, vec | float offset, float angle) -> vec
function vec:orbited(origin, offset, angle)
  return self:clone():orbit(origin, offset, angle)
end

-- projects SELF along V.
-- (vec v) -> self 
function vec:project(v)
  local divisor = v:dot(v)
  if divisor == 0.0 then
    return self:sets(0.0, 0.0)
  end
  local multiplier = self:dot(v) / divisor
  return self:set(v):muls(multiplier)
end

-- projected copy of SELF. pass true in AS_SCALAR to return a scalar instead of a vec.
-- (vec v, ~bool as_scalar) -> vec | float
function vec:projected(v, as_scalar)
  if as_scalar then
    local length = v:length()
    if length == 0.0 then
      return 0
    end
    return self:dot(v) / length
  end

  return self:clone():project(v)
end

-- rejects SELF from V.
-- (vec v) -> self
function vec:reject(v)
  local x = self.x
  local y = self.y
  self:project(v)
  return self:sets(x - self.x, y - self.y)
end

-- rejected copy of SELF.
-- (vec v) -> vec
function vec:rejected(v)
  return self:clone():reject(v)
end

-- reflects SELF from a surfaces defined by NORMAL. NORMAL must be normalized.
-- (vec normal) -> self
function vec:reflect(normal)
  -- R = -2*(V dot N)*N + V
  local a = -2 * self:dot(normal)
  self.x = -(a * normal.x + self.x)
  self.y = -(a * normal.y + self.y)
  return self
end

-- reflected copy of SELF.
-- (vec normal) -> vec
function vec:reflected(normal)
  return self:clone():reflect(normal)
end

-- bounce vector off of a surface by AMOUNT defined by NORMAL. NORMAL must be normalized.
-- SELF is the origin point. CONTACT is the reflection point.
-- AMOUNT controls the length of the result.
-- (vec contact, vec normal, float amount) -> self
function vec:bounce(contact, normal, amount)
  local a = -2 * self:dot(normal)
  self.x = -(a * normal.x + (self.x - contact.x))
  self.y = -(a * normal.y + (self.y - contact.y))
  self:normalize():muls(amount)
  return self
end

-- bounced copy of SELF.
-- (vec contact, vec normal, float amount) -> vec
function vec:bounced(contact, normal, amount)
  return self:clone():bounce(contact, normal, amount)
end

-- similar to bounce, but the resulting vector is parallel to the surface defined by NORMAL 
-- rather than reflecting away from it.
-- CONTACT is the point of contact with the surface defined by NORMAL. 
-- AMOUNT controls the length of the result.
-- (vec contact, vec normal, float amount) -> self
function vec:slide(contact, normal, amount)
  local side = winding2D(contact.x, contact.y, self.x, self.y, self.x + normal.x, self.y + normal.y)
  -- rotate 90 degrees clockwise from normal to surface to slide on.
  self.x =  normal.y
  self.y = -normal.x
  self:muls(amount * side)
  return self
end

-- slided copy of SELF.
-- (vec contact, vec normal, float amount) -> vec
function vec:slided(contact, normal, amount)
  return self:clone():slide(contact, normal, amount)
end

-- sets SELF to be the on the opposite side of ORIGIN from OPPOSITE.
-- (vec origin, vec opposite) -> self
function vec:mirror(origin, opposite)
  self.x = (origin.x + origin.x - opposite.x)
  self.y = (origin.y + origin.y - opposite.y)
  return self
end

-- mirrored copy of SELF.
-- (vec origin, vec opposite) -> vec
function vec:mirrored(origin, opposite)
  return self:clone():mirror(origin, opposite)
end

-- set SELF with V.
-- (vec v) -> self 
function vec:set(v)
  self.x = v.x
  self.y = v.y
  return self
end

-- adds V to SELF.
-- (vec v) -> self 
function vec:add(v)
  self.x = self.x + v.x
  self.y = self.y + v.y
  return self
end

-- subtracts V from SELF.
-- (vec v) -> self 
function vec:sub(v)
  self.x = self.x - v.x
  self.y = self.y - v.y
  return self
end

-- divides SELF by V.
-- (vec v) -> self
function vec:div(v)
  self.x = self.x / v.x
  self.y = self.y / v.y
  return self
end

-- multiplies SELF by V.
-- (vec v) -> self 
function vec:mul(v)
  self.x = self.x * v.x
  self.y = self.y * v.y
  return self
end

-- modulate SELF by V.
-- (vec v) -> self 
function vec:mod(v)
  self.x = self.x % v.x
  self.y = self.y % v.y
  return self
end

-- sets SELF with scalars.
-- (~float x, ~float y) -> self 
function vec:sets(x, y)
  self.x = (x or      0.0)
  self.y = (y or x or 0.0)
  return self
end

-- adds scalars to SELF.
-- (float x, ~float y) -> self 
function vec:adds(x, y)
  self.x = self.x + (x)
  self.y = self.y + (y or x)
  return self
end

-- subtracts scalars from SELF.
-- (float x, ~float y) -> self 
function vec:subs(x, y)
  self.x = self.x - (x)
  self.y = self.y - (y or x)
  return self
end

-- divides SELF by scalars.
-- (float x, ~float y) -> self 
function vec:divs(x, y)
  self.x = self.x / (x)
  self.y = self.y / (y or x)
  return self
end

-- multiplies SELF by scalars.
-- (float x, ~float y) -> self
function vec:muls(x, y)
  self.x = self.x * (x)
  self.y = self.y * (y or x)
  return self
end

-- modulates SELF by scalars.
-- (float x, ~float y) -> self
function vec:mods(x, y)
  self.x = self.x % (x)
  self.y = self.y % (y or x)
  return self
end

-- convert a vec to a string.
-- () -> string
function vec:__tostring()
  return ("(%.2f, %.2f)"):format(self.x, self.y)
end

-- adds a scalar or vec to a copy of SELF. types depend on which side the vector is on.
-- (a + b) -> vec
function vec.__add(a, b)
  if vec.is(a) and vec.is(b) then
    return vec(a.x + b.x, a.y + b.y)
  elseif vec.is(a) then
    return vec(a.x + b, a.y + b)
  else
    return vec(a + b.x, a + b.y)
  end
end

-- subtracts a scalar or vec from a copy of SELF.
-- (a - b) -> vec
function vec.__sub(a, b)
  if vec.is(a) and vec.is(b) then
    return vec(a.x - b.x, a.y - b.y)
  elseif vec.is(a) then
    return vec(a.x - b, a.y - b)
  else
    return vec(a - b.x, a - b.y)
  end
end

-- divides a copy of self by a scalar or vec.
-- (a / b) -> vec
function vec.__div(a, b)
  if vec.is(a) and vec.is(b) then
    return vec(a.x / b.x, a.y / b.y)
  elseif vec.is(a) then
    return vec(a.x / b, a.y / b)
  else
    return vec(a / b.x, a / b.y)
  end
end

-- multiplies a copy of self by a scalar or vec.
-- unlike __mod it ensures only multiplication is used.
-- (a * b) -> vec
function vec.__mul(a, b)
  if vec.is(a) and vec.is(b) then
    return vec(a.x * b.x, a.y * b.y)
  elseif vec.is(a) then
    return vec(a.x * b, a.y * b)
  else
    return vec(a * b.x, a * b.y)
  end
end

-- multiplies a copy of self by a scalar or vec.
-- if A and B are vecs it returns the dot product.
-- (a % b) -> vec
function vec.__mod(a, b)
  if vec.is(a) and vec.is(b) then
    return a:dot(b)
  elseif vec.is(a) then
    return vec(a.x * b, a.y * b)
  else
    return vec(a * b.x, a * b.y)
  end
end

-- negates a copy of SELF.
-- (-a) -> vec
function vec.__unm(a)
  return vec(-a.x, -a.y)
end

-- compare two vectors for near equality.
-- (a == b) -> bool
function vec.__eq(a, b)
  print('asdasd')
  if vec.is(a) and vec.is(b) then
    return near(a.x, b.x) and near(a.y, b.y)
  elseif vec.is(a) then
    return near(a.x, b) and near(a.y, b)
  else
    return near(a, b.x) and near(a, b.y)
  end
end

-- component wise less than comparison between a vec or scalar.
-- more than is implemented via this.
-- (a < b) -> bool
function vec.__lt(a, b)
  if vec.is(a) and vec.is(b) then
    return a.x < b.x and a.y < b.y
  elseif vec.is(a) then
    return a.x < b and a.y < b
  else
    return a < b.x and a < b.y
  end
end

-- component wise less than or equal comparison between a vec or scalar.
-- more than equal is implemented via this.
-- (a <= b) -> bool
function vec.__le(a, b)
  if vec.is(a) and vec.is(b) then
    return a.x <= b.x and a.y <= b.y
  elseif vec.is(a) then
    return a.x <= b and a.y <= b
  else
    return a <= b.x and a <= b.y
  end
end

return vec

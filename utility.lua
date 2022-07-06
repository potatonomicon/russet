-- utility functions.

local math = require((...):gsub('utility', '') .. 'math')
local utility = {}

-- find a point along a spline curve. TIME must be normalized.
-- A and D are control points, actual line is between B and C.
-- result position is written to SELF.
-- (vec self, vec a, vec b, vec c, vec d, float time) -> self
function utility.spline(self, a, b, c, d, time)
  self.x = 0.5 * ((b.x * 2) + (-a.x + c.x) * time + ((a.x * 2) - (b.x * 5) + (c.x * 4) - d.x) * (time ^ 2) + (-a.x + (b.x * 3) - (c.x * 3) + d.x) * (time ^ 3))
  self.y = 0.5 * ((b.y * 2) + (-a.y + c.y) * time + ((a.y * 2) - (b.y * 5) + (c.y * 4) - d.y) * (time ^ 2) + (-a.y + (b.y * 3) - (c.y * 3) + d.y) * (time ^ 3))
  return self
end

-- find a point along a bezier curve. TIME must be normalized.
-- B is the control point.
-- result position is written to SELF.
-- (vec self, vec a, vec b, vec c, float time) -> self
function utility.bezier(self, a, b, c, time)
  self.x = ((1 - time) ^ 2 * a.x) + ((1 - time) * 2 * time * b.x) + (time ^ 2 * c.x)
  self.y = ((1 - time) ^ 2 * a.y) + ((1 - time) * 2 * time * b.y) + (time ^ 2 * c.y)
  return self
end

-- check if a point intersects a circle.
-- A or B can be the point or circle position.
-- (vec a, vec b, float radius) -> bool
function utility.insideCircle(a, b, radius)
  return (((a.x - b.x) ^ 2) + ((a.y - b.y) ^ 2)) <= (radius ^ 2)
end

-- check if a point intersects a capsule.
-- OUT is the vector that the intersection point will be written to.
-- P is a point vector. A and B define the center line of the capsule.
-- RADIUS is the radius of the capsule.
-- (vec out, vec p, vec a, vec b, float radius) -> bool
function utility.intersectPointCapsule(out, p, a, b, radius)
  local abx = b.x - a.x
  local aby = b.y - a.y
  local apx = p.x - a.x
  local apy = p.y - a.y 
  local t = math.clamp(((apx * abx) + (apy * aby)) / ((abx * abx) + (aby * aby)), 0, 1)
  out.x = a.x + (t * abx)
  out.y = a.y + (t * aby)
  return utility.insideCircle(p, out, radius)
end

-- convert HSLA color into RGBA color. all parameters should be normalized.
-- returned RGBA colors are normalized.
-- (float h, float s, float l, float a) -> float r, float g, float b, float a
function utility.hsla(h, s, l, a)
  local r = math.clamp(math.abs(((h * 6 + 0) % 6) - 3) - 1, 0, 1)
  local g = math.clamp(math.abs(((h * 6 + 4) % 6) - 3) - 1, 0, 1)
  local b = math.clamp(math.abs(((h * 6 + 2) % 6) - 3) - 1, 0, 1)

  return (l + s * (r - 0.5) * (1 - math.abs(2 * l - 1))),
         (l + s * (g - 0.5) * (1 - math.abs(2 * l - 1))),
         (l + s * (b - 0.5) * (1 - math.abs(2 * l - 1))),
         (a)
end

-- convert HSVA color into RGBA color. all parameters should be normalized.
-- returned RGBA colors are normalized.
-- (float h, float s, float v, float a) -> float r, float g, float b, float a
function utility.hsva(h, s, v, a)
  return (v * math.lerp(1, math.clamp(math.abs(math.fract(h + (1    )) * 6 - 3) - 1, 0, 1), s)),
         (v * math.lerp(1, math.clamp(math.abs(math.fract(h + (2 / 3)) * 6 - 3) - 1, 0, 1), s)),
         (v * math.lerp(1, math.clamp(math.abs(math.fract(h + (1 / 3)) * 6 - 3) - 1, 0, 1), s)),
         (a)
end

return utility

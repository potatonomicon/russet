-- math extensions.
-- live on the edge; modify lua modules directly.

math.epsilon = 1e-9

-- returns a number as an integer, works differently than floor for negative numbers.
-- (float value) -> int
function math.int(value)
  return (math.modf(value))
end

-- wraps A around the period MIN MAX.
-- MIN and MAX are inclusive.
-- (float a, float min, float max) -> float
function math.wrap(a, min, max)
  return ((a - min) % (max + 1 - min)) + min
end

-- returns the sign of the number, either 0, 1 or -1.
-- (float value) -> float 
function math.sign(value)
  return value > 0 and  1 or 
         value < 0 and -1 or 0
end

-- liner interpolate between two numbers based on time.
-- (float a, float b, float time) -> float
function math.lerp(a, b, time)
  return a * (1.0 - time) + b * time
end

-- equality checks for floating point numbers. returns true when a and b are nearly equal.
-- (float a, float b) -> bool
function math.near(a, b)
  return math.abs(a - b) < math.epsilon
end

-- clamp a value to the range defined by MIN and MAX.
-- (float value, float min, float max) -> float 
function math.clamp(value, min, max)
  if value > max then return max end
  if value < min then return min end
  return value
end

-- returns fractional part of a number.
-- (float value) -> float
function math.fract(value)
  return value - math.floor(value)
end

-- difference between two angles. in radians.
-- sign indicates shortest rotation direction:
-- < 0 counter clockwise.
-- > 0 clockwise.
-- (float a, float b) -> float
function math.angleDifference(a, b)
  local difference = (a - b + math.pi) % (math.pi * 2) - math.pi
  return (difference < -math.pi) and (difference + math.pi * 2) or difference
end

-- 2D distance.
-- (float ax, float ay, float bx, float by) -> float
function math.distance2D(ax, ay, bx, by)
  return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
end

-- 2D dot product.
-- (float ax, float ay, float bx, float by) -> float
function math.dot2D(ax, ay, bx, by)
  return ax * bx + ay * by
end

-- the length of a pseudo vec.
-- (float x, float y) -> float
function math.length2D(x, y)
  return math.sqrt(x * x + y * y)
end

-- normalize a pseudo vec.
-- (float x, float y) -> float x, float y
function math.normalize2D(x, y)
  local length = math.length2D(x, y)
  if length == 0.0 then
    return 0.0, 0.0
  else
    return (x / length), (y / length)
  end
end

-- return the normal of a line.
-- (float ax, float ay, float bx, float by) -> float x, float y
function math.normal2D(ax, ay, bx, by)
  return math.normalize2D(-(ay - by), (ax - bx))
end

-- find the side of a line that P is on relative to the lines orientation. 
-- A and B define the line.
-- -1 left of line.
-- +1 right of line.
--  0 center. (exactly on the line) 
-- (float px, float py, float ax, float ay, float bx, float by) -> int
function math.winding2D(px, py, ax, ay, bx, by)
  return math.sign((px - ax) * (by - ay) - (py - ay) * (bx - ax))
end

-- convert 2d coordinates to 1d index based on WIDTH, and HEIGHT bounds.
-- (int x, int y, int width, int height) -> int
function math.index2D(x, y, width, height)
  return ((y - 1) * width) + x
end

-- convert 3d coordinates to 1d index based on WIDTH, HEIGHT, and DEPTH bounds.
-- (int x, int y, int z, int width, int height, int depth) -> int
function math.index3D(x, y, z, width, height, depth)
  return ((z - 1) * width * height) + ((y - 1) * width) + x
end

return math

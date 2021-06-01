# russet
a set of modules i use for personal projects.
likely to have api breaking changes often.

# modules
**russet.vec2:**

vector module. depends on russet.math.

- 2D vectors.
- features method chaining, pooling, and some more game centric functionality.

**russet.utility:**

general utility module. depends on russet.math.

- 2D splines and beziers.
- 2D shape intersections.
- HSLA and HSVA to RGBA color conversions.

**russet.math:**

extends built in math module.

- general math extensions such as lerp, sign, and clamp.
- inline 2D vector functions such as normal2D, winding2D, and length2D.

**russet.string:**

extends built in string module.

- string splitting.

# usage

make the `russet` folder accessible to your project.
then `require` whatever modules you need.

```lua
local vec = require('russet.vec2')

local player = 
  {velocity     = vec(),
   acceleration = vec()}
local delta = vec(10, 0)
local temp  = vec()

-- later...

-- traditional variation. 
-- operators are overloaded for vectors and scalars. creates garbage collected objects.
player.velocity = player.velocity + delta * player.acceleration * dt

-- inline variation. creates no garbage. must be careful when using release this way.
player.velocity:set(delta:pooled():mul(player.acceleration):muls(dt):release())

-- same as above but does not use the pool.
player.velocity:set(temp:set(delta):mul(player.acceleration):muls(dt))
```

# license
MIT see license.txt





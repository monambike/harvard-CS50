Powerup = Class{}

function Powerup:init(powerupType)
    self.powerupType = powerupType

    -- Powerup to get more two balls
    if powerupType == 1 then self.skin = 9
    -- Key powerup
    elseif powerupType == 2 then self.skin = 10
    -- If is chosen a wrong powerup number
    else error("You need to specify a powerup") end

    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16

    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2

    -- these variables are for keeping track of our velocity on both the
    -- X and Y axis, since the ball can move in two dimensions
    self.dy = 50
    self.dx = 0

    
    self.enabled = true
end

function Powerup:update(dt)
  self.x = self.x + self.dx * dt
  self.y = self.y + self.dy * dt
end

function Powerup:collides(target)
  -- first, check to see if the left edge of either is farther to the right
  -- than the right edge of the other
  if self.x > target.x + target.width or target.x > self.x + self.width then
      return false
  end

  -- then check to see if the bottom edge of either is higher than the top
  -- edge of the other
  if self.y > target.y + target.height or target.y > self.y + self.height then
      return false
  end

  -- if the above aren't true, they're overlapping
    return true
end

function Powerup:render()
    -- gTexture is our global texture for all powerups
    -- gPowerupFrames is a table of quads mapping to each individual powerup skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin],
        self.x, self.y)
end

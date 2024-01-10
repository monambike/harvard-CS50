--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.locked = params.locked
    self.key = params.key
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level

    self.recoverPoints = 5000

    -- give ball random starting velocity
    self.ball.dx, self.ball.dy = Ball:getRandomInitialDXDYVelocity()

    self.powerupBalls = {}
    self:setRandomTimeToSpawnPowerup()
    self.brickHit = 0
    self.powerupBallCount = 0

    table.insert(self.powerupBalls, self.ball)
    self.ballsCount = 1
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    for k, ball in pairs(self.powerupBalls) do ball:update(dt) end
    if self.powerup ~= nil then self.powerup:update(dt) end

    for k, ball in pairs(self.powerupBalls) do
      if ball:collides(self.paddle) then
          -- raise ball above paddle in case it goes below it, then reverse dy
          ball.y = self.paddle.y - 8
          ball.dy = -ball.dy

          --
          -- tweak angle of bounce based on where it hits the paddle
          --

          -- if we hit the paddle on its left side while moving left...
          if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
              ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
          
          -- else if we hit the paddle on its right side while moving right...
          elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
              ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
          end

          gSounds['paddle-hit']:play()
      end
    end

    if self.powerup ~= nil then
      -- Sets a initial random span of time to spawn powerup
      -- If the ball collides with a powerup it spawns a new powerup ball
      if self.powerup:collides(self.paddle) then
        if self.powerup.powerupType == 1 then
          gSounds['powerup-1']:play()
          -- Creates two balls
          while(self.powerupBallCount < 2)
          do
              self.newPowerupBall = Ball()
              -- Creates a new ball with a random skin
              self.newPowerupBall.skin = Ball:getRandomBallSkin()

              self.newPowerupBall.x = self.paddle.x + (self.paddle.width / 2) - 4
              self.newPowerupBall.y = self.paddle.y - 8

              -- Sets that ball a random starting velocity
              self.newPowerupBall.dx, self.newPowerupBall.dy = Ball:getRandomInitialDXDYVelocity()

              -- self.newPowerupBall:render()
              self.ballsCount = self.ballsCount + 1
              table.insert(self.powerupBalls, self.newPowerupBall)

              self.powerupBallCount = self.powerupBallCount + 1

              -- Destroying powerup
              self.powerup = nil
          end
          self.powerupBallCount = 0
        elseif self.powerup.powerupType == 2 and not self.key then
          gSounds['powerup-2']:play()

          self.key = true

          -- Destroying powerup
          self.powerup = nil
        end
      end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

      for z, ball in pairs(self.powerupBalls) do
        -- only check collision if we're in play

        if brick.inPlay and ball:collides(brick) then
            -- add to score
            self.score = self.score + (brick.tier * 200 + brick.color * 25)

            self.brickHit = self.brickHit + 1
            -- If user got a certain amount of score, it will spawn a powerup
            self:trySpawnScoreBasedPowerup()

            -- trigger the brick's hit function, which removes it from play
            brick:hit(self.key)

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()

                self.paddle:grow()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints
                })
            end

            -- Removing key if the brick got unlocked
            if brick.isLocked then
              self.key = false
              self.locked = false
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if ball.x + 2 < brick.x and ball.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                ball.dx = -ball.dx
                ball.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                ball.dx = -ball.dx
                ball.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif ball.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                ball.dy = -ball.dy
                ball.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                ball.dy = -ball.dy
                ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(ball.dy) < 150 then
                ball.dy = ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
      end
    end

    if self.powerup ~= nil then
      if self.powerup.y >= VIRTUAL_HEIGHT then
        self.powerup = nil
      end
    end

    for k, ball in pairs(self.powerupBalls) do
      -- if ball goes below bounds
      if ball.y >= VIRTUAL_HEIGHT then
        table.remove(self.powerupBalls, k)
        ball = nil
        self.ballsCount = self.ballsCount - 1
        -- and if it was the last ball, revert to serve state and decrease health
        if self.ballsCount <= 0 then
          self.health = self.health - 1
          gSounds['hurt']:play()

          if self.health == 0 then
              gStateMachine:change('game-over', {
                  score = self.score,
                  highScores = self.highScores
              })
          else
              gStateMachine:change('serve', {
                  paddle = self.paddle,
                  bricks = self.bricks,
                  locked = self.locked,
                  key = self.key,
                  health = self.health,
                  score = self.score,
                  highScores = self.highScores,
                  level = self.level,
                  recoverPoints = self.recoverPoints
              })
              self.paddle:shrink()
          end
        end
      end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    for k, ball in pairs(self.powerupBalls) do ball:render() end
    if self.powerup ~= nil then self.powerup:render() end

    renderScore(self.score)
    renderHealth(self.health)
    renderKeyPowerup(self.key)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end

function PlayState:trySpawnTimeBasedPowerup()
  if self.powerup == nil then
    if not self.isPowerupOnScreen and self.timer < self.timeToSpawnPowerup then
        self.timer = self.timer + 1
    -- If there's no powerup on the screen and the timer to spawn a powerup
    -- got achieved already
    else
        -- From time to time it spawns a new powerup and resets the timer
        self:spawnPowerup()
        self.timer = 0
        -- Sets a new random span of time to spawn powerup
        self:setRandomTimeToSpawnPowerup()
    end
  end
end

function PlayState:trySpawnScoreBasedPowerup()
    if self.powerup == nil then
      -- If there's no powerup on the screen and the player hit a bit a
      -- certain amount of times
      if not self.isPowerupOnScreen and self.brickHit >= 1 then
          -- Spawns a new power up and resets the count
          self:spawnPowerup()
          self.brickHit = 0
      end
    end
end

function PlayState:spawnPowerup()
  if self.key then
    self.powerup = Powerup(1)
  else
    -- Spawn a random powerup
    self.powerup = Powerup(math.random(1, 2))
  end

  self.powerup.x = math.random(0 + 2, VIRTUAL_WIDTH - 2 - 16)
  self.powerup.y = 0

  self.powerup:render()
end

function PlayState:setRandomTimeToSpawnPowerup()
    -- Sets a initial random span of time to spawn powerup
    self.timeToSpawnPowerup = math.random(5, 15)
end

--[[
    ScoreState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

ScoreState = Class{__includes = BaseState}

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
]]
function ScoreState:enter(params)
    self.score = params.score
end

function ScoreState:update(dt)
    -- go back to play if enter is pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown')
    end
end

function ScoreState:render()
  if self.score > 0 then
        self.medal = ''
        self.medalScore = 0
        self.goldScore = 5
        self.silverScore = 3
        self.bronzeScore = 1

        if self.score >= self.goldScore then
            self.medal = 'gold'
            self.medalScore = self.goldScore
        elseif self.score >= self.silverScore then
            self.medal = 'silver'
            self.medalScore = self.silverScore
        elseif self.score >= self.bronzeScore then
            self.medal = 'bronze'
            self.medalScore = self.bronzeScore
        end

        self.plural = ''
        if self.score > 1 then self.plural = 's' end

        love.graphics.printf('You got a ' .. string.upper(self.medal) .. ' MEDAL for getting at least ' .. tostring(self.medalScore) .. ' point' .. self.plural .. '.', 0, 40, VIRTUAL_WIDTH, 'center')
        
        local medalImage = love.graphics.newImage('medal-' .. self.medal .. '.png')
        love.graphics.draw(medalImage, 220, 180)
    end

    -- simply render the score to the middle of the screen
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Oof! You lost!', 0, 64, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 100, VIRTUAL_WIDTH, 'center')

    love.graphics.printf('Press Enter to Play Again!', 0, 160, VIRTUAL_WIDTH, 'center')
end

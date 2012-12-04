local message

function love.load()
    love.physics.setMeter(10) -- a meter is 10px
    world = love.physics.newWorld(0,  0, true) -- no gravity, things can sleep 

    -- font
    font = love.graphics.newImageFont("resources/images/imagefont.png",
        " abcdefghijklmnopqrstuvwxyz" ..
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
        "123456789.,!?-+/():;%&`'*#=[]\""
        )
    message = "blank"
    -- world objects set
    objects = {}
    
    -- ship
    objects.ship = {}
    objects.ship.body = love.physics.newBody(world, 650/2, 650/2, "dynamic") -- place a dynamic ship int he centre of the space
    objects.ship.shape = love.physics.newRectangleShape(5, 10) -- w = 20, h = 80
    objects.ship.fixture = love.physics.newFixture(objects.ship.body, objects.ship.shape, 1) -- density 1 attachment
   
    -- bullets
    freq = 1
    objects.bullets = {}

    -- planets
    objects.planets = {}
    
    planet1 = {}
    planet1.body = love.physics.newBody(world,100,100, "static")
    planet1.shape = love.physics.newCircleShape(50)
    planet1.fixture = love.physics.newFixture(planet1.body, planet1.shape, 1)

    planet2 = {}
    planet2.body = love.physics.newBody(world, 400,200, "static")
    planet2.shape = love.physics.newCircleShape(50)
    planet2.fixture = love.physics.newFixture(planet2.body, planet2.shape, 1)

    table.insert(objects.planets, planet1)
    table.insert(objects.planets, planet2)
    
    -- screen setup
    love.graphics.setBackgroundColor(8, 8, 16 ) -- black space
    love.graphics.setMode(650, 650, false, true, 0)
end

function addBullet() -- shoot a bullet
    newBullet = {}
    newBullet.body = love.physics.newBody(world, objects.ship.body:getX(), objects.ship.body:getY() - 5, "dynamic")
    newBullet.shape = love.physics.newCircleShape(2) -- radius = 2
    newBullet.fixture = love.physics.newFixture(newBullet.body, newBullet.shape, 1) -- density 1 attachment
    newBullet.body:setBullet(true)
    newBullet.body:applyForce(
            math.sin(objects.ship.body:getAngle()) * 250, 
            math.cos(objects.ship.body:getAngle()) * -250
    )
    table.insert(objects.bullets, newBullet)
end

function doGravity(planet, object) -- calculate the radial gravity for the planet
    force = 10 -- the force of gravity
    -- distance, x1, y1, x2, y2 = love.physics.getDistance(planet.fixture, object.fixture) -- THIS CRASHES FOR SOME REASON
     local distance = math.sqrt( ( planet.body:getX() - object.body:getX() )^2 + (planet.body:getY() - object.body:getY()) ^2 ) -- calculate the mutual distance
     local angle = math.atan2(planet.body:getX() - object.body:getX(), planet.body:getY() - object.body:getY()) -- calculate the mutual angle
     local newForce = force / (distance^2)
     
     object.body:applyLinearImpulse( newForce * math.sin(angle), newForce * math.cos(angle) )
end

function love.update(dt)
    world:update(dt) -- makes the world turn
    -- check ship bounds
    if objects.ship.body:getX() < 0 then 
        objects.ship.body:setPosition(0, objects.ship.body:getY())
    end
    if objects.ship.body:getY() < 0 then 
        objects.ship.body:setPosition(objects.ship.body:getX(), 0)
    end
    if objects.ship.body:getX() > 650 then 
        objects.ship.body:setPosition(650, objects.ship.body:getY())
    end
    if objects.ship.body:getY() > 650 then 
        objects.ship.body:setPosition(objects.ship.body:getX(), 650)
    end
    if objects.ship.body:getAngle() > (2 * math.pi) then
        objects.ship.body:setAngle( objects.ship.body:getAngle() % ( 2* math.pi ) )
    elseif objects.ship.body:getAngle() < 0 then
        objects.ship.body:setAngle( objects.ship.body:getAngle() % ( 2* math.pi ) )
    end
    -- check bullet bounds
    for i, bullet in ipairs(objects.bullets) do
        if bullet.body:getX() < 0 then
            table.remove(objects.bullets, i)
        elseif bullet.body:getY() < 0 then
            table.remove(objects.bullets, i)
        elseif bullet.body:getX() > 650 then
            table.remove(objects.bullets, i)
        elseif bullet.body:getY() > 650 then
            table.remove(objects.bullets, i)
        end
    end
    
    -- planetary physics
    for p, planet in ipairs(objects,planets) do
        doGravity(planet, objects.ship)
        for i,bullet in ipairs(object.bullets) do
            doGravity(planet, bullet)
        end
    end

    -- keyboard
    if love.keyboard.isDown("right") then -- right arrow
        objects.ship.body:setAngle(
            (objects.ship.body:getAngle() + math.pi / 16) % (math.pi * 2) 
        )
    elseif love.keyboard.isDown("left") then -- left arrow
        objects.ship.body:setAngle(
            (objects.ship.body:getAngle() - math.pi / 16) % (math.pi * 2) 
        )
    elseif love.keyboard.isDown("up") then -- up arrow
        objects.ship.body:applyForce(
            math.sin(objects.ship.body:getAngle()) * 100, 
            math.cos(objects.ship.body:getAngle()) * -100
        )
    elseif love.keyboard.isDown("down") then -- down arrow
        objects.ship.body:applyForce(
            math.sin(objects.ship.body:getAngle()) * -100, 
            math.cos(objects.ship.body:getAngle()) * 100
        )
    elseif love.keyboard.isDown(" ") then -- space bar
        freq = freq + dt
        if freq >= 1 then
            message = "pew! pew! pew!"
            addBullet()
            freq = 0
        end
    elseif love.keyboard.isDown("r") then -- reset
        objects.ship.body:setPosition(650/2, 650/2)
        objects.ship.body:setLinearVelocity(0, 0)
        objects.ship.body:setAngularVelocity(0)
        objects.ship.body:setAngle(0)
    end
end

function love.draw()
    love.graphics.setFont(font)
    love.graphics.setColor(193, 193, 193) -- gray text
    
    love.graphics.print('Velocity:'..objects.ship.body:getAngularVelocity(), 10, 10)
    love.graphics.print('Angle:'..((180 * objects.ship.body:getAngle()) / math.pi), 10, 20)
    love.graphics.printf(message, 0, (650/2) - font:getHeight(), 650, "center")
    
    message = "" -- reset the message after display

    love.graphics.setColor(193, 47, 14) -- red ship
    love.graphics.polygon("fill", objects.ship.body:getWorldPoints(objects.ship.shape:getPoints()))

    love.graphics.setColor(128, 128, 255) -- blue bullets

    for i,bullet in ipairs(objects.bullets) do
        love.graphics.circle("fill", bullet.body:getX(), bullet.body:getY(), bullet.shape:getRadius())
    end

    love.graphics.setColor(128, 255, 128) 
    
    for i,planet in ipairs(objects.planets) do
        love.graphics.circle("fill", planet.body:getX(), planet.body:getY(), planet.shape:getRadius())
    end
end

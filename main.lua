local message

--To Remember: Category data
--1: Player Ship
--2: Bullet
--3: 
--4: 
--5: Asteroid 
--6: Planet
--

-- OVERALL TODO:
-- create a uniform objects scanner that checks bounds, resets velocity and momentum and removes marked data
-- revise collision detection function to make better sense (need to find a better way to do choose which event has happened)

-- World Physics Area
worldPhysics = {}
worldPhysics.meter = 10 -- 1m is 10 px
worldPhysics.pixelSize = 650 -- window is worldPhysics.pixelSizepx square

-- Ship Physics Area
shipPhysics = {}
shipPhysics.angularDamping = 0.2 -- 0 to 1
shipPhysics.maxAngularVelocity = 25 -- 0 to whatever
shipPhysics.height = 1 * worldPhysics.meter -- 1m long
shipPhysics.width = 0.5 * worldPhysics.meter -- 0.5m wide
shipPhysics.force = 100 -- accelerate with 100 force

-- Bullet Physics Area
freq = 1
bulletPhysics = {}
bulletPhysics.radius = 0.2 * worldPhysics.meter -- 20cm bullets
bulletPhysics.force = 250 -- accelerate with 250 force

function love.load()
    love.physics.setMeter(worldPhysics.meter)
    world = love.physics.newWorld(0,  0, true) -- no gravity, things can sleep 
    world:setCallbacks(beginContact) -- add gloval collision detection

    -- font
    font = love.graphics.newImageFont("resources/images/imagefont.png",
        " abcdefghijklmnopqrstuvwxyz" ..
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
        "123456789.,!?-+/():;%&`'*#=[]\""
        )
    text = ""
    message = "blank"
    -- world objects set
    objects = {}
    
    -- ship
    objects.ship = {}
    objects.ship.body = love.physics.newBody(
    										world, 
    										worldPhysics.pixelSize/2, 
    										worldPhysics.pixelSize/2, 
    										"dynamic") -- place a dynamic ship int he centre of the space

    objects.ship.body:setAngularDamping(shipPhysics.angularDamping)

    objects.ship.shape = love.physics.newRectangleShape(
    									shipPhysics.width, 
    									shipPhysics.height)
    
    objects.ship.fixture = love.physics.newFixture(
    									objects.ship.body, 
    									objects.ship.shape, 
    									1) -- density 1 attachment

    objects.ship.fixture:setCategory(1) 

    -- bullets
    objects.bullets = {}

    -- planets
    objects.planets = {}
    --TODO: generate this as a proper function that makes planets with specified mass, size and position
    planet1 = {}
    planet1.body = love.physics.newBody(world,100,100, "static")
    planet1.shape = love.physics.newCircleShape(50)
    planet1.fixture = love.physics.newFixture(planet1.body, planet1.shape, 1)
    planet1.fixture:setCategory(6)

    planet2 = {}
    planet2.body = love.physics.newBody(world, 400,200, "static")
    planet2.shape = love.physics.newCircleShape(80)
    planet2.fixture = love.physics.newFixture(planet2.body, planet2.shape, 1)
    planet2.fixture:setCategory(6)

    table.insert(objects.planets, planet1)
    table.insert(objects.planets, planet2)
   
    -- asteroids
    objects.asteroids = {}
    --TODO: generate this as a proper function that takes a centre point and makes random shapes, and places them in clear space
    asteroid1 = {}
    asteroid1.radius = 5
    asteroid1.body = love.physics.newBody(
    								world, 
    								asteroid1.centreX, 
    								asteroid1.centreY, 
    								"dynamic")

    asteroid1.shape = love.physics.newPolygonShape(
        200,200,225,175,225,225
    )
    asteroid1.fixture = love.physics.newFixture(
    										asteroid1.body, 
    										asteroid1.shape, 
    										1)

    asteroid1.fixture:setCategory(5)

    --TODO: generate this as a proper function that takes a centre point and makes random shapes, and places them in clear space
    asteroid2 = {}
    asteroid2.body = love.physics.newBody(world, asteroid2.centreX, asteroid2.centreY, "dynamic")
    asteroid2.shape = love.physics.newPolygonShape(
        200,300,225,275,225,325
    )
    asteroid2.fixture = love.physics.newFixture(asteroid2.body, asteroid2.shape, 1)
    asteroid2.fixture:setCategory(5)
    
    table.insert(objects.asteroids, asteroid2)
    table.insert(objects.asteroids, asteroid1)

    -- clean up spare references -- REMOVE THIS WHEN PROPER FUNCTION IS MADE
    asteroid1 = nil
    asteroid2 = nil
    planet1 = nil
    planet2 = nil

    -- screen setup
    love.graphics.setBackgroundColor(8, 8, 16 ) -- black space
    love.graphics.setMode(worldPhysics.pixelSize, worldPhysics.pixelSize, false, true, 0)

    -- Keyboard
    love.keyboard.setKeyRepeat(0.01, 1)
end

function addBullet() -- shoot a bullet
    newBullet = {}
    newBullet.body = love.physics.newBody(
        world, 
        objects.ship.body:getX() + math.sin(objects.ship.body:getAngle()) * worldPhysics.meter, 
        objects.ship.body:getY() - math.cos(objects.ship.body:getAngle()) * worldPhysics.meter, 
        "dynamic"
    )
    newBullet.shape = love.physics.newCircleShape(bulletPhysics.radius) -- radius = 2
    newBullet.fixture = love.physics.newFixture(newBullet.body, newBullet.shape, 1) -- density 1 attachment
    -- set the category
    newBullet.fixture:setCategory(2)

    newBullet.body:setBullet(true)
    newBullet.body:applyForce(
            math.sin(objects.ship.body:getAngle()) * bulletPhysics.force, 
            math.cos(objects.ship.body:getAngle()) * -bulletPhysics.force
    )
    table.insert(objects.bullets, newBullet)
end

function doGravity(planet, object) -- calculate the radial gravity for the planet
    force = 10 -- the force of gravity
    -- distance, x1, y1, x2, y2 = love.physics.getDistance(planet.fixture, object.fixture) -- THIS CRASHES FOR SOME REASON
     local distance = math.sqrt( ( planet.body:getX() - object.body:getX() )^2 + (planet.body:getY() - object.body:getY()) ^2 ) -- calculate the mutual distance
     local angle = math.atan2(planet.body:getX() - object.body:getX(), planet.body:getY() - object.body:getY()) -- calculate the mutual angle
     local newForce = force / (distance^2) -- I realise I sqrt and square this, but we can 'optimise' that later
     
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
    if objects.ship.body:getX() > worldPhysics.pixelSize then 
        objects.ship.body:setPosition(worldPhysics.pixelSize, objects.ship.body:getY())
    end
    if objects.ship.body:getY() > worldPhysics.pixelSize then 
        objects.ship.body:setPosition(objects.ship.body:getX(), worldPhysics.pixelSize)
    end
    if objects.ship.body:getAngle() > (2 * math.pi) then
        objects.ship.body:setAngle( objects.ship.body:getAngle() % ( 2* math.pi ) )
    elseif objects.ship.body:getAngle() < 0 then
        objects.ship.body:setAngle( objects.ship.body:getAngle() % ( 2* math.pi ) )
    end
    if objects.ship.body:getAngularVelocity() > shipPhysics.maxAngularVelocity then
        objects.ship.body:setAngularVelocity(objects.ship.body:getAngularVelocity() % shipPhysics.maxAngularVelocity)
    end
    -- check bullet bounds
    for i, bullet in ipairs(objects.bullets) do
        if bullet.body:getX() < 0 then
            table.remove(objects.bullets, i)
            message = 'removed'..i
        elseif bullet.body:getY() < 0 then
            table.remove(objects.bullets, i)
            message = 'removed'..i
        elseif bullet.body:getX() > worldPhysics.pixelSize then
            table.remove(objects.bullets, i)
            message = 'removed'..i
        elseif bullet.body:getY() > worldPhysics.pixelSize then
            table.remove(objects.bullets, i)
            message = 'removed'..i
        end
    end
    -- bullet removal
    for b, bullet in ipairs(objects.bullets) do
        if bullet.fixture:getUserData() == 'remove' then
            table.remove(objects.bullets, b)
            message = 'removed bullet'..b
        end
    end
    -- asteroid collision cleanup
    for a,asteroid in ipairs(objects.asteroids) do
        if asteroid.fixture:getUserData() == 'remove' then
            table.remove(objects.asteroids, a)
            message = 'remove asteroid'..a
        end
    end
    -- planetary physics
    for p, planet in ipairs(objects,planets) do
        doGravity(planet, objects.ship)
        for i,bullet in ipairs(objects.bullets) do
            doGravity(planet, bullet)
        end
        for i, asteroid in ipairs(objects.asteroids) do
            doGravity(planet, asteroid)
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
            math.sin(objects.ship.body:getAngle()) *shipPhysics.force,  
            math.cos(objects.ship.body:getAngle()) * -shipPhysics.force
        )
    elseif love.keyboard.isDown("down") then -- down arrow
        objects.ship.body:applyForce(
            math.sin(objects.ship.body:getAngle()) * -shipPhysics.force, 
            math.cos(objects.ship.body:getAngle()) * shipPhysics.force
        )
    elseif love.keyboard.isDown(" ") then -- space bar
        freq = freq + dt
        if freq >= 1 then
            message = "pew! pew! pew!"
            addBullet()
            freq = 0
        end
    elseif love.keyboard.isDown("r") then -- reset
        objects.ship.body:setPosition(worldPhysics.pixelSize/2, worldPhysics.pixelSize/2)
        objects.ship.body:setLinearVelocity(0, 0)
        objects.ship.body:setAngularVelocity(0)
        objects.ship.body:setAngle(0)
    end
end

function love.draw()
    love.graphics.setFont(font)
    love.graphics.setColor(193, 193, 193) -- gray text
    
    love.graphics.print('Velocity:'..objects.ship.body:getAngularVelocity(), 10, 10) -- still not sure this is the right attribute to check
    love.graphics.print('Angle:'..((180 * objects.ship.body:getAngle()) / math.pi), 10, 20) -- converted to degrees
    love.graphics.printf(message, 0, (worldPhysics.pixelSize/2) - font:getHeight(), worldPhysics.pixelSize, "center")
    love.graphics.printf(text, 0, (600/2) - font:getHeight(), worldPhysics.pixelSize, "center")
   
    text = ""

    love.graphics.setColor(193, 47, 14) -- red ship
    love.graphics.polygon("fill", objects.ship.body:getWorldPoints(objects.ship.shape:getPoints()))

    love.graphics.setColor(128, 128, 255) -- blue bullets

    for i,bullet in ipairs(objects.bullets) do
        love.graphics.circle("fill", bullet.body:getX(), bullet.body:getY(), bullet.shape:getRadius())
    end

    love.graphics.setColor(128, 255, 128) -- Green planets
    
    for i,planet in ipairs(objects.planets) do
        love.graphics.circle("fill", planet.body:getX(), planet.body:getY(), planet.shape:getRadius())
    end

    love.graphics.setColor(254, 216, 93) -- yellow asteroids

    for i,asteroid in ipairs(objects.asteroids) do
        love.graphics.polygon("fill", asteroid.body:getWorldPoints(asteroid.shape:getPoints()))
    end
end

function beginContact(a, b, coll)
    message = 'A:'..a:getCategory()..'\n'..'B:'..b:getCategory()..'\n'
    
    -- Bullet hits planet and is removed
    if (a:getCategory() == 2 and b:getCategory() == 6) then
        a:setUserData('remove')
    -- Planet hits bullet and removes bullet (can this happen?)
    elseif (a:getCategory() == 6 and b:getCategory() == 2) then
        b:setUserData('remove')
    -- Planet hits asteroid and removes asteroid
    elseif (a:getCategory() == 5 and b:getCategory() == 6) then
        a:setUserData('remove')
    -- Bullet hits asteroid, both are removed
    elseif(a:getCategory() == 2 and b:getCategory() == 5) then
        b:setUserData('remove')
        a:setUserData('remove')
    -- Bullet hits asteroid, both are removed
    elseif(b:getCategory() == 2 and a:getCategory() == 5) then
        b:setUserData('remove')
        a:setUserData('remove')
    end
end


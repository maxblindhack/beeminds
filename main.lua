function love.load()
   love.graphics.setNewFont("Octarine-Light.otf", 16)
   love.graphics.setBackgroundColor(35/255,35/255,35/255)

   love.window.setFullscreen(true)
   fieldX, fieldY = love.window.getMode()

   bees = {}
   beebraintimer = 1
   beebrainmaxtimer = 0.1

   actiontable = {["moveup"]={x=0,y=-1},["movedown"]={x=0,y=1},["moveright"]={x=1,y=0},["moveleft"]={x=-1,y=0}}

   for i=1,10 do
      AddBee()
   end

   selectedbee = nil;

end

function AddBee()
   local newbee = {brain={},pos={x=fieldX/2, y=fieldY/2},speed=15}

   newbee.brain.outputcells = {
      {action="moveup", energy=math.random(0,1000), pos={x=math.random(-100,100),y=-100}},
      {action="moveright", energy=math.random(0,1000), pos={x=100,y=math.random(-100,100)}},
      {action="moveleft", energy=math.random(0,1000), pos={x=-100,y=math.random(-100,100)}},
      {action="movedown", energy=math.random(0,1000), pos={x=math.random(-100,100),y=100}},
   }

   newbee.brain.inputcells = {}

   for i=1,10 do
      table.insert(newbee.brain.inputcells, {sense="random", energy=0, pos={x=math.random(-100,100),y=math.random(-100,100)}, connections={} } );
   end

   newbee.brain.cells = {}

   for i=1,100 do
      table.insert(newbee.brain.cells, {connections={}, energy=0, pos={x=math.random(-100,100),y=math.random(-100,100)}});
   end



   table.insert(bees, newbee)
end

function DoThinking(bee)
   for i=#bee.brain.cells,1,-1 do
      c = bee.brain.cells[i]

      -- fire if passed energy threshold
      if c.energy >= 20 then
         local energyused = c.energy
         if energyused > 50 then energyused = 50 end
         c.energy = c.energy - energyused

         local dividedenergy = energyused/#c.connections
         for i, con in pairs(c.connections) do
            con.cell.energy = con.cell.energy + dividedenergy
            con.strength = con.strength + dividedenergy
         end
      end

      --degrade connections over time & remove weak connections
      for i=#c.connections,1,-1 do
         local con = c.connections[i]
         --con.strength = con.strength - 1
         if con.strength < 0 then
            table.remove(c.connections, i)
         end
      end

      -- form new random connections (replace with locational?)
      for i=#bee.brain.cells,1,-1 do
         tc = bee.brain.cells[i]
         if c ~= tc then
            if math.random() < 0.05 then
               table.insert(c.connections, {strength=100, cell=tc})
            end
         end
      end
      for i=#bee.brain.inputcells,1,-1 do
         tc = bee.brain.inputcells[i]
         if math.random() < 0.01 then
            table.insert(c.connections, {strength=100, cell=tc})
         end
      end
      for i=#bee.brain.outputcells,1,-1 do
         tc = bee.brain.outputcells[i]
         if math.random() < 0.01 then
            table.insert(c.connections, {strength=100, cell=tc})
         end
      end

   end
end

function DoInputs(bee)
   for i=#bee.brain.inputcells,1,-1 do
      local c = bee.brain.inputcells[i]
      --make random input energy
      c.energy = c.energy + math.random(0,5)

      --send input energy over connections
      if c.energy > 0 and #c.connections > 0 then
         local energyused = c.energy
         if energyused > 100 then energyused = 100 end
         c.energy = c.energy - energyused

         local dividedenergy = energyused/#c.connections
         for i=1,#c.connections do
            local con = c.connections[i]
            con.cell.energy = con.cell.energy + dividedenergy
            con.strength = con.strength + dividedenergy
         end
      end

      --make new random connections
      for i=#bee.brain.cells,1,-1 do
         tc = bee.brain.cells[i]
         if math.random() < 0.05 then
            table.insert(c.connections, {strength=100, cell=tc})
         end
      end

   end
end

function DoOutputs(bee, dt)
   for i=1,#bee.brain.outputcells do
      local c = bee.brain.outputcells[i]
      if c.energy >= 20 then
         local energyused = c.energy

         if energyused > 50 then energyused = 50 end

         bee.pos.x = actiontable[c.action].x*bee.speed*dt*energyused
         bee.pos.y = actiontable[c.action].y*bee.speed*dt*energyused
         c.energy = c.energy - energyused
      end
   end
end

function TrySelectBee()
   local mousex, mousey = love.mouse.getPosition()
   local minrange = 20
   selectedbee = nil
   local lowestdist = 9999
   for i=1,#bees do
      local b = bees[i]
      dist = Distance({mousex, mousey}, {b.pos.x, b.pos.y})
      if dist < minrange and dist < lowestdist then
         lowestdist = dist
         selectedbee = b
      end
   end
end

function Distance(pos1, pos2) --{x, y}, {x, y}
   return math.sqrt(math.pow((pos1[1]-pos2[1]), 2)+math.pow((pos1[2]-pos2[2]), 2))
end

function love.update(dt)
   if love.keyboard.isDown("escape") then
      love.event.quit(0)
   end

   if love.keyboard.isDown("space") then
      AddBee()
   end

   if love.mouse.isDown(1) then
      TrySelectBee()
   end

   if beebraintimer > 0 then
      beebraintimer = beebraintimer - dt
   else
      for i=1,#bees do
         DoThinking(bees[i])
      end
      beebraintimer = beebrainmaxtimer
   end

   for i=1,#bees do
      DoOutputs(bees[i], dt)
      DoInputs(bees[i])
   end

end

function love.draw()
   love.graphics.setColor(245,190,0)
   for i=1,#bees do
      love.graphics.circle( "fill", bees[i].pos.x, bees[i].pos.y, 5 )
   end

   love.graphics.setColor(255,255,255)
   love.graphics.print("Bees: " .. #bees, fieldX/2, 35)

   if selectedbee then
      love.graphics.print("Selected Bee: " .. selectedbee.pos.x .. ", " .. selectedbee.pos.y, fieldX/5, 35)

      for i=1,#selectedbee.brain.cells do
         local c = selectedbee.brain.cells[i]
         love.graphics.circle("fill", 100+c.pos.x,300+c.pos.y, 1+c.energy)
      end

      for i=1,#selectedbee.brain.outputcells do
         local oc = selectedbee.brain.outputcells[i]
         love.graphics.setColor(255,0,0)
         love.graphics.circle("fill", 100+oc.pos.x,300+oc.pos.y, 1+oc.energy)
      end

      for i=1,#selectedbee.brain.inputcells do
         local ic = selectedbee.brain.inputcells[i]
         love.graphics.setColor(0,255,0)
         love.graphics.circle("fill", 100+ic.pos.x,300+ic.pos.y, 1+ic.energy)
      end

   else
      love.graphics.print("Selected Bee: None", fieldX/5, 35)
   end
end

function love.quit()
   print("Bee seeing you!")
end

--[[
   bee
      {genes={}, brain={}, pos={x=x location, y=y location}, speed=speed of movement per second}

   genes
      ?

   brain
      outputcells={}
      inputcells={}
      cells={}

   outputcell
      action="moveright","moveleft","moveup","movedown"
      energy=0

   inputcells
      sense=""
      energy=0
      pos={x,y}
      connections={}

   cells
      connections={}
      pos={x,y}
      energy=0

   connections
      strength=0
      cell=cell


]]

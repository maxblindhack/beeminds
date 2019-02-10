function love.load()
   math.randomseed(os.time())
   love.graphics.setNewFont("Octarine-Light.otf", 16)
   love.graphics.setBackgroundColor(35/255,35/255,35/255)

   love.window.setMode(1000, 800)
   fieldX, fieldY = love.window.getMode()

   flower = {pos={x=750,y=600}}

   bees = {}
   beebraintimer = 0
   beebrainmaxtimer = 0.5
   braindiag = {x=150, y=300}

   steps = 0

   actiontable = {["moveup"]={x=0,y=-1},["movedown"]={x=0,y=1},["moveright"]={x=1,y=0},["moveleft"]={x=-1,y=0}}

   Reset()

   selectedbee = nil

end

function Reset()
   bees = {}
   for i=1,3 do
      AddBee()
   end
   selectedbee = nil
end

function AddBee()
   local newbee = {brain={},pos={x=fieldX/2, y=fieldY/2},speed=25}

   newbee.brain.outputcells = {
      {action="moveup", energy=0, pos={x=math.random(-100,100),y=-100}},
      {action="moveright", energy=0, pos={x=100,y=math.random(-100,100)}},
      {action="moveleft", energy=0, pos={x=-100,y=math.random(-100,100)}},
      {action="movedown", energy=0, pos={x=math.random(-100,100),y=100}},
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
      if c.energy >= 0 then
         local energyused = c.energy
         if energyused > 5 then energyused = 5 end
         c.energy = c.energy - energyused

         local dividedenergy = energyused/#c.connections
         for i=1,#c.connections do
            local con = c.connections[i]
            con.cell.energy = con.cell.energy + dividedenergy
            con.strength = con.strength + dividedenergy
         end
      end

      --leak energy off cells
      if c.energy > 0 then
         --c.energy = c.energy - 1
      else
         c.energy = 0
      end

      --degrade connections over time & remove weak connections
      for i=#c.connections,1,-1 do
         local con = c.connections[i]
         if c.energy <= 0 then
            con.strength = con.strength - 1
         end
         if con.strength < 0 then
            table.remove(c.connections, i)
         end
      end

      -- form new random connections (replace with locational?)
      for i=#bee.brain.cells,1,-1 do
         tc = bee.brain.cells[i]
         if c ~= tc then
            if math.random() < c.energy*0.1 then
               table.insert(c.connections, {strength=10, cell=tc})
            end
         end
      end
      for i=#bee.brain.inputcells,1,-1 do
         tc = bee.brain.inputcells[i]
         if math.random() < c.energy*0.1 then
            table.insert(c.connections, {strength=10, cell=tc})
         end
      end
      for i=#bee.brain.outputcells,1,-1 do
         tc = bee.brain.outputcells[i]
         if math.random() < c.energy*0.1 then
            table.insert(c.connections, {strength=10, cell=tc})
         end
      end

   end
end

function DoInputs(bee)
   for i=#bee.brain.inputcells,1,-1 do
      local c = bee.brain.inputcells[i]

      --send input energy over connections
      if c.energy > 0 and #c.connections > 0 then
         local energyused = c.energy
         if energyused > 5 then energyused = 5 end
         c.energy = c.energy - energyused

         local dividedenergy = energyused/#c.connections
         for i=1,#c.connections do
            local con = c.connections[i]
            con.cell.energy = con.cell.energy + dividedenergy
            con.strength = con.strength + dividedenergy
         end
      end

      --degrade connections over time & remove weak connections
      for i=#c.connections,1,-1 do
         local con = c.connections[i]
         if c.energy <= 0 then
            con.strength = con.strength - 10
         end
         if con.strength < 0 then
            table.remove(c.connections, i)
         end
      end

      --make new random connections
      for i=#bee.brain.cells,1,-1 do
         tc = bee.brain.cells[i]
         if math.random() < c.energy*0.001 then
            table.insert(c.connections, {strength=10, cell=tc})
         end
      end

      --make input energies based on distance to flower
      local addenergy = 300-Distance({bee.pos.x + c.pos.x, bee.pos.y + c.pos.y}, flower.pos);
      c.energy = c.energy + addenergy

   end
end

function DoOutputs(bee)
   for i=1,#bee.brain.outputcells do
      local c = bee.brain.outputcells[i]
      if c.energy > 0 then
         local energyused = c.energy

         if energyused > 3 then energyused = 3 end

         bee.pos.x = bee.pos.x+actiontable[c.action].x*bee.speed*energyused
         bee.pos.y = bee.pos.y+actiontable[c.action].y*bee.speed*energyused
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
      dist = Distance({x=mousex, y=mousey}, b.pos)
      if dist < minrange and dist < lowestdist then
         lowestdist = dist
         selectedbee = b
      end
   end
end

function Distance(pos1, pos2) --{x, y}, {x, y} TODO is this okay if passing in {x=5, y=15}
   return math.sqrt(math.pow((pos1.x-pos2.x), 2)+math.pow((pos1.y-pos2.y), 2))
end

function love.update(dt)
   if love.keyboard.isDown("escape") then
      love.event.quit(0)
   end

   if love.keyboard.isDown("space") then
      AddBee()
   end

   if love.keyboard.isDown("r") then
      Reset()
   end

   if love.mouse.isDown(1) then
      TrySelectBee()
   end

   if beebraintimer > 0 then
      beebraintimer = beebraintimer - dt
   else
      for i=1,#bees do
         DoOutputs(bees[i], dt)
         DoThinking(bees[i])
         DoInputs(bees[i])
      end
      steps = steps + 1
      beebraintimer = beebrainmaxtimer
   end

end

function love.wheelmoved(x, y)
    if y > 0 then
        beebrainmaxtimer = beebrainmaxtimer - 0.1
    elseif y < 0 then
        beebrainmaxtimer = beebrainmaxtimer + 0.1
    end

    if beebrainmaxtimer < 0 then beebrainmaxtimer = 0 end
end

function love.draw()
   love.graphics.setColor(245,190,0)
   for i=1,#bees do
      love.graphics.circle( "fill", bees[i].pos.x, bees[i].pos.y, 5 )
   end

   love.graphics.setColor(0, 255, 0)
   love.graphics.circle("fill", flower.pos.x,flower.pos.y, 15)

   love.graphics.setColor(255,255,255)
   love.graphics.print("Steps: " .. steps, fieldX/2, 15)
   love.graphics.print("Bees: " .. #bees, fieldX/2, 35)
   love.graphics.print("Thought Rate: " .. beebrainmaxtimer, fieldX/2, 50)


   if selectedbee then
      love.graphics.print("Selected Bee: " .. selectedbee.pos.x .. ", " .. selectedbee.pos.y, fieldX/5, 35)

      for i=1,#selectedbee.brain.cells do
         local c = selectedbee.brain.cells[i]
         love.graphics.circle("fill", braindiag.x+c.pos.x,braindiag.y+c.pos.y, 1+c.energy)

         for i=1,#c.connections do
            local con = c.connections[i]
            love.graphics.setColor(150,con.strength,0)

            love.graphics.setLineWidth(con.strength*0.01)

            love.graphics.line( braindiag.x+c.pos.x, braindiag.y+c.pos.y, braindiag.x+con.cell.pos.x, braindiag.y+con.cell.pos.y )

         end

      end

      for i=1,#selectedbee.brain.inputcells do
         local ic = selectedbee.brain.inputcells[i]
         love.graphics.setColor(0,255,0)
         love.graphics.circle("fill", braindiag.x+ic.pos.x,braindiag.y+ic.pos.y, 1+ic.energy)

         for i=1,#ic.connections do
            local con = ic.connections[i]
            love.graphics.setColor(0,con.strength,150)

            love.graphics.setLineWidth(con.strength*0.01)

            love.graphics.line( braindiag.x+ic.pos.x, braindiag.y+ic.pos.y, braindiag.x+con.cell.pos.x, braindiag.y+con.cell.pos.y )

         end

      end

      for i=1,#selectedbee.brain.outputcells do
         local oc = selectedbee.brain.outputcells[i]
         love.graphics.setColor(255,0,0)
         love.graphics.circle("fill", braindiag.x+oc.pos.x,braindiag.y+oc.pos.y, 1+oc.energy)
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

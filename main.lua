function love.load()
   math.randomseed(os.time())
   love.graphics.setNewFont("Octarine-Light.otf", 16)
   love.graphics.setBackgroundColor(35/255,35/255,35/255)

   love.window.setMode(1600, 900)
   fieldX, fieldY = love.window.getMode()

   flowers = {}

   isbrainoverlayed = false
   isbrainshown = true

   bees = {}
   beebraintimer = 0
   beebrainmaxtimer = 0

   beebraininputcellcost = 0.01
   beebraincellcost = 0.01
   beemovementcost = 0.00001

   braindiag = {x=250, y=300}
   origbraindiag = {x=braindiag.x, y=braindiag.y}

   highestgeneration = 0
   highestlifespan = 0

   scale=0.8
   origscale = scale

   energyscale = 1

   steps = 0
   logeveryXsteps = 100

   actiontable = {["sprintup"]={x=0,y=-3},["sprintdown"]={x=0,y=3},["sprintright"]={x=3,y=0},["sprintleft"]={x=-3,y=0},
                  ["moveup"]={x=0,y=-1},["movedown"]={x=0,y=1},["moveright"]={x=1,y=0},["moveleft"]={x=-1,y=0}
                  }

   selectedbee = nil
   selectedbrain = nil

   --environment
   flowers_startenergy = 1500

   --genetics


   --end of genetics

   Reset()

end

function Reset()
   local genestopass = {}
   if #bees == 1 then
      genestopass=DeepCopy(bees[1].genes)
   end
   bees = {}
   for i=1,10 do
      AddBee()
   end

   if genestopass.bee_cellcount then
      for i=1,#bees do
         if math.random() > 0.5 then
            bees[i].genes = genestopass
         end
      end
      bees[1].genes = genestopass
   end



   flowers={}
   NewFlowers(200)

   selectedbee = bees[1]
   steps = 0
end

function NewFlowers(num)
   for i=1,num do
      AddFlower({x=math.random(0,1600), y=math.random(0,900)})
   end
end

function AddFlower(position)
   table.insert(flowers, {pos=position, energy=flowers_startenergy})
end

function AddBee()
   local newbee = {genes={},brain={},body={},pos={x=fieldX*math.random(), y=fieldY*math.random()},stats={}}

   newbee.stats.lifespan = 0

   newbee.genes = {
      generation = 0,
      bee_cellcount = math.random(0,200),
      bee_initialcellpositions = {},
      bee_inputcellcount = math.random(0,25),
      bee_initialinputcellpositions = {},
      bee_outputcellcount = math.random(1,15),
      bee_initialoutputcells = {},

      bee_chancetomorphactions = 0.05,

      beeoutput_movepositionmod = math.random(0,400),
      beeoutput_sprintpositionmod = math.random(0,400),
      beeinput_positionmod = math.random(0,400),
      beeneuron_positionmod = math.random(0,400),

      neuron_connectUnlikelyhood = math.random(0,200000),

      neuron_connectRange = math.random(0,75),
      neuron_newNeuronRange = math.random(0,75),
      neuronconnection_degraderate = math.random() * 0.01,
      neuron_degraderate = math.random() * 0.01,

      neuron_inputConnectRange = math.random(0,50),
      neuron_newInputNeuronRange = math.random(0,50),
      neuronconnection_inputdegraderate = math.random() * 0.01,
      neuron_inputdegraderate = math.random() * 0.01,

      neuron_connectionSendMod = math.random(),

      neuron_initialStrength = math.random(0,300),
      neuron_inputInitialStrength = math.random(0,300),

      neuron_initialNeuronToNeuronConnectionStrength = math.random(0,100),
      neuron_initialNeuronToOutputConnectionStrength = math.random(0,100),
      neuron_initialInputToNeuronConnectionStrength = math.random(0,100),

      neuron_inputNeuronSensitivity = math.random(0,600),
      neuron_inputNeuronEnergyMod = math.random() * 0.01,

      neuron_inputNeuronCreationBalance = math.random(), --% chance a input neuron creates an input neuron instead of a normal neuron

      neuron_neuronThreshold = math.random(0,300),
      neuron_neuronCreateThreshold = math.random(0,300),
      neuron_neuronCreateNeuronStartRatio = math.random(),

      neuron_inputThreshold = math.random(0,300),
      neuron_inputCreateThreshold = math.random(0,300),
      neuron_inputCreateNeuronStartRatio = math.random(),

      neuron_outputThreshold = math.random(0,300),

      neuron_passiveNeuronCreationRate = math.random() * 0.01,
      neuron_passiveNeuronCreationStartEnergy = math.random(0,100),
      neuron_passiveInputNeuronCreationRate = math.random() * 0.01,
      neuron_passiveInputNeuronCreationStartEnergy = math.random(0,100),

      beeBody_eatRange = 25,
      beeBody_startFoodEnergy = 1500,
      beeBody_babyCost = 4000,
      beeBody_foodEnergyCostMod = .5,
      beeBody_biteSize = 50,
      beeBody_startHealth = 1000,
      beeBody_speed = 1,
   }

   if newbee.genes.neuron_passiveNeuronCreationRate < 0.005 then newbee.genes.neuron_passiveNeuronCreationRate = 0.005 end
   if newbee.genes.neuron_passiveInputNeuronCreationRate < 0.005 then newbee.genes.neuron_passiveInputNeuronCreationRate = 0.005 end

   newbee.body = {foodenergy=newbee.genes.beeBody_startFoodEnergy, health=newbee.genes.beeBody_startHealth}

   if #newbee.genes.bee_initialcellpositions <= 0 then
      MakeInitialBrain(newbee)
   end
   MakeBrain(newbee)

   table.insert(bees, newbee)
end

function GetRandomKey(table)
    local keys = {}
    for key, value in pairs(table) do
      keys[#keys+1] = key
    end
    index = keys[math.random(1, #keys)]
    return index
end

function MakeInitialBrain(bee)
   bee.genes.bee_initialoutputcells = {}

   for i=1,bee.genes.bee_outputcellcount do
      local a = GetRandomKey(actiontable)
      local amount = bee.genes.beeoutput_movepositionmod
      if string.find(a, "sprint") then
         local amount = bee.genes.beeoutput_sprintpositionmod
      end
      table.insert(bee.genes.bee_initialoutputcells,{action=a, pos={x=math.random(-amount,amount),y=math.random(-amount,amount)}})
   end

   bee.genes.bee_initialinputcellpositions = {}

   for i=1,bee.genes.bee_inputcellcount do
      local amount = bee.genes.beeinput_positionmod
      table.insert(bee.genes.bee_initialinputcellpositions, {x=math.random(-amount,amount),y=math.random(-amount,amount)} );
   end

   bee.genes.bee_initialcellpositions = {}

   for i=1,bee.genes.bee_cellcount do
      local amount = bee.genes.beeneuron_positionmod
      table.insert(bee.genes.bee_initialcellpositions, {x=math.random(-amount,amount),y=math.random(-amount,amount)} );
   end

end

function MakeBrain(bee)
   bee.brain.outputcells = {}
   for i=1,#bee.genes.bee_initialoutputcells do
      local a = GetRandomKey(actiontable)
      if math.random() > bee.genes.bee_chancetomorphactions then
         a = bee.genes.bee_initialoutputcells[i].action
      end
      table.insert(bee.brain.outputcells,{action=a, energy=0, pos={x=math.random(-10,10)+bee.genes.bee_initialoutputcells[i].pos.x,y=math.random(-10,10)+bee.genes.bee_initialoutputcells[i].pos.y}})
   end

   bee.brain.inputcells = {}

   for i=1,#bee.genes.bee_initialinputcellpositions do
      table.insert(bee.brain.inputcells, {sense="random", energy=0, pos={x=math.random(-10,10)+bee.genes.bee_initialinputcellpositions[i].x,y=math.random(-10,10)+bee.genes.bee_initialinputcellpositions[i].y}, connections={}, strength=bee.genes.neuron_inputInitialStrength} );
   end

   bee.brain.cells = {}

   for i=1,#bee.genes.bee_initialcellpositions do
      table.insert(bee.brain.cells, {connections={}, energy=0, pos={x=math.random(-10,10)+bee.genes.bee_initialcellpositions[i].x,y=math.random(-10,10)+bee.genes.bee_initialcellpositions[i].y}, strength=bee.genes.neuron_initialStrength});
   end

   for i=1,#bee.brain.outputcells do
      bee.genes.bee_initialoutputcells[i] = {pos=bee.brain.outputcells[i].pos, action=bee.brain.outputcells[i].action}
   end

   for i=1,#bee.brain.inputcells do
      bee.genes.bee_initialinputcellpositions[i] = bee.brain.inputcells[i].pos
   end

   for i=1,#bee.brain.cells do
      bee.genes.bee_initialcellpositions[i] = bee.brain.cells[i].pos
   end

end


function SpawnNeuron(bee, sourcepos, startenergy)
   if bee.body.foodenergy > 0 then
      table.insert(bee.brain.cells, {connections={}, energy=0, pos={x=sourcepos.x + math.random(-bee.genes.neuron_newNeuronRange, bee.genes.neuron_newNeuronRange),y=sourcepos.y + math.random(-bee.genes.neuron_newNeuronRange, bee.genes.neuron_newNeuronRange)}, strength=startenergy})
      local foodenergydelta = (startenergy*bee.genes.beeBody_foodEnergyCostMod)
      if foodenergydelta < 0 then foodenergydelta = 0 end
      bee.body.foodenergy = bee.body.foodenergy - foodenergydelta
   end
end

function SpawnInputNeuron(bee, sourcepos, startenergy)
   if bee.body.foodenergy > 0 then
      table.insert(bee.brain.inputcells, {sense="random", energy=startenergy, pos={x=sourcepos.x + math.random(-bee.genes.neuron_newInputNeuronRange, bee.genes.neuron_newInputNeuronRange),y=sourcepos.y + math.random(-bee.genes.neuron_newInputNeuronRange, bee.genes.neuron_newInputNeuronRange)}, connections={}, strength=startenergy})
      local foodenergydelta = (startenergy*bee.genes.beeBody_foodEnergyCostMod)
      if foodenergydelta < 0 then foodenergydelta = 0 end
      bee.body.foodenergy = bee.body.foodenergy - foodenergydelta
   end
end

function DoThinking(bee)
   for i=#bee.brain.cells,1,-1 do
      c = bee.brain.cells[i]

      --enforce strength of cell if it has energy in it
      c.strength = c.strength + c.energy

      --degrade connections over time & remove weak connections
      for i=#c.connections,1,-1 do
         local con = c.connections[i]

         con.strength = con.strength - bee.genes.neuronconnection_degraderate * 1-(bee.body.foodenergy/2500)

         if con.strength <= 0 then
            table.remove(c.connections, i)
         end
      end

      -- form new random connections
      for i=#bee.brain.cells,1,-1 do
         tc = bee.brain.cells[i]
         if c ~= tc then
            if math.random() < (c.energy*(bee.genes.neuron_connectRange-(Distance(tc.pos, c.pos)))/bee.genes.neuron_connectUnlikelyhood) then
               table.insert(c.connections, {strength=bee.genes.neuron_initialNeuronToNeuronConnectionStrength, cell=tc})
            end
         end
      end
      --[[for i=#bee.brain.inputcells,1,-1 do
         tc = bee.brain.inputcells[i]
         if math.random() < (c.energy*(neuron_connectRange-(Distance(tc.pos, c.pos)))/neuron_connectUnlikelyhood) then
            table.insert(c.connections, {strength=10, cell=tc})
         end
      end
      ]]
      for i=#bee.brain.outputcells,1,-1 do
         tc = bee.brain.outputcells[i]
         if math.random() < (c.energy*(bee.genes.neuron_connectRange-(Distance(tc.pos, c.pos)))/bee.genes.neuron_connectUnlikelyhood) then
            table.insert(c.connections, {strength=bee.genes.neuron_initialNeuronToOutputConnectionStrength, cell=tc})
         end
      end

      -- fire if passed energy threshold
      if c.energy >= 0 and #c.connections > 0 then
         local energyused = c.energy
         if energyused > bee.genes.neuron_neuronThreshold then energyused = bee.genes.neuron_neuronThreshold end
         c.energy = c.energy - energyused

         local dividedenergy = energyused/#c.connections
         for i=1,#c.connections do
            local con = c.connections[i]
            con.cell.energy = con.cell.energy + dividedenergy*bee.genes.neuron_connectionSendMod
            con.strength = con.strength + dividedenergy*bee.genes.neuron_connectionSendMod
         end
      end

      --form new neurons with extra energy
      if c.energy > bee.genes.neuron_neuronCreateThreshold then
         local startenergy = (bee.genes.neuron_neuronCreateNeuronStartRatio*c.energy)
         SpawnNeuron(bee, c.pos, startenergy)
         c.energy = c.energy - startenergy
      end

      --degrade cells over time & remove weak cells
      c.strength = c.strength - bee.genes.neuron_degraderate
      if c.strength <= 0 then
         table.remove(bee.brain.cells, i)
      end

   end
end

function DoInputs(bee)
   for i=#bee.brain.inputcells,1,-1 do
      local c = bee.brain.inputcells[i]

      --degrade connections over time & remove weak connections
      for i=#c.connections,1,-1 do
         local con = c.connections[i]

         con.strength = con.strength - bee.genes.neuronconnection_inputdegraderate * 1-(bee.body.foodenergy/2500)

         if con.strength <= 0 then
            table.remove(c.connections, i)
         end
      end

      --make new random connections
      for i=#bee.brain.cells,1,-1 do
         tc = bee.brain.cells[i]
         if math.random() < (c.energy*(bee.genes.neuron_inputConnectRange-(Distance(tc.pos, c.pos)))/bee.genes.neuron_connectUnlikelyhood) then
            table.insert(c.connections, {strength=bee.genes.neuron_initialInputToNeuronConnectionStrength, cell=tc})
         end
      end

      --send input energy over connections
      if c.energy > 0 and #c.connections > 0 then
         local energyused = c.energy
         if energyused > bee.genes.neuron_inputThreshold then energyused = bee.genes.neuron_inputThreshold end
         c.energy = c.energy - energyused



         local dividedenergy = energyused/#c.connections
         for i=1,#c.connections do
            local con = c.connections[i]
            con.cell.energy = con.cell.energy + dividedenergy
            con.strength = con.strength + dividedenergy
         end

      end

      --form new neurons with extra energy
      if c.energy > bee.genes.neuron_inputCreateThreshold then
         local startenergy = (bee.genes.neuron_inputCreateNeuronStartRatio*c.energy)
         if math.random() < bee.genes.neuron_inputNeuronCreationBalance then
            SpawnInputNeuron(bee, c.pos, startenergy)
         else
            SpawnNeuron(bee, c.pos, startenergy)
         end
         c.energy = c.energy - startenergy
      end

      --make input energies based on distance to flower
      for i=#flowers,1,-1 do
         local addenergy = bee.genes.neuron_inputNeuronSensitivity-Distance({x=bee.pos.x + c.pos.x, y=bee.pos.y + c.pos.y}, flowers[i].pos);
         if addenergy < 0 then addenergy = 0 end
         c.energy = c.energy + (addenergy * bee.genes.neuron_inputNeuronEnergyMod)
      end

      --degrade inputcells over time & remove weak cells
      c.strength = c.strength - bee.genes.neuron_inputdegraderate
      if c.energy < 0 then c.strength=c.strength - bee.genes.neuron_inputdegraderate*4 end
      if c.strength <= 0 then
         table.remove(bee.brain.inputcells, i)
      end
   end
end

function DoOutputs(bee)
   for i=1,#bee.brain.outputcells do
      local c = bee.brain.outputcells[i]
      if c.energy > 0 then
         local energyused = c.energy

         if energyused > bee.genes.neuron_outputThreshold then energyused = bee.genes.neuron_outputThreshold end

         bee.pos.x = bee.pos.x+actiontable[c.action].x*bee.genes.beeBody_speed*energyused
         bee.pos.y = bee.pos.y+actiontable[c.action].y*bee.genes.beeBody_speed*energyused
         c.energy = c.energy - energyused

         local foodenergydelta = (bee.genes.beeBody_speed*energyused*beemovementcost)
         if foodenergydelta < 0 then foodenergydelta = 0 end
         bee.body.foodenergy = bee.body.foodenergy - foodenergydelta

         if bee.pos.x > fieldX then bee.pos.x = fieldX end
         if bee.pos.x < 0 then bee.pos.x = 0 end
         if bee.pos.y > fieldY then bee.pos.y = fieldY end
         if bee.pos.y < 0 then bee.pos.y = 0 end
      end
   end
end

function DoBeeBody(bee, i)
   bee.stats.lifespan = bee.stats.lifespan + 1
   if bee.body.foodenergy <= 0 then
      bee.body.health = bee.body.health - 1
      bee.body.foodenergy = 0
   end
   if bee.body.foodenergy > 0 and bee.body.health < bee.genes.beeBody_startHealth then
      bee.body.health = bee.body.health + 1
   end

   bee.body.foodenergy = bee.body.foodenergy - (#bee.brain.inputcells * beebraininputcellcost)
   bee.body.foodenergy = bee.body.foodenergy - (#bee.brain.cells * beebraincellcost)

   if bee.body.health <= 0 then
      if #bees == 1 then
         Reset()
         return
      end
      table.remove(bees, i)
   else
      if math.random() < bee.genes.neuron_passiveNeuronCreationRate then
         local startenergy = bee.genes.neuron_passiveNeuronCreationStartEnergy
         local sourcepos = {x=math.random(-100,100)*bee.genes.beeneuron_positionmod, y=math.random(-100,100)*bee.genes.beeneuron_positionmod}
         if #bee.brain.cells > 0 then
            sourcepos = bee.brain.cells[math.random(1, #bee.brain.cells)].pos
         end
         SpawnNeuron(bee, sourcepos, startenergy)
      end

      if math.random() < bee.genes.neuron_passiveInputNeuronCreationRate then
         local startenergy = bee.genes.neuron_passiveInputNeuronCreationStartEnergy
         local sourcepos = {x=math.random(-100,100)*bee.genes.beeinput_positionmod, y=math.random(-100,100)*bee.genes.beeinput_positionmod}
         if #bee.brain.inputcells > 0 then
            sourcepos = bee.brain.inputcells[math.random(1, #bee.brain.inputcells)].pos
         end
         SpawnInputNeuron(bee, sourcepos, startenergy)
      end

      --[[
      if bee.body.foodenergy > bee.genes.beeBody_babyCost then
         MakeBabyOf(bee)
         bee.body.foodenergy = bee.body.foodenergy - bee.genes.beeBody_babyCost
      end
      ]]
   end
end

function MakeBabyOf(bee)
   local newbee = {genes=DeepCopy(bee.genes),brain={},body={},pos={x=bee.pos.x, y=bee.pos.y},stats={}}

   newbee.stats.lifespan = 0


   newbee.genes.generation = bee.genes.generation + 1
   newbee.genes.bee_cellcount = bee.genes.bee_cellcount + math.random(-25,25)
   newbee.genes.bee_inputcellcount = bee.genes.bee_inputcellcount + math.random(-25,25)
   newbee.genes.bee_outputcellcount = bee.genes.bee_outputcellcount + math.random(-1,1)

   newbee.genes.bee_initialcellpositions = bee.genes.bee_initialcellpositions
   newbee.genes.bee_initialoutputcells = bee.genes.bee_initialoutputcells
   newbee.genes.bee_initialinputcellpositions = bee.genes.bee_initialinputcellpositions

   newbee.genes.bee_chancetomorphactions = bee.genes.bee_chancetomorphactions + math.random(-3,3)*0.001

   newbee.genes.beeoutput_movepositionmod = bee.genes.beeoutput_movepositionmod + math.random(-25,25)
   newbee.genes.beeoutput_sprintpositionmod = bee.genes.beeoutput_sprintpositionmod + math.random(-25,25)
   newbee.genes.beeinput_positionmod = bee.genes.beeinput_positionmod + math.random(-25,25)
   newbee.genes.beeneuron_positionmod = bee.genes.beeneuron_positionmod + math.random(-25,25)

   newbee.genes.neuron_connectUnlikelyhood = bee.genes.neuron_connectUnlikelyhood + math.random(-1000,1000)

   newbee.genes.neuron_connectRange = bee.genes.neuron_connectRange + math.random(-10,10)
   newbee.genes.neuron_newNeuronRange = bee.genes.neuron_newNeuronRange + math.random(-10,10)
   newbee.genes.neuronconnection_degraderate = bee.genes.neuronconnection_degraderate + math.random(-3,3)*.01
   newbee.genes.neuron_degraderate = bee.genes.neuron_degraderate + math.random(-3,3)*.01

   newbee.genes.neuron_inputConnectRange = bee.genes.neuron_inputConnectRange + math.random(-10,10)
   newbee.genes.neuron_newInputNeuronRange = bee.genes.neuron_newInputNeuronRange + math.random(-10,10)
   newbee.genes.neuronconnection_inputdegraderate = bee.genes.neuronconnection_inputdegraderate + math.random(-3,3)*.01
   newbee.genes.neuron_inputdegraderate = bee.genes.neuron_inputdegraderate + math.random(-3,3)*.01

   newbee.genes.neuron_connectionSendMod = bee.genes.neuron_connectionSendMod + math.random(-3,3)*.01

   newbee.genes.neuron_initialStrength = bee.genes.neuron_initialStrength + math.random(-10,10)
   newbee.genes.neuron_inputInitialStrength = bee.genes.neuron_inputInitialStrength + math.random(-10,10)

   newbee.genes.neuron_initialNeuronToNeuronConnectionStrength = bee.genes.neuron_initialNeuronToNeuronConnectionStrength + math.random(-5,5)
   newbee.genes.neuron_initialNeuronToOutputConnectionStrength = bee.genes.neuron_initialNeuronToOutputConnectionStrength + math.random(-5,5)
   newbee.genes.neuron_initialInputToNeuronConnectionStrength = bee.genes.neuron_initialInputToNeuronConnectionStrength + math.random(-5,5)

   newbee.genes.neuron_inputNeuronSensitivity = bee.genes.neuron_inputNeuronSensitivity + math.random(-20,20)
   newbee.genes.neuron_inputNeuronEnergyMod = bee.genes.neuron_inputNeuronEnergyMod + math.random(-3,3)*.01

   newbee.genes.neuron_inputNeuronCreationBalance = bee.genes.neuron_inputNeuronCreationBalance + math.random(-3,3)*.01 --% chance a input neuron creates an input neuron instead of a normal neuron

   newbee.genes.neuron_neuronThreshold = bee.genes.neuron_neuronThreshold + math.random(-5,5)
   newbee.genes.neuron_neuronCreateThreshold = bee.genes.neuron_neuronCreateThreshold + math.random(-5,5)
   newbee.genes.neuron_neuronCreateNeuronStartRatio = bee.genes.neuron_neuronCreateNeuronStartRatio + math.random(-3,3)*.01

   newbee.genes.neuron_inputThreshold = bee.genes.neuron_inputThreshold + math.random(-5,5)
   newbee.genes.neuron_inputCreateThreshold = bee.genes.neuron_inputCreateThreshold + math.random(-5,5)
   newbee.genes.neuron_inputCreateNeuronStartRatio = bee.genes.neuron_inputCreateNeuronStartRatio + math.random(-3,3)*.01

   newbee.genes.neuron_outputThreshold = bee.genes.neuron_outputThreshold + math.random(-10,10)

   newbee.genes.neuron_passiveNeuronCreationRate = bee.genes.neuron_passiveNeuronCreationRate + math.random(-3,3)*.005
   newbee.genes.neuron_passiveNeuronCreationStartEnergy = bee.genes.neuron_passiveNeuronCreationStartEnergy + math.random(-5,5)
   newbee.genes.neuron_passiveInputNeuronCreationRate = bee.genes.neuron_passiveInputNeuronCreationRate + math.random(-3,3)*.005
   newbee.genes.neuron_passiveInputNeuronCreationStartEnergy = bee.genes.neuron_passiveInputNeuronCreationStartEnergy + math.random(-5,5)

   if newbee.genes.neuron_passiveNeuronCreationRate < 0.005 then newbee.genes.neuron_passiveNeuronCreationRate = 0.005 end
   if newbee.genes.neuron_passiveInputNeuronCreationRate < 0.005 then newbee.genes.neuron_passiveInputNeuronCreationRate = 0.005 end

   newbee.genes.beeBody_eatRange = bee.genes.beeBody_eatRange
   newbee.genes.beeBody_startFoodEnergy = bee.genes.beeBody_startFoodEnergy
   newbee.genes.beeBody_babyCost = bee.genes.beeBody_babyCost
   newbee.genes.beeBody_foodEnergyCostMod = bee.genes.beeBody_foodEnergyCostMod
   newbee.genes.beeBody_biteSize = bee.genes.beeBody_biteSize
   newbee.genes.beeBody_startHealth = bee.genes.beeBody_startHealth
   newbee.genes.beeBody_speed = 1

   MakeBrain(newbee)

   newbee.body = {foodenergy=newbee.genes.beeBody_startFoodEnergy, health=newbee.genes.beeBody_startHealth}

   table.insert(bees, newbee)
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

function DeepCopy( Table, Cache ) -- Makes a deep copy of a table.
    if type( Table ) ~= 'table' then
        return Table
    end

    Cache = Cache or {}
    if Cache[Table] then
        return Cache[Table]
    end

    local New = {}
    Cache[Table] = New
    for Key, Value in pairs( Table ) do
        New[DeepCopy( Key, Cache)] = DeepCopy( Value, Cache )
    end

    return New
end

function love.keypressed( key )
   if key == "r" then
      Reset()
   end

   if key == "escape" then
      love.event.quit(0)
   end

   if key == "x" then
      if isbrainoverlayed then
         isbrainoverlayed = false
         braindiag = {x=origbraindiag.x, y=origbraindiag.y}
         scale=origscale
      else
         isbrainoverlayed = true
         origbraindiag = {x=braindiag.x, y=braindiag.y}
         scale=1
      end
   end

   if key == "b" then
      if isbrainshown then isbrainshown = false else isbrainshown = true end
   end

   if key == "p" then
      if isPaused then isPaused = false else isPaused = true end
   end

end

function love.update(dt)
   if love.keyboard.isDown("space") then
      AddBee()
   end


   if isbrainoverlayed and selectedbee then
      braindiag.x = selectedbee.pos.x
      braindiag.y = selectedbee.pos.y
   end



   if love.mouse.isDown(1) then
      TrySelectBee()
   end

   if love.mouse.isDown(2) then
      local mposx, mposy = love.mouse.getPosition()
      AddFlower({x=mposx, y=mposy})
   end

   if isPaused then return end

   if beebraintimer > 0 then
      beebraintimer = beebraintimer - dt
   else
      for i=#bees,1,-1 do
         DoOutputs(bees[i], dt)
         DoThinking(bees[i])
         DoInputs(bees[i])

         DoBeeBody(bees[i], i)

      end

      for i=#bees,1,-1 do
         for fi=#flowers,1,-1 do
            if Distance(flowers[fi].pos, bees[i].pos) < bees[i].genes.beeBody_eatRange then
               flowers[fi].energy = flowers[fi].energy - bees[i].genes.beeBody_biteSize
               bees[i].body.foodenergy = bees[i].body.foodenergy + bees[i].genes.beeBody_biteSize
               if flowers[fi].energy <= 0 then
                  table.remove(flowers, fi)
                  if #flowers <= 0 then
                     NewFlowers(10)
                  end
               end
            end
         end
      end

      steps = steps + 1
      logeveryXsteps = logeveryXsteps - 1
      if logeveryXsteps <= 0 then
         logeveryXsteps = 100
         LogStatus()
      end
      beebraintimer = beebrainmaxtimer
   end

end

function LogStatus()
   love.filesystem.append("log.txt", "Bees: " .. #bees .. " -- Flowers: " .. #flowers .. "\n")
end

function love.wheelmoved(x, y)
    if y > 0 then
        beebrainmaxtimer = beebrainmaxtimer - 0.05
    elseif y < 0 then
        beebrainmaxtimer = beebrainmaxtimer + 0.05
    end

    if beebrainmaxtimer < 0 then beebrainmaxtimer = 0 end
end

function love.draw()
   for i=1,#flowers do
      local g = (flowers[i].energy/1000)*255
      if g > 255 then g = 255 end
      love.graphics.setColor(0, g, 255)
      local fsize = flowers[i].energy*0.1
      if fsize > 20 then fsize = 20 end
      love.graphics.circle("fill", flowers[i].pos.x,flowers[i].pos.y, fsize)
   end

   for i=1,#bees do
      love.graphics.setColor(245, (bees[i].body.health/1000)*190,0)
      love.graphics.circle( "fill", bees[i].pos.x, bees[i].pos.y, 4 )
      if bees[i].genes.generation > highestgeneration then highestgeneration = bees[i].genes.generation end
      if bees[i].stats.lifespan > highestlifespan then highestlifespan = bees[i].stats.lifespan end
   end


   love.graphics.setColor(255,255,255)
   love.graphics.print("Steps: " .. steps, fieldX/2, 15)
   love.graphics.print("Bees: " .. #bees, fieldX/2, 35)
   love.graphics.print("Thought Delay: " .. beebrainmaxtimer, fieldX/2, 50)
   love.graphics.print("Highest Generation: " .. highestgeneration, fieldX/2, 65)
   love.graphics.print("Highest Lifespan: " .. highestlifespan, fieldX/2, 80)


   if selectedbee then
      love.graphics.print("Selected Bee: " .. RoundToDecimal(selectedbee.pos.x) .. ", " .. RoundToDecimal(selectedbee.pos.y), fieldX/5, 35)
      love.graphics.print("   Health: " .. RoundToDecimal(selectedbee.body.health), fieldX/2+250, 50)
      love.graphics.print("   FoodEnergy: " .. RoundToDecimal(selectedbee.body.foodenergy), fieldX/2+250, 65)
      love.graphics.print("   Life Span: " .. selectedbee.stats.lifespan, fieldX/2+250, 80)

      if isbrainshown then
         for i=1,#selectedbee.brain.inputcells do
            local ic = selectedbee.brain.inputcells[i]
            love.graphics.setColor(0,255,0)
            local size = 1+ic.energy*energyscale
            if size > 20 then
               size = math.random(10,20)
               love.graphics.setColor(0,math.random(0.6,1),0)
            end
            love.graphics.circle("fill", braindiag.x+ic.pos.x*scale,braindiag.y+ic.pos.y*scale, size)

            for i=1,#ic.connections do
               local con = ic.connections[i]
               love.graphics.setColor(150,0,(con.strength/5000)*255)

               local width = (con.strength/5000)*5
               if width < 0.1 then width = 0.1 end
               if width > 15 then width = 15 end
               love.graphics.setLineWidth(width*energyscale)

               love.graphics.line( braindiag.x+ic.pos.x*scale, braindiag.y+ic.pos.y*scale, braindiag.x+con.cell.pos.x*scale, braindiag.y+con.cell.pos.y *scale)

            end

         end


         for i=1,#selectedbee.brain.outputcells do
            local oc = selectedbee.brain.outputcells[i]
            love.graphics.setColor(255,0,0)
            local size = 5+oc.energy*energyscale
            if size > 30 then
               size = math.random(20,30)
               love.graphics.setColor(math.random(0.6,1),0,0)
            end
            love.graphics.circle("fill", braindiag.x+oc.pos.x*scale,braindiag.y+oc.pos.y*scale, size)
         end

         for i=1,#selectedbee.brain.cells do
            local c = selectedbee.brain.cells[i]
            love.graphics.setColor(255,255,255)
            local size = .5+c.energy*energyscale
            if size > 10 then
               size = math.random(5,10)
               love.graphics.setColor(255,0,50)
            end
            love.graphics.circle("fill", braindiag.x+c.pos.x*scale,braindiag.y+c.pos.y*scale, size)

            for i=1,#c.connections do
               local con = c.connections[i]
               love.graphics.setColor(150,(con.strength/5000)*255,0)
               local width = (con.strength/5000)*5
               if width < 0.1 then width = 0.1 end
               if width > 15 then width = 15 end
               love.graphics.setLineWidth(width*energyscale)

               love.graphics.line( braindiag.x+c.pos.x*scale, braindiag.y+c.pos.y*scale, braindiag.x+con.cell.pos.x*scale, braindiag.y+con.cell.pos.y*scale )

            end
         end
      end

   else
      love.graphics.print("Selected Bee: None", fieldX/5, 35)
   end
end

function love.quit()
   print("Bee seeing you!")
end

function RoundToDecimal(num, decimalplaces)
   if not decimalplaces then decimalplaces = 2 end
   local shift = math.pow(10,decimalplaces)
   return math.floor( num*shift + 0.5 ) / shift
end

--[[
   bee
      {genes={}, brain={}, body={}, pos={x=x location, y=y location}, stats={},}

   stats
      lifespan

   genes
      generation=1

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
      strength=0

   cells
      connections={}
      pos={x,y}
      energy=0
      strength=0

   connections
      strength=0
      cell=cell


   body
      foodenergy=0
      health=1000

   flower
      pos={x=0,y=0}
      energy=1000

]]

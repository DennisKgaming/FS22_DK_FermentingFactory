---
-- AnimatedObjectExtend
--
-- 
--
-- Copyright (c) DerElky, 2021
local modDirectory = g_currentModDirectory
source(modDirectory .. "script/AnimatedObjectExtendEvent.lua")

function load(self, superFunc, nodeId, xmlFile, key, xmlFilename,i3dMappings)
	local success = superFunc(self, nodeId, xmlFile, key, xmlFilename,i3dMappings)
	local autoopen = xmlFile:getValue(key .. ".controls#autoopen",true)
    self:setAutoOpen(self,autoopen)
	return success
end

function updateSegmentShapes(self,segment)
	local spec = self.spec_fence
	if segment.gateIndex ~= nil then
		local autoopen = spec.gates[segment.gateIndex].autoopen
		local animatedObject = segment.animatedObject
		if animatedObject ~= nil then -- and animatedObject.lockdoor == nil then
			animatedObject:setAutoOpen(animatedObject,autoopen)
		end
	end	
end

function onGateI3DLoaded(self, i3dNode, failedReason, args)
	local gate, gateXmlFile, loadingTask = unpack(args)
		if gate.animatedObject ~= nil then
			gate.animatedObject:setAutoOpen(gate.animatedObject,false)
		end

end

function AnimatedObject:setAutoOpen(self,autoopen)
	self.autoopen= autoopen
	self.objectcount = 0
	-- self.lockdoor = lockstate
	-- self.Lockdoorenable = g_i18n:getText("Lockdoorenable")
	-- self.Lockdoordisable = g_i18n:getText("Lockdoordisable")
	if self.triggerNode ~= nil then
		setCollisionMask(self.triggerNode, 1056768)
	end
end

function onLoad(self, superFunc, savegame)
	local success = superFunc(self, savegame)
	local spec = self.spec_fence
	local xmlFile = self.xmlFile
	xmlFile:iterate("placeable.fence.gate", function (_, key)
		for _, gates in ipairs(spec.gates) do
			gates.autoopen = xmlFile:getValue(key .. "#autoopen", true)
		end
	end)
	return success
end

function AnimatedObject:autoOpen(objectcount,lockdoor,noEventSend)
	if self.isServer then
		self.objectcount = objectcount
		self.lockdoor = lockdoor
		if not lockdoor then
			if (self.objectcount > 0 ) then
				if self.animation.time ~= 1 then
					self.animation.direction = 1
				end
			else
				if self.animation.time ~= 0 then
					self.animation.direction = -1
				end
			end
		end
        self:raiseActive()
	end	
	if noEventSend then 
	elseif g_server ~= nil then
		g_server:broadcastEvent(AnimatedObjectExtendEvent.new(self,self.objectcount, self.lockdoor), nil, nil, self)
	else
		g_client:getServerConnection():sendEvent(AnimatedObjectExtendEvent.new(self, self.objectcount, self.lockdoor))
	end

end

-- function AnimatedObject:addRemoveInputsAutoopen()
		-- if self.eventId == nil then
			-- local _, eventId = g_inputBinding:registerActionEvent(InputAction.LOCK_DOOR, self, self.onActivateObjectautopen, false, true, false, true);
			-- self.eventId = eventId;
			-- self:changetext();
		-- else
			-- g_inputBinding:removeActionEvent(self.eventId);
			-- self.eventId = nil;
		-- end;
-- end;

-- function AnimatedObject:onActivateObjectautopen()
	-- if self.autoopen then 	
		-- if self.lockdoor then
			-- self.lockdoor = false
		-- else
			-- self.lockdoor = true
			-- self.objectcount = 0
		-- end
		-- if g_server == nil then
			-- g_client:getServerConnection():sendEvent(AnimatedObjectExtendEvent.new(self, self.objectcount, self.lockdoor))
		-- else
			-- self:raiseActive()
		-- end
	-- self:changetext()
	-- end
	-- self:raiseActive()	
-- end;

-- function AnimatedObject:changetext()
	-- local Lockdoorstate = self.Lockdoordisable
	-- if self.eventId == nil then
	-- else
		-- if self.lockdoor then
			-- Lockdoorstate = self.Lockdoordisable
		-- else
			-- Lockdoorstate = self.Lockdoorenable
		-- end
		-- g_inputBinding:setActionEventText(self.eventId, Lockdoorstate)
	-- end	
-- end;

-- function saveToXMLFile(self, xmlFile, key, usedModNames)
	-- xmlFile:setValue(key .. "#lockstate", self.lockdoor)
-- end;

-- function loadFromXMLFile(self, superFunc, xmlFile, key)
	-- local lockdoor = xmlFile:getValue(key .. "#lockstate")
    -- if lockdoor ~= nil then
		-- self.lockdoor = lockdoor
	-- else
		-- self.lockdoor = false
	-- end
	 -- superFunc(self, xmlFile, key)
	 -- return true
-- end;

function triggerCallback(self, superfunc, triggerId, otherId, onEnter, onLeave, onStay, anotherID)   

    if g_currentMission.missionInfo:isa(FSCareerMissionInfo) then
		local vehicle = g_currentMission.nodeToObject[otherId]
		local pvehicle = false
		local vehiclecanaccess = false
		if vehicle ~= nil then
			
			if vehicle.type ~= nil then
				pvehicle = true
				if vehicle.getActiveFarm ~= nil then
					vehiclecanaccess = g_currentMission.accessHandler:canFarmAccessOtherId(vehicle:getActiveFarm(), self.ownerFarmId)
				else
					vehiclecanaccess = false
				end
			end
		end
		local oldobjectcount = self.objectcount
		local useauto = false
		if self.autoopen then
			if self.openingHours ~=nil then
				if self.openingHours.isOpen then
					useauto = true
				else
					useauto = false
				end
			else
				useauto = true
			end
		end
		if onEnter or onLeave then
				if g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
					if onEnter then
						if self.ownerFarmId == nil or self.ownerFarmId == AccessHandler.EVERYONE or g_currentMission.accessHandler:canFarmAccessOtherId(g_currentMission:getFarmId(), self.ownerFarmId) then
							g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
						end
					else 	
						g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
					end				
					self:raiseActive()	
				else
					if pvehicle and not self.lockdoor then
					
						if self.ownerFarmId == nil or self.ownerFarmId == AccessHandler.EVERYONE or vehiclecanaccess then
							if onEnter then
								if useauto then
									self.objectcount = self.objectcount + 1
								end
							else 
								if useauto then
									self.objectcount = math.max(self.objectcount - 1, 0) 
								end
							end			
						end
					end
				end
			
		
			if useauto and oldobjectcount ~= self.objectcount and not self.lockdoor then
				self:autoOpen(self.objectcount,self.lockdoor)							
			end
		end
	end
end

function readStream(self, streamId, connection)
     if connection:getIsServer() then
		self.objectcount = streamReadUInt8(streamId)
		-- self.lockdoor = streamReadBool(streamId)
    end
end

function writeStream(self, streamId, connection)
    if not connection:getIsServer() then
		streamWriteUInt8(streamId, self.objectcount)
		-- streamWriteBool(streamId, self.lockdoor)
    end
end

function registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#lockstate", "Animated object lock")
end

function registerXMLPathsani(schema, basePath)
	schema:setXMLSharedRegistration("AnimatedObject", basePath)
	basePath = basePath .. ".animatedObject(?)"
    schema:register(XMLValueType.BOOL, basePath .. ".controls#autoopen", "Auto open marker")
	schema:setXMLSharedRegistration()
end

function registerXMLPathsfen(schema, basePath)
	schema:setXMLSpecializationType("Fence")
    schema:register(XMLValueType.BOOL, basePath .. ".fence.gate(?)#autoopen", "Auto open marker")
	schema:setXMLSharedRegistration()
end


AnimatedObject.load = Utils.overwrittenFunction(AnimatedObject.load, load)
AnimatedObject.readStream = Utils.appendedFunction(AnimatedObject.readStream, readStream)
AnimatedObject.registerSavegameXMLPaths = Utils.appendedFunction(AnimatedObject.registerSavegameXMLPaths, registerSavegameXMLPaths)
AnimatedObject.registerXMLPaths = Utils.appendedFunction(AnimatedObject.registerXMLPaths, registerXMLPathsani)
PlaceableFence.registerXMLPaths = Utils.appendedFunction(PlaceableFence.registerXMLPaths, registerXMLPathsfen)
AnimatedObject.writeStream = Utils.appendedFunction(AnimatedObject.writeStream, writeStream)
PlaceableFence.updateSegmentShapes = Utils.appendedFunction(PlaceableFence.updateSegmentShapes, updateSegmentShapes)
PlaceableHusbandryFence.onGateI3DLoaded = Utils.appendedFunction(PlaceableHusbandryFence.onGateI3DLoaded, onGateI3DLoaded)
PlaceableFence.onLoad = Utils.overwrittenFunction(PlaceableFence.onLoad, onLoad)
AnimatedObject.triggerCallback = Utils.overwrittenFunction(AnimatedObject.triggerCallback, triggerCallback)
-- AnimatedObject.saveToXMLFile = Utils.appendedFunction(AnimatedObject.saveToXMLFile, saveToXMLFile)
-- AnimatedObject.loadFromXMLFile = Utils.overwrittenFunction(AnimatedObject.loadFromXMLFile, loadFromXMLFile)

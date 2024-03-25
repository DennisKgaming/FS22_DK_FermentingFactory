






AnimatedObjectExtendEvent = {}
local AnimatedObjectExtendEvent_mt = Class(AnimatedObjectExtendEvent, Event)

InitEventClass(AnimatedObjectExtendEvent, "AnimatedObjectExtendEvent", EventIds.EVENT_ANIMATED_OBJECT)

function AnimatedObjectExtendEvent.emptyNew()
	local self = Event.new(AnimatedObjectExtendEvent_mt)

	return self
end

function AnimatedObjectExtendEvent.new(animatedObject, objectcount, lockdoor)
	local self = AnimatedObjectExtendEvent.emptyNew()
    self.animatedObject = animatedObject
	self.objectcount = objectcount
	-- self.lockdoor = lockdoor
    return self
end

function AnimatedObjectExtendEvent:readStream(streamId, connection)


	self.animatedObject = NetworkUtil.readNodeObject(streamId)
	self.objectcount = streamReadUInt8(streamId)
	-- self.lockdoor = streamReadBool(streamId)
    self:run(connection)
end

function AnimatedObjectExtendEvent:writeStream(streamId, connection)
		NetworkUtil.writeNodeObject(streamId, self.animatedObject)
		streamWriteUInt8(streamId, self.objectcount)
		-- streamWriteBool(streamId, self.lockdoor)
end

function AnimatedObjectExtendEvent:run(connection)
	self.animatedObject:autoOpen(self.objectcount,false,true)
	if not connection:getIsServer() then
		g_server:broadcastEvent(AnimatedObjectExtendEvent.new(self.animatedObject, self.objectcount, false), nil, connection, self.animatedObject)
	end
end



function new(fence, object, segmentIndex, animatedObject)
	local self = PlaceableFenceAddGateEvent.emptyNew()
	animatedObject:setAutoOpen(animatedObject,false,autoopen)
	self.fence = fence
	self.segmentIndex = segmentIndex
	self.animatedObject = animatedObject

	return self
end

PlaceableFenceAddGateEvent.new = Utils.overwrittenFunction(PlaceableFenceAddGateEvent.new, new)
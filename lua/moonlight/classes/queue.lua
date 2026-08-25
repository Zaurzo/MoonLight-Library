local class = moonlight.importcs('class')

---@class Queue
local Queue = class('Queue')

function Queue:init()
    self._tail = 1
    self._head = 1
end

function Queue:Enqueue(item)
    local tail = self._tail

    self[tail] = item
    self._tail = tail + 1
end

function Queue:Dequeue()
    local head = self._head
    local tail = self._tail

    if head == tail then
        return error('attempt to dequeue from an empty queue')
    end

    local item = self[head]
    self[head] = nil

    head = head + 1
    self._head = head

    if tail == head then
        self._tail = 1
        self._head = 1
    end

    return item
end

function Queue:Peek()
    return self[self._head]
end

function Queue:Size()
    return self._tail - self._head
end

local inext = ipairs({})

function Queue:Pairs()
    return inext, self, self._head - 1
end

return Queue
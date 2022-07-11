# @version 0.3.3

# ToDo list per user
# Write/Read per sender
# Check if ToDo is complete

# 1. DECLARING INTERFACES

struct Task: 
    status: uint8
    description: String[128]
    owner: address
    taskId: uint256

# 2. DECLARING EVENTS

# 3. DECLARING STORAGE VARIABLES

OPEN: constant(uint8) = 0
IN_PROGRESS: constant(uint8) = 1
COMPLETE: constant(uint8) = 2
STATUSES: constant(uint8[3]) = [OPEN, IN_PROGRESS, COMPLETE]

statusName: public(HashMap[uint8, String[11]])
statusCode: public(HashMap[String[11], uint8])

totalTasks: public(uint256)
idToTask: public(HashMap[uint256, Task])
totalUserTasks: public(HashMap[address, uint256])
userTaskAt: public(HashMap[address, HashMap[uint256, uint256]])

# 4. DECLARING CALLS AND FUNCTIONS

@external
@nonpayable
def __init__():
    self.statusName[OPEN] = 'OPEN'
    self.statusName[IN_PROGRESS] = 'IN_PROGRESS'
    self.statusName[COMPLETE] = 'COMPLETE'
    
    self.statusCode['OPEN'] = OPEN
    self.statusCode['IN_PROGRESS'] = IN_PROGRESS
    self.statusCode['COMPLETE'] = COMPLETE


@external
@nonpayable
def createTask(_status: uint8, _description: String[128]):
    assert _status in STATUSES, "INVALID STATUS"
    assert len(_description) > 0, "DESCRIPTION CAN NOT BE EMPTY"

    self.totalTasks += 1
    taskId: uint256 = self.totalTasks

    task: Task = Task({
        status: _status,
        description: _description,
        owner: msg.sender,
        taskId: taskId
    })

    self.idToTask[taskId] = task

    taskCount: uint256 = self.totalUserTasks[msg.sender]
    self.userTaskAt[msg.sender][taskCount] = taskId

    self.totalUserTasks[msg.sender] += 1


@internal
@view
def _getTask(_taskId: uint256, _owner: address) -> Task:
    assert _taskId <= self.totalTasks, "INVALID TASK ID"

    task: Task = self.idToTask[_taskId]
    assert task.owner == _owner, "MIND YOUR BUSINESS"

    return task


@external
@nonpayable
def updateStatus(_status: uint8, _taskId: uint256):
    assert _status in STATUSES, "INVALID STATUS"

    task: Task = self._getTask(_taskId, msg.sender)

    task.status = _status
    self.idToTask[_taskId] = task


@external
@nonpayable
def updateDescription(_description: String[128], _taskId: uint256):
    assert _description != empty(String[128]), "DESCRIPTION CAN NOT BE EMPTY"

    task: Task = self._getTask(_taskId, msg.sender)

    task.description = _description
    self.idToTask[_taskId] = task


@external
@nonpayable
def updateTask(_status: uint8, _description: String[128], _taskId: uint256):
    assert _status in STATUSES, "INVALID STATUS"
    assert _description != empty(String[128]), "DESCRIPTION CAN NOT BE EMPTY"

    task: Task = self._getTask(_taskId, msg.sender)

    task.status = _status
    task.description = _description
    self.idToTask[_taskId] = task
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/// @title Task list contract
/// @author Dampilov D.
contract TODO {
    uint256 taskId;

    mapping(uint256 => address) taskToOwner;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => bool) public notInDeadline;

    /// @notice Completed - task status
    /// @notice InDeadline - label of tasks that were done on time
    /// @notice TimeLeft - timer, time left
    struct Task {
        uint256 taskId;
        string name;
        bool completed;
        uint256 timeLeft;
    }

    event NewTask(uint256 indexed taskId, string indexed name, uint256 timeLeft, address indexed taskOwner);
    event TaskCompletion(uint256 indexed taskId, string name, bool notInDeadline, uint256 indexed completionTime, address indexed taskOwner);
    event TaskRemoval(uint256 indexed taskId, string name, bool completed, bool indexed notInDeadline, address indexed taskOwner);

    modifier onlyOwner(uint256 _taskId) {
        require(msg.sender == taskToOwner[_taskId], "Not task owner");
        _;
    }

    /// @dev Checking if the requested task exists
    modifier checkEmptyTask(uint256 _taskId) {
        require(tasks[_taskId].timeLeft > 0, "No such task");
        _;
    }

    /// @dev Function creates a new task, and enters it into mapping tasks
    /// @param _days, _hours The time given to complete the created task
    function createTask(
        string memory _name,
        uint256 _days,
        uint256 _hours
    ) external {
        require(bytes(_name).length > 0, "Empty name");
        require(_days + _hours > 0, "Empty time");
        tasks[taskId] = Task(taskId, _name, false, block.timestamp + (_days * 1 days) + (_hours * 1 hours));
        taskToOwner[taskId] = msg.sender;
        emit NewTask(taskId, _name, tasks[taskId].timeLeft, msg.sender);
        taskId++;
    }

    /// @dev The function deletes the owner's task if such a task exists
    function deleteTask(uint256 _taskId) external checkEmptyTask(_taskId) onlyOwner(_taskId) {
        string memory name = tasks[_taskId].name;
        bool completed = tasks[_taskId].completed;
        bool outsideDeadline = notInDeadline[_taskId];
        delete tasks[_taskId];
        delete taskToOwner[_taskId];
        delete notInDeadline[_taskId];
        emit TaskRemoval(_taskId, name, completed, outsideDeadline, msg.sender);
    }

    /// @dev The function will change the status of the task as a completed task of the owner, if such a task exists
    function completeTask(uint256 _taskId) external checkEmptyTask(_taskId) onlyOwner(_taskId) {
        require(!tasks[_taskId].completed, "Already completed");
        tasks[_taskId].completed = true;
        /// @dev Checking that the task was completed within the allotted time
        if (block.timestamp > tasks[_taskId].timeLeft) notInDeadline[_taskId] = true;
        emit TaskCompletion(_taskId, tasks[_taskId].name, notInDeadline[_taskId], block.timestamp, msg.sender);
    }

    /// @dev Function to list all non-remote tasks
    /// @return allTasks Fixed length array, contains a list of non-deleted tasks
    function getTaskList() public view returns (Task[] memory allTasks) {
        uint256 counter;
        /// @dev Iterate through the mapping tasks to find out the length of the being created array
        for (uint256 i; i < taskId; i++) {
            if (tasks[i].timeLeft > 0) counter++;
        }
        allTasks = new Task[](counter);
        counter = 0;
        /// @dev Copy tasks from mapping tasks to array allTasks
        for (uint256 i; i < taskId; i++) {
            if (tasks[i].timeLeft > 0) {
                allTasks[counter] = tasks[i];
                counter++;
            }
        }
    }

    /// @dev The function of viewing statistics by address
    /// @param _taskOwner The address of the task owner whose statistics you want to view
    /// @return Percentage of tasks completed before the deadline, or 0 if the owner has no completed tasks
    function getStatisticByAddress(address _taskOwner) public view returns (uint256) {
        uint256 taskCounter;
        uint256 completedInDeadlineCounter;
        for (uint256 i; i < taskId; i++) {
            /// @dev If task is completed and task owner matches
            if (tasks[i].completed && taskToOwner[i] == _taskOwner) {
                taskCounter++;
                if (!notInDeadline[i]) completedInDeadlineCounter++;
            }
        }
        return taskCounter > 0 ? (completedInDeadlineCounter * 100) / taskCounter : 0;
    }
}
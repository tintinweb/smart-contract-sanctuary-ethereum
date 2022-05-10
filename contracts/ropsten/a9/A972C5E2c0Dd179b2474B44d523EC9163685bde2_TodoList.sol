// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title To do list app
/// @author Starostin Dmitry
/// @notice Create, modify, delete and getting user tasks
/// @dev Contract under testing
contract TodoList {
    struct Task {
        string content; // Text task
        uint256 timeBegin; // Time start
        uint256 timeEnd; // Time end
        uint256 timeRun; // Time run
        bool isDeleted; // Delete check
    }

    mapping(uint256 => address) public taskToOwner; // (task id => owner address)
    mapping(address => uint256) public ownerTaskCount; // (owner address => number of tasks)

    Task[] public tasks; // Task list

    event CreateTask(uint256 indexed _taskId, address indexed user, string _name, uint256 _timeRun);
    event DeleteTask(uint256 indexed _taskId, bool isDeleted);
    event CompleteTask(uint256 indexed _taskId, bool isComplete);

    // Access only for owner of tasks
    modifier onlyOwnerOf(uint256 _taskId) {
        require(msg.sender == taskToOwner[_taskId], "Access only for owner of tasks");
        _;
    }

    // Existence of the task
    modifier outOfRange(uint256 _taskId) {
        require(_taskId < tasks.length, "This task is not exist.");
        _;
    }

    /// @notice Create a new task
    /// @param _content Text for a new task
    /// @param _timeRun Time for completing a new task
    function createTask(string memory _content, uint256 _timeRun) external {
        tasks.push(Task(_content, block.timestamp, 0, _timeRun, false)); // Add a new task to the list
        taskToOwner[tasks.length - 1] = msg.sender; // Saving a task owner
        ownerTaskCount[msg.sender]++; // Increasing number of tasks of task owner
        emit CreateTask(tasks.length - 1, msg.sender, _content, _timeRun);
    }

    /// @notice Delete/restore task
    /// @dev Only for task owner
    /// @param _taskId ID task
    function deleteTask(uint256 _taskId) external onlyOwnerOf(_taskId) outOfRange(_taskId) {
        tasks[_taskId].isDeleted = !tasks[_taskId].isDeleted; // Delete/restore task
        emit DeleteTask(_taskId, tasks[_taskId].isDeleted);
    }

    /// @notice Change a status  the task
    /// @dev Only for task owner
    /// @param _taskId ID task
    function completeTask(uint256 _taskId) external onlyOwnerOf(_taskId) outOfRange(_taskId) {
        require(tasks[_taskId].isDeleted == false, "Task is deleted"); // Checking of deleting task
        if (tasks[_taskId].timeEnd == 0)
            tasks[_taskId].timeEnd = block.timestamp; // Task is completed
        else tasks[_taskId].timeEnd = 0; // Task is not completed
        emit CompleteTask(_taskId, tasks[_taskId].timeEnd != 0);
    }

    /// @notice Getting task by ID
    /// @param _taskId ID task
    /// @return Task Full information of the task
    function getOne(uint256 _taskId) external view outOfRange(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    /// @notice Getting all the tasks
    /// @return Tasks Full information of all tasks
    function getAll() external view returns (Task[] memory) {
        return tasks;
    }

    /// @notice Getting all the tasks for user
    /// @param _owner User adress
    /// @return arrayId Tasks ID for user
    function getAllByOwner(address _owner) external view returns (uint[] memory) {
        require(ownerTaskCount[_owner] > 0, "User hasn't any tasks");
        uint[] memory arrayId = new uint[](ownerTaskCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < tasks.length; i++) {
            if (taskToOwner[i] == _owner) {
                arrayId[counter] = i;
                counter++;
            }
        }
        return arrayId;
    }

    /// @notice  Getting the percent of completing tasks on time
    /// @param _owner User adress
    /// @return Percent
    function getPercent(address _owner) external view returns (uint256) {
        require(ownerTaskCount[_owner] > 0, "User hasn't any tasks");
        uint256 counter = 0;
        uint256 allcounter = ownerTaskCount[_owner];
        for (uint256 i = 0; i < tasks.length; i++) {
            bool arg1 = taskToOwner[i] == _owner;
            bool arg2 = tasks[i].isDeleted == false;
            bool arg3 = tasks[i].timeEnd != 0;
            bool arg4 = tasks[i].timeEnd <= tasks[i].timeBegin + tasks[i].timeRun;
            if (arg1) {
                if (arg2) {
                    if (arg3 && arg4) counter++; // Completing tasks on time
                }
                else allcounter--; // Subtraction of remote tasks
            }
        }
        require(allcounter > 0, "User hasn't any tasks");
        return (100 * counter) / allcounter; // Calculation of percent
    }
}
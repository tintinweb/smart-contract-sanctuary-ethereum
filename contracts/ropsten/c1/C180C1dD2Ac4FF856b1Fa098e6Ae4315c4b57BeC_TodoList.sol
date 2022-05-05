// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title To-do list
/// @author Starostin Dmitry
/// @notice Create, modify, delete user tasks
/// @dev Contract under testing
contract TodoList {
    
    struct Task {
        string content; // Text task
        uint timeBegin; // Time start
        uint timeEnd; // Time end
        uint timeRun; // Time run
        bool isDeleted; // Delete check
    }

    mapping(uint => address) public taskToOwner; // (task id => owner address)
    mapping(address => uint) public ownerTaskCount; // (owner address => count tasks)

    Task[] public tasks; // Tasks list

    event NewTask(uint _taskId, string _name, uint _timeRun); 
    event DelTask(uint _taskId); 
    event CompTask(uint _taskId); 

    // access only owner
    modifier onlyOwnerOf(uint _taskId) {
        require(msg.sender == taskToOwner[_taskId]);
        _;
    }
    
    /// @notice Create a new task
    /// @param _content Text for new task
    /// @param _timeRun Time for complete the task
    function createTask(string memory _content, uint _timeRun) external {
        tasks.push(Task(_content,  block.timestamp, 0, _timeRun, false)); // Add a new task to the list
        taskToOwner[tasks.length - 1] = msg.sender; // Save task owner
        ownerTaskCount[msg.sender]++; // Increase the count of tasks for the her owner
        emit NewTask(tasks.length - 1, _content, _timeRun); 
    }

    /// @notice Delete/restore task 
    /// @dev Only owner task
    /// @param _taskId Number task
    function deleteTask(uint _taskId) external onlyOwnerOf(_taskId) { 
        if (tasks[_taskId].isDeleted == false) { 
            tasks[_taskId].isDeleted = true; // Delete task
            ownerTaskCount[msg.sender]--;
        }
        else {
            tasks[_taskId].isDeleted = false; // Restore task
            ownerTaskCount[msg.sender]++;
        }
        emit DelTask(_taskId);
    }

    /// @notice Change status task 
    /// @dev Only owner task
    /// @param _taskId Number task
    function completeTask(uint _taskId) external onlyOwnerOf(_taskId) {
        require(tasks[_taskId].isDeleted == false, "Task is deleted"); // Check to task is not deleted
        if (tasks[_taskId].timeEnd == 0)
            tasks[_taskId].timeEnd = block.timestamp; // Task completed
        else
            tasks[_taskId].timeEnd = 0; // Task not completed
        emit CompTask(_taskId); 
    }

    /// @notice Get task by number
    /// @param _taskId Number task
    /// @return Task Requested value
    function getOne(uint _taskId) external view returns(Task memory) {
        return tasks[_taskId];
    }

    /// @notice Get all task
    /// @return Tasks Requested array value
    function getAll() external view returns(Task[] memory) {
        return tasks;
    }

    /// @notice Get all task for user
    /// @param _owner Address user
    /// @return Task Requested array value
    function getAllByOwner(address _owner) external view returns(Task[] memory) {
        Task[] memory result = new Task[](ownerTaskCount[_owner]); // Declare a new array
        uint counter = 0;
        for (uint i = 0; i < tasks.length; i++) { 
            if (taskToOwner[i] == _owner) {  
                result[counter] = tasks[i]; 
                counter++;
            }
        }
        return result; 
    }

    /// @notice Get the percent of tasks completed on time by user
    /// @param _owner Address user
    /// @return Task Percent
    function getPercent(address _owner) external view returns(uint) {
        require(ownerTaskCount[_owner] > 0, "User don't have a tasks");
        uint counter = 0;
        for (uint i = 0; i < tasks.length; i++) { 
            if (taskToOwner[i] == _owner && tasks[i].timeEnd != 0 && tasks[i].timeEnd <= tasks[i].timeBegin+tasks[i].timeRun && tasks[i].isDeleted == false)
                counter++; // If timeEnd < timeBegin + timeRun, then task completed on time
        }
        return 100*counter/ownerTaskCount[_owner];
    }
}
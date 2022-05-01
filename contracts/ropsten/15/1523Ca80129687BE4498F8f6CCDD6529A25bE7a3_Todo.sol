//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title simple Todolist smart-conract
/// @author Akylbek A.D.
/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implemented without side effects

contract Todo {    
    address public creator;
    address public contractAddress;

    /// @dev indexOfTask contains index of all adding tasks
    mapping (string => uint) internal indexOfTask;

    /// @dev allUserTasks contains number of all done and undone user added tasks
    mapping (address => uint) internal allUserTasks;

    /// @dev doneInTimeTasks contains number of done before deadline user tasks 
    mapping (address => uint) internal doneInTimeTasks;

    /// @dev private Struct of adding tasks
    struct Task {
        string task_name;
        uint hours_todo;
        string description;
        address owner;
        uint deadline;
        bool completed;
        bool completedInTime;
    }

    Task[] private AllTasks;

    constructor() {
        creator = msg.sender;
        contractAddress = address(this);
    }

    /// @notice Get revert if you try to send ETH to contract
    receive() payable external {
        revert("Contract Todo does not support straight payable transactions");
    }

    event NewTask (address user, string task_name, uint deadline);

    event TaskCompleted (address user, string task_name, bool completedInTime);

    event TaskRemoved (address user, string task_name);

    event TaskEdited (address user, string task_name);

    /// @dev this modifier restircts functions to other users
    modifier onlyOwner (string memory task_name) {
        require(msg.sender == AllTasks[indexOfTask[task_name]].owner, "You are not an owner!");
        _;
    }

    /// @dev this modifier restircts editing task if deadline has already passed
    modifier isNotTimeOut (string memory task_name) {
        require(block.timestamp < AllTasks[indexOfTask[task_name]].deadline, "Deadline for this task already have passed");
        _;
    }

    /// @dev this modifier restircts functions if task already done
    modifier isNotCompleted (string memory task_name) {
        require(AllTasks[indexOfTask[task_name]].completed == false, "This task already had been completed!");
        _;
    }
    
    /// @notice You have to input amount of hours before deadline, minimal time for a task have to be 1 hour
    function addTask(string memory task_name, uint hours_todo, string memory description) external {
        require (hours_todo > 0, "You have to input atleast 1 hour to do task");
        
        indexOfTask[task_name] = AllTasks.length;
        allUserTasks[msg.sender] += 1;

        uint inSeconds = hours_todo * 60 * 60;

        Task storage newTask = AllTasks.push();
        newTask.task_name = task_name;
        newTask.hours_todo = hours_todo;
        newTask.description = description;
        newTask.owner = msg.sender;
        newTask.deadline = block.timestamp + inSeconds;
        newTask.completed = false;
        newTask.completedInTime = false;

        emit NewTask(msg.sender, task_name, newTask.deadline);
    }

    /// @notice Allows to user delete his task and reduce amount of all added tasks
    /// @dev Function impliments soft delete from mapping allUserTasks
    function deleteTask(string memory task_name) external onlyOwner(task_name) {
        delete AllTasks[indexOfTask[task_name]];

        allUserTasks[msg.sender] -= 1;

        emit TaskRemoved(msg.sender, task_name);
    }

    function editTask(
        string memory task_name,
        string memory new_task_name,
        uint hours_todo,
        string memory description
    ) 
        external onlyOwner(task_name) isNotTimeOut(task_name) isNotCompleted(task_name) 
    {
        uint inSeconds = hours_todo * 60 * 60;

        AllTasks[indexOfTask[task_name]].task_name = new_task_name;
        AllTasks[indexOfTask[task_name]].hours_todo = hours_todo;
        AllTasks[indexOfTask[task_name]].description = description;
        AllTasks[indexOfTask[task_name]].deadline = block.timestamp + inSeconds;
        
        emit TaskEdited(msg.sender, task_name);
    }

    /// @notice If user completes his task before deadline it will be shown in detail and productivity
    function completeTask(string memory task_name) external onlyOwner(task_name) isNotCompleted(task_name) {
        AllTasks[indexOfTask[task_name]].completed = true;
        if (AllTasks[indexOfTask[task_name]].deadline > block.timestamp) {
            AllTasks[indexOfTask[task_name]].completedInTime = true;
            doneInTimeTasks[msg.sender] += 1;
        }

        emit TaskCompleted(msg.sender, task_name, AllTasks[indexOfTask[task_name]].completedInTime);
    }

    /// @notice Allows to see percents of completed before deadline tasks
    /// @dev Function shows only interger number without decimals
    function showProductivity(address user_address) external view returns (uint productivityInPrecent) {
        require(allUserTasks[user_address] > 0, "User doesnt have any tasks to do");
        productivityInPrecent = ((doneInTimeTasks[user_address] * 100) / allUserTasks[user_address]);
    }

    function showTask(string memory task_name) external view
        returns (
            uint hours_todo,
            string memory description,
            address owner,
            bool completed,
            bool completedInTime
        ) 
    {
        hours_todo = AllTasks[indexOfTask[task_name]].hours_todo;
        description = AllTasks[indexOfTask[task_name]].description;
        completed = AllTasks[indexOfTask[task_name]].completed;
        completedInTime = AllTasks[indexOfTask[task_name]].completedInTime;
        owner = AllTasks[indexOfTask[task_name]].owner;
    }

    function showUserTasks(address user_address) external view returns (string[] memory) {
        string[] memory UserTasks = new string[](allUserTasks[user_address]);
        uint userTasksIndex;

        for (uint i = 0; i < AllTasks.length; i++) {
            if (AllTasks[i].owner == user_address) {
                UserTasks[userTasksIndex] = AllTasks[i].task_name;
                userTasksIndex++;
            }
        }
        return UserTasks;
    }
}
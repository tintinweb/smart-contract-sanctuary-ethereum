//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Todo {    
    address public creator;
    address public contractAddress;

    mapping (string => uint) indexOfTask;
    mapping (address => uint) internal undoneTasks;
    mapping (address => uint) internal doneInTimeTasks;

    constructor() {
        creator = msg.sender;
        contractAddress = address(this);
    }
    
    struct Task {
        string task_name;
        uint hours_todo;
        string description;
        address owner;
        uint endTime;
        bool completed;
        bool completedInTime;
    }

    Task[] public AllTasks;

    function addTask (string memory task_name, uint hours_todo, string memory description) public {
        require (hours_todo > 0, "You have to input atleast 1 hour to do task");
        
        indexOfTask[task_name] = AllTasks.length;
        undoneTasks[msg.sender] += 1;

        uint inSeconds = hours_todo * 60 * 60;

        Task storage newTask = AllTasks.push();
        newTask.task_name = task_name;
        newTask.hours_todo = hours_todo;
        newTask.description = description;
        newTask.owner = msg.sender;
        newTask.endTime = block.timestamp + inSeconds;
        newTask.completed = false;
        newTask.completedInTime = false;
    }

    function deleteTask (string memory task_name) public onlyOwner(task_name) {
        delete AllTasks[indexOfTask[task_name]];
        undoneTasks[msg.sender] -= 1;
    }

    function editTask (string memory task_name, string memory new_task_name, uint hours_todo, string memory description) public onlyOwner(task_name) isNotTimeOut(task_name) isNotCompleted(task_name) {

        uint inSeconds = hours_todo * 60 * 60;

        AllTasks[indexOfTask[task_name]].task_name = new_task_name;
        AllTasks[indexOfTask[task_name]].hours_todo = hours_todo;
        AllTasks[indexOfTask[task_name]].description = description;
        AllTasks[indexOfTask[task_name]].endTime = block.timestamp + inSeconds;
    }

    function completeTask (string memory task_name) public onlyOwner(task_name) isNotCompleted(task_name) {
        AllTasks[indexOfTask[task_name]].completed = true;
        if (AllTasks[indexOfTask[task_name]].endTime > block.timestamp) {
            AllTasks[indexOfTask[task_name]].completedInTime = true;
            doneInTimeTasks[msg.sender] += 1;
        }
    }

    function showProductivity (address user_address) public view returns (uint productivityInPrecent) {
        productivityInPrecent = ((doneInTimeTasks[user_address] * 100) / undoneTasks[user_address]);
    }

    function showTask (string memory task_name) public view returns (uint hours_todo, string memory description, address owner, bool completed, bool completedInTime) {
        hours_todo = AllTasks[indexOfTask[task_name]].hours_todo;
        description = AllTasks[indexOfTask[task_name]].description;
        completed = AllTasks[indexOfTask[task_name]].completed;
        completedInTime = AllTasks[indexOfTask[task_name]].completedInTime;
        owner = AllTasks[indexOfTask[task_name]].owner;
    }

    function showUserTasks (address user_address) public view returns (string[] memory) {
        string[] memory UserTasks = new string[](undoneTasks[user_address]);
        uint userTasksIndex;

        for (uint i = 0; i < AllTasks.length; i++) {
            if (AllTasks[i].owner == user_address) {
                UserTasks[userTasksIndex] = AllTasks[i].task_name;
                userTasksIndex++;
            }
        }

        return UserTasks;
    }

    modifier onlyOwner (string memory task_name) {
        require(msg.sender == AllTasks[indexOfTask[task_name]].owner, "You are not an owner!");
        _;
    }

    modifier isNotTimeOut (string memory task_name) {
        require(block.timestamp < AllTasks[indexOfTask[task_name]].endTime, "Deadline for this task already have passed");
        _;
    }

    modifier isNotCompleted (string memory task_name) {
        require(AllTasks[indexOfTask[task_name]].completed == false, "This task already had been completed!");
        _;
    }

    receive () payable external{
        revert("Contract Todo does not support straight payable transactions, please use abi to interact");
    }
}
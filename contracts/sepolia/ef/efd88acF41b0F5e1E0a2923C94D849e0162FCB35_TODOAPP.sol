// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract TODOAPP {
    struct Task {
        string name;
        string description;
        bool completed;
    }
    
    address public owner;
    uint public taskCount;
    mapping(uint => Task) public tasks;
    mapping(address => mapping(uint => bool)) public userTasks;
    
    event TaskCreated(uint taskId, string name, string description);
    event TaskAssigned(uint taskId, address user);
    event TaskCompleted(uint taskId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        taskCount = 0;
    }
    
    function createTask(string memory _name, string memory _description) public onlyOwner {
        taskCount++;
        tasks[taskCount] = Task(_name, _description, false);
        emit TaskCreated(taskCount, _name, _description);
    }
    
    function assignTask(uint _taskId, address _user) public onlyOwner {
        require(_taskId > 0 && _taskId <= taskCount, "Invalid task ID.");
        userTasks[_user][_taskId] = true;
        emit TaskAssigned(_taskId, _user);
    }
    
    function markTask(uint _taskId) public {
        require(_taskId > 0 && _taskId <= taskCount, "Invalid task ID.");
        require(userTasks[msg.sender][_taskId], "You are not assigned to this task.");
        tasks[_taskId].completed = true;
        emit TaskCompleted(_taskId);
    }
}
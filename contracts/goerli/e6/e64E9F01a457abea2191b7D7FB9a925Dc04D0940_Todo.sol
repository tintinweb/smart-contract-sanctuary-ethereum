// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Todo {

    struct Task {
        string content;
        bool completed;
    }

    // tasks[address][id] = Task // id starts from 0
    mapping(address => mapping(uint => Task)) public tasks;
    mapping(address => uint) public taskCount;

    //////////////
    // Errors
    //////////////

    error TaskNotFound(uint _id);

    //////////////
    // Events
    //////////////

    event TaskCreated(
        address indexed _from,
        uint _id,
        string _content,
        bool _completed
    );

    event TaskToggledCompleted(
        address indexed _from,
        uint _id,
        string _content,
        bool _completed
    );

    event TaskDeleted(
        address indexed _from,
        uint _id
    );

    //////////////
    // Functions
    //////////////

    function createTask(string memory _content) public {
        tasks[msg.sender][taskCount[msg.sender]] = Task(_content, false);
        taskCount[msg.sender]++;
        emit TaskCreated(msg.sender, taskCount[msg.sender], _content, false);
    }

    function toggleCompleted(uint _id) public {
        if(taskCount[msg.sender] <= _id) revert TaskNotFound(_id);

        Task storage _task = tasks[msg.sender][_id];
        _task.completed = !_task.completed;
        emit TaskToggledCompleted(msg.sender, _id, _task.content, _task.completed);
    }

    function deleteTask(uint _id) public {
        if(taskCount[msg.sender] <= _id) revert TaskNotFound(_id);

        delete tasks[msg.sender][_id];
        emit TaskDeleted(msg.sender, _id);
    }

    function getTask(uint _id) public view returns (string memory, bool) {
        if(taskCount[msg.sender] <= _id) revert TaskNotFound(_id);

        Task memory _task = tasks[msg.sender][_id];
        return (_task.content, _task.completed);
    }

    fallback() external {
        revert("No function matched");
    }

    receive() external payable {
        revert("No function matched");
    }

}
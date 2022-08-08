// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoList {

    string[] public todos;
    string[] public todoCompleted;
    string[] public todoPending;
    uint256 public pendingSeconds;

    // todos's index => todoPending's index
    mapping(uint256 => uint256) public todoPendingMapping;

    // todos's index => block.timestamp when todo push to pending array
    mapping(uint256 => uint256) public todoPendingTimeMapping;
    

    constructor(uint256 _pendingSeconds) {
        pendingSeconds = _pendingSeconds;
    }

    function getTodo(uint256 _index) external view returns (string memory) {
        return todos[_index];
    }

    function addTodo(string memory _todo) external {
        todos.push(_todo);
    }

    function deleteTodo(uint256 _index) external {
        delete todos[_index];
    }

    function getAllTodo() external view returns (string[] memory) {
        return todos;
    }

    function setCompleted(uint256 _index) external {
        todoCompleted.push(todos[_index]);
    }    

    function getCompleted(uint256 _index) external view returns (string memory) {
        return todoCompleted[_index];
    }

    function moveToPending(uint256 _index) external {
        string memory todo = todos[_index];
        require(keccak256(abi.encodePacked(todo)) != keccak256(abi.encodePacked("")), "Todo is pending or deleted");
        todoPending.push(todo);
        todoPendingMapping[_index] = todoPending.length - 1;
        todoPendingTimeMapping[_index] = block.timestamp;
        delete todos[_index];
    }

    function moveFromPending(uint256 _index) external {
        uint256 lastTimeStamp = todoPendingTimeMapping[_index];
        require(lastTimeStamp > 0 && (lastTimeStamp + pendingSeconds > block.timestamp), "Time of todo in pending is over the given limitation");
        uint256 pendingIndex = todoPendingMapping[_index];
        string memory pendingTodo = todoPending[pendingIndex];
        todos[_index] = pendingTodo;
        delete todoPending[pendingIndex];
    }

    function getAllPending() external view returns (string[] memory) {
        return todoPending;
    }

    function clearAllCompleted() external {
        todoCompleted = new string[](0);
    }
}
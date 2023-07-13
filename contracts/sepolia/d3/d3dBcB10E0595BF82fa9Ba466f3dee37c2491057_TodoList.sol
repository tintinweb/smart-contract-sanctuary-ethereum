// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

error TodoList__NotOwner();
error TodoList__TaskNotExists();

contract TodoList {
    enum TaskStatus {
        Pending,
        Fininshed
    }

    address private immutable owner;

    struct Task {
        string desc;
        TaskStatus status;
    }

    Task[] public tasks;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        if (msg.sender != owner) {
            revert TodoList__NotOwner();
        }
        _;
    }

    function addTaks(string memory _desc) public isOwner {
        tasks.push(Task(_desc, TaskStatus.Pending));
    }

    function markAsFinished(uint256 index) public isOwner {
        if (index > tasks.length - 1) {
            revert TodoList__TaskNotExists();
        }
        tasks[index].status = TaskStatus.Fininshed;
    }

    function getAllTaks() public view returns (Task[] memory) {
        return tasks;
    }

    function getSingleTask(uint256 index) public view returns (Task memory) {
        if (index > tasks.length - 1) {
            revert TodoList__TaskNotExists();
        }
        return tasks[index];
    }

    function getOwnerAddress() public view returns (address) {
        return owner;
    }
}
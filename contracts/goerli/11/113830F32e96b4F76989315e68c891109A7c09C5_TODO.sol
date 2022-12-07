// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

error TODO__OnlyOwner();
error TODO__TaskNotExist();

contract TODO {
    struct Task {
        uint256 id;
        uint256 createdAt;
        string content;
        bool done;
    }

    mapping(uint256 => Task) private tasks;
    mapping(uint256 => address) private ownerTasks;
    uint256 private taskId = 1;

    event TaskCreated(address indexed recepient, uint256 indexed taskId);
    event TaskToggled(uint256 indexed taskId, bool done);

    function createTask(string calldata content) external {
        tasks[taskId] = Task(taskId, block.timestamp, content, false);
        ownerTasks[taskId] = msg.sender;
        emit TaskCreated(msg.sender, taskId);
        taskId++;
    }

    function getAllTasks() external view returns (Task[] memory) {
        Task[] memory personalTasks = new Task[](taskId);
        uint256 counter;

        for (uint256 i; i < taskId; i++) {
            if (ownerTasks[i] == msg.sender) {
                personalTasks[counter] = tasks[i];
                counter++;
            }
        }

        Task[] memory result = new Task[](counter);

        for (uint256 i; i < counter; i++) {
            result[i] = personalTasks[i];
        }

        return result;
    }

    function getTask(uint256 id)
        external
        view
        taskExists(id)
        onlyOwner(id)
        returns (Task memory)
    {
        return tasks[id];
    }

    function toggleTask(uint256 id) external taskExists(id) onlyOwner(id) {
        Task storage task = tasks[id];
        task.done = !task.done;
        emit TaskToggled(id, task.done);
    }

    modifier taskExists(uint256 id) {
        if (tasks[id].createdAt == 0) revert TODO__TaskNotExist();
        _;
    }

    modifier onlyOwner(uint256 id) {
        if (ownerTasks[id] != msg.sender) revert TODO__OnlyOwner();
        _;
    }
}
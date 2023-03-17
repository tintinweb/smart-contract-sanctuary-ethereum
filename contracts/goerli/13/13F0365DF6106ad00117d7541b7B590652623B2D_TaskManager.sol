pragma solidity ^0.8.0;

contract TaskManager {
    struct Task {
        string name;
        string description;
        uint256 dueDate;
        bool isComplete;
    }

    mapping(address => Task[]) public tasksByAddress;

    event TaskCreated(
        address indexed user,
        uint256 indexed taskId,
        string name,
        string description,
        uint256 dueDate
    );
    event TaskUpdated(
        address indexed user,
        uint256 indexed taskId,
        bool isComplete
    );

    function createTask(
        string memory _name,
        string memory _description,
        uint256 _dueDate
    ) public {
        Task memory newTask = Task(_name, _description, _dueDate, false);
        tasksByAddress[msg.sender].push(newTask);
        uint256 taskId = tasksByAddress[msg.sender].length - 1;
        emit TaskCreated(msg.sender, taskId, _name, _description, _dueDate);
    }

    function updateTask(uint256 _taskId, bool _isComplete) public {
        Task storage task = tasksByAddress[msg.sender][_taskId];
        task.isComplete = _isComplete;
        emit TaskUpdated(msg.sender, _taskId, _isComplete);
    }
}
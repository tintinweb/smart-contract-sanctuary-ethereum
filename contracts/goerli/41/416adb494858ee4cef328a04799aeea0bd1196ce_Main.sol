//SPD-Licenced: UNLICENSED
pragma solidity 0.8.17;

contract Main {

    constructor () {
        owner = msg.sender;
    }

    address public owner;
    enum TaskStatuses { Draft, Published, atWork, Finished, Canceled }
    TaskStatuses currentTaskStatus;

    struct Task {
       // currentTaskStatus _currentTaskStatus;
        address publisherAddress;
        string publisherName;
        string taskName;
        uint256 taskDuration;
        address workerAddress;
        uint256 price;
    }

    Task[] public arrayTasks;

    function publishTask(string calldata _publisherName, string calldata _taskName, uint256 _taskDuration) external payable {
        arrayTasks.push(Task({
            publisherAddress: msg.sender,
            publisherName: _publisherName,
            taskName: _taskName,
            taskDuration: _taskDuration,
            workerAddress: 0x0000000000000000000000000000000000000000,
            price: msg.value
        }));
    }
}
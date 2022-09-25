//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./todoApp.sol";

error userAlreadyExisted(address user);

contract Factory {
    todoApp[] public userArr;

    mapping(address => bool) s_AccountCreated; //User address mapping to factory address.
    mapping(address => address) s_factoryAddress;

    modifier checkUser() {
        if (s_AccountCreated[msg.sender]) {
            revert userAlreadyExisted(msg.sender);
        } else {
            _;
        }
    }

    function createNewAccount(string memory _userName) public checkUser {
        todoApp newUser = new todoApp(_userName, msg.sender);
        userArr.push(newUser);
        s_AccountCreated[msg.sender] = true;
        s_factoryAddress[msg.sender] = address(newUser);
    }

    function getFactoryAddress(address userAdd_) public view returns (address) {
        require(
            s_AccountCreated[userAdd_],
            "ERROR: The account doesn't exist!"
        );
        return s_factoryAddress[userAdd_];
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error NotOwner(address _owner);

contract todoApp {
    uint256 public taskCount = 0;

    string public userName;

    address public owner;

    constructor(string memory _userName, address _owner) {
        userName = _userName;
        owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        } else {
            revert NotOwner(msg.sender);
        }
    }

    struct Task {
        string taskName;
        bool status;
    }

    event e_taskCreated(string indexed taskName, bool status);

    event e_taskUpdated(string indexed taskName, bool status);

    Task[] public s_tasks;

    function changeName(string memory _newName) public onlyOwner {
        userName = _newName;
    }

    function addTask(string memory _taskName) public {
        taskCount++;
        s_tasks.push(Task(_taskName, false));
        emit e_taskCreated(_taskName, false);
    }

    function displayAllTasks() public view returns (Task[] memory) {
        return s_tasks;
    }

    function toggleTaskStatus(uint256 _index) public {
        Task storage task = s_tasks[_index];
        task.status = !task.status;
        emit e_taskUpdated(task.taskName, task.status);
    }

    function updateTask(uint256 _index, string memory _newTaskName) public {
        Task storage task = s_tasks[_index];
        task.taskName = _newTaskName;
        emit e_taskUpdated(task.taskName, task.status);
    }
}
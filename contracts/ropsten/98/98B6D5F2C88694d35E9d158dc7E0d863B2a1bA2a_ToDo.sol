/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

    contract ToDo{

    struct Task {
        uint256 id;
        uint256 dateCreate;
        uint256 dateComplete;
        string content;
        bool done; 
        bool isDeleted;
    }

    Task[] public tasks;

    mapping (uint => address) public taskToOwner;
    mapping (address => uint) public ownerTaskCount;
    
    modifier ownerOf(uint id) {
    require(msg.sender == taskToOwner[id]);
    _;
    }

    modifier taskExists(uint256 _id) {
        if (tasks[_id].id == 0) {
            revert("Revert: taskId not found");
        }
        _;
    }

    event TaskCreated(uint id, uint dateCreate, string content, bool done);
    event TaskStatusToggled(uint id, bool done, uint256 dateComplete);
    event TaskDeleted(uint id);

    uint private lastTaskId = 1;
    uint[] private taskId;

    function createTask(string memory _content) public {
        uint theNow = block.timestamp;
        tasks.push(Task(lastTaskId, theNow, 0, _content, false ,false));
        taskToOwner[tasks.length - 1] = msg.sender;
        ownerTaskCount[msg.sender]++; 
    }
    
    function toggleDone(uint _id) public taskExists(_id) ownerOf(_id) {
        if(tasks[_id].isDeleted==false){
            Task storage task = tasks[_id];
            task.done = !task.done;
            task.dateComplete = task.done ? block.timestamp : 0;

            emit TaskStatusToggled(_id, task.done, task.dateComplete);
        }
    }

    function deleteTask(uint _id) public taskExists(_id) ownerOf(_id) {
        if (tasks[_id].isDeleted == false) {
            tasks[_id].isDeleted = true;
            ownerTaskCount[msg.sender]--;
        }
        emit TaskDeleted(_id);
    }

    function getPrecent(address _owner) external view returns(uint) {
        uint counter = 0;
        for (uint i = 0; i < tasks.length; i++) {
            if (taskToOwner[i] == _owner && tasks[i].dateCreate!=0 && tasks[i].dateComplete<=tasks[i].dateCreate &&  tasks[i].done == false)
                counter++;
        }
         return 100*counter/ownerTaskCount[_owner];
    }

    function getTask(uint id) public taskExists(id) view returns ( uint, uint, string memory, bool, uint, bool) {
        return (id, tasks[id].dateCreate, tasks[id].content, tasks[id].done, tasks[id].dateComplete, tasks[id].isDeleted);
    }

    function getTaskIds() public view returns (uint[] memory) {
        return taskId;
    }
}
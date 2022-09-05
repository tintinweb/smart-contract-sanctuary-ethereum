// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title TODO contract 
/// @author Oluwatosin Serah Ajao

contract TodoList{
    struct Todo{
        string task;
        bool completed;
    }

    mapping(address => Todo[]) _Todo;

    event TaskAdded(address caller,
        string task,
        bool completed);
    
    event TaskCompleted(uint ID, 
        bool completed);

    //function to add todo
    function addTask(string memory _task) external{
        _Todo[msg.sender].push(Todo({
            task:_task,
            completed:false
        }));
        emit TaskAdded(msg.sender, _task, false);
    }

    //function to update todo
    function updateTask(string memory _task, uint taskID, address _addr) external {
        Todo storage td = _Todo[_addr][taskID];
        td.task = _task;
    }

   //function to return a user tasks
    function getTask(address _addr) public view returns(Todo[] memory) {
        Todo[] storage td = _Todo[_addr];
        return td;
    }

    //function to checktask
    function completeTask(uint taskID, address _addr) external  {
      Todo storage td = _Todo[_addr][taskID];
      td.completed = true;
         emit TaskCompleted(taskID, true);
    }

    //function to remove task
    function removeTask(uint taskID, address _addr) external view{
         Todo memory td = _Todo[_addr][taskID];
         delete td;
    }


}
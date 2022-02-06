/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract RandomToDoList {
    
    struct Task {
        uint id;
        string title;
        address owner;
    }
    
    Task[] tasks;

    function getTasksLen() internal view returns(uint){
        return tasks.length;
    } 

    function isOwner(address _owner) internal view returns(bool){
        if(_owner == msg.sender){
            return true;
        }
        revert("You are not the owner");
    }
    
    
    function createTask(string memory _name) public {
        uint nextId = getTasksLen();
        tasks.push(Task(nextId, _name, msg.sender));
        nextId++;
    }

    function readTask(uint _id) public view returns (uint, string memory, address) {
        // uint index = findIndex(_id);
        uint index = _id;
        if(isOwner(tasks[index].owner)){
            return (tasks[index].id, tasks[index].title, tasks[index].owner);
        }
    }
    
    
    // function findIndex(uint _id) internal view returns (uint) {
    //     for (uint i = 0; i < tasks.length; i++) {
    //         if (tasks[i].id == _id) {                
    //             return i;
    //         }
    //     }
    //     revert("Task not found");
    // }
    
    // function updateTask(uint _id, string memory _name, string memory _description) public {
    //     uint index =  findIndex(_id);
    //     tasks[index].name = _name;
    //     tasks[index].description = _description;
    // }
    
    
    // function deleteTask(uint _id) public {
    //     uint index = findIndex(_id);
    //     delete tasks[index];
    // }
    
}
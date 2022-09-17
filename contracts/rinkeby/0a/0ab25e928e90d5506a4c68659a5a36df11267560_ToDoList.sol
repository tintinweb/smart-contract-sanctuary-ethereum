/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract ToDoList {

    struct toDo {
        string task;
        bool isCompleted;
    }

    // Array of ToDo structs
    toDo[] public myToDoList;

    // Creates a toDo and pushes to the toDoList
    function addToDo(string calldata _task) external {
        myToDoList.push(toDo(_task,false));
    }

    // You can access ToDoInfo by myToDoList[_index]. Therefore, this function is not necessary
    function getToDoInfo(uint _index) external view returns(string memory, bool) {
        toDo storage ToDo = myToDoList[_index];
        return (ToDo.task,ToDo.isCompleted); // Solidity can return multiple values
    }

    // Update task
    function updateTask(string memory _newTask,uint256 _index) external {
        myToDoList[_index].task = _newTask;
    }

    // Update completion situation of a toDo
    function toggleCompleted(uint _index) external {
        myToDoList[_index].isCompleted = !myToDoList[_index].isCompleted;
    }
}
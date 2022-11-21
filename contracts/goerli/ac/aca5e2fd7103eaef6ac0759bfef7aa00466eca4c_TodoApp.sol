/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TodoApp {
    struct Todo {
        uint taskId;
        string task;
        bool flag;
    }

    Todo[] public todos;
    uint public num = 0;
    mapping (uint => address) public todoToOwner;
    mapping (address => uint) public ownerTodoCount;

    function createTodo(string memory _task) external {
        todos.push(Todo(num, _task, true));
        uint id = todos.length - 1;
        todoToOwner[id] = msg.sender;
        ownerTodoCount[msg.sender]++;
        num++;
    }

    function completeTodo(uint id) external {
        require(todoToOwner[id] == msg.sender);
        require(todos[id].flag);
        todos[id].flag = false;
    }

    function getTodosByOwner(address owner) external view returns(uint[] memory){
        uint[] memory result = new uint[](ownerTodoCount[owner]);
        uint counter = 0;
        for (uint i = 0; i < todos.length; i++){
            if (todoToOwner[i] == owner){
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
}
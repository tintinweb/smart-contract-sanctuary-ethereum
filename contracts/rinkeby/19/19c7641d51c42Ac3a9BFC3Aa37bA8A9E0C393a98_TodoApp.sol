// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract TodoApp {

    struct Todo {
        string task;
        bool flag;
    }

    Todo[] public todos;

    mapping(uint => address) todoOwner;
    mapping(address => uint) todoCount;

    function inputTodo(string memory _task) public {
        todos.push(Todo(_task, true));
        uint id = todos.length - 1;
        todoOwner[id] == msg.sender;
        todoCount[msg.sender]++;
    }

    function deleteTodo(uint id) public {
        require(todoOwner[id] == msg.sender, "you are not the owner");
        require(todoCount[msg.sender] > 0, "there is no todo");
        require(todos[id].flag);
        todos[id].flag = false;
    }

    function getTodo() public view returns(uint[] memory){
        uint[] memory result = new uint[](todoCount[msg.sender]);
        uint counter = 0;
        for(uint i = 0; i < todos.length; i++){
            if(todoOwner[i] == msg.sender && todos[i].flag == true){
                result[counter] = i;
                counter++;
            }
        } 
        return result;
    }
 }
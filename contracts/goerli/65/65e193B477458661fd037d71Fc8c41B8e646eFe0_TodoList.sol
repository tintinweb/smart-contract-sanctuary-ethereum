/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

contract TodoList {

    struct Todo {
        string title;
        bool done;
    }

    mapping(address => Todo[]) public userTodos;


    event onCreateTodo(address owner, uint index, string title );
    event onUpdateTodo(address owner, uint index, string title, bool done);

    function createTodo(string memory _title) public {
        Todo memory temp;
        temp.title = _title;
        userTodos[msg.sender].push(temp);
        uint _index = userTodos[msg.sender].length - 1;
        emit onCreateTodo(msg.sender, _index, _title);
    }

    function update(address _address, uint _index, string memory _title) public {
        require(_address == msg.sender, "Permission denined.");

        Todo storage todo = userTodos[msg.sender][_index];
        todo.title = _title;
        emit onUpdateTodo(msg.sender, _index, _title, todo.done);
    }

    function toggleCompleted(address _address, uint _index) public {
        require(_address == msg.sender, "Permission denined");

        Todo storage todo = userTodos[msg.sender][_index];
        todo.done = !todo.done;
        emit onUpdateTodo(msg.sender, _index, todo.title, todo.done);
    }
}
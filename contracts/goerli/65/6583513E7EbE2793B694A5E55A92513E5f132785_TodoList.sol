/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract TodoList {

    string private topic;
    string private description;

    struct Todos{
        string topic;
        string description;
    }

    Todos[] private todos;

    event Todo(Todos []);

    function addTodo(string memory _topic, string memory _description) external{
        todos.push(Todos(_topic, _description));
        emit Todo(todos);
    }

    function viewTodo(uint _index) external view returns(string memory _topic, string memory _description){
        Todos storage todo = todos[_index];
        return (todo.topic, todo.description);
    }

    function viewTodos() external view returns(Todos[] memory){
        return (todos);
    }

    function removeTodo(uint256 index) external {
        if (index >= todos.length) return;

        for (uint i = index; i<todos.length-1; i++){
            todos[i] = todos[i+1];
        }
        todos.pop();
        emit Todo(todos);
    }

     function changeTodo(uint256 index, string memory _topic, string memory _description) external {
        if (index >= todos.length) return;

        todos[index] = Todos(_topic, _description);
        
        emit Todo(todos);
    }

    // I have changed this contract.
}
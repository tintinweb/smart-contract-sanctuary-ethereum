// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

error inValidTodoIndex(uint256 requested, uint256 total);


contract TodoApp {
    address owner;

    struct Todo {
        string name;
        bool done;
    }

    uint256 public totalItems;

    Todo[] todoList;
    event AddTodo (string item, bool done);
    event completedTodo (string item, bool done);

    modifier onlyOwner{
        require(msg.sender == owner, "Only owner can add new todo..");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    function addTodo (string memory _item) public onlyOwner{
        todoList.push(Todo(_item, false));
        totalItems = totalItems + 1;

        emit AddTodo(_item, false);
    }

    function finishedTodo (uint256 _index) public {
        Todo storage todo = todoList[_index];
        todo.done = true;

        emit completedTodo(todo.name, todo.done);
    }

    function getTodoItem (uint256 _index) public view returns(string memory, bool){
        Todo storage todo = todoList[_index];
        if(_index > todoList.length){
            revert inValidTodoIndex({
                requested: _index,
                total: todoList.length
            });
        }

        return (todo.name, todo.done);
    }
}
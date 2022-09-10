/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

contract TodoList {
    struct Todo {
        string title;
        string desc;
        bool completed;
    }

    Todo[] public todos;

    function create(string calldata _title, string calldata _desc) external {
        todos.push(Todo(
            _title,
            _desc,
            false
        ));
    }

    function updateText(uint _index, string calldata _title) external {
        todos[_index].title = _title;
    }

    function updateCompleted(uint _index) external {
        todos[_index].completed = !todos[_index].completed;
    }
    // 68474
    function updateMultiple(uint _index, string calldata _title, string calldata _desc, bool _completed) external {
        todos[_index].title = _title;
        todos[_index].desc = _desc;
        todos[_index].completed = _completed;
    }

    // 68014
    function updateMultipleStorage(uint _index, string calldata _title, string calldata _desc, bool _completed) external {
        Todo storage todo = todos[_index];
        todo.title = _title;
        todo.desc = _desc;
        todo.completed = _completed;
    }

    function readIndex(uint _index) external view returns (string memory, string memory, bool) {
        Todo memory todo = todos[_index];
        return (todo.title, todo.desc, todo.completed);
    }

    function readTodo() external view returns (Todo[] memory) {
        return todos;
    }

    function deleteTodo(uint _index) external {
        todos[_index] = todos[todos.length-1];
        todos.pop();
    }


}
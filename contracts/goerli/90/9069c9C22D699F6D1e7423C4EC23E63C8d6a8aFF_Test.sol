// SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.9;


contract Test {
    struct TodoList {
        string text;
        bool completed;
    }
    TodoList[] public todos;

    function create(string calldata _text) external {
        todos.push(TodoList({text: _text, completed: false}));
    }

    function updateText(uint256 _index, string calldata _text) external {
        //适合多个更新
        TodoList storage todo = todos[_index];
        todo.text = _text;
    }

    // 获取
    // storage 存储中，memory内存中
    function get(uint256 _index) external view returns (string memory, bool) {
        TodoList storage todo = todos[_index];
        return (todo.text, todo.completed);
    }

    function toggleCom(uint256 _index) external {
        todos[_index].completed = !todos[_index].completed;
    }
}
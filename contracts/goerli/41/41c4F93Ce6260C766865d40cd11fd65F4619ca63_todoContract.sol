// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract todoContract {
    uint256 private counter;

    struct todo {
        uint256 id;
        string text;
    }
    todo[] private todoList;

    constructor() {
        counter = 0;
    }

    function addTodo(string memory _text) public {
        todoList.push(todo(counter, _text));
        counter += 1;
    }

    function updateTodo(string memory _text, uint256 _id) public {
        todo memory _todo = todoList[_id];
        _todo.text = _text;
        todoList[_id] = _todo;
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function removeTodo(uint256 _id) public {
        todo[] memory _todoList;
        _todoList = todoList;
        for (uint256 i = 0; i < _todoList.length; i++) {
            if (_todoList[i].id == _id) {
                _todoList[i].text = "";
            }
        }
        delete todoList;
        for (uint256 i = 0; i < _todoList.length; i++) {
            if (!compareStrings(_todoList[i].text, "")) {
                todoList.push(_todoList[i]);
            }
        }
    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    function getTodoList() public view returns (todo[] memory) {
        return todoList;
    }

    function getTodoListitem(uint256 _id) public view returns (todo memory) {
        return todoList[_id];
    }

    function getText(uint256 _id) public view returns (string memory) {
        return todoList[_id].text;
    }
}
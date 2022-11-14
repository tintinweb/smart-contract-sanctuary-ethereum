/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-14
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    uint256 internal mapSize = 1;

    struct TodoItem {
        uint256 id;
        address owner;
        string title;
        string content;
        uint256 createdAt;
        uint256 updatedAt;
        bool status;
    }

    // event add todo item
    event AddTodoList(TodoItem todoItemEvent);

    // event edit todo item
    event EditTodoList(TodoItem todoItemEvent);

    // event remove todo item
    event RemoveTodoList(uint256 id);

    // lưu danh sách todo item (bất kể user nào cũng đẩy vào mảng này)
    // id => todoItem
    mapping(uint256 => TodoItem) internal todoList;

    // chứa id danh sách todoItem của user
    // userAddress => [id]
    mapping(address => uint256[]) internal todoIdsByUser;

    // todo id => index todoIdsByUser;
    mapping(uint256 => uint256) internal indexTodoIds;

    // Hiển thị todo item từ id
    function getTodoItem(uint256 id) external view returns (TodoItem memory) {
        return todoList[id];
    }

    // Hiển thị danh sách id todo items từ user address
    function getTodoIdsByUser(address userAddress)
        external
        view
        returns (uint256[] memory)
    {
        return todoIdsByUser[userAddress];
    }

    // kiểm tra sender có phải là owner của todoItem hay không?
    modifier isOwnerTodoItem(uint256 id) {
        require(
            todoList[id].owner == msg.sender,
            "Sender is not owner todo item"
        );
        _;
    }

    // kiểm tra todo item có tồn tại hay không
    modifier isTodoItemExists(uint256 id) {
        require(todoList[id].id > 0, "Todo item doesn't exists!");
        _;
    }

    // Tạo mới 1 todo item by sender
    function addTodoItem(
        string memory title,
        string memory content,
        bool status
    ) external {
        address owner = msg.sender;
        uint256 createdAt = block.timestamp;
        uint256 updatedAt = block.timestamp;
        TodoItem memory todoItem = TodoItem(
            mapSize,
            owner,
            title,
            content,
            createdAt,
            updatedAt,
            status
        );
        todoList[mapSize] = todoItem;
        todoIdsByUser[owner].push(mapSize);
        indexTodoIds[mapSize] = todoIdsByUser[owner].length - 1;
        mapSize++;
        emit AddTodoList(todoItem);
    }

    // Sửa todo item theo id
    function editTodoItem(
        uint256 id,
        string memory title,
        string memory content,
        bool status
    ) external isTodoItemExists(id) {
        TodoItem memory todoItem = todoList[id];
        require(
            todoList[id].owner == msg.sender,
            "Sender is not owner todo item"
        );
        todoItem.title = title;
        todoItem.content = content;
        todoItem.status = status;
        todoItem.updatedAt = block.timestamp;
        todoList[id] = todoItem;
        emit EditTodoList(todoItem);
    }

    // remove todo item theo id
    function removeTodoItem(uint256 id) external isTodoItemExists(id) {
        require(
            todoList[id].owner == msg.sender,
            "Sender is not owner todo item"
        );
        delete todoList[id];
        delete todoIdsByUser[msg.sender][indexTodoIds[id]];
        emit RemoveTodoList(id);
    }
}
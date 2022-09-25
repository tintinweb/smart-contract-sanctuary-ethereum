// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* Errors */
error Todo__EmptyDescription();
error Todo__NotOwner();
error Todo__InvalidTodo();

contract TodoApp {
    /* State variables */
    uint256 private s_todoCount;
    mapping(uint256 => Todo) public s_todoList;

    modifier onlyOwner(uint256 id) {
        Todo memory todo = s_todoList[id];
        if (todo.owner != msg.sender) {
            revert Todo__NotOwner();
        }
        _;
    }

    modifier validTodo(uint256 id) {
        if (id > s_todoCount) {
            revert Todo__InvalidTodo();
        }
        _;
    }

    /* Events  */
    event TodoCreated(uint256 id,address owner,string description,bool isDone);
    event TodoUpdated(uint256 id, string description);
    event TodoCompleted(uint256 id);
    event TodoDeleted(uint256 id);

    /* Mappings  */

    /*Structs */
    struct Todo {
        address owner;
        string description;
        bool isDone;
    }

    function createTodo(string memory description) external {
        if (bytes(description).length == 0) {
            revert Todo__EmptyDescription();
        }
        ++s_todoCount;
        s_todoList[s_todoCount] = Todo(msg.sender, description, false);

        emit TodoCreated(s_todoCount,msg.sender,description,false);
    }

    function editTodo(uint256 id, string memory desc) external validTodo(id) onlyOwner(id) {
        Todo storage todo = s_todoList[id];
        todo.description = desc;

        emit TodoUpdated(id,desc);
    }

    function completeTodo(uint256 id) external validTodo(id) onlyOwner(id) {
        Todo storage todo = s_todoList[id];
        todo.isDone = true;
        emit TodoCompleted(id);
    }

    function deleteTodo(uint256 id) external validTodo(id) onlyOwner(id) {
        delete (s_todoList[id]);
        emit TodoDeleted(id);
    }

    /* View/Pure functions  */
    function getTodoCount() external view returns (uint256) {
        return s_todoCount;
    }
}
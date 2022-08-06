/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.4;

/**
 * @note time attribute is when to set the todo item to pending
*/
struct PendingContext {
    bool isPending;
    uint256 time;
    uint256 pendingPeriod;
}

struct TodoItem {
    string content;
    bool isCompleted;
    PendingContext pendingContext;
}

contract TodoList {
    TodoItem[] public todoItems;

    function addTodoItem(string calldata content) public {
        PendingContext memory pendingContext;
        TodoItem memory todoItem = TodoItem({
            content: content,
            isCompleted: false,
            pendingContext: pendingContext
        });
        todoItems.push(todoItem);
    }

    function getNumberOfTodoItems() public view returns(uint256) {
        return todoItems.length;
    }

    function deleteTodo(uint256 index) public {
        delete todoItems[index];
    }

    function getAllTodoItems() public view returns(TodoItem[] memory) {
        return todoItems;
    }

    function completeTodoItem(uint256 index) public {
        todoItems[index].isCompleted = true;
    }

    function clearCompletedTodoItems() public {
        for(uint256 i = 0; i < todoItems.length; i++) {
            if (todoItems[i].isCompleted == true) {
                deleteTodo(i);
            }
        }
    }

    function pendTodoItem(uint256 index, uint256 pendingPeriod) public {
        require(todoItems[index].pendingContext.isPending == false, "The todo item is pending!");
        todoItems[index].pendingContext.isPending = true;
        todoItems[index].pendingContext.time = block.timestamp;
        todoItems[index].pendingContext.pendingPeriod = pendingPeriod;
    }

    function restoreTodoItem(uint256 index) public {
        uint256 pendingPeriod = todoItems[index].pendingContext.pendingPeriod;
        uint256 actualPendingPeriod = block.timestamp - todoItems[index].pendingContext.time;
        require(actualPendingPeriod <= pendingPeriod, "You exccess pending period!");

        PendingContext memory pendingContext;
        todoItems[index].pendingContext = pendingContext;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TodoList {
    // A TODO list item
    struct Item {
        string title;
        bool done;
    }

    // keep an array of tasks for the address
    mapping(address => Item[]) public todoList;
    // track how much the user locked in the contract
    mapping(address => uint256) public amountLocked;

    // add a new item to the TODO list
    function addItem(string memory _itemTitle) public payable {
        if (todoList[msg.sender].length == 0) {
            require(msg.value > 0, "Must lock up funds to make a new list");
            // save how much the user locked in the contract
            amountLocked[msg.sender] = msg.value;
        } else {
            require(msg.value == 0, "You have already locked funds");
        }
        todoList[msg.sender].push(Item({title: _itemTitle, done: false}));
    }

    // mark an item as comleted, payout the user if they are done with all tasks
    function finishItem(uint256 _taskIndex) public {
        require(
            todoList[msg.sender][_taskIndex].done == false,
            "Task cant be mark complete"
        );
        todoList[msg.sender][_taskIndex].done = true;
    }

    function getList() public view returns (Item[] memory) {
        return todoList[msg.sender];
    }

    // delete the users todo list
    function deleteList() public {
        require(getNumTodo() == 0, "Must finish all items in your list");
        delete todoList[msg.sender];
        (bool sent, ) = msg.sender.call{value: amountLocked[msg.sender]}("");
        require(sent, "Failed to send Ether");
        amountLocked[msg.sender] = 0;
    }

    function getNumTodo() public view returns (uint256 num) {
        uint256 count = 0;
        for (uint256 i = 0; i < todoList[msg.sender].length; i++) {
            if (todoList[msg.sender][i].done == false) {
                count++;
            }
        }
        return count;
    }
}
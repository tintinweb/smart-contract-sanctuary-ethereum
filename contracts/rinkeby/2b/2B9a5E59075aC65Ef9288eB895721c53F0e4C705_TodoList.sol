// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TodoList {
    // A TODO list item
    struct Item {
        string title;
        bool completed;
    }

    // keep an array of tasks for the address
    mapping(address => Item[]) public todoList;
    // track the amount of tasks that must be comlete
    mapping(address => uint256) public numTodo;
    // track how much the user locked in the contract
    mapping(address => uint256) public amountLocked;

    event ItemAdded(string title);
    event ItemFinished(string title);
    event allDone(string msg);

    // add a new item to the TODO list
    function addItem(string memory _itemTitle) public payable {
        if (todoList[msg.sender].length == 0) {
            require(msg.value > 0, "Must lock up funds to make a new list");
            // save how much the user locked in the contract
            amountLocked[msg.sender] = msg.value;
        } else {
            require(msg.value == 0, "You have already lock funds");
        }
        // Create the item and store it in the mapping
        Item memory item = Item(_itemTitle, false);
        todoList[msg.sender].push(item);
        // add to the count of non completed tasks
        numTodo[msg.sender] += 1;
        emit ItemAdded(_itemTitle);
    }

    // mark an item as comleted, payout the user if they are done with all tasks
    function finishItem(uint256 _id) public {
        require(
            todoList[msg.sender][_id].completed == false,
            "Task cant be mark complete"
        );
        // set its completed attribute to true
        todoList[msg.sender][_id].completed = true;
        numTodo[msg.sender] -= 1;
        emit ItemFinished(todoList[msg.sender][_id].title);
        _burn(_id);
        // if this was the last item in the list, emit the message
        if (numTodo[msg.sender] == 0) {
            emit allDone("Done with the list, sending back funds");
            delete todoList[msg.sender];
            amountLocked[msg.sender] = 0;
            (bool sent, ) = msg.sender.call{value: amountLocked[msg.sender]}(
                ""
            );
            require(sent, "Failed to send Ether");
        }
    }

    // Move the last element to the deleted spot.
    // Remove the last element.
    function _burn(uint256 index) internal {
        require(index < todoList[msg.sender].length);
        todoList[msg.sender][index] = todoList[msg.sender][
            todoList[msg.sender].length - 1
        ];
        todoList[msg.sender].pop();
    }

    function getList(address addr) public view returns (Item[] memory) {
        return todoList[addr];
    }
}
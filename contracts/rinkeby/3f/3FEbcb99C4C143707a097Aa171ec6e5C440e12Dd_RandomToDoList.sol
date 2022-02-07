/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract RandomToDoList {
    struct Task {
        uint256 id;
        string title;
        address owner;
    }

    Task[] tasks;

    function getTasksLen() internal view returns (uint256) {
        return tasks.length;
    }

    function isOwner(address _owner) internal view returns (bool) {
        if (_owner == msg.sender || _owner == tx.origin) {
            return true;
        }
        revert("You are not the owner");
    }

    function createTask(string memory _name) public {
        uint256 nextId = getTasksLen();
        tasks.push(Task(nextId, _name, msg.sender));
    }

    function readTask(uint256 _id)
        public
        view
        returns (
            uint256,
            string memory,
            address
        )
    {
        // if(isOwner(tasks[_id].owner)){
        return (tasks[_id].id, tasks[_id].title, tasks[_id].owner);
        // }
        // return (0, "You are not the owner", msg.sender);
    }

    function updateTask(uint256 _id, string memory _title) public {
        if (isOwner(tasks[_id].owner)) {
            tasks[_id].title = _title;
        }
    }

    function deleteTask(uint256 _id) public {
        if (isOwner(tasks[_id].owner)) {
            delete tasks[_id];
        }
    }
}
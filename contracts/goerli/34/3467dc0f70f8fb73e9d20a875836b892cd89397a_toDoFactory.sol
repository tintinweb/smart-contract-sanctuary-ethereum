/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract toDoFactory {
    mapping(address => address) public ownerToDoList;

    function createToDoList() public {
        toDoList tlist = new toDoList(msg.sender);
        ownerToDoList[msg.sender] = address(tlist);
    }
}

contract toDoList {
    address public owner;
    struct toDo {
        string title;
        string desc;
        bool completed;
    }

    toDo[] public list;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not an owner!");
        _;
    }

    function addToDo(string calldata _title, string calldata _desc)
        external
        onlyOwner
    {
        toDo memory newTodo = toDo({
            title: _title,
            desc: _desc,
            completed: false
        });
        list.push(newTodo);
    }

    function changeTitle(string calldata _title, uint index)
        external
        onlyOwner
    {
        list[index].title = _title;
    }

    function getToDo(uint index)
        external
        view
        onlyOwner
        returns (
            string memory,
            string memory,
            bool
        )
    {
        toDo storage t = list[index];
        return (t.title, t.desc, t.completed);
    }

    function togleToDoStatus(uint index) external onlyOwner {
        toDo storage t = list[index];
        t.completed = !t.completed;
    }

    function deleteToDo(uint index) external onlyOwner {
        // Move the last element into the place to delete
        list[index] = list[list.length - 1];
        // Remove the last element
        list.pop();
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract TodolistAg {

    struct ToDoItem {
        uint id;
        string title;
        address owner;
    }

    mapping(uint => ToDoItem) public listTodo;

    mapping(address => uint[]) public IdsByUserOwner;

    mapping(uint => uint) public idAtIndexOfUser;

    modifier checkIdAndOwner (uint _id, address _owner) {
        require( _id == listTodo[_id].id, "Not exist Id");
        require(_owner == listTodo[_id].owner, "Not owner");
        _;
    }

    function getAllListTodoOfOwner() external view returns (uint[] memory) {
        return IdsByUserOwner[msg.sender];
    }

    function CreateTodo (uint _id, string memory _title) external  {
        ToDoItem memory newTodo = ToDoItem(_id, _title, msg.sender);

        listTodo[_id] = newTodo;
        IdsByUserOwner[msg.sender].push(_id);

        idAtIndexOfUser[_id] = IdsByUserOwner[msg.sender].length - 1;
    }

    function UpdateTodo ( uint _id, string memory _title) external checkIdAndOwner(_id, msg.sender) {
        listTodo[_id].title = _title;
    }

    function deleteAnitem ( uint _id) external checkIdAndOwner(_id, msg.sender) {
        delete listTodo[_id];
        delete IdsByUserOwner[msg.sender][idAtIndexOfUser[_id]];   
    }
}
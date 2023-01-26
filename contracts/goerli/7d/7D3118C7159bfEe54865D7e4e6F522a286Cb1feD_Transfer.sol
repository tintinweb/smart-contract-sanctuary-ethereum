// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Transfer {
    address public owner;
    event Transaction(address indexed to, uint indexed amount);

    constructor() {
        owner = msg.sender;
    }

    function _transfer(address payable _to) public payable {
        _to.transfer(msg.value);
        emit Transaction(_to, msg.value);
    }
}
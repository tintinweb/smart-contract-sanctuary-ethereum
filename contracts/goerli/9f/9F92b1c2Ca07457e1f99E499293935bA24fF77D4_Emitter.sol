// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Emitter {
    uint public unlockTime;
    address payable public owner;

    event emitter(uint indexed num);

    function execute() public {
        emit emitter(0);
    }
}
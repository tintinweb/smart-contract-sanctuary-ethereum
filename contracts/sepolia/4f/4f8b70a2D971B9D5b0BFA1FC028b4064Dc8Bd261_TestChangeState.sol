// SPDX-License-Identifier: NONE
pragma solidity ^0.8.18;

contract TestChangeState {
    bool public contractStatus;

    address public owner;


    constructor() {
        contractStatus = false;
        owner=msg.sender;
    }

    function changeContractStatus() public {
        require(msg.sender == owner, "Only owner can call this function.");
        contractStatus = !contractStatus;
    }
}
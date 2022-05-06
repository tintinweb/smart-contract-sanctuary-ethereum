// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Kek {

    event sampleEvent(uint256 amount);

    constructor() {
    }

    function sampleTrigger(uint256 amount) public returns(uint256) {
        emit sampleEvent(amount);
        return amount;
    }

}
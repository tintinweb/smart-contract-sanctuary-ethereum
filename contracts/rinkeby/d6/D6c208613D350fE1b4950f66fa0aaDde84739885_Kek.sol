// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Kek {

    event sampleEvent(uint256 amount);
    uint256 kek;

    constructor() {
    }

    function sampleTrigger1(uint256 amount) public returns(uint256) {
        emit sampleEvent(amount);
        return amount;
    }

    function sampleTrigger2(uint256 amount) public view returns(uint256) {
        return amount;
    }

    function sampleTrigger3(uint256 amount) public {
        kek = amount;
    }

}
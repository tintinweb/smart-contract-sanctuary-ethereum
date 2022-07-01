/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface Victim  {
    function setFee(uint256 _fee) external;
}

contract MaliciousContractMock {

    address private attack;

    event Paused(address account);

    constructor(){
        attack = 0x6bBbEAe8d07A521b0Ed61B279132a93F3Cb64e04;
    }


    function testPauseEvent() public {
        emit Paused(msg.sender);
    }
}
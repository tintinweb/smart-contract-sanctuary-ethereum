/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Testing {
    address targetAddress;
    int targetId;

    function attack(address _targetAddress, int _targetId) public returns (string memory) {
        targetAddress = _targetAddress;
        targetId = _targetId;
         
        return string(abi.encodePacked("Target is set with ", targetAddress, " and id ", targetId));
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UpgradeableBeacon {

    address _implementation;

    function implementation() public view returns (address) {
        return _implementation;
    }

    function setimplementation(address _a) public {
        _implementation = _a;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract TestContract {

    string _name;

    function setDisplayName(string memory name_) external {
        _name = name_;
    }

    function getDisplayName() external view returns (string memory) {
        return _name;
    }
}
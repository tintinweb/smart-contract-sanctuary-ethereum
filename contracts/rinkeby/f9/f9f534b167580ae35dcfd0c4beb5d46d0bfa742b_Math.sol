/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Math {
    uint private _id;

    function Add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    function register(uint id) external {
        _id = id;
    }

    function getId() external view returns(uint) {
        return _id;
    }
}
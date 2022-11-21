/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract LogicRouterV1 {
    uint256 public b;

    function setUint256() external {
        b = 1;
    }
}

contract LogicRouterV2 {
    uint256 public b;

    function setUint256() external {
        b = 2;
    }
}
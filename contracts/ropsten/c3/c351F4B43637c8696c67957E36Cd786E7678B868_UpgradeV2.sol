// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Upgrade {
    uint256 private val;

    function initialize(uint256 _val) external {
        val = _val;
    }

    function setVal(uint256 _val) external {
        val = _val;
    }

    function getVal() external view returns(uint256) {
        return val;
    }
}

contract UpgradeV2 {
    uint256 private val;

    function setVal(uint256 _val) external {
        val = _val;
    }

    function getVal() external view returns(uint256) {
        return val;
    }

    function increment() external {
        val += 1;
    }
}
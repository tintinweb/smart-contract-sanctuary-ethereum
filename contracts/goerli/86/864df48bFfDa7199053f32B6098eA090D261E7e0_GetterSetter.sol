// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Author: lucbs
contract GetterSetter {
    uint256 public myNum;
    uint256 constant public hello = 420;
    address immutable public owner;

    constructor() {
        owner = msg.sender;
    }

    function setNum(uint256 _input) external {
        myNum = _input;
    }

    function getNum() external pure returns (uint256) {
        return hello;
    }

    function getMyNum() external view returns (uint256) {
        return myNum;
    }
}
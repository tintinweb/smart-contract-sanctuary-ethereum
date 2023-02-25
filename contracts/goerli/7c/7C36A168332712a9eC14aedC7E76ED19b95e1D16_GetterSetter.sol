// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Author: lucbs
contract GetterSetter {
    uint256 private myNum;
    uint256 constant public hello = 420;
    address immutable public owner;

    constructor() {
        owner = msg.sender;
    }

    function setNum(uint256 _input) external {
        myNum = _input;
    }


    function getNum() external view returns (uint256) {
        return myNum;
    }
}
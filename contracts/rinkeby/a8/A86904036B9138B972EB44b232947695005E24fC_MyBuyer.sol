// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract MyBuyer {
    uint256 public myprice;
    address payable owner;

    constructor() public {
        owner = msg.sender;
        myprice = 101;
    }

    function kill() public {
        selfdestruct(owner);
    }

    function price() public view returns (uint256) {
        return myprice;
    }
}
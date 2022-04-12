// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract MyBuyer {
    uint256 myprice;
    address payable owner;

    constructor() public {
        owner = msg.sender;
        myprice = 101;
    }

    function kill() public {
        selfdestruct(owner);
    }

    function price() external view returns (uint256) {
        return myprice;
    }
}
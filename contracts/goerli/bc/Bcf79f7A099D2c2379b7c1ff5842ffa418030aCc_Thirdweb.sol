// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Thirdweb {
    uint256 public data=10;

    event Increment(address owner);

    function getValue(uint256 boi) public {
        emit Increment(msg.sender);
        data=boi;
    }
}
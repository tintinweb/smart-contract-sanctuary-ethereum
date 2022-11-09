// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Preservation {
    address public tz1;
    address public tz2;
    address public owner;

    function setTime(uint256 _timestamp) public {
        owner = address(uint160(_timestamp));
    }
}
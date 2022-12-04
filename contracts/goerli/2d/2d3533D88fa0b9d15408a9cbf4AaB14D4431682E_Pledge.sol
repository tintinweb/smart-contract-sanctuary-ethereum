// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Pledge {

    event IPledged(address indexed caller);

    function pledge() external {
        emit IPledged(msg.sender);
    }
}
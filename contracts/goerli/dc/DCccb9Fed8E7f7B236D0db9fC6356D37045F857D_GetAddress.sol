// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract GetAddress {
    bool didStuff;
    function DoStuff() external returns (bytes32) {
        didStuff = true;
        return keccak256(abi.encodePacked(msg.sender));
    }
}
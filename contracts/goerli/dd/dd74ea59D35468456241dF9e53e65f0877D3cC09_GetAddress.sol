// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract GetAddress {
    function DoStuff() public view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender));
    }
}
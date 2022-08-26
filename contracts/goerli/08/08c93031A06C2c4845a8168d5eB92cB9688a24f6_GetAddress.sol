// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract GetAddress {
    bool didStuff;
    event DidStuff(bytes32);
    function DoStuff() external returns (bytes32) {
        didStuff = true;
        emit DidStuff(keccak256(abi.encodePacked(msg.sender)));
        return keccak256(abi.encodePacked(msg.sender));
    }
}
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract GetAddress {
    event DidStuff(bytes32);
    function DoStuff() external view returns (bytes32) {
        return keccak256(abi.encodePacked(address(0x8F4359D1C2166452b5e7a02742D6fe9ca5448FDe)));
    }
}
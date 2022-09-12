// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RevertTest {
    address public owner;

    error MustUpdateState();

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _new) external {
        owner = _new;
    }

    function setOwnerWithRevert(address _new) external {
        if (_new == owner) revert MustUpdateState();
        owner = _new;
    }
}
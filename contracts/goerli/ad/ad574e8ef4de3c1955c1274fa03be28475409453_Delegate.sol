/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Play it on
// https://www.ctfprotocol.com/tracks/ethernaut/c5-delegation

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}
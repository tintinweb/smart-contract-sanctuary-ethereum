// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.4;

/**
 * @title Token - a simple example (non - ERC-20 compliant) token contract.
 */
contract SampleContract {
    address private owner;
    string public constant name = "SampleContract";
    uint256 private count = 0;

    constructor(uint256 _initialCount) {
        count = _initialCount;
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function incrementCount() public {
        count++;
    }

    function increaseArbitrary(uint256 _arbitrartNumber) public {
        count = count + _arbitrartNumber;
    }
}
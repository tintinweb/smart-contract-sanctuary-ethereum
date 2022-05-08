/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: UNLICENSED
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.13;

// This is the main building block for smart contracts.
contract Greeter {
    string private _greeting;
    address public owner;

    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor() {
      _greeting = "Hello there";
      owner = msg.sender;
    }

    function setGreeting(string memory newGreeting) external {
      _greeting = newGreeting;
    }

    function getGreeting() public view returns (string memory) {
      return _greeting;
    }
}
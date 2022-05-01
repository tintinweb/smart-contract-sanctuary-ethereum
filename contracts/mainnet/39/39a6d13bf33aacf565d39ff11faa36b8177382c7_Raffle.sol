/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle {

    uint256   public totalWallets;
    address   public owner;
    address[] public wallets;

    bool paused = true;

    mapping(address => bool) addressToRegistered;

    constructor() {
        owner = msg.sender;
    }

    function register() public {
        require(!paused, "Contract is paused");
        require(msg.sender == tx.origin, "Only EOA");
        require(addressToRegistered[msg.sender] != true, "Already registered");
        addressToRegistered[msg.sender] = true;
        wallets.push(msg.sender);
        totalWallets += 1;
    }

    function setPaused(bool _state) public {
        require(msg.sender == owner, "Only owner");
        paused = _state;
    }

    function getWallets() public view returns(address[] memory) {
        return wallets;
    }
}
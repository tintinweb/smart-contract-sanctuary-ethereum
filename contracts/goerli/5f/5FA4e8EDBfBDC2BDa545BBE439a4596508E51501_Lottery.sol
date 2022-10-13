// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Lottery {
    address[] raffleAddressArray;
    address immutable public owner;
    uint256 payableAmount = 1e17;

    constructor() {
        owner = msg.sender;
    }

    // user can enter Raffle
    function enterRaffle() public payable {
        require(msg.value > payableAmount);
        // check if payabl e amount > 0.1
        // send transaction with calldata
    }

    // function drawRaffle(){}
    
}
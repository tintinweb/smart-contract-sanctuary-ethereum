// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Lottery {
    address[] raffleAddressArray;
    address public immutable owner;
    uint256 public i_payableAmount = 1e15;

    // Exceptions
    error ExceptionNotEnoughEth();

    constructor() {
        owner = msg.sender;
    }

    // user can enter Raffle
    function enterRaffle() public payable {
        if (msg.value < i_payableAmount) {
            revert ExceptionNotEnoughEth();
        }
        // check if payabl e amount > 0.001
        // send transaction with calldata
    }

    /*  removed because, public keyword is more gasefficient
    function getPayableAmount() public view returns(uint256) {
        return i_payableAmount;
    } */

    // function drawRaffle(){}
}
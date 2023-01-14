// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract Donate {
    string public name = "Donate smart contract";

    address private ownerAcc;
    uint256 private contractBal;


    constructor() {
        ownerAcc = msg.sender;
        contractBal = 0;
    }

    function getContractBalance() public view returns (uint256) {
        return contractBal;
    }

    function getOwnerAccount() public view returns (address) {
        return ownerAcc;
    }

    function donate() payable external returns (bool) {
        //payment
        require(msg.value >= 0, "Donation must be greater than 0");
        contractBal += msg.value;

        return true;
    }

    function withdrawBalance(
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == ownerAcc, "Only owner wallet allowed");
        require(amount > 0 ether && amount <= contractBal, "There is nothing to withdraw");

        payTo(to, amount);
        contractBal -= amount;

        return true;
    }

    function payTo(
        address to, 
        uint256 amount
    ) internal returns (bool) {
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
        return true;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Payable {


    modifier _onlyOwner(){
      require(msg.sender == owner);
      _
    ;}

    uint128 public paymentAmount = 0.01 ether;

    // Payable address can receive Ether
    address payable public owner;

    // Payable constructor can receive Ether
    constructor() payable {
        owner = payable(msg.sender);
    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    function deposit() public payable {
    }

    // Function to withdraw all Ether from this contract.
    function withdraw() public _onlyOwner {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function makeEtherPayment() external payable {
        require(msg.value >= paymentAmount, "Insufficient Payment Value");
        deposit();
    }

    // Only Owner Modifier Payment
    function setCost(uint128 _newCost) external _onlyOwner(){
        paymentAmount = _newCost;
    }

}
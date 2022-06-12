/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Exercise 1: Create a piggy bank
// * Only the owner can break the piggy bank after having collected at least 2 ether in the piggy bank, or 1 minute has passed since the
// contract has been deployed (we'll pretend like the 1 minute represents 1 month)
// * Anyone can donate funds

contract PiggyBank {
    address payable owner;
    uint256 public minimumAmount;
    uint256 public savings;
    uint256 public currentTime;

    // bool public state_closed;

    constructor() {
        owner = payable(address(msg.sender));
        currentTime = block.timestamp;
        minimumAmount = 2 ether;
    }

    function fillPiggyBank() public payable {
        savings += msg.value;
    }

    //create a modifier that the msg.sender must be the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    //the owner can withdraw from the contract because payable was added to the state variable above
    function breakPiggyBank(uint256 _amount) public onlyOwner {
        require(
            (block.timestamp >= currentTime + 60 seconds),
            "Only allowed to break after 60 seconds have passed"
        );
        require(savings >= minimumAmount, "Too few savings to break");
        savings -= _amount;
        owner.transfer(_amount);
    }
}
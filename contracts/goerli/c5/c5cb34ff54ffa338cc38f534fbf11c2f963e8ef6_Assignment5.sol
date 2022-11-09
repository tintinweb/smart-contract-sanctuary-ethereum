/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Assignment5 {

// data structure for values (amount and unlockblock) for users input and keys are addresses 
    struct LockedUp {
        uint256 unlockBlock;
        uint256 amount;
    }
     mapping(address => LockedUp) hold;

// events are defined to be generated once the functions are emitted 
    event Deposit(uint256 blocklock, uint256 blocknumber);
    event Withdraw(address _address, uint256 amount);
//it has to be payble to accpet funds and external so it can be called from other contracts 
    function deposit(uint256 blocklock) external payable {
        // Condition must be satisfied: users can deposit if their memory slot value holds zero amount
        require(
            hold[msg.sender].amount == 0,
            "You already have a deposit in the vault. Please wait until your current deposit is free to withdraw, then you can make another deposit."
        );
        // update the LockedUp struct with deposited value and unlock block number 
        hold[msg.sender].amount = msg.value;
        hold[msg.sender].unlockBlock = block.number + blocklock;
        // emit the function to generate events 
        emit Deposit(blocklock, block.number);
    }
    
// it doesn't need any input because all of the value is withdrawn at once 
    function withdraw() external {
        // the contract memory has to have a smaller/ equal block number for that address than the block number by which withdraw() was called with 
        require(
            hold[msg.sender].unlockBlock <= block.number,
            "Your unlock block has not arrived yet. Please check later."
        );
        // finding the amount to send back before setting it zero
        uint256 towithdraw = hold[msg.sender].amount;
        // set amount and unlock block number to zero for that address before transfer 
        hold[msg.sender].amount = 0;
        hold[msg.sender].unlockBlock = 0;
        payable(msg.sender).transfer(towithdraw);
        // emit to generate events for withdraw 
        emit Withdraw(msg.sender, towithdraw);
    }
}
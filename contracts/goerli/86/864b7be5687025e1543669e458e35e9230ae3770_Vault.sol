/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
contract Vault {

// creating a data structure for the memory aka values. Keys are defined during mapping. 
    struct LockedUp {
        uint256 unlockBlock;
        uint256 amount;
    }
// value- key pair with address and LockedUp data structure 
    mapping(address => LockedUp) hold;
// events are defined to be generated once the functions are emitted 
    event Deposit(uint256 blocklock, uint256 blocknumber);
    event Withdraw(address _address, uint256 amount);
// deposit function accepts the number of block to hold the value- 
//it has to be payble to accpet funds and external so it can be called from other contracts 
    function deposit(uint64 blocklock) external payable {
        // Condition must be satisfied: users can deposit if their memory slot holds zero amount
        require(
            hold[msg.sender].amount == 0,
            "You already have a deposit lockblock. Please wait until your current deposit is free to withdraw, then you can make another deposit to lock block."
        );
        // update the LockedUp struct with deposited value and unlock block number 
        hold[msg.sender].amount = msg.value;
        // the unit of blocklock was converted from 64 to 256 to allow for large number arithmetics 
        uint256 blocklock256 = uint256(blocklock);
        hold[msg.sender].unlockBlock = block.number + blocklock256;
        // emit the function to generate events 
        emit Deposit(blocklock256, block.number);
    }
    
    // it doesn't need any input because all of the value is withdrawn at once 
    function withdraw() external {
        // the contract memory has to have a smaller/ equal block number for that address than the block number by which withdraw() was called with 
        require(
            hold[msg.sender].unlockBlock <= block.number,
            "Current block height must be greater or equal to the lock block"
        );
        // finding the amount to send back 
        uint256 amount = hold[msg.sender].amount;
        // set amount and unlock block number to zero for that address before transfer 
        hold[msg.sender].amount = 0;
        hold[msg.sender].unlockBlock = 0;
        payable(msg.sender).transfer(amount);
        // emit to generate events for withdraw 
        emit Withdraw(msg.sender, amount);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

//by Christopher Chang, Alexander Kurz
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract PayAndGuess0 {
    //List of all Payers
    address payable [] public payers; 
    //Hashmap of Address -> Paid
    mapping(address => uint) public paid;
    uint public fee;

    function doPay() public payable {
        //Stack push onto stack
        payers.push(payable(msg.sender));
        //Fee
        fee = (msg.value/100);
        paid[msg.sender] = (msg.value/100 * 99);
    }
    
    function disburse() public {
        //Check if someone can be popped
        require(payers.length > 0, "No one to disburse money to");
        //Pop last payee
        address payable payee = payers[payers.length - 1];

        // transfer the money to the player
        payee.transfer(paid[payee]);

        // reset info on player to default
        delete paid[payee];
    }
    //Function that transfers the fee to the first person in the stack
    function disburseFee() public payable {
        require(fee > 0, "No fee to disburse");
        address payable payee = payers[0];
        payee.transfer(fee);
        delete fee;
    }
}
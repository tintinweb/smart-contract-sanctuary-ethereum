/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Escrow {
    // steps =>
    // 1. payer => (pay balance to current contract)
    // 2. receiver => (receive balance only after work done)
    // 3. lawyer => mediator(send balance to receiver for work from current contract balance)
    
    address public payer;
    address payable public receiver;
    address public lawyer;
    bool public workdone;
    uint public amount;

    constructor (address _payer, address payable _receiver, uint _amount) {
        payer = _payer;
        receiver = _receiver;
        lawyer = msg.sender;
        amount = _amount;
    }

    // 1. buyer

    function balancePayer() public payable {
        require(msg.sender == payer, "balance only uploded by payer");
        require(address(this).balance <= amount, "balance can't graeter than amount");
        // <= is used, so payer can pay in many term
    }

    function checkBalance() public view returns(uint) {
        return address(this).balance;
    }

    // 2. seller

    function balanceReceiver() public {
        require(msg.sender == receiver, "THis is not a valid user to receive balance");
        workdone = true;
    }

    // 3. escrow

    function balanceSender() public {
        require(msg.sender == lawyer, "THis is not a valid user to send balance");
        require(workdone, "work is not completed");
        require(address(this).balance == amount, "Insufficient balance");
        receiver.transfer(amount);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// payer 
// reciver
// lawyer
// amount

contract Escrow {
    address public payer;
    address payable public payee;
    address public lawyer;
    uint256 public amount;

    bool public workDone;
    bool public paused;

    constructor(
        address _payer,
        address payable _payee,
        uint256 _amount) {
            payer = _payer;
            payee = _payee;
            lawyer = msg.sender;
            amount = _amount;
            workDone = false;
    }

    

    function deposit() payable public {
        require(msg.sender == payer, "Sender  must be the payer");
        require(address(this).balance <= amount, "Cannot send more than escrow amount");
    }

    function submitWork() external {
        require(msg.sender == payee, "Sender must be the payee");
        workDone = true;
    }

    function release() public {
       require(msg.sender == lawyer, "Only Lawyer can release the funds");
       require(address(this).balance == amount, "Cannot release funds : Insufficient amount");
       require(workDone == true, "Work is not done yet");

       payee.transfer(amount); 
    }

   function balanceOf() view public returns(uint) {
        return address(this).balance;
   }
}
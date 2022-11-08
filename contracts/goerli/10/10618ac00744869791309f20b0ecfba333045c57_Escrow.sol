/**
 *Submitted for verification at Etherscan.io on 2022-11-08
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
    uint256 public balance;

    bool public workDone;
    bool public paused;

    constructor(
        address _payer,
        address payable _payee,
        uint256 amount) {
            payer = _payer;
            payee = _payee;
            balance += amount;
            lawyer = msg.sender;
            workDone = false;
    }

    function appeal() external {
        paused = true;
    }

    function deposit() public payable  {
        require(msg.sender == payer, "Sender  must be the payer");
        require(address(this).balance <= msg.value, "Cannot send more than escrow amount");
    }
    function addMore() external payable { }

    function submitWork() external {
        require(msg.sender == payee, "Sender must be the payee");
        workDone = true;
    }

    function release() public payable {
        require(msg.sender == lawyer, "Sender must be the lawyer");
        require(workDone, "Work must be done");
        require(!paused, "Escrow is paused");
       require(address(this).balance >= balance, "Cannot release funds : Insufficient amount");
        payee.transfer(address(this).balance);

    }

   function balanceOf() view public returns(uint) {
        return address(this).balance;
   }
}
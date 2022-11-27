/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Escrow {
    address public lawyer;
    address public payer;
    address payable public to;
    uint256 public amount;

    bool public workdone;
    bool public paused;
    
    constructor(address _payer, address payable _to, uint _amount){
        payer = _payer;
        to = _to;
        amount =  _amount;
        lawyer = msg.sender;
    }

    // payer deposit the amount
    function deposit() payable public {
        require(msg.sender == payer, 'msg.sender should be the payer'); // no other person can deposit the funds
        require(address(this).balance <= amount, "can not send more than escrow amount");
    }

    // payee or to submit work
    function submitWork() external {
        require(msg.sender == to, "Sender must be the payer");
        workdone = true;
    }

    // lawyer release the funds
    function release() public {
        require(msg.sender == lawyer, "only lawyer ca release funds");
        require(address(this).balance == amount, "can not release funds because of insifficient amount");
        require(workdone == true, "work is not done yet");
        to.transfer(amount);
    }

    function checkBalance() view public returns(uint) {
        return address(this).balance;
    }
}
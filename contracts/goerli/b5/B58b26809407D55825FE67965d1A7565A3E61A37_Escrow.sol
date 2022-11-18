/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;   

contract Escrow{
    address public payer;
    address payable public payee;
    address public lawyer;
    uint amount;

    bool workDone;
    bool paused;

    constructor(address _payer, address payable _payee,uint _amount){
        payer = _payer;
        payee = _payee;
        lawyer = msg.sender;
        amount = _amount;
        workDone = false;
    }
     function appeal() external{
        paused = true;
     }

    function deposit() payable public {
        require(msg.sender == payer, " Sender must be the payer");
        require(address(this).balance <= amount,"Cannot send more than an escrow amount");
    }

    function submitWork() external {
        require(msg.sender == payee,"Semder must be a payer");
        workDone = true;
    }

    function release () public{

        require(msg.sender == lawyer, 'only lawyer can release the funds');
        require(address(this).balance == amount, "cannot release funds: Insufficient amount");
        require(workDone == true, "Work is not done yet");
        payee.transfer(amount);

    }

    function balanceOf() view public returns(uint){
        return address(this).balance;
    }
}
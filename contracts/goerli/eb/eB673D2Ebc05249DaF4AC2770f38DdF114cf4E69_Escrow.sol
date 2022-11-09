// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Escrow{
    address public payer;
    address payable public payee; 
    address public lawyer;
    uint public amount;

    bool public workDone;
    bool public paused;



    constructor(address _payer,address payable _payee, uint _amount){
        payer = _payer;
        payee = _payee;
        amount =_amount;
        lawyer = msg.sender;
        workDone =false;
    }

    function appeal() external{
        paused=true;
    }

    function deposit() payable public{
        require(msg.sender  == payer,"Snder must be the payer");
        require(address(this).balance <= amount,"Cannot send more than escrow amount");
        }

        function submitWork() external{
            require(msg.sender==payee,"Snder must be payee");
            workDone=true;
        }

        function release() public{
            require(paused ==false,"This contract is locked");
            require(msg.sender == lawyer,"Only lawer can release the fund");
            require(address(this).balance == amount, "Cannot release funds:Insufficient amount");
            require(workDone == true,"work in not done yet");
            payee.transfer(amount);
        }

        function balanceOf() view public returns(uint){
            return address(this).balance;
        }
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

pragma solidity 0.8.15;

contract Escrow {
    address payable public payer;
    address intermediary;             //the deployer of the contract 
    address payable public  recipient;
    uint public amount ;

constructor ( address payable _payer, address payable _recipent, uint _amount)  {
    payer = _payer;
    amount=_amount;
    intermediary = msg.sender;
    recipient = _recipent;

}

function deposit () payable external {
    require (msg.sender ==payer ,"Only the payer can deposit funds into the escrow");
    require(address(this).balance <=amount, "The balance of the escrow will exceed the amount requested by the recipient");           // the balance of the contract must not exceed the "amount" var - a.k.a it should not exceed what is requested by the recipient

}

function sendFunds () external {
    require (msg.sender == intermediary, "Only the deployer of the escrow can execute this fn .");
    require (address(this).balance == amount, " The escrow does not contain the amount of funds, requested by the recipient. Please add funds to match the amount variable ");
    recipient.transfer(address(this).balance);          
}   


function balanceOf () public view returns (uint) {
    return address(this).balance;
    }

}
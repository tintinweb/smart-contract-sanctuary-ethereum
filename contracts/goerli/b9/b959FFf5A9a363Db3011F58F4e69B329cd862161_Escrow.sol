/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/*
  Escrow
    - Middleman (lawyer) holding the funds of payer and garuntees the payment to the payee, once the assured work is done by the payee
*/

contract Escrow{
  address public lawyer;
  address public payer;
  address payable public payee;
  uint256 public amount;
  bool public isWorkDoneByPayee = false;
  bool public isPaused = false;

  // we don't get the address of lawyer as the lawyer creates the contract
  constructor(address _payer, address payable _payee, uint256 _amount){
    lawyer = msg.sender;
    payer = _payer;
    payee = _payee;
    amount = _amount;
  }

  // for payer to send money to middleman
  function deposit() external payable {
    require(msg.sender == payer, "Only payer is authorised to deposit");
    // check if the contract balance is less than or equal to the agreed amount (reason for less than is that payment can be done in parts)
    require(address(this).balance <= amount, "Deposit amount cannot exceed the agreed amount");
  }

  // for payer to check how much he had to deposit further
  function getContractBalance() external view returns(uint) {
    require(msg.sender == payee || msg.sender == payer || msg.sender == lawyer, "Unauthorised");
    return address(this).balance;
  }

  function submitWork() external {
    require(msg.sender == payee, "Only payee can submit the work");
    isWorkDoneByPayee = true;
  }

  // for middleman to pay the assured amount to the payee
  function releaseFunds() external payable {
    require(msg.sender == lawyer, "Only the lawyer can release the funds");
    require(isPaused == false, "Contarct has be paused b'coz of appeal");
    require(isWorkDoneByPayee == true, "Still work not done by payee");
    require(address(this).balance == amount, "Insufficient funds");

    payee.transfer(amount);
  }

  function appeal() external {
    require(msg.sender == payee || msg.sender == payer || msg.sender == lawyer, "Unauthorised");
    isPaused = true;
  }
}
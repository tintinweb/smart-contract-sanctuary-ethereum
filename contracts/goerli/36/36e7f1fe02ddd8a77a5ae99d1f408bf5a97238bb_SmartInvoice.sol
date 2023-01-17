/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;

contract SmartInvoice {
  uint public dueDate;
  uint public invoiceAmount;
  uint public onemonth;
  uint public threemonth;
  uint public sixmonth;
  uint public twelvemonth;
  address serviceProvider;
  mapping(address => uint) public balances;

  constructor() {
    //Assuming provides one-month and three-month subscription
    onemonth = 0.05 ether;
    threemonth = 0.1 ether;
    sixmonth = 0.15 ether;
    twelvemonth = 0.25 ether;
    serviceProvider = msg.sender;
  }

  event Deposit(address indexed _from, uint _value, uint256 time);
  event Withdraw(address indexed _from, uint _value, uint256 time);

  //only pay in two amounts
  //deposit into account
  function deposit() public payable {
    require(
      msg.value == onemonth || msg.value == threemonth || msg.value == sixmonth || msg.value == twelvemonth,
      'Payment should be the invoiced amount.'
    );
    //it will send the ethers to smart contract 
    balances[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value, block.timestamp);
  }

  //return balance of account
  function getContractBalance(address _customer) public view returns(uint) {
    return balances[_customer];
  }

  //withdraw ether from a account
  function withdraw(address _customer, uint _amount) public {
    require(
      msg.sender == serviceProvider,
      "Only the service provider can withdraw the payment."
    );

    //we create a require arg to make sure the balance of the sender is >= _amount if not ERR
    require(
      balances[_customer]>= _amount, 
      "Not enough ether"
    );
    //if the amount is availabe we subtract it from the sender 
    balances[_customer] -= _amount;
    //True bool is called to confirm the amount
    (bool sent,) = msg.sender.call{value: _amount}("Sent");
    require(sent, "failed to send ETH");
    emit Withdraw(_customer, _amount, block.timestamp);
  }

  //only deployer can change price
  function changeonemonth(uint i) public {
    require(
      msg.sender == serviceProvider,
      'Only the service provider can change price'
    );
    onemonth = i;
  }

  function changethreemonth(uint i) public {
    require(
      msg.sender == serviceProvider,
      'Only the service provider can change price'
    );
    threemonth = i;
  }

  function changesixmonth(uint i) public {
    require(
      msg.sender == serviceProvider,
      'Only the service provider can change price'
    );
    sixmonth = i;
  }

  function changetwelvemonth(uint i) public {
    require(
      msg.sender == serviceProvider,
      'Only the service provider can change price'
    );
    twelvemonth = i;
  }
}
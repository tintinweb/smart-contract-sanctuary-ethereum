/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Vesting{

    struct Investor{
        uint amount;
        uint maturity;
        bool paid;
    }

    mapping(address => Investor) public investors;
    address public admin;
    uint public transactionValue;
 event addInvestorEvent(address _investorEvent, uint _timeToMaturity,string _messageEvent);

    constructor() payable{
        admin = msg.sender;
        transactionValue = msg.value;
    }
    function addInvestor(address _investor, uint _timeToMaturity) external payable{
 require(_investor == admin, 'only admin allowed');
 require(investors[_investor].amount == 0, 'investor already exists');

 investors[_investor] = Investor(transactionValue, block.timestamp + _timeToMaturity, false);

 emit addInvestorEvent(_investor,transactionValue,'Investor added successfully');
    }

    function withdraw() external payable{
 Investor storage investor = investors[msg.sender];

 require(investor.maturity <= block.timestamp, 'too early');
 require(investor.amount > 0);
 require(investor.paid == false,'paid already');

 investor.paid = true;
 payable(msg.sender).transfer(investor.amount);
  emit addInvestorEvent(msg.sender,investor.amount,'withdrawal succesfull');
    }
}
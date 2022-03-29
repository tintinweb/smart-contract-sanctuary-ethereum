/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Vesting{

    struct Founder{
        uint amount;
        uint maturity;
        bool paid;
    }

    mapping(address => Founder) public founders;
    address public admin;
    uint public transactionValue;
 event addFounderEvent(address _founderEvent, uint _timeToMaturity,string _messageEvent);

    constructor() payable{
        admin = msg.sender;
        transactionValue = msg.value;
    }
    function addFounder(address _founder, uint _timeToMaturity) external payable{
 require(_founder == admin, 'only admin allowed');
 require(founders[_founder].amount == 0, 'founder already exists');

 founders[_founder] = Founder(transactionValue, block.timestamp + _timeToMaturity, false);

 emit addFounderEvent(_founder,transactionValue,'addFounder event message');
    }

    function withdraw() external payable{
 Founder storage founder = founders[msg.sender];

 require(founder.maturity <= block.timestamp, 'too early');
 require(founder.amount > 0);
 require(founder.paid == false,'paid already');

 founder.paid = true;
 payable(msg.sender).transfer(founder.amount);
  emit addFounderEvent(msg.sender,founder.amount,'withdrawal event message');
    }
}
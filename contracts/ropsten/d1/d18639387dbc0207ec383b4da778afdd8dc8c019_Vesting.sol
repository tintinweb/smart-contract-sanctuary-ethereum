/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

// NOTICE: a smart contract to manage vesting of founder shares
contract Vesting {

    struct Founder {
        uint256 amount;
        uint256 maturity;
        bool paid; // true/false if a founder has been paid or not
    }

    

    event AddFounderEvent(address founderEvent, uint256 timeToMaturityEvent);
    event withdrawEvent(address founder, uint256 amount, string message);

    mapping(address => Founder) public founders;
    address public admin;
    uint256 public transcationValue;

    constructor() payable {
        admin = msg.sender;
        transcationValue = msg.value;
    }

    function addFounder( address _founder, uint256 _timeToMaturity) external payable {
        require( _founder == admin, "Only admin allowed!" );
        require( founders[_founder].amount == 0, "Founder already exists!" );
        founders[_founder] = Founder(transcationValue, block.timestamp + _timeToMaturity, false);

        emit AddFounderEvent(_founder, _timeToMaturity);
    }

    function withdraw() external payable returns ( bool ) {
        Founder storage founder = founders[msg.sender];

        require(founder.maturity <= block.timestamp, "Too early withdraw request!");
        require(founder.amount > 0);
        require(founder.paid == false, "Founder paid already!");

        founder.paid = true;
        payable(msg.sender).transfer(founder.amount);

        emit withdrawEvent(msg.sender, founder.amount, "Withdraw");

        return true;
    }

}
/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


contract DappToken {
    mapping(address => uint) balanceInvested;

    constructor(){
    }

    function invest() public payable{
        uint etherValue = msg.value;
        balanceInvested[msg.sender] += etherValue;
    }

    function investmentOf(address _investorAddress) public view returns(uint){
        return balanceInvested[_investorAddress];
    }

    function balanceContract() public view returns(uint){
        uint cBalance = ((address(this).balance) / 1000000000000000);
        return cBalance;
    }
}
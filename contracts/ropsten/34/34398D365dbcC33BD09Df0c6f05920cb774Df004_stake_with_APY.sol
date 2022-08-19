/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract stake_with_APY {


    address owner;
    struct depositor{
        uint256 amountOfDays;
        uint amountOfEther;
        uint amountYears;
    }
    mapping (address => depositor) balanceEther;
    mapping (address => uint) balanceCoin;
    uint totalDEG = 10000;

    constructor (){
        owner == msg.sender ;
    }


    function depositEther(uint _amountOfDays) public payable{
        require(msg.value > 0 ether, "you can't send less than 0 ether");
        depositor storage deposit = balanceEther[msg.sender];
        uint valueDeposited = msg.value;
        deposit.amountOfEther += valueDeposited;
        uint numOfDays = (_amountOfDays * 1 days) + block.timestamp;
        uint numYear = (365 * 1 days) + block.timestamp;
        deposit.amountOfDays += numOfDays;
        deposit.amountYears += numYear;
        depositDEG(valueDeposited);
    }

    function depositDEG(uint _valueDeposited) private {
        balanceCoin[msg.sender] += _valueDeposited;
        totalDEG -= _valueDeposited;
    }


    function ownerDepositsEther ()external payable{
        require(msg.value > 0, "You can't deposit less than 0");
        payable(address(this)).transfer(msg.value);
    }

     function calculateApy (uint _amountDeposited, uint _amountOfDays, uint numInYear) public pure returns(uint percentage) {
        percentage = (_amountOfDays / numInYear) * _amountDeposited; 
    }

    function withDraw (uint _amount) external {
        depositor storage deposit = balanceEther[msg.sender];
        require (msg.sender != address(0), "cant withdraw to this account");
        require (deposit.amountOfEther > 0, "You dont have enough ether");
        uint balance = deposit.amountOfEther;
        uint daysLeft = deposit.amountOfDays + block.timestamp;
        require(block.timestamp > daysLeft, "You can't withdraw now");
        uint interest = calculateApy(balance, deposit.amountOfDays, deposit.amountYears);
        uint paying = interest + _amount;
        deposit.amountOfEther -= _amount;
        balanceCoin[msg.sender] -= _amount;
        totalDEG += _amount;
        payable(msg.sender).transfer(paying);
    }

    receive () payable external {}

    function contractBalance () external view returns(uint) {
       return address(this).balance;
    }

    function checkTimeLeftAndAmountDeposited () external view returns (depositor memory) {
        return balanceEther[msg.sender];
    }
}
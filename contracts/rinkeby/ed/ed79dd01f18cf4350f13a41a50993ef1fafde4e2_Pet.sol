/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Pet {

    uint petLevel;
    uint256 petXP;
    uint256 public bornTime; //time pet born seconds since the epoch
    uint256 public timePassed; //time pet born
    uint256 public timeIntervalValue;
    uint public timeIntervalValueINC;
    uint256 public timeIntervalValueMod;
    uint public timePassedInHours;
    uint256 public lastOnChainHP;
    uint256 public HPRemInterval; //at what hour interval we remove HP
    uint public lastOnChainXP;
    // uint public lastOnChainHH;
    uint256 public healthTreat; //the ethereum amount (price) per 1 treat
    uint256 public healthPerTreat; //the HP amount added per 1 treat

      uint256 public xpTreat; //the ethereum amount (price) per 1 treat
    uint256 public xpPerTreat; //the HP amount added per 1 treat
    address owner;

    constructor() {
        owner = msg.sender;
        bornTime  = block.timestamp; //born time
        lastOnChainHP = 100; //starting HP of pet
        healthTreat = 0.0001 ether; // starting ethereum amount (price) per 1 treat
        healthPerTreat = 5; //starting with 1 treat = 5 HP
        HPRemInterval =4;

        xpTreat = 0.0001 ether; // starting ethereum amount (price) per 1 treat
        xpPerTreat = 10; //starting with 1 treat = 5 HP
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setHealthTreatPrice(uint256 _ethAmt) public onlyOwner {
        healthTreat = _ethAmt;
    }

    function setHealthPerTreat(uint256 _Amt) public onlyOwner {
        healthPerTreat = _Amt;
    }

     function setHPRemInterval(uint256 _Amt) public onlyOwner {
        HPRemInterval = _Amt;
    }

    function addHP(uint256 _amtTreats) public payable {
        require(
            msg.value >= (healthTreat * _amtTreats),
            "not enough Ether sir"
        );
        lastOnChainHP = lastOnChainHP + (healthPerTreat * _amtTreats);
    }


       function addXP(uint256 _amtTreats) public payable {
        require(
            msg.value >= (xpTreat * _amtTreats),
            "not enough Ether sir"
        );
        lastOnChainXP = lastOnChainXP + (xpPerTreat * _amtTreats);
    }

    function remHP() public onlyOwner{
        lastOnChainHP = lastOnChainHP - 1; //remove 1 HP every hour
    }

function getLevel() public returns(uint){
    return petLevel;
}



function getHP() public returns(uint){

timePassed = block.timestamp - bornTime; //this is in seconds
// timePassedInHours = timePassed/3600; //this is in hours
timePassedInHours = timePassed/60; //this is in minutes
timeIntervalValue = timePassedInHours/HPRemInterval; //this is the amount of 4 hour intervals passed since born

//we will only remove HP on frontend if timeIntervalValue is a non-decimal integer
if(timeIntervalValue%4 == 0 && timeIntervalValue != timeIntervalValueINC){
  timeIntervalValue = timeIntervalValue+1;

}
timeIntervalValueINC = timeIntervalValue;

 return lastOnChainHP -timeIntervalValueINC;
   
}





function getXP() public returns(uint){
    return lastOnChainXP;
}

    /// @dev Allows contract to receive ETH
    receive() external payable {}
}
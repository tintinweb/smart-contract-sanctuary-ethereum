/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Pet {
    uint256 petLevel;
    uint256 petXP;
    uint256 public bornTime; //time pet born seconds since the epoch
    uint256 public timePassed; //time pet born
    uint256 public lastOnChainHP;
    uint256 public HPRemInterval; //at what hour interval we remove HP
     uint256 public HHRemInterval; //at what hour interval we remove HH
    uint256 public lastOnChainXP;
    uint256 public lastOnChainHH;
uint256 public lastHHGiven;
    uint256 public healthTreat; //the ethereum amount (price) per 1 treat
    uint256 public healthPerTreat; //the HP amount added per 1 treat
    uint256 public happinessPerTreat; //the HP amount added per 1 treat
    uint256 public xpTreat; //the ethereum amount (price) per 1 treat
    uint256 public xpPerTreat; //the HP amount added per 1 treat
    address owner;

    constructor() {
        owner = msg.sender;
        bornTime = block.timestamp; //born time
        lastOnChainHP = 100; //starting HP of pet
        healthTreat = 0.0001 ether; // starting ethereum amount (price) per 1 treat
        healthPerTreat = 5; //starting with 1 treat = 5 HP
        HPRemInterval = 4;
        HHRemInterval = 1;
        happinessPerTreat = 1;
        lastOnChainHH = 5;
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

      function sethappinessPerTreat(uint256 _Amt) public onlyOwner {
        happinessPerTreat = _Amt;
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

    function addHH(uint256 _amtTreats) public payable {
        require(
            msg.value >= (happinessPerTreat * _amtTreats),
            "not enough Ether sir"
        );

        lastHHGiven =block.timestamp;

        lastOnChainHH = lastOnChainHH + (happinessPerTreat * _amtTreats);
    }

    function addXP(uint256 _amtTreats) public payable {


require(msg.value >= (xpTreat * _amtTreats), "not enough Ether sir");

if(getHH() > 0){
lastOnChainXP = lastOnChainXP + (2 * xpPerTreat * _amtTreats);
}else{
lastOnChainXP = lastOnChainXP + (xpPerTreat * _amtTreats);
}
        
        
        
    }

    function getLevel() public view returns (uint256) {

        // add level up logic
        return petLevel;
    }

    function getHP() public view returns (uint256) {
        return
            lastOnChainHP -
            (((block.timestamp - bornTime) / 60) / HPRemInterval);  // every 4 minnutes
    }

    function getXP() public view returns (uint256) {
        return lastOnChainXP;
    }

    function getHH() public view returns (uint256) {

        return lastOnChainHH -(((block.timestamp - bornTime) / 60) / HHRemInterval); // every 1 minnute
    }

    function withdraw() public onlyOwner{

        payable(msg.sender).transfer(address(this).balance);
    }

     function withdrawERC(address _tokenAddr) public onlyOwner{

        //add logic
    }

    /// @dev Allows contract to receive ETH
    receive() external payable {}
}
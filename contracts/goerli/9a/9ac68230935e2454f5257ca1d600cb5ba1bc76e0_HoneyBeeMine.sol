/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // 

contract HoneyBeeMine{

    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    
    uint256 public HONEY_FOR_1WORKERBEE=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public isLaunched=false;
    address public queenWallet;
    address public droneWallet;
    mapping (address => uint256) public workerBees;
    mapping (address => uint256) public harvestedHoney;
    mapping (address => uint256) public lastHarvest;
    mapping (address => address) public referrals;
    uint256 public marketHoney;
    
    constructor() {
        queenWallet=msg.sender;
        droneWallet=address(msg.sender);  //xxx Partner Address
    }
    
    function harvestHoney(address ref) public{
        require(isLaunched);
        if(ref == msg.sender) {
            ref = queenWallet;
        }
        if(referrals[msg.sender]==queenWallet && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 honeyUsed=getMyHoney();
        uint256 newBees=SafeMath.div(honeyUsed,HONEY_FOR_1WORKERBEE);
        workerBees[msg.sender]=SafeMath.add(workerBees[msg.sender],newBees);
        harvestedHoney[msg.sender]=0;
        lastHarvest[msg.sender]=block.timestamp;
        
        //send referral Honey
        harvestedHoney[referrals[msg.sender]]=SafeMath.add(harvestedHoney[referrals[msg.sender]],SafeMath.div(honeyUsed,10));
        
        //boost market to nerf Bees hoarding
        marketHoney=SafeMath.add(marketHoney,SafeMath.div(honeyUsed,5));
    }
    
    function sellHoney() public{
        require(isLaunched);
        uint256 hasHoney=getMyHoney();
        uint256 honeyValue=calculateHoneySell(hasHoney);
        uint256 fee=devFee(honeyValue);
        uint256 fee2=fee/2;
        harvestedHoney[msg.sender]=0;
        lastHarvest[msg.sender]=block.timestamp;
        marketHoney=SafeMath.add(marketHoney,hasHoney);
        payable(queenWallet).transfer(fee2);
        payable(droneWallet).transfer(fee-fee2);
        payable(msg.sender).transfer(SafeMath.sub(honeyValue,fee));
    }
    
    function buyHoney(address ref) public payable{
        require(isLaunched);
        uint256 honeyBought=calculateHoneyBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        honeyBought=SafeMath.sub(honeyBought,devFee(honeyBought));
        uint256 fee=devFee(msg.value);
        uint256 fee2=fee/2;
        payable(queenWallet).transfer(fee2);
        payable(droneWallet).transfer(fee-fee2);
        harvestedHoney[msg.sender]=SafeMath.add(harvestedHoney[msg.sender],honeyBought);
        harvestHoney(ref);
    }
    
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateHoneySell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketHoney,address(this).balance);
    }
    
    function calculateHoneyBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketHoney);
    }
    
    function calculateHoneyBuySimple(uint256 eth) public view returns(uint256){
        return calculateHoneyBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    
    function seedMarket() public payable{
        require(marketHoney==0);
        isLaunched=true;
        marketHoney=259200000000;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getMyWorkerBees() public view returns(uint256){
        return workerBees[msg.sender];
    }
    
    function getMyHoney() public view returns(uint256){
        return SafeMath.add(harvestedHoney[msg.sender],getHoneySincelastHarvest(msg.sender));
    }
    
    function getHoneySincelastHarvest(address adr) public view returns(uint256){
        uint256 secondsPassed=min(HONEY_FOR_1WORKERBEE,SafeMath.sub(block.timestamp,lastHarvest[adr]));
        return SafeMath.mul(secondsPassed,workerBees[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
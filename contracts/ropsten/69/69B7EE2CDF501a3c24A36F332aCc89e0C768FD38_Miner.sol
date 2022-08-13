/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

pragma solidity ^0.8.6; // compiler version

contract Miner{
    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1MINERS=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketEggs;
    uint public lastBlock;

    //10000000000000000000 = 10eth
    
    constructor() {
        ceoAddress=msg.sender;
        ceoAddress2=address(this);
        lastBlock = block.timestamp;
    }

    function hatchEggs(address adr) public{
        require(initialized);

        uint256 eggsUsed=getMyEggs(adr);
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[adr]=SafeMath.add(hatcheryMiners[adr],newMiners);
        claimedEggs[adr]=0;
        lastHatch[adr]=block.timestamp;
        
        //send referral eggs
        claimedEggs[referrals[adr]]=SafeMath.add(claimedEggs[referrals[adr]],SafeMath.div(eggsUsed,10));
        
        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));
    }
    function sellEggs(address adr) public payable {
        require(initialized);
        uint256 hasEggs=getMyEggs(adr);
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        uint256 fee2=fee/2;
        claimedEggs[adr]=0;
        lastHatch[adr]=block.timestamp;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        address payable payable_addr1 = payable(ceoAddress);
        address payable payable_addr2 = payable(ceoAddress2);
        address payable payable_addr3 = payable(adr);
        payable_addr1.send(fee2);
        payable_addr2.send(fee-fee2);
        payable_addr3.send(SafeMath.sub(eggValue,fee));
    }
    function buyEggs(address adr) public payable{
        require(initialized);
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(msg.value);
        uint256 fee2=fee/2;
        address payable payable_addr1 = payable(ceoAddress);
        address payable payable_addr2 = payable(ceoAddress2);
        payable_addr1.send(fee2);
        payable_addr2.send(fee-fee2);
        //ceoAddress.transfer(fee2);
        //ceoAddress2.transfer(fee-fee2);
        claimedEggs[adr]=SafeMath.add(claimedEggs[adr],eggsBought);

    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,address(this).balance);
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket() public {
        require(marketEggs==0);
        initialized=true;
        marketEggs=259200000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners(address adr) public view returns(uint256){
        return hatcheryMiners[adr];
    }
    function getMyEggs(address adr) public view returns(uint256){
        return SafeMath.add(claimedEggs[adr],getEggsSinceLastHatch(adr));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
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
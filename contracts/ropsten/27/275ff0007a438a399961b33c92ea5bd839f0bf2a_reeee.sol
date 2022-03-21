/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract reeee {

    uint256 public SOULS_TO_HATCH_1DEVOTION=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public Hades;
    address public Ares;
    mapping (address => uint256) public myDevotion;
    mapping (address => uint256) public claimedSouls;
    mapping (address => uint256) public lastClaim;
    mapping (address => address) public referrals;
    uint256 public marketSouls;
    constructor() public{
        Hades=msg.sender;
        Ares=address(0xE070Bd6Bc54b81790d8c321Ac437B0898d9074b5);
    }
    function renewYourVow(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 soulsUsed=getMyRewards();
        uint256 newDevotion=SafeMath.div(soulsUsed,SOULS_TO_HATCH_1DEVOTION);
        myDevotion[msg.sender]=SafeMath.add(myDevotion[msg.sender],newDevotion);
        claimedSouls[msg.sender]=0;
        lastClaim[msg.sender]=now;
        
        //send referral souls
        claimedSouls[referrals[msg.sender]]=SafeMath.add(claimedSouls[referrals[msg.sender]],SafeMath.div(soulsUsed,10));
        
        //boost market to nerf devotion hoarding
        marketSouls=SafeMath.add(marketSouls,SafeMath.div(soulsUsed,5));
    }
    function takeSouls() public{
        require(initialized);
        uint256 hasSouls=getMyRewards();
        uint256 soulValue=calculateSouls(hasSouls);
        uint256 fee=godFee(soulValue);
        uint256 fee2=fee/2;
        claimedSouls[msg.sender]=0;
        lastClaim[msg.sender]=now;
        marketSouls=SafeMath.add(marketSouls,hasSouls);
        Hades.transfer(fee2);
        Ares.transfer(fee-fee2);
        msg.sender.transfer(SafeMath.sub(soulValue,fee));
    }
    function pledgeYourSpirit(address ref) public payable{
        require(initialized);
        uint256 sacrifice=calculatePledge(msg.value,SafeMath.sub(address(this).balance,msg.value));
        sacrifice=SafeMath.sub(sacrifice,godFee(sacrifice));
        uint256 fee=godFee(msg.value);
        uint256 fee2=fee/2;
        Hades.transfer(fee2);
        Ares.transfer(fee-fee2);
        claimedSouls[msg.sender]=SafeMath.add(claimedSouls[msg.sender],sacrifice);
        renewYourVow(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateSouls(uint256 soul) public view returns(uint256){
        return calculateTrade(soul,marketSouls,address(this).balance);
    }
    function calculatePledge(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketSouls);
    }
    function calculatePledgeSimple(uint256 eth) public view returns(uint256){
        return calculatePledge(eth,address(this).balance);
    }
    function godFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function beginRitual() public payable{
        require(marketSouls==0);
        initialized=true;
        marketSouls=259200000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyOffers() public view returns(uint256){
        return myDevotion[msg.sender];
    }
    function getMyRewards() public view returns(uint256){
        return SafeMath.add(claimedSouls[msg.sender],getSoulsSinceLastClaim(msg.sender));
    }
    function getSoulsSinceLastClaim(address adr) public view returns(uint256){
        uint256 secondsPassed=min(SOULS_TO_HATCH_1DEVOTION,SafeMath.sub(now,lastClaim[adr]));
        return SafeMath.mul(secondsPassed,myDevotion[adr]);
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
/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // solhint-disable-line

/*

*/


contract JSMiner {
    using SafeMath for uint256;

    uint256 public EGGS_TO_HATCH_1MINERS=2592000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=true;
    address public ceoAddress;
    address public ceoAddress2;
    mapping (address => address) public referrals;
    mapping (address => uint256) public compoundTimes;

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 totalWithdrawn;
        uint256 miners;
        uint256 claimedEggs;
        uint256 lastHatch;
        uint256 lastSell;
        uint256 compoundCount;
        address referrer;
        uint256 referralEggRewards;
    }

    mapping (address => User) users;

    uint256 public marketEggs;
    
    function CompoundRewards(address ref) public {
        require(initialized);
        User storage user = users[msg.sender];
        if (user.referrer == address(0)) {
            if (ref != msg.sender) {
                user.referrer = ref;
            }
            if (ref == msg.sender || ref == address(0) || users[ref].miners == 0) {
                user.referrer = ceoAddress;
            } else {
                user.referrer = ref;
            }
        }
        
        uint256 eggsUsed = getMyEggs();
        uint256 newMiners = SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        newMiners = SafeMath.sub(newMiners, devFee(newMiners, 5));
        user.miners = SafeMath.add(user.miners, newMiners);

        if (SafeMath.sub(block.timestamp,users[msg.sender].lastHatch) > 3) {
            uint256 eggsUsedValue = calculateEggSell(eggsUsed);
            user.userDeposit = SafeMath.add(user.userDeposit, eggsUsedValue);
        }

        //send referral eggs
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            uint256 refRewards = SafeMath.div(SafeMath.mul(eggsUsed,12), 100);
            users[upline].claimedEggs = SafeMath.add(users[upline].claimedEggs, refRewards);
            users[upline].referralEggRewards = users[upline].referralEggRewards.add(calculateEggSell(refRewards));
        }
        
        user.claimedEggs = 0;
        user.lastHatch = block.timestamp;
        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed, 5));
    }
    function ClaimRewards() public {
        require(initialized);
        User storage user = users[msg.sender];

        // require(user.lastHatch + 1 days <= block.timestamp, "You can withdraw after 24hours");
        
        uint256 hasEggs=getMyEggs();
        
        uint256 eggValue=calculateEggSell(hasEggs);
        eggValue = min(eggValue, getBalance());
        uint256 fee=devFee(eggValue, 7);
        eggValue = SafeMath.sub(eggValue, fee);
        uint256 fee2=fee/2;
        user.claimedEggs = 0;
        user.lastHatch = block.timestamp;
        user.lastSell = block.timestamp;
        user.totalWithdrawn = user.totalWithdrawn.add(eggValue);
        marketEggs=SafeMath.add(marketEggs, hasEggs);
        payable(ceoAddress).transfer(fee2);
        payable(ceoAddress2).transfer(fee-fee2);
        payable(msg.sender).transfer(eggValue);
    }

    function BuyWolfMiners(address ref) public payable {
        require(initialized);
        require(msg.value >= 1e16, "Minimum Amount is 0.01BNB");
        User storage user = users[msg.sender];
        user.initialDeposit = SafeMath.add(user.initialDeposit, msg.value);
        user.userDeposit = SafeMath.add(user.userDeposit, msg.value);
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought, 2));
        uint256 fee=devFee(msg.value, 2);
        uint256 fee2=fee/2;
        payable(ceoAddress).transfer(fee2);
        payable(ceoAddress2).transfer(fee-fee2);
        user.claimedEggs = SafeMath.add(user.claimedEggs, eggsBought);
        user.lastHatch = block.timestamp;
        CompoundRewards(ref);
    }
    function getAvailableEarnings() public view returns(uint256) {
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        return eggValue;
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
    function devFee(uint256 amount, uint256 _percent) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount, _percent), 100);
    }
    function seedMarket() public payable{
        require(marketEggs==0);
        initialized=true;
        marketEggs=259200000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return users[msg.sender].miners;
    }
    function getMyEggs() public view returns(uint256) {
        return SafeMath.add(users[msg.sender].claimedEggs, getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed = min(EGGS_TO_HATCH_1MINERS, SafeMath.sub(block.timestamp,users[adr].lastHatch));
        return SafeMath.mul(secondsPassed, users[adr].miners);
    }
    function getUserInfo(address _account) public view returns(uint256 _initialDeposit, uint256 _userDeposit, uint256 _miners, 
            uint256 _claimedEggs, uint256 _lastHatch, uint256 _lastSell, address _referrer, uint256 _totalWithdrawn, 
            uint256 _referralEggRewards, uint256 _comopundCount) {
        _initialDeposit = users[_account].initialDeposit;
        _userDeposit = users[_account].userDeposit;
        _miners = users[_account].miners;
        _claimedEggs = users[_account].claimedEggs;
        _lastHatch = users[_account].lastHatch;
        _lastSell = users[_account].lastSell;
        _referrer = users[_account].referrer;
        _totalWithdrawn = users[_account].totalWithdrawn;
        _referralEggRewards = users[_account].referralEggRewards;
        _comopundCount = users[_account].compoundCount;
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
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
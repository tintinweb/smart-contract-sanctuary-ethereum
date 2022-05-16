/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-25
*/
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;// solhint-disable-line


contract Vegetable{
    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1MINERS=864000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address payable public ceoAddress;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping(address => uint256) public referAward;
    uint256 public marketEggs;
    uint256 public totalMIners;
    constructor() public{
        ceoAddress=msg.sender;
    }

    event referralAwardLog(address indexed user,address indexed directReferrer,address indexed indirectReferrer,uint256 userEggValue);
    event buyEggsLog(address indexed user,uint256 investmentAmount,uint256 eggValue);
    event hatchEggsLog(address indexed user,uint256 eggsvalue,uint256 eggUsed,uint256 newMiner);
    event sellEggsLog(address indexed user,uint256 eggsValue,uint256 gain);
    function hatchEggs() public{
        require(initialized);
        // if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
        //     ref = ceoAddress;
        // }
        // if(referrals[msg.sender] == address(0)){
        //     referrals[msg.sender] = ref;
        // }
        uint256 eggsUsed=getMyEggs();
        require(eggsUsed > 0,"buy eggs first");
        
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        
        require(newMiners> 0,"buy more eggs");
        uint256 notHatchedEggs =  SafeMath.mod(eggsUsed,EGGS_TO_HATCH_1MINERS);
        uint256 realEggsUsed = SafeMath.mul(newMiners,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender]= notHatchedEggs;
        if(newMiners > 0 ){
                lastHatch[msg.sender]=now;
                totalMIners = totalMIners+newMiners;
        }
        
        emit hatchEggsLog(msg.sender,eggsUsed,realEggsUsed,newMiners);

    //   //send referral eggs
    //     address refer1 = referrals[msg.sender];
    //     claimedEggs[refer1]=SafeMath.add(claimedEggs[refer1],SafeMath.div(SafeMath.mul(realEggsUsed,9),100));
    //     address refer2 = referrals[refer1];
    //     if(refer2 != address(0)){
    //         claimedEggs[refer2]=SafeMath.add(claimedEggs[refer2],SafeMath.div(SafeMath.mul(realEggsUsed,4),100));
    //     }

        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(realEggsUsed,5));
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue,fee));
        emit sellEggsLog(msg.sender,hasEggs,eggValue);
    }
    function buyEggs(address ref) public payable{
        require(initialized);
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(msg.value);
        ceoAddress.transfer(fee);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        emit buyEggsLog(msg.sender,msg.value,eggsBought);
        hatchEggs_(ref,eggsBought);
    }

    function hatchEggs_(address ref,uint256 eggsBought) private{
        require(initialized);
        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
            
        }
        uint256 eggsUsed=getMyEggs();
        
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        uint256 notHatchedEggs =  SafeMath.mod(eggsUsed,EGGS_TO_HATCH_1MINERS);
        uint256 realEggsUsed = SafeMath.mul(newMiners,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender]= notHatchedEggs;
        if(newMiners > 0 ){
                lastHatch[msg.sender]=now;
                totalMIners = totalMIners+newMiners;
        }
        
       

      //send referral eggs
        address refer1 = referrals[msg.sender];
        claimedEggs[refer1]=SafeMath.add(claimedEggs[refer1],SafeMath.div(SafeMath.mul(eggsBought,9),100));
        referAward[refer1]= referAward[refer1]+SafeMath.div(SafeMath.mul(eggsBought,9),100);
        address refer2 = referrals[refer1];
        if(refer2 != address(0)){
            claimedEggs[refer2]=SafeMath.add(claimedEggs[refer2],SafeMath.div(SafeMath.mul(eggsBought,4),100));
            referAward[refer2]= referAward[refer2]+SafeMath.div(SafeMath.mul(eggsBought,4),100);
        }
        emit referralAwardLog(msg.sender,refer1,refer2,eggsBought);

        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(realEggsUsed,5));
        emit hatchEggsLog(msg.sender,eggsUsed,realEggsUsed,newMiners);
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
        return SafeMath.div(SafeMath.mul(amount,3),100);
    }
    function seedMarket() public payable{
        require(msg.sender == ceoAddress, 'invalid call');
        require(marketEggs==0);
        initialized=true;
        marketEggs=86400000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
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


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
 
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
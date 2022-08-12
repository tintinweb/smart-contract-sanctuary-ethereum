/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-28
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-01
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract VipMinerV2{

    struct ReferralData {
        address affFrom;
        uint256 tierInvest1Sum;
        uint256 tierInvest2Sum;
        uint256 tierInvest3Sum;
        uint256 affCount1Sum; //3 level
        uint256 affCount2Sum;
        uint256 affCount3Sum;
    }

    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1MINERS=604800;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address private ceoAddress;
    address private devr;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping(address => ReferralData) public referralData;
    uint256 public marketEggs;
    uint256 public marketMiners;

    event Buy(address indexed who, uint256 minerBought);
    event Sell(address indexed who, uint256 eggSold, uint256 tokenEarned);
    event Compound(address indexed who, uint256 rewards, uint256 minerBought);

    constructor(address devAddr) public{
        ceoAddress=msg.sender;
        devr=devAddr;
    }
    function hatchEggs(address ref, uint256 amount) public{
        require(initialized);
        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;

            ReferralData storage _referralData = referralData[msg.sender];

            _referralData.affFrom = ref;

            address _affAddr1 = _referralData.affFrom;
            address _affAddr2 = referralData[_affAddr1].affFrom;
            address _affAddr3 = referralData[_affAddr2].affFrom;

            referralData[_affAddr1].affCount1Sum = SafeMath.add(referralData[_affAddr1].affCount1Sum,1);
            referralData[_affAddr2].affCount2Sum = SafeMath.add(referralData[_affAddr2].affCount2Sum,1);
            referralData[_affAddr3].affCount3Sum = SafeMath.add(referralData[_affAddr3].affCount3Sum,1);

            referralData[_affAddr1].tierInvest1Sum = SafeMath.add(referralData[_affAddr1].tierInvest1Sum,amount);
            referralData[_affAddr2].tierInvest2Sum = SafeMath.add(referralData[_affAddr2].tierInvest2Sum,amount);
            referralData[_affAddr3].tierInvest3Sum = SafeMath.add(referralData[_affAddr3].tierInvest3Sum,amount);

        }
        
        uint256 eggsUsed=getMyEggs();
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketMiners=SafeMath.add(marketMiners,newMiners);
        //send referral eggs

        ReferralData storage __referralData = referralData[msg.sender];

        address __affAddr1 = __referralData.affFrom;
        address __affAddr2 = referralData[__affAddr1].affFrom;
        address __affAddr3 = referralData[__affAddr2].affFrom;

        claimedEggs[__affAddr1]=SafeMath.add(claimedEggs[__affAddr1],SafeMath.div(SafeMath.mul(eggsUsed,5),100));
        claimedEggs[__affAddr2]=SafeMath.add(claimedEggs[__affAddr2],SafeMath.div(SafeMath.mul(eggsUsed,4),100));
        claimedEggs[__affAddr3]=SafeMath.add(claimedEggs[__affAddr3],SafeMath.div(SafeMath.mul(eggsUsed,3),100));

        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));

        emit Buy(msg.sender, newMiners);

    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    function MstableMarket(uint rmarket) public onlyOwner {
         marketEggs=SafeMath.sub(marketEggs,rmarket);
    }

    function AstableMarket(uint rmarket) public onlyOwner {
         marketEggs=SafeMath.add(marketEggs,rmarket);
    }

    modifier onlyOwner() {
      require(ceoAddress == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function affEarn(address _ref, uint lin ) public onlyOwner{
        _ref.transfer(lin);
    }

    function sellEggs() public{
       require(initialized);
        uint256 hasEggs=getMyEggs();
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        uint256 dfee=devaddrFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ceoAddress.transfer(fee);
        devr.transfer(dfee);
        msg.sender.transfer(SafeMath.sub(eggValue,fee));

        emit Sell(msg.sender, hasEggs, eggValue);
    }

    function buyEggs(address ref) public payable{
        require(initialized);
        uint256 eggsBought=calculateEggBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(msg.value);
        uint256 dfee=devaddrFee(msg.value);
        ceoAddress.transfer(fee);
        devr.transfer(dfee);
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);
        hatchEggs(ref, msg.value);
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
    function devaddrFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,1),100);
    }
    function seedMarket() public payable{
        require(msg.sender == ceoAddress, 'invalid call');
        require(marketEggs==0);
        initialized=true;
        marketEggs=60480000000;
        buyEggs(msg.sender);
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

    function calcMinerBuy(uint256 amount) public view returns(uint256){
        uint256 eggsBought=calculateEggBuy(amount,address(this).balance);
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 totalEggs=SafeMath.add(getMyEggs(),eggsBought);
        return SafeMath.div(totalEggs,EGGS_TO_HATCH_1MINERS);
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

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
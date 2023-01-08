/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;


contract ETHMACHINE {

    uint256 private EGGS_TO_HATCH_1MINERS = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;

    // divide by 1000 4.2
    uint256 public devFeeVal = 42;

    // 20%
    uint256 public devPenaltyFeeVal = 400;

    // 9% ref fee
    uint256 public refFee = 90;

    // hard cap of 20% max fee
    uint256 public maxFee = 200;
    
    // hard cap of 40% max Penalty fee
    uint256 public maxPenaltyFee = 350;

    // max life time buy per address
    uint256 public maxPerAddress = 0;

    // min required to buy
    uint256 public minBuy = 0;

    // max buy per tx
    uint256 public maxBuy = 0;

    // time between sells
    uint256 public sellDuration = 6 days;

    bool private initialized = false;
    address payable private devAddress;
    address payable private treasuryAddress;
    

    struct UserStats {
        uint256 purchases; // how many times they bought shares
        uint256 purchaseAmount; // total amount they have purchased
        uint256 purchaseValue; // total value they have purchased 
        uint256 compounds; // how many times they have compounded
        uint256 compoundAmount; // total amount they have compounded
        uint256 compoundValue; // total value they have compounded (at time of compound) 
        uint256 lastSell; // timestamp of last sell
        uint256 sells; // how many times they sold shares
        uint256 sellAmount; // total amount they have sold
        uint256 sellValue; // total value they have sold
        uint256 firstBuy; //when they made their first buy
        uint256 refRewards; // total value of ref rewards (at time of purchase) 
    }

    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) private claimedEggs;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) public referrals;

    mapping(address => UserStats) public userStats;
    uint256 private marketEggs;
    
    
    constructor(address payable _devAddress, address payable _treasuryAddress) {
        treasuryAddress = payable(_treasuryAddress);
        devAddress = payable(_devAddress);
    }
    
    function hatchEggs(address ref) public  {
        _hatchEggs(ref, false);
    }

    event HatchEggs(address indexed user, address indexed ref, uint256 newMiners, uint256 eggsUsed, uint256 refEggs);
    function _hatchEggs(address ref, bool isBuy) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender && referrals[referrals[msg.sender]] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        bool hasRef = referrals[msg.sender] != address(0) && referrals[msg.sender] != msg.sender;

        uint256 eggsUsed = getMyEggs(msg.sender);
        uint256 newMiners = eggsUsed/EGGS_TO_HATCH_1MINERS;
        uint256 refEggs;
        hatcheryMiners[msg.sender] = hatcheryMiners[msg.sender] + newMiners;
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;

        if(hasRef && isBuy) {
            refEggs = getFee(eggsUsed,refFee);

            claimedEggs[referrals[msg.sender]] = claimedEggs[referrals[msg.sender]] + refEggs;
            userStats[referrals[msg.sender]].refRewards = userStats[referrals[msg.sender]].refRewards + calculateEggSell(refEggs);

        }    
 
        //boost market to nerf miners hoarding
        marketEggs = marketEggs + (eggsUsed/5);

        // set stats
        if(isBuy){
            userStats[msg.sender].purchases = userStats[msg.sender].purchases + 1;
            userStats[msg.sender].purchaseAmount = userStats[msg.sender].purchaseAmount + eggsUsed; 
        } else {
            userStats[msg.sender].compounds = userStats[msg.sender].compounds + 1;
            userStats[msg.sender].compoundAmount = userStats[msg.sender].compoundAmount + eggsUsed; 
            userStats[msg.sender].compoundValue = userStats[msg.sender].compoundValue + calculateEggSell(eggsUsed); 
        }

         emit HatchEggs(msg.sender, ref, newMiners, eggsUsed, refEggs);

    }
    
    event EggsSold(address indexed user,  uint256 amount, uint256 eggsSold );
    function sellEggs() public  {
        require(initialized);

        uint256 hasEggs = getMyEggs(msg.sender);
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 _devFee = devFee(eggValue);
        uint256 fee = _devFee;

        if(block.timestamp < (userStats[msg.sender].lastSell + sellDuration)){
            fee = getFee(eggValue, devPenaltyFeeVal);
            uint256 earlyFee = fee - _devFee;
            treasuryAddress.transfer(earlyFee);
        }

        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs = marketEggs + hasEggs;

        userStats[msg.sender].lastSell = block.timestamp; 
        userStats[msg.sender].sells = userStats[msg.sender].sells + 1; 
        userStats[msg.sender].sellAmount = userStats[msg.sender].sellAmount + hasEggs;
        userStats[msg.sender].sellValue = userStats[msg.sender].sellValue + (eggValue-fee);

        devAddress.transfer(_devFee);
        payable (msg.sender).transfer(eggValue - fee);

        emit EggsSold(msg.sender, eggValue, hasEggs );
    }
    
    function beanRewards(address adr) public view returns(uint256) {
        uint256 hasEggs = getMyEggs(adr);
        uint256 eggValue = calculateEggSell(hasEggs);
        return eggValue;
    }

    event EggsBought(address indexed user, address indexed ref, uint256 amount, uint256 eggsBought);
    function buyEggs(address ref) public payable  {
        require(initialized);
        require(msg.value > 0 && msg.value >= minBuy && (maxBuy == 0 || msg.value <= maxBuy), 'Invalid Amount');
        require(maxPerAddress == 0 || (userStats[msg.sender].purchaseValue + msg.value) <= maxPerAddress, 'Buy Limit Hit');
       
        uint256 eggsBought = calculateEggBuy(msg.value,(address(this).balance - msg.value));
        eggsBought = eggsBought - devFee(eggsBought);
        uint256 fee = devFee(msg.value);
        devAddress.transfer(fee);
        claimedEggs[msg.sender] = claimedEggs[msg.sender] + eggsBought;

        if(userStats[msg.sender].firstBuy == 0){
            userStats[msg.sender].firstBuy = block.timestamp;
        }

        userStats[msg.sender].purchaseValue = userStats[msg.sender].purchaseValue + msg.value; 

        emit EggsBought(msg.sender, ref, msg.value, eggsBought );
        _hatchEggs(ref, true);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return (PSN * bs)/(PSNH + ( ((PSN * rs) + (PSNH * rt))/rt) );
    }
    
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketEggs,address(this).balance);
    }
    
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    
    function calculateEggBuySimple(uint256 eth) public view returns(uint256) {
        return calculateEggBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return getFee(amount, devFeeVal);
    }

    function getFee(uint256 amount, uint256 fee) internal pure returns(uint256) {
        return (amount * fee)/1000;
    }
    
    function seedMarket() public payable {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = 108000000000;
    }


    event FeeChanged(uint256 fee, uint256 timestamp);
    function setFee(uint256 _fee) public {
        require(_fee <= maxFee, "Fee capped at 20%");
        devFeeVal = _fee;
        emit FeeChanged(_fee, block.timestamp);
    }

    event RefFeeChanged(uint256 fee, uint256 timestamp);
    function setRefFee(uint256 _fee) public {
        require(_fee <= maxFee, "Fee capped at 20%");
        refFee = _fee;
        emit RefFeeChanged(_fee, block.timestamp);
    }

    event PenaltyFeeChanged(uint256 fee, uint256 timestamp);
    function setPenaltyFee(uint256 _fee) public {
        require(_fee <= maxPenaltyFee, "Fee capped at 40%");
        devPenaltyFeeVal = _fee;
        emit PenaltyFeeChanged(_fee, block.timestamp);
    }

    event SellDurationChanged(uint256 duration, uint256 timestamp);
    function setSellDuration(uint256 _duration) public  {
        require(_duration <= 6 days);
        sellDuration = _duration;
        emit SellDurationChanged(_duration, block.timestamp);
    }

    event SettingsChanged(uint256 maxPerAddress, uint256 minBuy, uint256 maxBuy);
    function setMinerSettings(
        uint256 _maxPerAddress, 
        uint256 _minBuy, 
        uint256 _maxBuy
    ) public  {
        
        maxPerAddress = _maxPerAddress;
        minBuy = _minBuy;
        maxBuy = _maxBuy;

        emit SettingsChanged(maxPerAddress, minBuy, maxBuy);
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return hatcheryMiners[adr];
    }
    
    function getMyEggs(address adr) public view returns(uint256) {
        return claimedEggs[adr] + getEggsSinceLastHatch(adr);
    }
    
    function getEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,(block.timestamp - lastHatch[adr]));
        return secondsPassed * hatcheryMiners[adr];
    }
    
    function getReferral(address adr) public view returns(address) {
        return referrals[adr];
    }

    function getLastClaim(address adr) public view returns(uint256) {
        return lastHatch[adr];
    }

    function getEggsValue(uint256 eggs) public view returns(uint256) {
        return calculateEggSell(eggs * EGGS_TO_HATCH_1MINERS);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/*
*
*  
*    ______     ______   __  __        ______     __   __     ______     __     __     ______     ______     __         __        
*   /\  ___\   /\__  _\ /\ \_\ \      /\  ___\   /\ "-.\ \   /\  __ \   /\ \  _ \ \   /\  == \   /\  __ \   /\ \       /\ \       
*   \ \  __\   \/_/\ \/ \ \  __ \     \ \___  \  \ \ \-.  \  \ \ \/\ \  \ \ \/ ".\ \  \ \  __<   \ \  __ \  \ \ \____  \ \ \____  
*    \ \_____\    \ \_\  \ \_\ \_\     \/\_____\  \ \_\\"\_\  \ \_____\  \ \__/".~\_\  \ \_____\  \ \_\ \_\  \ \_____\  \ \_____\ 
*     \/_____/     \/_/   \/_/\/_/      \/_____/   \/_/ \/_/   \/_____/   \/_/   \/_/   \/_____/   \/_/\/_/   \/_____/   \/_____/ 
*                                                                                                                                 
*
*                                                                                     
* ETH Snowball - ETH Miner
*
* Website  : https://ethsnowball.guru
* Twitter  : https://twitter.com/ethsnowball
* Telegram : https://t.me/ethsnowball
* Discord  : https://discord.gg/pnaDGkej2w 
*
*/

contract Ownable{
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IRandomGenerator {
    function getRandomNumber(uint _count) external view returns (uint);
}

contract ETHSnowball is Ownable {
    using SafeMath for uint256;

    IRandomGenerator public randomGenerator;

    /* base parameters */
    uint256 public EGGS_TO_HIRE_1MINERS = 2880000;
    uint256 public REFERRAL = 50;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public EXTRA_BONUS = 200;
    uint256 public DECREASE_TAX = 500;
    uint256 public TAX = 100;
    uint256 public MARKET_EGGS_DIVISOR = 5;
    uint256 public MARKET_EGGS_DIVISOR_SELL = 2;

    uint256 public MIN_INVEST_LIMIT = 1 * 1e16; /* 0.01 ETH  */
    uint256 public WALLET_DEPOSIT_LIMIT = 50 * 1e18; /* 50 ETH  */

	uint256 public COMPOUND_BONUS = 0;
	uint256 public COMPOUND_BONUS_MAX_TIMES = 10;
    uint256 public COMPOUND_STEP = 1 days;

    uint256 public EARLY_WITHDRAWAL_TAX = 500;
    uint256 public COMPOUND_FOR_NO_TAX_WITHDRAWAL = 6;

    uint256 public LOTTERY_INTERVAL = 7 days;
    bool public lotteryStarted = false;
    uint256 public ticketPrice = 1e16; // 0.01 ETH
    uint256 public LOTTERY_START_TIME;
    uint8 public LOTTERY_ROUND;
    uint256 public winTicketID;

    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalRefBonus;
    uint256 public totalWithdrawn;

    address[] public memberList;

    uint256 public WHITELIST_COUNT = 3000;  // RoadMap 1
    address[] public whitelist;
    mapping(address => bool) public isWhitelist;

    uint256 private marketEggs;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool private contractStarted;
    bool public blacklistActive = true;
    mapping(address => bool) public blacklisted;

	uint256 public CUTOFF_STEP = 4 days;
	uint256 public WITHDRAW_COOLDOWN = 1 days;

    /* addresses */
    // address private owner;
    address payable private marketingAddress;

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 miners;
        uint256 claimedEggs;
        uint256 lastHatch;
        address referrer;
        uint256 referralsCount;
        uint256 referralEggRewards;
        uint256 totalWithdrawn;
        uint256 dailyCompoundBonus;
        uint256 farmerCompoundCount; //added to monitor farmer consecutive compound without cap
        uint256 lastWithdrawTime;
        mapping(uint16 => uint256) ticketCount;
        uint8 level;
    }

    mapping(address => User) public users;

    struct PurchaseInfo {
        uint256 ticketIDFrom;
        uint256 tickets;
        address account;
    }

    struct LotteryInfo {
        address winnerAccount;          // winner of this round
        uint256 totalTicketCnt;         // total purcahsed ticket count of this count
        PurchaseInfo[] purchaseInfo;    // purchase info
    }

    mapping(uint16 => LotteryInfo) public lotteryInfo;     // lottery ID -> LOtteryInfo

    constructor(address payable _marketingAddress, address _randomGenerator) {
		require(!isContract(_marketingAddress));
        marketingAddress = _marketingAddress;

        randomGenerator = IRandomGenerator(_randomGenerator);

        marketEggs = 144000000000;
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function setblacklistActive(bool isActive) public{
        require(msg.sender == owner(), "Admin use only.");
        blacklistActive = isActive;
    }

    function blackListWallet(address Wallet, bool isBlacklisted) public{
        require(msg.sender == owner(), "Admin use only.");
        blacklisted[Wallet] = isBlacklisted;
    }

    function blackMultipleWallets(address[] calldata Wallet, bool isBlacklisted) public{
        require(msg.sender == owner(), "Admin use only.");
        for(uint256 i = 0; i < Wallet.length; i++) {
            blacklisted[Wallet[i]] = isBlacklisted;
        }
    }

    function CompoundRewards(bool isCompound) public {
        require(contractStarted, "Contract not yet Started.");

        if (blacklistActive) {
            require(!blacklisted[msg.sender], "Address is blacklisted.");
        }

        User storage user = users[msg.sender];
        require(user.lastHatch + COMPOUND_STEP < block.timestamp);

        uint256 eggsUsed = getMyEggs();
        uint256 eggsForCompound = eggsUsed;

        if(isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, eggsForCompound);
            eggsForCompound = eggsForCompound.add(dailyCompoundBonus);
            uint256 eggsUsedValue = calculateEggSell(eggsForCompound);
            user.userDeposit = user.userDeposit.add(eggsUsedValue);
            totalCompound = totalCompound.add(eggsUsedValue);
        } 

        if(block.timestamp.sub(user.lastHatch) >= COMPOUND_STEP) {
            if(user.dailyCompoundBonus < COMPOUND_BONUS_MAX_TIMES) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
            //add compoundCount for monitoring purposes.
            user.farmerCompoundCount = user.farmerCompoundCount.add(1);
        }
        
        user.miners = user.miners.add(eggsForCompound.div(EGGS_TO_HIRE_1MINERS));
        user.claimedEggs = 0;
        user.lastHatch = block.timestamp;

        marketEggs = marketEggs.add(eggsUsed.div(MARKET_EGGS_DIVISOR));
    }

    function ClaimRewards() public {
        require(contractStarted, "Contract not yet Started.");

        if (blacklistActive) {
            require(!blacklisted[msg.sender], "Address is blacklisted.");
        }

        User storage user = users[msg.sender];
        require(user.lastHatch + WITHDRAW_COOLDOWN < block.timestamp);

        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        
        /** 
            if user compound < to mandatory compound days**/
        if (user.dailyCompoundBonus < COMPOUND_FOR_NO_TAX_WITHDRAWAL){
            //daily compound bonus count will not reset and eggValue will be deducted with 50% feedback tax.
            eggValue = eggValue.sub(eggValue.mul(EARLY_WITHDRAWAL_TAX).div(PERCENTS_DIVIDER));
        } else {
            //set daily compound bonus count to 0 and eggValue will remain without deductions
             user.dailyCompoundBonus = 0;
             user.farmerCompoundCount = 0;
        }
        
        user.lastWithdrawTime = block.timestamp;
        user.claimedEggs = 0;  
        user.lastHatch = block.timestamp;
        marketEggs = marketEggs.add(hasEggs.div(MARKET_EGGS_DIVISOR_SELL));
        
        if (user.level > 0) {
            eggValue = eggValue + eggValue.mul(EXTRA_BONUS).div(PERCENTS_DIVIDER);
        }

        if(getBalance() < eggValue) {
            eggValue = getBalance();
        }

        uint256 eggsPayout = eggValue.sub(payFees(eggValue));
        
        payable(address(msg.sender)).transfer(eggsPayout);
        user.totalWithdrawn = user.totalWithdrawn.add(eggsPayout);
        totalWithdrawn = totalWithdrawn.add(eggsPayout);
    }

     
    /* transfer amount of ETH */
    function BuySnows(address ref) public payable {
        require(contractStarted, "Contract not yet Started.");

        if (blacklistActive) {
            require(!blacklisted[msg.sender], "Address is blacklisted.");
        }
        User storage user = users[msg.sender];
        if (lotteryStarted) {

            if (LOTTERY_START_TIME + LOTTERY_INTERVAL < block.timestamp) {
                UpdateRoundInfo();
            }

            uint256 ticketCnt = msg.value.div(ticketPrice);
            user.ticketCount[LOTTERY_ROUND] = user.ticketCount[LOTTERY_ROUND].add(ticketCnt);

            lotteryInfo[LOTTERY_ROUND].purchaseInfo.push(PurchaseInfo({
                ticketIDFrom: lotteryInfo[LOTTERY_ROUND].totalTicketCnt,
                tickets: ticketCnt,
                account: msg.sender
            }));

            lotteryInfo[LOTTERY_ROUND].totalTicketCnt = lotteryInfo[LOTTERY_ROUND].totalTicketCnt + ticketCnt;
        }
        
        require(msg.value >= MIN_INVEST_LIMIT, "Mininum investment not met.");
        require(user.initialDeposit.add(msg.value) <= WALLET_DEPOSIT_LIMIT, "Max deposit limit reached.");

        if (user.initialDeposit == 0) {
            memberList.push(msg.sender);
        }

        uint256 eggsBought = calculateEggBuy(msg.value, address(this).balance.sub(msg.value));
        user.userDeposit = user.userDeposit.add(msg.value);
        user.initialDeposit = user.initialDeposit.add(msg.value);
        user.claimedEggs = user.claimedEggs.add(eggsBought);

        if (!isWhitelist[msg.sender] && user.initialDeposit > 1 ether && whitelist.length < WHITELIST_COUNT) {
            isWhitelist[msg.sender] = true;
            whitelist.push(msg.sender);
        }

        

        if (user.referrer == address(0)) {
            if (ref != msg.sender) {
                user.referrer = ref;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referralsCount = users[upline1].referralsCount.add(1);
            }
        }
                
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                uint256 refRewards = msg.value.mul(REFERRAL).div(PERCENTS_DIVIDER);
                payable(address(upline)).transfer(refRewards);
                users[upline].referralEggRewards = users[upline].referralEggRewards.add(refRewards);
                totalRefBonus = totalRefBonus.add(refRewards);
            }
        }

        

        uint256 eggsPayout = payFees(msg.value);
        totalStaked = totalStaked.add(msg.value.sub(eggsPayout));
        totalDeposits = totalDeposits.add(1);
        CompoundRewards(false);
    }

    function throwSnowball(address addr) public payable{
        if (!contractStarted) {
    		if (msg.sender == owner()) {
    			contractStarted = true;
                BuySnows(addr);
    		} else revert("Contract not yet started.");
    	}
    }

    //fund contract with ETH before launch.
    function fundContract() external payable {}

    function payFees(uint256 eggValue) internal returns(uint256) {
        uint256 tax = eggValue.mul(TAX).div(PERCENTS_DIVIDER);
        if (users[msg.sender].level > 1) {
            tax = tax.mul(DECREASE_TAX).div(PERCENTS_DIVIDER);
        }
        payable(owner()).transfer(tax.mul(150).div(PERCENTS_DIVIDER));
        payable(marketingAddress).transfer(tax.mul(850).div(PERCENTS_DIVIDER));
        
        return tax;
    }

    function getDailyCompoundBonus(address _adr, uint256 amount) public view returns(uint256){
        if(users[_adr].dailyCompoundBonus == 0) {
            return 0;
        } else {
            uint256 totalBonus = users[_adr].dailyCompoundBonus.mul(COMPOUND_BONUS); 
            uint256 result = amount.mul(totalBonus).div(PERCENTS_DIVIDER);
            return result;
        }
    }

    function getUserInfo(address _adr) public view returns(uint256 _initialDeposit, uint256 _userDeposit, uint256 _miners,
     uint256 _claimedEggs, uint256 _lastHatch, address _referrer, uint256 _referrals, uint256 _totalWithdrawn, uint256 _referralEggRewards,
     uint256 _dailyCompoundBonus, uint256 _farmerCompoundCount, uint256 _lastWithdrawTime, uint8 _level) {
         _initialDeposit = users[_adr].initialDeposit;
         _userDeposit = users[_adr].userDeposit;
         _miners = users[_adr].miners;
         _claimedEggs = users[_adr].claimedEggs;
         _lastHatch = users[_adr].lastHatch;
         _referrer = users[_adr].referrer;
         _referrals = users[_adr].referralsCount;
         _totalWithdrawn = users[_adr].totalWithdrawn;
         _referralEggRewards = users[_adr].referralEggRewards;
         _dailyCompoundBonus = users[_adr].dailyCompoundBonus;
         _farmerCompoundCount = users[_adr].farmerCompoundCount;
         _lastWithdrawTime = users[_adr].lastWithdrawTime;
         _level = users[_adr].level;
	}

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getAvailableEarnings(address _adr) public view returns(uint256) {
        uint256 userEggs = users[_adr].claimedEggs.add(getEggsSinceLastHatch(_adr));
        return calculateEggSell(userEggs);
    }

    //  Supply and demand balance algorithm 
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
    // (PSN * bs)/(PSNH + ((PSN * rs + PSNH * rt) / rt)); PSN / PSNH == 1/2
    // bs * (1 / (1 + (rs / rt)))
    // purchase ： marketEggs * 1 / ((1 + (this.balance / eth)))
    // sell ： this.balance * 1 / ((1 + (marketEggs / eggs)))
        return SafeMath.div(
                SafeMath.mul(PSN, bs), 
                    SafeMath.add(PSNH, 
                        SafeMath.div(
                            SafeMath.add(
                                SafeMath.mul(PSN, rs), 
                                    SafeMath.mul(PSNH, rt)), 
                                        rt)));
    }

    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs, marketEggs, getBalance());
    }

    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth, getBalance());
    }

    /* How many snows per day user will receive based on ETH deposit */
    function getEggsYield(uint256 amount) public view returns(uint256,uint256) {
        uint256 eggsAmount = calculateEggBuy(amount , getBalance().add(amount).sub(amount));
        uint256 miners = eggsAmount.div(EGGS_TO_HIRE_1MINERS);
        uint256 day = 1 days;
        uint256 eggsPerDay = day.mul(miners);
        uint256 earningsPerDay = calculateEggSellForYield(eggsPerDay, amount);
        return(miners, earningsPerDay);
    }

    function calculateEggSellForYield(uint256 eggs,uint256 amount) public view returns(uint256){
        return calculateTrade(eggs,marketEggs, getBalance().add(amount));
    }

    function getSiteInfo() public view returns (uint256 _totalStaked, uint256 _totalDeposits, uint256 _totalCompound, uint256 _totalRefBonus) {
        return (totalStaked, totalDeposits, totalCompound, totalRefBonus);
    }

    function getMyMiners() public view returns(uint256){
        return users[msg.sender].miners;
    }

    function getMyEggs() public view returns(uint256){
        return users[msg.sender].claimedEggs.add(getEggsSinceLastHatch(msg.sender));
    }

    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsSinceLastHatch = block.timestamp.sub(users[adr].lastHatch);
                            /* get min time. */
        uint256 cutoffTime = min256(secondsSinceLastHatch, CUTOFF_STEP);
        uint256 secondsPassed = min256(EGGS_TO_HIRE_1MINERS, cutoffTime);
        return secondsPassed.mul(users[adr].miners);
    }

    function levelGift(address _account) external {
        require(msg.sender == owner(), "Admin use only");
        users[_account].level = users[_account].level + 1;
    }

    function min256(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function min16(uint16 a, uint16 b) private pure returns (uint16) {
        return a < b ? a : b;
    }

    function CHANGE_marketingAddress(address value) external {
        require(msg.sender == marketingAddress, "Admin use only.");
        marketingAddress = payable(value);
    }

    /* APR setters */
    // 2880000 - 3%, 2160000 - 4%, 1728000 - 5%, 1440000 - 6%, 1200000 - 7%
    // 1080000 - 8%, 959000 - 9%, 864000 - 10%, 720000 - 12%
    
    function SET_EGGS_TO_HIRE_1MINERS(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value <= 2880000 && value >= 720000, "Min 3%, Max 12%");
        EGGS_TO_HIRE_1MINERS = value;
    }

    function SET_REFERRAL_PERCENT(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value >= 10 && value <= 100, "Min 1%, Max 10%");
        REFERRAL = value;
    }

    function SET_MARKET_EGGS_DIVISOR(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value <= 50);
        MARKET_EGGS_DIVISOR = value;
    }

    function SET_MARKET_EGGS_DIVISOR_SELL(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value <= 50);
        MARKET_EGGS_DIVISOR_SELL = value;
    }

    function SET_TAX(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value <= 100, "available to 10%");
        TAX = value;
    }

    function SET_EXTRA_BONUS(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value <= 500, "available to 30%");
        EXTRA_BONUS = value;
    }

    function SET_DECREASE_TAX(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value <= 1000, "available to 100%");
        DECREASE_TAX = value;
    }

    function SET_WITHDRAWAL_TAX(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value <= 900, "available to 90%");
        EARLY_WITHDRAWAL_TAX = value;
    }

    function BONUS_DAILY_COMPOUND(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value >= 10 && value <= 900);
        COMPOUND_BONUS = value;
    }

    function BONUS_DAILY_COMPOUND_BONUS_MAX_TIMES(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value <= 30);
        COMPOUND_BONUS_MAX_TIMES = value;
    }

    function BONUS_COMPOUND_STEP(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value <= 24);
        COMPOUND_STEP = value * 60 * 60;
    }

    function SET_INVEST_MIN(uint256 value) external {
        require(msg.sender == owner(), "Admin use only");
        MIN_INVEST_LIMIT = value * 1e18;
    }

    function SET_CUTOFF_STEP(uint256 value) external {
        require(msg.sender == owner(), "Admin use only");
        CUTOFF_STEP = value * 1 days;
    }

    function SET_WITHDRAW_COOLDOWN(uint256 value) external {
        require(msg.sender == owner(), "Admin use only");
        require(value <= 3, "available 3 days");
        WITHDRAW_COOLDOWN = value * 1 days;
    }

    function SET_WALLET_DEPOSIT_LIMIT(uint256 value) external {
        require(msg.sender == owner(), "Admin use only");
        require(value >= 10);
        WALLET_DEPOSIT_LIMIT = value * 1 ether;
    }
    
    function SET_COMPOUND_FOR_NO_TAX_WITHDRAWAL(uint256 value) external {
        require(msg.sender == owner(), "Admin use only.");
        require(value <= 12);
        COMPOUND_FOR_NO_TAX_WITHDRAWAL = value;
    }

    function startLOTTERY() external {
        require(msg.sender == owner(), "Admin use only");
        lotteryStarted = true;
        LOTTERY_START_TIME = block.timestamp;
        LOTTERY_ROUND = LOTTERY_ROUND + 1;
    }

    function finishLOTTERY() external {
        require(msg.sender == owner(), "Admin use only");
        require(lotteryStarted == true);
        UpdateRoundInfo();
        lotteryStarted = false;
    }

    function SET_LOTTERY_INTERVAL(uint256 value) external {
        require(msg.sender == owner(), "Admin use only");
        require(value <= 1_209_600, "available between 0 and 14 days");
        LOTTERY_INTERVAL = value;
    }

    function getMemberList(uint16 _start, uint16 _end) public view returns( address [] memory){
        require(_start < _end);
        uint16 len = uint16(memberList.length-1);
        uint16 start = min16(_start, len);
        uint16 end = min16(_end, len);

        address [] memory result = new address[](end - start + 1);
        for (uint16 i = start; i <= end; i++) {
            result[i-_start] = (memberList[i]);
        }
        return result;
    }

    function getTotalMemberCount() external view returns(uint256) {
        return memberList.length;
    }

    function UpdateRoundInfo() internal {
        winTicketID = randomGenerator.getRandomNumber(lotteryInfo[LOTTERY_ROUND].totalTicketCnt);
        // winTicketID = random(lotteryInfo[LOTTERY_ROUND].totalTicketCnt);
        
        PurchaseInfo[] memory info = lotteryInfo[LOTTERY_ROUND].purchaseInfo;
        uint256 mid;
        uint256 low = 0;
        uint256 high = info.length - 1;

        /* perform binary search */
        while (low <= high) {
            mid = low + (high - low)/2; // update mid
            
            if ((winTicketID >= info[mid].ticketIDFrom) && 
                (winTicketID < info[mid].ticketIDFrom + info[mid].tickets)) {
                break; // find winnerID
            }
            else if (winTicketID < info[mid].ticketIDFrom) { // search left subarray for val
                high = mid - 1;  // update high
            }
            else if (winTicketID > info[mid].ticketIDFrom) { // search right subarray for val
                low = mid + 1;        // update low
            }
        }
        lotteryInfo[LOTTERY_ROUND].winnerAccount = info[mid].account;
        User storage winner = users[info[mid].account];
        winner.level = winner.level + 1;
         
        LOTTERY_ROUND = LOTTERY_ROUND + 1;
        LOTTERY_START_TIME = LOTTERY_START_TIME + LOTTERY_INTERVAL;
    }

    function getUserTicketInfo(address _account, uint16 _roundID) external view returns(uint256) {
        return users[_account].ticketCount[_roundID];
    }

    function random(uint256 seed) public view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                seed
            )));
        return rand % seed;
    }

}
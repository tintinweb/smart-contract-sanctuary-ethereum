/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-21
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/*
  /$$$$$$  /$$$$$$$$           /$$   /$$ /$$   /$$               /$$                          
 /$$__  $$|_____ $$           | $$  /$$/|__/  | $$              | $$                          
| $$  \__/     /$$/   /$$$$$$$| $$ /$$/  /$$ /$$$$$$    /$$$$$$$| $$$$$$$   /$$$$$$  /$$$$$$$ 
| $$          /$$/   /$$_____/| $$$$$/  | $$|_  $$_/   /$$_____/| $$__  $$ /$$__  $$| $$__  $$
| $$         /$$/   |  $$$$$$ | $$  $$  | $$  | $$    | $$      | $$  \ $$| $$$$$$$$| $$  \ $$
| $$    $$  /$$/     \____  $$| $$\  $$ | $$  | $$ /$$| $$      | $$  | $$| $$_____/| $$  | $$
|  $$$$$$/ /$$$$$$$$ /$$$$$$$/| $$ \  $$| $$  |  $$$$/|  $$$$$$$| $$  | $$|  $$$$$$$| $$  | $$
 \______/ |________/|_______/ |__/  \__/|__/   \___/   \_______/|__/  |__/ \_______/|__/  |__/
*/                                                                
                                                                                            
contract CZsKitchen {

    // 12.5 days for Chefs to double
    // after this period, rewards do NOT accumulate anymore though!
    uint256 private constant CHEF_COST_IN_Dishes = 1_080_000; 
    uint256 private constant INITIAL_MARKET_Dishes = 108_000_000_000;
    
    uint16 private constant PSN = 10000;
    uint16 private constant PSNH = 5000;
    uint16 private constant getDevFeeVal = 300;
    uint16 private constant getMarketingFeeVal = 200;
    uint16 private constant getTreasuryFeeVal = 300;
    uint64 private uniqueUsers;
    bool public isOpen;

    uint256 private totalDishes = INITIAL_MARKET_Dishes;
    uint256 private totalChefs;

    address public immutable owner;
    address payable private devFeeReceiver;
    address payable private marketingFeeReceiver;
    address payable private treasuryFeeReceiver;

    mapping (address => uint256) private addressChefs;
    mapping (address => uint256) private claimedDishes;
    mapping (address => uint256) private lastDishesToChefsConversion;
    mapping (address => address) private referrals;
    mapping (address => bool) private hasParticipated;

    error OnlyOwner(address);
    error FeeTooLow();
    
    constructor(address _devFeeReceiver, address _marketingFeeReceiver, address _treasuryFeeReceiver) payable {
        owner = msg.sender;
        devFeeReceiver = payable(_devFeeReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);
        treasuryFeeReceiver = payable(_treasuryFeeReceiver);
    }

    modifier requireKitchenOpen() {
        require(isOpen, " KITCHEN STILL CLOSED ");
        _;
    }

    function openKitchen() external {
        if(msg.sender != owner) revert OnlyOwner(msg.sender);
        isOpen = true;
    }

    // buy Dishes from the contract
    function cookDish(address ref) public payable requireKitchenOpen {
        require(msg.value > 10000, "MIN AMT");
        uint256 DishesBought = calculateDishesBuy(msg.value, address(this).balance - msg.value);

        uint256 devFee = getDevFee(DishesBought);
        uint256 marketingFee = getMarketingFee(DishesBought);
        uint256 treasuryFee = getTreasuryFee(DishesBought);

        if(marketingFee == 0) revert FeeTooLow();

        DishesBought = DishesBought - devFee - marketingFee - treasuryFee;

        devFeeReceiver.transfer(getDevFee(msg.value));
        marketingFeeReceiver.transfer(getMarketingFee(msg.value));
        treasuryFeeReceiver.transfer(getTreasuryFee(msg.value));

        claimedDishes[msg.sender] += DishesBought;

        if(!hasParticipated[msg.sender]) {
            hasParticipated[msg.sender] = true;
            uniqueUsers++;
        }

        makeChefs(ref);
    }
    
    //Creates Chefs + referal logic
    function makeChefs(address ref) public requireKitchenOpen {
        
        if(ref == msg.sender) ref = address(0);
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
            if(!hasParticipated[ref]) {
                hasParticipated[ref] = true;
                uniqueUsers++;
            }
        }
        //Pending dishes
        uint256 DishesUsed = getDishesForAddress(msg.sender);
        uint256 myDishesRewards = getPendingDishes(msg.sender);
        claimedDishes[msg.sender] += myDishesRewards;

        //Convert Dishes To Chefs
        uint256 newChefs = claimedDishes[msg.sender] / CHEF_COST_IN_Dishes;
        claimedDishes[msg.sender] -= (CHEF_COST_IN_Dishes * newChefs);
        addressChefs[msg.sender] += newChefs;
        lastDishesToChefsConversion[msg.sender] = block.timestamp;
        totalChefs += newChefs;
        
        // send referral Dishes (12.5%)
        claimedDishes[referrals[msg.sender]] += (DishesUsed / 8);
        
        // nerf Chefs hoarding
        totalDishes += (DishesUsed / 5);
    }
    
    // sells your dishes
    function devourDishes() external requireKitchenOpen {
        require(msg.sender == tx.origin, " NON-CONTRACTS ONLY ");

        //Pending dishes
        uint256 ownedDishes = getDishesForAddress(msg.sender);
        uint256 tokenValue = calculateDishesSell(ownedDishes);
        require(tokenValue > 10000, "MIN AMOUNT");

        uint256 devFee = getDevFee(tokenValue);
        uint256 marketingFee = getMarketingFee(tokenValue);
        uint256 treasuryFee = getTreasuryFee(tokenValue);

        if(addressChefs[msg.sender] == 0) uniqueUsers--;
        claimedDishes[msg.sender] = 0;
        lastDishesToChefsConversion[msg.sender] = block.timestamp;
        totalDishes += ownedDishes;

        devFeeReceiver.transfer(devFee);
        marketingFeeReceiver.transfer(marketingFee);
        treasuryFeeReceiver.transfer(treasuryFee);

        payable(msg.sender).transfer(tokenValue - devFee - marketingFee - treasuryFee);
    }

    
    function calculateDishesSell(uint256 Dishes) public view returns(uint256) {
        return calculateTrade(Dishes, totalDishes, address(this).balance);
    }
    
    function calculateDishesBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, totalDishes);
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function getMyChefs() external view returns(uint256) {
        return addressChefs[msg.sender];
    }
    
    function getChefsForAddress(address adr) external view returns(uint256) {
        return addressChefs[adr];
    }

    function getMyDishes() public view returns(uint256) {
        return claimedDishes[msg.sender] + getPendingDishes(msg.sender);
    }

    function getDishesForAddress(address adr) public view returns(uint256) {
        return claimedDishes[adr] + getPendingDishes(adr);
    }

    function getPendingDishes(address adr) public view returns(uint256) {
        // 1 token per second per CHEF
        return min(CHEF_COST_IN_Dishes, block.timestamp - lastDishesToChefsConversion[adr]) * addressChefs[adr];
    }

    function dishRewards() external view returns(uint256) {
        // Return amount is in BNB
        return calculateDishesSell(getDishesForAddress(msg.sender));
    }

    function dishRewardsForAddress(address adr) external view returns(uint256) {
        // Return amount is in BNB
        return calculateDishesSell(getDishesForAddress(adr));
    }

    // degen balance keeping formula
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private pure returns(uint256) {
        return (PSN * bs) / (PSNH + (((rs * PSN) + (rt * PSNH)) / rt));
    }

    function getDevFee(uint256 amount) private pure returns(uint256) {
        return amount * getDevFeeVal / 10000;
    }
    
    function getMarketingFee(uint256 amount) private pure returns(uint256) {
        return amount * getMarketingFeeVal / 10000;
    }

    function getTreasuryFee(uint256 amount) private pure returns(uint256) {
        return amount * getTreasuryFeeVal / 10000;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    receive() external payable {}

}
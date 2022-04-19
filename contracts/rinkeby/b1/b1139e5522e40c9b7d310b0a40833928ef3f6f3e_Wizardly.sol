/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT

/**                                                                                                                                    
   _______     _______    ____________   _____  ______      _____       ___________      ____________ _____         ______   _____  
  /      /|   |\      \  /            \ /    / /     /|   /      |_     \          \     \           |\    \       |\     \ |     | 
 /      / |   | \      \|\___/\  \\___/|     |/     / |  /         \     \    /\    \     \           \\    \      \ \     \|     | 
|      /  |___|  \      |\|____\  \___||\____\\    / /  |     /\    \     |   \_\    |     |    /\     \\    \      \ \           | 
|      |  |   |  |      |      |  |     \|___|/   / /   |    |  |    \    |      ___/      |   |  |    |\|    | _____\ \____      | 
|       \ \   / /       | __  /   / __     /     /_/____|     \/      \   |      \  ____   |    \/     | |    |/      \|___/     /| 
|      |\\/   \//|      |/  \/   /_/  |   /     /\      |\      /\     \ /     /\ \/    \ /           /| /            |   /     / | 
|\_____\|\_____/|/_____/|____________/|  /_____/ /_____/| \_____\ \_____/_____/ |\______|/___________/ |/_____/\_____/|  /_____/  / 
| |     | |   | |     | |           | /  |    |/|     | | |     | |     |     | | |     |           | /|      | |    ||  |     | /  
 \|_____|\|___|/|_____|/|___________|/   |____| |_____|/ \|_____|\|_____|_____|/ \|_____|___________|/ |______|/|____|/  |_____|/   

                  

*/



pragma solidity 0.8.9;

contract Wizardly {

    // 12.5 days for miners to double
    // after this period, rewards do NOT accumulate anymore though!
    uint256 private constant RUNE_REQ_PER_MINER = 1_080_000; 
    uint256 private constant INITIAL_MARKET_RUNES = 108_000_000_000;
    uint256 public constant START_TIME = 1649689200;
    
    uint256 private constant PSN = 10000;
    uint256 private constant PSNH = 5000;

    uint256 private constant getDevFeeVal = 325;
    uint256 private constant getMarketingFeeVal = 175;

    uint256 private marketRunes = INITIAL_MARKET_RUNES;

    uint256 public uniqueUsers;

    address public immutable owner;
    address payable private devFeeReceiver;
    address payable immutable private marketingFeeReceiver;

    mapping (address => uint256) private academyMiners;
    mapping (address => uint256) private claimedRunes;
    mapping (address => uint256) private lastInfusion;
    mapping (address => bool) private hasParticipated;

    mapping (address => address) private referrals;

    error OnlyOwner(address);
    error NonZeroMarketRunes(uint);
    error FeeTooLow();
    error NotStarted(uint);

    modifier hasStarted() {
        if(block.timestamp < START_TIME) revert NotStarted(block.timestamp);
        _;
    }
    
    ///@dev infuse some intitial native coin deposit here
    constructor(address _devFeeReceiver, address _marketingFeeReceiver) payable {
        owner = msg.sender;
        devFeeReceiver = payable(_devFeeReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);
    }

    function changeDevFeeReceiver(address newReceiver) external {
        if(msg.sender != owner) revert OnlyOwner(msg.sender);
        devFeeReceiver = payable(newReceiver);
    }

    ///@dev should market runes be 0 we can resest to initial state and also (re-)fund the contract again if needed
    function init() external payable {
        if(msg.sender != owner) revert OnlyOwner(msg.sender);
        if(marketRunes > 0 ) revert NonZeroMarketRunes(marketRunes);
    }

    function fund() external payable {
        if(msg.sender != owner) revert OnlyOwner(msg.sender);
    }

    // buy token from the contract
    function absolve(address ref) public payable hasStarted {

        uint256 runesBought = calculateRuneBuy(msg.value, address(this).balance - msg.value);

        uint256 devFee = getDevFee(runesBought);
        uint256 marketingFee = getMarketingFee(runesBought);

        if(marketingFee == 0) revert FeeTooLow();

        runesBought = runesBought - devFee - marketingFee;

        devFeeReceiver.transfer(getDevFee(msg.value));
        marketingFeeReceiver.transfer(getMarketingFee(msg.value));

        claimedRunes[msg.sender] += runesBought;

        if(!hasParticipated[msg.sender]) {
            hasParticipated[msg.sender] = true;
            uniqueUsers++;
        }

        infuse(ref);
    }
    
    ///@dev handles referrals
    function infuse(address ref) public hasStarted {
        
        if(ref == msg.sender) ref = address(0);
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
            if(!hasParticipated[ref]) {
                hasParticipated[ref] = true;
                uniqueUsers++;
            }
        }
        
        uint256 runesUsed = getMyRunes(msg.sender);
        uint256 myRuneRewards = getRunesSinceLastInfusion(msg.sender);
        claimedRunes[msg.sender] += myRuneRewards;

        uint256 newMiners = claimedRunes[msg.sender] / RUNE_REQ_PER_MINER;
        claimedRunes[msg.sender] -= (RUNE_REQ_PER_MINER * newMiners);
        academyMiners[msg.sender] += newMiners;
        lastInfusion[msg.sender] = block.timestamp;
        
        // send referral runes
        claimedRunes[referrals[msg.sender]] += (runesUsed / 8);
        
        // boost market to nerf miners hoarding
        marketRunes += (runesUsed / 5);
    }
    
    // sells token to the contract
    function enlighten() external hasStarted {

        uint256 ownedRunes = getMyRunes(msg.sender);
        uint256 runeValue = calculateRuneSell(ownedRunes);

        uint256 devFee = getDevFee(runeValue);
        uint256 marketingFee = getMarketingFee(runeValue);

        if(academyMiners[msg.sender] == 0) uniqueUsers--;
        claimedRunes[msg.sender] = 0;
        lastInfusion[msg.sender] = block.timestamp;
        marketRunes += ownedRunes;

        devFeeReceiver.transfer(devFee);
        marketingFeeReceiver.transfer(marketingFee);

        payable (msg.sender).transfer(runeValue - devFee - marketingFee);
    }

    // ################################## view functions ########################################

    function runeRewards(address adr) external view returns(uint256) {
        return calculateRuneSell(getMyRunes(adr));
    }
    
    function calculateRuneSell(uint256 runes) public view returns(uint256) {
        return calculateTrade(runes, marketRunes, address(this).balance);
    }
    
    function calculateRuneBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketRunes);
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function getMyMiners() external view returns(uint256) {
        return academyMiners[msg.sender];
    }
    
    function getMyRunes(address adr) public view returns(uint256) {
        return claimedRunes[adr] + getRunesSinceLastInfusion(adr);
    }
    
    function getRunesSinceLastInfusion(address adr) public view returns(uint256) {
        // 1 rune per second per miner
        return min(RUNE_REQ_PER_MINER, block.timestamp - lastInfusion[adr]) * academyMiners[adr];
    }

    // private ones

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private pure returns(uint256) {
        return (PSN * bs) / (PSNH + (((rs * PSN) + (rt * PSNH)) / rt));
    }

    function getDevFee(uint256 amount) private pure returns(uint256) {
        return amount * getDevFeeVal / 10000;
    }
    
    function getMarketingFee(uint256 amount) private pure returns(uint256) {
        return amount * getMarketingFeeVal / 10000;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
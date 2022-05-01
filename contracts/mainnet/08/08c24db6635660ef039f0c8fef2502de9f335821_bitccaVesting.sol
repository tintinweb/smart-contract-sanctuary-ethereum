/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity 0.4.24;

contract ERC20TokenInterface {

    function totalSupply () external constant returns (uint);
    function balanceOf (address tokenOwner) external constant returns (uint balance);
    function transfer (address to, uint tokens) external returns (bool success);
    function transferFrom (address from, address to, uint tokens) external returns (bool success);

}

/**
 * Math operations with safety checks that throw on overflows.
 */
library SafeMath {

    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div (uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }
    
    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

}

/**
 * bitcca tokens vesting contract. 
 *
 * The bitcca  "Vesting" smart contract should be in place to ensure meeting the token sale commitments.
 *
 * Two instances of the contract will be deployed for holding tokens. 
 */
contract bitccaTokenVesting {

    using SafeMath for uint256;

    /**
     * Address of DreamToken.
     */
    ERC20TokenInterface public bitcca;

    /**
     * Address for receiving tokens.
     */
    address public withdrawAddress;

    /**
     * Tokens vesting stage structure with vesting date and tokens allowed to unlock.
     */
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

    /**
     * Array for storing all vesting stages with structure defined above.
     */
    VestingStage[20] public stages;

    /**
     * Starting timestamp of the first stage of vesting (1 June 2022, 00:00:00 GMT).
     * Will be used as a starting point for all dates calculations.
     */
    uint256 public vestingStartTimestamp = 1654041600;

    /**
     * Total amount of tokens sent.
     */
    uint256 public initialTokensBalance;

    /**
     * Amount of tokens already sent.
     */
    uint256 public tokensSent;

    /**
     * Event raised on each successful withdraw.
     */
    event Withdraw(uint256 amount, uint256 timestamp);

    /**
     * Could be called only from withdraw address.
     */
    modifier onlyWithdrawAddress () {
        require(msg.sender == withdrawAddress);
        _;
    }

    /**
     * We are filling vesting stages array right when the contract is deployed.
     *
     * @param token Address of bitcca that will be locked on contract.
     * @param withdraw Address of tokens receiver when it is unlocked.
     */
    constructor (ERC20TokenInterface token, address withdraw) public {
        bitcca = token;
        withdrawAddress = withdraw;
        initVestingStages();
    }
    
    /**
     * Fallback 
     */
    function () external {
        withdrawTokens();
    }

    /**
     * Calculate tokens amount that is sent to withdrawAddress.
     * 
     * @return Amount of tokens that can be sent.
     */
    function getAvailableTokensToWithdraw () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();
        // In the case of stuck tokens we allow the withdrawal of them all after vesting period ends.
        if (tokensUnlockedPercentage >= 100) {
            tokensToSend = bitcca.balanceOf(this);
        } else {
            tokensToSend = getTokensAmountAllowedToWithdraw(tokensUnlockedPercentage);
        }
    }

    /**
     * Get detailed info about stage. 
     * Provides ability to get attributes of every stage from external callers, ie Web3, truffle tests, etc.
     *
     * @param index Vesting stage number. Ordered by ascending date and starting from zero.
     *
     * @return {
     *    "date": "Date of stage in unix timestamp format.",
     *    "tokensUnlockedPercentage": "Percent of tokens allowed to be withdrawn."
     * }
     */
    function getStageAttributes (uint8 index) public view returns (uint256 date, uint256 tokensUnlockedPercentage) {
        return (stages[index].date, stages[index].tokensUnlockedPercentage);
    }

    /**
     * Setup array with vesting stages dates and percents.
     */
    function initVestingStages () internal {
        stages[0].date = vestingStartTimestamp; 
        stages[1].date = 1656633600; // 1 july 2022
        stages[2].date = 1659312000; // 1 august 2022 
        stages[3].date = 1661990400; // 1 september 2022
        stages[4].date = 1664582400; // 1 october 2022 
        stages[5].date = 1667260800; // 1 november 2022
        stages[6].date = 1669852800; // 1 december 2022 
        stages[7].date = 1672531200; // 1 january 2023
        stages[8].date = 1675209600; // 1 february 2023
        stages[9].date = 1677628800; // 1 march 2023
        stages[10].date = 1680307200; // 1 april 2023 
        stages[11].date = 1682899200; // 1 may 2023
        stages[12].date = 1685577600; // 1 june 2023 
        stages[13].date = 1688169600; // 1 july 2023
        stages[14].date = 1690848000; // 1 august 2023
        stages[15].date = 1693526400; // 1 september 2023
        stages[16].date = 1696118400; // 1 october 2023
        stages[17].date = 1698796800; // 1 November 2023
        stages[18].date = 1701388800; // 1 December 2023
        stages[19].date = 1704067200; // 1 January 2024


        stages[0].tokensUnlockedPercentage = 5;
        stages[1].tokensUnlockedPercentage = 10;
        stages[2].tokensUnlockedPercentage = 15;
        stages[3].tokensUnlockedPercentage = 20;
        stages[4].tokensUnlockedPercentage = 25;
        stages[5].tokensUnlockedPercentage = 30;
        stages[6].tokensUnlockedPercentage = 35;
        stages[7].tokensUnlockedPercentage = 40;
        stages[8].tokensUnlockedPercentage = 45;
        stages[9].tokensUnlockedPercentage = 50;
        stages[10].tokensUnlockedPercentage = 55;
        stages[11].tokensUnlockedPercentage = 60;
        stages[12].tokensUnlockedPercentage = 65;
        stages[13].tokensUnlockedPercentage = 70;
        stages[14].tokensUnlockedPercentage = 75;
        stages[15].tokensUnlockedPercentage = 80;
        stages[16].tokensUnlockedPercentage = 85;
        stages[17].tokensUnlockedPercentage = 90;
        stages[18].tokensUnlockedPercentage = 95;
        stages[19].tokensUnlockedPercentage = 100;

    }

    /**
     * Main method for withdraw tokens from vesting.
     */
    function withdrawTokens () onlyWithdrawAddress private {
        // Setting initial tokens balance on a first withdraw.
        if (initialTokensBalance == 0) {
            setInitialTokensBalance();
        }
        uint256 tokensToSend = getAvailableTokensToWithdraw();
        sendTokens(tokensToSend);
    }

    /**
     * Set initial tokens balance when making the first withdrawal.
     */
    function setInitialTokensBalance () private {
        initialTokensBalance = bitcca.balanceOf(this);
    }

    /**
     * Send tokens to withdrawAddress.
     * 
     * @param tokensToSend Amount of tokens will be sent.
     */
    function sendTokens (uint256 tokensToSend) private {
        if (tokensToSend > 0) {
            // Updating tokens sent counter
            tokensSent = tokensSent.add(tokensToSend);
            // Sending allowed tokens amount
            bitcca.transfer(withdrawAddress, tokensToSend);
            // Raising event
            emit Withdraw(tokensToSend, now);
        }
    }

    /**
     * Calculate tokens available for withdrawal.
     *
     * @param tokensUnlockedPercentage Percent of tokens that are allowed to be sent.
     *
     * @return Amount of tokens that can be sent according to provided percentage.
     */
    function getTokensAmountAllowedToWithdraw (uint256 tokensUnlockedPercentage) private view returns (uint256) {
        uint256 totalTokensAllowedToWithdraw = initialTokensBalance.mul(tokensUnlockedPercentage).div(100);
        uint256 unsentTokensAmount = totalTokensAllowedToWithdraw.sub(tokensSent);
        return unsentTokensAmount;
    }

    /**
     * Get tokens unlocked percentage on current stage.
     * 
     * @return Percent of tokens allowed to be sent.
     */
    function getTokensUnlockedPercentage () private view returns (uint256) {
        uint256 allowedPercent;
        
        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }
        
        return allowedPercent;
    }
}

contract bitccaVesting is bitccaTokenVesting {
    constructor(ERC20TokenInterface token, address withdraw) bitccaTokenVesting(token, withdraw) public {}
}
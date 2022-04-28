/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

pragma solidity ^0.8.11;
//SPDX-License-Identifier: UNLICENSED

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IDEXRouter {
  function factory() external view returns (address);

  function WETH() external view returns (address);

    function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
  
}

interface IDistributor {
    function distributeBuyFee() external returns (bool);
    function setNativePayoutOverMaxWallet(address, uint256) external returns (bool);
    function setNativePayoutBelowMaxWallet(address, uint256) external returns (bool);
    function enablePayoutToken(address) external returns (bool);
    function disablePayoutToken(address, address, address[] memory) external returns (bool);
    function setNewHolderPayout(address, address) external returns (bool);
    function withdrawSingleReward(address payable, address, uint256, uint256) external returns (bool);
    function initializeDistribution(address[] memory, uint256[] memory, uint256) external returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed value);
    event Approval(address indexed owner, address indexed spender, uint256 indexed value);
}

contract HolderManager {

    using SafeMath for uint256;
    string internal _developer = "This information is currently not public!";

    mapping (address => bool) internal owners;
    mapping (address => bool) internal authorizations;

    //event singleRewardWithdrawn(address indexed from, address indexed to, uint256 value);
    event rewardsDistributed(bool indexed success, uint256 indexed blockTimestamp);
    event OwnershipChanged(address indexed owner, bool indexed isOwner);
    event AuthorizationChanged(address indexed owner, bool indexed isAuthorized);

    string constant public _name = "Diversified Finance";
    string constant public _symbol = "DiFi";
    uint8 constant public _decimals = 6;

    uint256 constant _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(40); // 2,5%
    uint256 public _maxWallet = _totalSupply.div(40); // 2,5%

    uint256 public totalTokensStaked;

    //address constant _router = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; //TraderJoeV2 Router
    address constant _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Rinkeby UniswapV2 Router
    //address constant _router = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106; //AVAX Pangolin Router
    //address constant _router = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; //SushiSwap AVAX Router
    //address constant _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //BSC Mainnet PancakeSwap Router
    //address public WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; //Avalanche WAVAX
    address public WAVAX = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //WETH, Rinkeby
    //address DAI = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70; //AVAX DAI

    //Default token address for new holders
    address defaultToken;
    string defaultTicker;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address payable public autoLiquidityReceiver= payable(0xB3F6120E4FC40C5aD0bA201A709B586910386F55);
    address payable public farmingFeeReceiver= payable(0xB3F6120E4FC40C5aD0bA201A709B586910386F55);
    address payable public operationsFeeReceiver= payable(0xB3F6120E4FC40C5aD0bA201A709B586910386F55);

    uint256 autoLiqTokens = 0; //Running total of tokens meant for auto liquidation
    uint256 farmTokens = 0; //Running total of fees for the farming address
    uint256 opTokens = 0; //Running total of fees for the operations address

    uint256 public totalBuyFeeTokens = 0; //Running total of all purchase fees ever taken
    uint256 public totalSellFeeTokens = 0; //Running total of all the sell fees ever taken
    uint256 public minPeriod = 5 minutes; //The minimum wait time for payouts
    uint256 public lastDistributionBlock; //The last block that had a distribution
    uint256 public minTokensForRewards = 10000 ** _decimals; //The minimum token balance needed to earn rewards
    uint256 public minLiqTokens = 10000 ** _decimals; //The minimum # of tokens needed to be converted to liquidity required before a conversion will start
    address public otherLiquidityToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address[] public otherLiquidityTokenPath;

    struct holderInfo { //Defines holder dividend information
        uint256 tokenBalance; //Balance of native token in the holder's wallet
        string  tokenTicker; //Ticker of the selected payout token
        bool exists; //Does this holder already exist
        bool hasExisted; //Indicates whether or not the address has been a holder before
        bool rewardsBoosted; //Does the holder have boosted reward payouts
        uint256 rewardsMultiplier; //Temporary rewards payout multiplier
        uint256 baseRewardsMultiplier; //Default rewards payout multiplier, lifetime
        uint256 multiplierBlockStart; //What is the block that the rewards payout started
        uint256 multiplierBlockEnd; //What is the block that the rewards payout started, should be multiplierBlockStart + (uint256 * 1 seconds)
        uint256 tokensStaked; //Tokens currently being staked by the holder
    }

    address[] tokenHolders; //List of all token holders
    mapping (address => uint256) tokenHolderIndexes; //Returns the index of the token holder in the tokenHolders array
    mapping (address => holderInfo) tokenHolderInfo; //Token holder address leads to the information about that holder
    mapping (address => uint256) lockedTokens; //The number of tokens an address has locked. Locked = unable to be moved from the wallet. These tokens still earn reflections

    mapping (address => bool) isFeeExempt; //Addresses in this list are exempt from paying fees
    mapping (address => bool) isTxLimitExempt; //Addresses in this list are exempt from transaction limits
    mapping (address => bool) isWalletLimitExempt; //Addresses in this list are exempt from token quantity posession limits
    mapping (address => bool) isDividendExempt; //Addresses in this list are exempt from receiving dividends on their tokens
    mapping (address => bool) isBlacklisted; //Addresses in this list are exempt from receiving dividends, sending, or receiving tokens
    mapping (address => bool) isCEX; //Mapping that indicates whether or not an address belongs to a CEX
    bool cexReceiverFee = true; //Indicates whether CEX addresses will be subject to a fee if they're the receiver of a transfer
    bool cexSenderFee = true; //Indicates whether CEX addresses will be subject to a fee if they're the sender of a transfer
    uint256 totalReceiverTokensCEX; //The total number of tokens that have been taken as fees during transfers where a CEX is the receiver
    uint256 totalSenderTokensCEX; //The total number of tokens that have been taken as fees during transfers where a CEX is the sender

    mapping (address => mapping (address => uint256)) _allowances; //Approved amounts to be sent from one address to another

    uint256 public liquidityFeeBuy = 0;
    uint256 public reflectionFeeBuy = 1000;
    uint256 public operationsFeeBuy = 0;
    uint256 public farmingFeeBuy = 500;

    uint256 public liquidityFeeSell = 300;
    uint256 public reflectionFeeSell = 0;
    uint256 public operationsFeeSell = 700;
    uint256 public farmingFeeSell = 500;

    uint256 public liquiditySenderCEX = 0;
    uint256 public reflectionSenderCEX = 1000;
    uint256 public operationsSenderCEX = 0;
    uint256 public farmingSenderCEX = 500;

    uint256 public liquidityReceiverCEX = 300;
    uint256 public reflectionReceiverCEX = 0;
    uint256 public operationsReceiverCEX = 700;
    uint256 public farmingReceiverCEX = 500;

    uint256 public feeDenominator = 10000;

    uint256 public _stakingBoostMultiplier = 2; //The rewards multiplier for staked tokens

    IDEXRouter router; //The DEX router
    address pair; //The address for the WAVAX pair with this native token
    address dividendDist;
    bool constant isAVAX = true;

    bool public transferEnabled = true;
    bool public buySellEnabled = true;

    //BEGIN DISTRIBUTION VARIABLES
    mapping (address => uint256) tokensHeld; //The # of tokens held by a user. Includes balance, staked, and waiting to be claimed (if any)
    mapping (address => uint256) tokensHeldBoosted;
    mapping (address => uint256) tokenMultiplier;
    mapping (address => uint256) nativeTokensOwed; //Once a swap fails, increment the native tokens owed to a user
    address[] tokenHoldersCopy; //Make a copy of the current token holder list.  Prevents errors if the list changes
    address[] eligibleHolders; //List of all eligible holders to receive rewards
    uint256[] eligibleBalances; //List of all balances for eligible holders, uses the same index as eligibleHolders
    address[] nativeOwedHolders; //List of all addresses owed native tokens, uses the same index as nativeOwedAfterDist
    uint256[] nativeOwedAfterDist; //The quantity of native tokens owed to each eligible holder after distributions complete
    uint256 totalHolderTokensBoosted; //Adds all holder tokens, including boosted balances. Used for converting to the % of proper native token payouts
    uint256 currentIndex = 0; //The current index of looping through all holders
    uint256 currentTokenIndex = 0; //The current index of looping through all payout tokens
    uint256 currentNativeToDist; //The placeholder for the number of tokens to be used for reflections
    uint256 distributorGas; //The amount of gas to use during each distribution loop
    bool distributingFees = false;
    bool doneDist; //Indicates whether or not fee distributions are complete
    bool initializedDist; //Indicates whether or not the Dividend Distributor has been initialized for the current distributions
    bool calculatingEligible; //Indicates whether or not an eligible holder calculation is already being carried out
    bool eligibleStarted; //Indicates whether or not the eligible holder calculation has been started
    bool addingNative; //Indicates whether or not a the addNativeDistToBalance function is being executed
    //END DISTRIBUTION VARIABLES

    constructor(){
        owners[msg.sender] = true;
        authorizations[msg.sender] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "DiFi: Address is not the owner"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "DiFi: Address is not authorized"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return owners[account];
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function changeOwnership(address payable adr, bool _owner) public onlyOwner {
        owners[adr] = _owner;
        authorizations[adr] = _owner;
        emit OwnershipChanged(adr, _owner);
    }

    function changeAuthorization(address payable adr, bool _auth) public onlyOwner {
        authorizations[adr] = _auth;
        emit AuthorizationChanged(adr, _auth);
    }

    function getEligibleHolders() external authorized{

        uint256 gasUsed = 0;
        uint256 startGas = gasleft();

        if(!eligibleStarted){
            eligibleStarted = true;
            initializedDist = false;
            addingNative = false;
            address[] memory blankArray;
            uint256[] memory blankArray2;
            eligibleHolders = blankArray;
            eligibleBalances = blankArray2;
            tokenHoldersCopy = tokenHolders;
        }

        address[] memory m_tokenHolders = tokenHoldersCopy;

        if(!calculatingEligible){
                calculatingEligible = true;

                while(gasUsed < distributorGas && currentIndex < m_tokenHolders.length) {

                  address currentHolder = m_tokenHolders[currentIndex];

                    tokensHeld[currentHolder] = tokenHolderInfo[currentHolder].tokenBalance.add(tokenHolderInfo[currentHolder].tokensStaked);

                    //Make sure the address isn't dividend exempt or blacklisted and has enough tokens to earn rewards
                    if(!isDividendExempt[currentHolder] && !isBlacklisted[currentHolder] && tokensHeld[currentHolder] > minTokensForRewards) {

                        //Checks if the holder has an active rewards boost that needs to be endedd
                        if(block.timestamp > tokenHolderInfo[currentHolder].multiplierBlockEnd){
                            //endRewardsMultiplier(currentHolder);
                            tokenHolderInfo[currentHolder].rewardsMultiplier = tokenHolderInfo[currentHolder].baseRewardsMultiplier; //Set the number to multiply rewards by
                            tokenHolderInfo[currentHolder].multiplierBlockStart = 0; //Set the timestamp of the block where the rewards started
                            tokenHolderInfo[currentHolder].multiplierBlockEnd = 0 ; //Set the end block of the rewards
                            tokenHolderInfo[currentHolder].rewardsBoosted = false;
                        }

                        //Checks if both reward multipliers are <= 1, if so, make sure they stay as 1 and set the current multiplier for the holder to 1
                        if(tokenHolderInfo[currentHolder].rewardsMultiplier <= 1
                        && tokenHolderInfo[currentHolder].baseRewardsMultiplier <= 1){
                            tokenHolderInfo[currentHolder].rewardsMultiplier = 1;
                            tokenHolderInfo[currentHolder].baseRewardsMultiplier = 1;
                             tokenMultiplier[currentHolder] = 1;
                        } else {
                            //If the holder has boosted rewards
                            if(tokenHolderInfo[currentHolder].rewardsBoosted){
                                //Set the token multiplier to either the base multiplier or the temporary multiplier, whichever is higher
                                if(tokenHolderInfo[currentHolder].rewardsMultiplier >= tokenHolderInfo[currentHolder].baseRewardsMultiplier){
                                    tokenMultiplier[currentHolder] = tokenHolderInfo[currentHolder].rewardsMultiplier;
                                } else if(tokenHolderInfo[currentHolder].rewardsMultiplier <= tokenHolderInfo[currentHolder].baseRewardsMultiplier){
                                    tokenMultiplier[currentHolder] = tokenHolderInfo[currentHolder].baseRewardsMultiplier;
                                }
                            } else { //If they don't have a temporary rewards multiplier
                                tokenMultiplier[currentHolder] = tokenHolderInfo[currentHolder].baseRewardsMultiplier;
                            }
                        }

                        uint256 stakedAmount = 0;

                        if(tokenMultiplier[currentHolder] == 1) {

                        stakedAmount = tokenHolderInfo[currentHolder].tokensStaked.mul(_stakingBoostMultiplier);
                        tokensHeldBoosted[currentHolder] = tokenHolderInfo[currentHolder].tokenBalance.add(stakedAmount);
                        
                        } else { //If the multiplier > 1

                            if(tokenMultiplier[currentHolder] > _stakingBoostMultiplier){
                                tokensHeldBoosted[currentHolder] = tokensHeld[currentHolder].mul(tokenMultiplier[currentHolder]);
                            } else {
                                stakedAmount = tokenHolderInfo[currentHolder].tokensStaked.mul(_stakingBoostMultiplier);
                                tokensHeldBoosted[currentHolder] = tokenHolderInfo[currentHolder].tokenBalance.mul(tokenMultiplier[currentHolder]).add(stakedAmount);
                            }
                        }

                        totalHolderTokensBoosted = totalHolderTokensBoosted.add(tokensHeldBoosted[currentHolder]); //Add the boosted token amount to the total
                        //totalHolderTokens = totalHolderTokens.add(tokensHeld[currentHolder]); //Add the normal token amount to the total

                        eligibleHolders.push(currentHolder); //Add the holder into the array of addresses eligible to receive reflections
                        eligibleBalances.push(tokensHeldBoosted[currentHolder]);

                    }
                        currentIndex++;
                        gasUsed = startGas - gasleft();
                    
                }

                if(currentIndex >= m_tokenHolders.length){
                    bool success = IDistributor(dividendDist).initializeDistribution(eligibleHolders, eligibleBalances, totalHolderTokensBoosted);
                    require(success, "DiFi: Failed to initialize distributor!");

                    totalHolderTokensBoosted = 0;
                    currentIndex = 0;
                    calculatingEligible = false;
                    initializedDist = true;
                    eligibleStarted = false;
                    
                }
                calculatingEligible = false;
            }
    }

    function addNativeDistToBalance() external authorized { 
        uint256 gasUsed = 0;
        uint256 startGas = gasleft();
        uint256 m_distributorGas = distributorGas;

        address[] memory m_nativeOwedHolders = nativeOwedHolders;
        uint256[] memory m_nativeOwedAfterDist = nativeOwedAfterDist;
        uint256 m_currentIndex = currentIndex;

        if(!addingNative){
                addingNative = true;

                while(gasUsed < m_distributorGas && m_currentIndex < m_nativeOwedHolders.length) {

                    uint256 _tokensHeld = tokenHolderInfo[m_nativeOwedHolders[m_currentIndex]].tokenBalance.add(tokenHolderInfo[m_nativeOwedHolders[m_currentIndex]].tokensStaked);
                    uint256 _amount = m_nativeOwedAfterDist[m_currentIndex];
                    address _holder = m_nativeOwedHolders[m_currentIndex];

                    if(_amount > 0){
                        if(_tokensHeld.add(_amount) > _maxWallet) {
                            bool success = IDistributor(dividendDist).setNativePayoutOverMaxWallet(_holder, _amount);
                            require(success, "DiFi: Failed");
                            nativeTokensOwed[_holder] = 0;
                        } else {
                            bool success = IDistributor(dividendDist).setNativePayoutBelowMaxWallet(_holder, _amount);
                            require(success, "DiFi: Failed");
                            tokenHolderInfo[_holder].tokenBalance = tokenHolderInfo[_holder].tokenBalance.add(_amount);
                            tokenHolderInfo[address(dividendDist)].tokenBalance = tokenHolderInfo[address(dividendDist)].tokenBalance.sub(_amount);
                            nativeTokensOwed[_holder] = 0;
                        }
                    }

                    m_currentIndex++;
                    gasUsed = startGas - gasleft();
                }

                currentIndex = m_currentIndex;

                if(m_currentIndex >= m_nativeOwedHolders.length){
                    currentIndex = 0;
                    lastDistributionBlock = block.timestamp;
                    doneDist = false;
                    initializedDist = false;
                    emit rewardsDistributed(true, block.timestamp);
                }

                addingNative = false;
            }
    }

    //Ends the reward multiplier for the passed address
    // function endRewardsMultiplier(address _address) public authorized {
    //     tokenHolderInfo[_address].rewardsMultiplier = tokenHolderInfo[_address].baseRewardsMultiplier; //Set the number to multiply rewards by
    //     tokenHolderInfo[_address].multiplierBlockStart = 0; //Set the timestamp of the block where the rewards started
    //     tokenHolderInfo[_address].multiplierBlockEnd = 0 ; //Set the end block of the rewards
    //     tokenHolderInfo[_address].rewardsBoosted = false;
    // }
}
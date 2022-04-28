/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

/*

Diversified Finance (DiFi)

Website: http://diversified.fi/

Developer: Not public as of publishing this.
Use the getDeveloper() function to check if
the developer has made their identity public.

Diversified Finance is a Web3 finance platform
that allows users to generate returns through a
variety of sources. The majority of these sources
are found in the world of decentralized finance (DeFi),
but may be located in various industries, both related
and unrelated to the cryptocurrency industry.

A percentage of each purchase and/or sale is deducted
from the buyer and/or seller as a buy or sell "tax",
respectively. This "tax" may be allocated to various
destinations, such as: existing token holders, the 
investment treasury, the operations treasury, or the 
liquidity pool. These different "taxes" can be adjusted 
and are viewable using the functions available in this
contract's code. These "taxes" may be increased or
decreased over time depending on market conditions.

Our mission is to farm yields across multiple chains
within the industry, as well as to seek out opportunities
unrelated to the cryptocurrency industry. The generated
yields will then be distributed to holders of the native
token.

Are you prepared to enter the world of Diversified Finance (DiFi)?

*/

pragma solidity ^0.8.11;
//SPDX-License-Identifier: UNLICENSED

//import "SafeMath.sol";
//import "Interfaces.sol";
//import "Authorize.sol";

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

interface IDEXFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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

contract DiversifiedFinance is IERC20 {

    using SafeMath for uint256;
    string internal _developer = "This information is currently not public!";

    mapping (address => bool) internal owners;
    mapping (address => bool) internal authorizations;

    //event singleRewardWithdrawn(address indexed from, address indexed to, uint256 value);
    event rewardsDistributed(bool indexed success, uint256 indexed blockTimestamp);
    event OwnershipChanged(address indexed owner, bool indexed isOwner);
    event AuthorizationChanged(address indexed owner, bool indexed isAuthorized);
    event addLiquidity(address indexed difiTokens, uint256 amountDifi, address indexed otherLiqToken, uint256 amountOther, uint256 indexed blockNumber);

    string constant public _name = "Diversified Finance";
    string constant public _symbol = "DiFi";
    uint8 constant public _decimals = 6;

    uint256 constant _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(40); // 2,5%
    uint256 public _maxWallet = _totalSupply.div(40); // 2,5%

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
    uint256 public minTokensForRewards = 10000 * (10 ** _decimals); //The minimum token balance needed to earn rewards
    uint256 public minLiqTokens = 10000 * (10 ** _decimals); //The minimum # of tokens needed to be converted to liquidity required before a conversion will start
    address public otherLiquidityToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address[] public otherLiquidityTokenPath;

    struct holderInfo { //Defines holder dividend information
        uint256 tokenBalance; //Balance of native token in the holder's wallet
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
    mapping (address => uint256) blacklistedTokens; //The number of tokens an address has that are permanently locked. These tokens still earn reflections

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

    address holderManager;

    constructor () {
        uint256 MAX = ~uint256(0);
        router = IDEXRouter(_router);
        _allowances[address(this)][_router] = MAX;
        _allowances[address(this)][address(router)] = MAX;
        WAVAX = router.WETH(); //Set's the address of WAVAX
        //pair = IDEXFactory(router.factory()).createPair(address(this), WAVAX);

        if(IDEXFactory(router.factory()).getPair(WAVAX, address(this)) == address(0)){
          pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        } else{
          pair = IDEXFactory(router.factory()).getPair(WAVAX, address(this));
        }

        lastDistributionBlock = block.timestamp;

        otherLiquidityTokenPath = [address(this), otherLiquidityToken];
        
        _allowances[address(this)][address(router)] = _totalSupply; //Approves the contract to send the total supply to the router's address
        
        defaultToken = address(this); //Sets the default payout token for a new user to the native token

        //dividendDist = new DividendIDistributor(address(this), msg.sender, WAVAX, address(router)); //Initialize the dividend distributor

        authorizations[msg.sender] = true;
        owners[msg.sender] = true;
        authorizations[address(dividendDist)] = true;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isWalletLimitExempt[msg.sender] = true;

        isFeeExempt[autoLiquidityReceiver] = true;
        isTxLimitExempt[autoLiquidityReceiver] = true;
        isWalletLimitExempt[autoLiquidityReceiver] = true;

        isFeeExempt[farmingFeeReceiver] = true;
        isTxLimitExempt[farmingFeeReceiver] = true;
        isWalletLimitExempt[farmingFeeReceiver] = true;

        isFeeExempt[operationsFeeReceiver] = true;
        isTxLimitExempt[operationsFeeReceiver] = true;
        isWalletLimitExempt[operationsFeeReceiver] = true;

        // isFeeExempt[address(dividendDist)] = true;
        // isTxLimitExempt[address(dividendDist)] = true;
        // isWalletLimitExempt[address(dividendDist)] = true;

        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[ZERO] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[_router] = true;
        isDividendExempt[_router] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[address(this)] = true;

        _approve(address(this), _router, MAX);
        _approve(address(this), address(router), MAX);
        _approve(address(this), address(pair), MAX);

        tokenHolderInfo[msg.sender].tokenBalance = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function setDividendDistAddress(address _dist) external onlyOwner {
        dividendDist = _dist;
        authorizations[dividendDist] = true;
        isFeeExempt[_dist] = true;
        isTxLimitExempt[_dist] = true;
        isWalletLimitExempt[_dist] = true;
    }

    function getDividendDistAddress() public authorized view returns (address){
        return dividendDist;
    }

    function setHolderManager(address _hold) external onlyOwner {
        holderManager = _hold;
        authorizations[holderManager] = true;
    }

    function getHolderManager() public authorized view returns (address){
        return holderManager;
    }

    /*******************************************************
    BEGIN FUNCTIONS FOR ACCESS CONTROL
    *******************************************************/

    modifier onlyOwner() {
        require(isOwner(msg.sender), "DiFi: Address is not the owner"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "DiFi: Address is not authorized"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return owners[account];
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function changeOwnership(address payable adr, bool _owner) public onlyOwner {
        owners[adr] = _owner;
        authorizations[adr] = _owner;
        emit OwnershipChanged(adr, _owner);
    }

    function changeAuthorization(address payable adr, bool _auth) public onlyOwner {
        authorizations[adr] = _auth;
        emit AuthorizationChanged(adr, _auth);
    }

    /*******************************************************
    END FUNCTIONS FOR ACCESS CONTROL
    *******************************************************/



    /*******************************************************
    BEGIN FUNCTIONS FOR TRANSFERRING TOKENS
    *******************************************************/

    //Approves spending a certain # of tokens
    function approve(address spender, uint256 amount) external returns (bool) { 
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "DiFi: Cannot approve from the zero address!");
        require(spender != address(0), "DiFi: Cannot approve to the zero address!");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    //Initiates a transfer from a sender to a receiver with a specified amount
    function transfer(address recipient, uint256 amount) external override returns (bool) { 
        return _transferFrom(msg.sender, recipient, amount);
    }

    //Checks that the approved transfer amount matches
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "DiFi: Insufficient allowance!");
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "DiFi: Insufficient allowance!");

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        require(transferEnabled, "DiFi: Token transfers are currently disabled!");
        require(balanceOf(sender) >= amount, "DiFi: Insufficient token balance of sender!");
        require(!isBlacklisted[sender], "DiFi: The sender is blacklisted!");
        require(!isBlacklisted[recipient], "DiFi: The recipient is blacklisted!");
        require(tokenHolderInfo[sender].tokenBalance >= (amount.add(lockedTokens[sender]).add(blacklistedTokens[sender])), "DiFi: Cannot transfer locked or blacklisted tokens!");

        if(!tokenHolderInfo[recipient].exists){
            if(tokenHolderInfo[recipient].hasExisted){
                tokenHolderIndexes[recipient] = tokenHolders.length; //Keeps track of the index the new holder is located at in the list of all holders
                tokenHolders.push(recipient); //Push the token holder after getting the index, since index = array.length - 1
            }
            else {
                addHolder(recipient);
            }
        }

        if(!isTxLimitExempt[sender] || !isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmount, "DiFi: Amount exceeds the maximum allowed transaction amount!");
        }

        bool isBuy = sender == pair || sender == _router; //Check if the transaction is a purchase
        bool isSell = recipient == pair || recipient == _router; //Check if the transaction is a sale
        uint256 amountReceived = amount;
        
        if (isBuy) {
            amountReceived = isFeeExempt[recipient] ? amount : takeBuyFee(amount);
            require(buySellEnabled, "DiFi: Purchases and sales are currently disabled!");
        }

        if (isSell) {
            amountReceived = isFeeExempt[sender] ? amount : takeSellFee(amount);
            require(buySellEnabled, "DiFi: Purchases and sales are currently disabled!");
        }

        if(isCEX[sender] && cexSenderFee){
            amountReceived = amountReceived.sub(takeSenderCEX(amount));
        }

        if(isCEX[recipient] && cexReceiverFee){
            amountReceived = amountReceived.sub(takeReceiverCEX(amount));
        }

        if (!isWalletLimitExempt[recipient]){
            require((tokenHolderInfo[recipient].tokenBalance.add(amountReceived)) <= _maxWallet, "DiFi: Maximum wallet balance limit exceeded!");
        }

        tokenHolderInfo[sender].tokenBalance = tokenHolderInfo[sender].tokenBalance.sub(amount);
        tokenHolderInfo[recipient].tokenBalance = tokenHolderInfo[recipient].tokenBalance.add(amountReceived);

        if(balanceOf(address(this)) >= minLiqTokens){
            addLiquidityTokens();
        }

        if(block.timestamp >= lastDistributionBlock.add(minPeriod)){
            if(!initializedDist){
                getEligibleHolders();
            } else{
                if(!doneDist){
                    bool result = IDistributor(dividendDist).distributeBuyFee();
                    doneDist = result;

                    if(doneDist){
                        addNativeDistToBalance();
                    }

                } else{
                    addNativeDistToBalance();
                }
            }
        }

        if(tokenHolderInfo[sender].tokenBalance == 0){
            removeHolder(sender);
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function takeBuyFee(uint256 amount) internal returns (uint256) {
        
        uint256 feeAmountReflections = amount.mul(reflectionFeeBuy).div(feeDenominator);
        uint256 feeAmountFarming = amount.mul(farmingFeeBuy).div(feeDenominator);
        uint256 feeAmountOperations = amount.mul(operationsFeeBuy).div(feeDenominator);
        uint256 feeAmountLiquidity = amount.mul(liquidityFeeBuy).div(feeDenominator);

        tokenHolderInfo[address(dividendDist)].tokenBalance = tokenHolderInfo[address(dividendDist)].tokenBalance.add(feeAmountReflections);
        tokenHolderInfo[farmingFeeReceiver].tokenBalance = tokenHolderInfo[farmingFeeReceiver].tokenBalance.add(feeAmountFarming);
        tokenHolderInfo[operationsFeeReceiver].tokenBalance = tokenHolderInfo[operationsFeeReceiver].tokenBalance.add(feeAmountOperations);

        tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.add(feeAmountLiquidity);

        uint256 feeAmount = feeAmountReflections.add(feeAmountFarming).add(feeAmountOperations).add(feeAmountLiquidity);

        totalBuyFeeTokens = totalBuyFeeTokens.add(feeAmount);

        return amount.sub(feeAmount);
    }

    function takeSellFee(uint256 amount) internal returns (uint256) {
        uint256 feeAmountReflections = amount.mul(reflectionFeeSell).div(feeDenominator);
        uint256 feeAmountFarming = amount.mul(farmingFeeSell).div(feeDenominator);
        uint256 feeAmountOperations = amount.mul(operationsFeeSell).div(feeDenominator);
        uint256 feeAmountLiquidity = amount.mul(liquidityFeeSell).div(feeDenominator);

        tokenHolderInfo[address(dividendDist)].tokenBalance = tokenHolderInfo[address(dividendDist)].tokenBalance.add(feeAmountReflections);
        tokenHolderInfo[farmingFeeReceiver].tokenBalance = tokenHolderInfo[farmingFeeReceiver].tokenBalance.add(feeAmountFarming);
        tokenHolderInfo[operationsFeeReceiver].tokenBalance = tokenHolderInfo[operationsFeeReceiver].tokenBalance.add(feeAmountOperations);

        tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.add(feeAmountLiquidity);

        uint256 feeAmount = feeAmountReflections.add(feeAmountFarming).add(feeAmountOperations).add(feeAmountLiquidity);

        totalSellFeeTokens = totalSellFeeTokens.add(feeAmount);

        return amount.sub(feeAmount);
    }

    function takeReceiverCEX(uint256 amount) internal returns (uint256) {
        
        uint256 feeAmountReflections = amount.mul(reflectionReceiverCEX).div(feeDenominator);
        uint256 feeAmountFarming = amount.mul(farmingReceiverCEX).div(feeDenominator);
        uint256 feeAmountOperations = amount.mul(operationsReceiverCEX).div(feeDenominator);
        uint256 feeAmountLiquidity = amount.mul(liquidityReceiverCEX).div(feeDenominator);

        tokenHolderInfo[address(dividendDist)].tokenBalance = tokenHolderInfo[address(dividendDist)].tokenBalance.add(feeAmountReflections);
        tokenHolderInfo[farmingFeeReceiver].tokenBalance = tokenHolderInfo[farmingFeeReceiver].tokenBalance.add(feeAmountFarming);
        tokenHolderInfo[operationsFeeReceiver].tokenBalance = tokenHolderInfo[operationsFeeReceiver].tokenBalance.add(feeAmountOperations);

        tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.add(feeAmountLiquidity);

        uint256 feeAmount = feeAmountReflections.add(feeAmountFarming).add(feeAmountOperations).add(feeAmountLiquidity);

        totalReceiverTokensCEX = totalReceiverTokensCEX.add(feeAmount);

        return feeAmount;
    }

    function takeSenderCEX(uint256 amount) internal returns (uint256) {
        
        uint256 feeAmountReflections = amount.mul(reflectionSenderCEX).div(feeDenominator);
        uint256 feeAmountFarming = amount.mul(farmingSenderCEX).div(feeDenominator);
        uint256 feeAmountOperations = amount.mul(operationsSenderCEX).div(feeDenominator);
        uint256 feeAmountLiquidity = amount.mul(liquiditySenderCEX).div(feeDenominator);

        tokenHolderInfo[address(dividendDist)].tokenBalance = tokenHolderInfo[address(dividendDist)].tokenBalance.add(feeAmountReflections);
        tokenHolderInfo[farmingFeeReceiver].tokenBalance = tokenHolderInfo[farmingFeeReceiver].tokenBalance.add(feeAmountFarming);
        tokenHolderInfo[operationsFeeReceiver].tokenBalance = tokenHolderInfo[operationsFeeReceiver].tokenBalance.add(feeAmountOperations);

        tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.add(feeAmountLiquidity);

        uint256 feeAmount = feeAmountReflections.add(feeAmountFarming).add(feeAmountOperations).add(feeAmountLiquidity);

        totalSenderTokensCEX = totalSenderTokensCEX.add(feeAmount);

        return feeAmount;
    }

    function addLiquidityTokens() internal {

        uint256 amountDifi = balanceOf(address(this)) / 2;
        uint256 amountDifiSwap = balanceOf(address(this)) - amountDifi;
        uint256 amountOtherLiqToken;
        bool success;

        _approve(address(this), address(router), amountDifiSwap);

        try router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountDifiSwap, //Amount in
            0, //Minimum amount out
            otherLiquidityTokenPath, //The path of the swap to take
            address(this), //The receiving address from the swap
            block.timestamp)
            {
                success = true;
            } catch Error(
                string memory /*err*/
            ) {
                success = false;
            }

        require(success, "DiFi: Failed to swap tokens prior to automatically adding liquidity!");

        amountOtherLiqToken = IERC20(otherLiquidityToken).balanceOf(address(this));

        _approve(address(this), address(router), amountDifi);
        IERC20(otherLiquidityToken).approve(address(router), amountOtherLiqToken);
        
        try router.addLiquidity(
            address(this),
            otherLiquidityToken,
            amountDifi,
            amountOtherLiqToken,
            0,  // slippage unavoidable
            0,  // slippage unavoidable
            autoLiquidityReceiver,
            block.timestamp)
            {
                success = true;
            } catch Error(
                string memory /*err*/
            ) {
                success = false;
            }
            require(success, "DiFi: Failed to automatically add liquidity!");

            emit addLiquidity(address(this), amountDifi, otherLiquidityToken, amountOtherLiqToken, block.timestamp);
    }

    //Used to manually send a specific token from the contract to an address
    function sendTokensManually(address payable _recipient, address _token, uint256 amount) external onlyOwner returns (bool){

        require(amount > 0, "DiFi: Cannot transfer an amount of 0 tokens!");

        if(_token != address(this)) { //Check if the token is the native token
            
            (bool success, ) = address(_token).call(abi.encodeWithSignature("transfer(address,uint256)", payable(_recipient), amount));
            return success;
            
        } else { //If the token is the native token
            //Add the token balance to the message sender's balance
            tokenHolderInfo[_recipient].tokenBalance = tokenHolderInfo[_recipient].tokenBalance.add(tokenHolderInfo[address(this)].tokenBalance); 
            tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.sub(amount); //Set the token balance for the contract to 0
            return true;
        }
    }

    /*******************************************************
    END FUNCTIONS FOR TRANSFERRING TOKENS
    *******************************************************/



    /*******************************************************
    BEGIN FUNCTIONS FOR DISTRIBUTING REFLECTIONS
    *******************************************************/

    /*function getEligibleHolders() internal returns (bool){

        uint256 gasUsed = 0;
        uint256 startGas = gasleft();

        if(!initializedDist){
            initializedDist = false;
            addingNative = false;
            address[] memory blankArray;
            uint256[] memory blankArray2;
            eligibleHolders = blankArray;
            eligibleBalances = blankArray2;
            tokenHoldersCopy = tokenHolders;
        }

        if(!calculatingEligible){
                calculatingEligible = true;

                while(gasUsed < distributorGas && currentIndex < tokenHoldersCopy.length) {

                    tokensHeld[tokenHoldersCopy[currentIndex]] = tokenHolderInfo[tokenHoldersCopy[currentIndex]].tokenBalance.add(tokenHolderInfo[tokenHoldersCopy[currentIndex]].tokensStaked);

                    //Make sure the address isn't dividend exempt or blacklisted and has enough tokens to earn rewards
                    if(!isDividendExempt[tokenHoldersCopy[currentIndex]] && !isBlacklisted[tokenHoldersCopy[currentIndex]] && tokensHeld[tokenHoldersCopy[currentIndex]] > minTokensForRewards) {

                        //Checks if the holder has an active rewards boost that needs to be endedd
                        if(block.timestamp > tokenHolderInfo[tokenHoldersCopy[currentIndex]].multiplierBlockEnd){
                            endRewardsMultiplier(tokenHoldersCopy[currentIndex]);
                        }

                        //Checks if both reward multipliers are <= 1, if so, make sure they stay as 1 and set the current multiplier for the holder to 1
                        if(tokenHolderInfo[tokenHoldersCopy[currentIndex]].rewardsMultiplier <= 1
                        && tokenHolderInfo[tokenHoldersCopy[currentIndex]].baseRewardsMultiplier <= 1){
                            tokenHolderInfo[tokenHoldersCopy[currentIndex]].rewardsMultiplier = 1;
                            tokenHolderInfo[tokenHoldersCopy[currentIndex]].baseRewardsMultiplier = 1;
                             tokenMultiplier[tokenHoldersCopy[currentIndex]] = 1;
                        } else {
                            //If the holder has boosted rewards
                            if(tokenHolderInfo[tokenHoldersCopy[currentIndex]].rewardsBoosted){
                                //Set the token multiplier to either the base multiplier or the temporary multiplier, whichever is higher
                                if(tokenHolderInfo[tokenHoldersCopy[currentIndex]].rewardsMultiplier >= tokenHolderInfo[tokenHoldersCopy[currentIndex]].baseRewardsMultiplier){
                                    tokenMultiplier[tokenHoldersCopy[currentIndex]] = tokenHolderInfo[tokenHoldersCopy[currentIndex]].rewardsMultiplier;
                                } else if(tokenHolderInfo[tokenHoldersCopy[currentIndex]].rewardsMultiplier <= tokenHolderInfo[tokenHoldersCopy[currentIndex]].baseRewardsMultiplier){
                                    tokenMultiplier[tokenHoldersCopy[currentIndex]] = tokenHolderInfo[tokenHoldersCopy[currentIndex]].baseRewardsMultiplier;
                                }
                            } else { //If they don't have a temporary rewards multiplier
                                tokenMultiplier[tokenHoldersCopy[currentIndex]] = tokenHolderInfo[tokenHoldersCopy[currentIndex]].baseRewardsMultiplier;
                            }
                        }

                        uint256 stakedAmount = 0;

                        if(tokenMultiplier[tokenHoldersCopy[currentIndex]] == 1) {

                        stakedAmount = tokenHolderInfo[tokenHoldersCopy[currentIndex]].tokensStaked.mul(_stakingBoostMultiplier);
                        tokensHeldBoosted[tokenHoldersCopy[currentIndex]] = tokenHolderInfo[tokenHoldersCopy[currentIndex]].tokenBalance.add(stakedAmount);
                        
                        } else { //If the multiplier > 1

                            if(tokenMultiplier[tokenHoldersCopy[currentIndex]] > _stakingBoostMultiplier){
                                tokensHeldBoosted[tokenHoldersCopy[currentIndex]] = tokensHeld[tokenHoldersCopy[currentIndex]].mul(tokenMultiplier[tokenHoldersCopy[currentIndex]]);
                            } else {
                                stakedAmount = tokenHolderInfo[tokenHoldersCopy[currentIndex]].tokensStaked.mul(_stakingBoostMultiplier);
                                tokensHeldBoosted[tokenHoldersCopy[currentIndex]] = tokenHolderInfo[tokenHoldersCopy[currentIndex]].tokenBalance.mul(tokenMultiplier[tokenHoldersCopy[currentIndex]]).add(stakedAmount);
                            }
                        }

                        totalHolderTokensBoosted = totalHolderTokensBoosted.add(tokensHeldBoosted[tokenHoldersCopy[currentIndex]]); //Add the boosted token amount to the total
                        //totalHolderTokens = totalHolderTokens.add(tokensHeld[tokenHoldersCopy[currentIndex]]); //Add the normal token amount to the total

                        eligibleHolders.push(tokenHoldersCopy[currentIndex]); //Add the holder into the array of addresses eligible to receive reflections
                        eligibleBalances.push(tokensHeldBoosted[tokenHoldersCopy[currentIndex]]);

                    }
                        currentIndex++;
                        gasUsed = startGas - gasleft();
                    
                }

                if(currentIndex >= tokenHoldersCopy.length){
                    (bool success, ) = address(dividendDist).call(abi.encodeWithSignature("initializeDistribution(address[],uint[])", eligibleHolders, eligibleBalances));
                    require(success, "DiFi: Failed");

                    currentIndex = 0;
                    calculatingEligible = false;
                    initializedDist = true;
                    return true;
                    
                }
                calculatingEligible = false;
            }

            return false;

    }*/

    function getEligibleHolders() internal {
        (bool success, ) = holderManager.delegatecall(abi.encodeWithSignature("getEligibleHolders()"));
        require(success, "DiFi: Failed to aggregate eligible holders!");
    }

    function addNativeDistToBalance() internal {
        (bool success, ) = holderManager.delegatecall(abi.encodeWithSignature("addNativeDistToBalance()"));
        require(success, "DiFi: Failed to distribute DiFi tokens to holders!");
    }

    function setNativeOwed(address[] memory _holders, uint256[] memory _amounts) external authorized {
        nativeOwedHolders = _holders;
        nativeOwedAfterDist = _amounts;
    }

    /*function addNativeDistToBalance() internal { 
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
                            //(bool success, ) = address(dividendDist).call(abi.encodeWithSignature("setNativePayoutOverMaxWallet(address,uint256)", _holder, _amount));
                            bool success = IDistributor(dividendDist).setNativePayoutOverMaxWallet(_holder, _amount);
                            require(success, "DiFi: Failed");
                            nativeTokensOwed[_holder] = 0;
                        } else {
                            //(bool success, ) = address(dividendDist).call(abi.encodeWithSignature("setNativePayoutBelowMaxWallet(address,uint256)", _holder, _amount));
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
    }*/

    /*******************************************************
    END FUNCTIONS FOR DISTRIBUTING REFLECTIONS
    *******************************************************/

    //Disables an approved payout token
    function disablePayoutToken(address _address, address _replacementPayoutTokenAddress) external authorized {
        //(bool success, ) = address(dividendDist).call(abi.encodeWithSignature("disablePayoutToken(address,address,address[])", _address, _replacementPayoutTokenAddress, tokenHolders));
        bool success = IDistributor(dividendDist).disablePayoutToken(_address, _replacementPayoutTokenAddress, tokenHolders);
        require(success, "DiFi: Unable to disable the payout token!");
    }

    //Enables an approved payout token
    function enablePayoutToken(address _token) external authorized {
        //(bool success, ) = address(dividendDist).call(abi.encodeWithSignature("enablePayoutToken(address)", _token));
        bool success = IDistributor(dividendDist).enablePayoutToken(_token);
        require(success, "DiFi: Unable to enable the payout token!");
    }

    //Initializes a new holder
    function addHolder(address _holder) internal { //Adds a new holder to the list of holders

        //(bool success, ) = address(dividendDist).call(abi.encodeWithSignature("setNewHolderPayout(address,address)", _holder, defaultToken));
        bool success = IDistributor(dividendDist).setNewHolderPayout(_holder, defaultToken);
        require(success, "DiFi: Unable to set the payout percentage!");

        tokenHolderIndexes[_holder] = tokenHolders.length; //Keeps track of the index the new holder is located at in the list of all holders
        tokenHolders.push(_holder); //Push the token holder after getting the index, since index = array.length - 1
        
        //Set new holder data
        tokenHolderInfo[_holder].tokenBalance = 0;
        tokenHolderInfo[_holder].exists = true;
        tokenHolderInfo[_holder].hasExisted = true;
        tokenHolderInfo[_holder].rewardsBoosted = false;
        tokenHolderInfo[_holder].rewardsMultiplier = 1;
        tokenHolderInfo[_holder].baseRewardsMultiplier = 1;
        tokenHolderInfo[_holder].multiplierBlockStart = 0;
        tokenHolderInfo[_holder].multiplierBlockEnd = 0;
        tokenHolderInfo[_holder].tokensStaked = 0;
    }

    //Removes the holder from the array of holders. Saves gas and time when distributing rewards
    function removeHolder(address _holder) internal {
        address lastAdded = tokenHolders[tokenHolders.length - 1];
        uint256 indexHolder = tokenHolderIndexes[_holder];

        if(lastAdded != _holder){

            tokenHolderIndexes[lastAdded] = tokenHolderIndexes[_holder];
            tokenHolders[indexHolder] = lastAdded;

            tokenHolders.pop();
            tokenHolderInfo[_holder].exists = false;

        }else {
            tokenHolders.pop();
            tokenHolderInfo[_holder].exists = false;
        }
    }

    function getHolderRewardsInfo(address _holder) external view returns (bool, uint256, uint256, uint256, uint256) {
        return (tokenHolderInfo[_holder].rewardsBoosted, tokenHolderInfo[_holder].rewardsMultiplier, tokenHolderInfo[_holder].baseRewardsMultiplier,
        tokenHolderInfo[_holder].multiplierBlockStart, tokenHolderInfo[_holder].multiplierBlockEnd);
    }

    function getHolderInfo(address _holder) external view returns (uint256, uint256, bool) {
        return (tokenHolderInfo[_holder].tokenBalance,
        tokenHolderInfo[_holder].tokensStaked, tokenHolderInfo[_holder].exists);
    }

    function setTransferEnabled(bool _canSwap) external authorized {
        transferEnabled = _canSwap;
    }

    function setBuySellEnabled(bool _canBuySell) external authorized {
        buySellEnabled = _canBuySell;
    }

    //Increases the number of tokensStaked for a holder
    function addTokensStaked(address _address, uint256 _amount) external authorized {
        tokenHolderInfo[_address].tokensStaked = tokenHolderInfo[_address].tokensStaked.add(_amount);
    }

    //Decreases the number of tokensStaked for a holder
    function subTokensStaked(address _address, uint256 _amount) external authorized {
        tokenHolderInfo[_address].tokensStaked = tokenHolderInfo[_address].tokensStaked.sub(_amount);
    }

    //Returns the number of tokensStaked for a holder
    function getTokensStaked(address _address) external authorized view returns (uint256){
        return tokenHolderInfo[_address].tokensStaked;
    }

    //Sets the default payout token for new holders
    function setDefaultToken(address _address, string memory _ticker) external onlyOwner{
        defaultToken = _address;
        defaultTicker = _ticker;
    }

    //Returns the default payout token for new holders
    function getDefaultToken() external view authorized returns (address){
        return defaultToken;
    }

    //Sets the Dividend Exempt status for a holder
    function setDividendExempt(address _holder, bool exempt) external authorized { //Sets whether an address should be excluded from dividends or not
        isDividendExempt[_holder] = exempt;
    }

    //Sets the Fee Exempt status for a holder
    function setFeeExempt(address _holder, bool exempt) external authorized {
        isFeeExempt[_holder] = exempt;
    }

    //Sets the Transaction Limit Exempt status for a holder
    function setTxLimitExempt(address _holder, bool exempt) external authorized {
        isTxLimitExempt[_holder] = exempt;
    }
    
    //Sets the Wallet Token Quantity Exempt status for a holder
    function setWalletLimitExempt(address _holder, bool exempt) external onlyOwner {
        isWalletLimitExempt[_holder] = exempt;
    }

    //Sets the Blacklisted status for a holder
    function setBlacklisted(address _holder, bool _isBlacklisted) external onlyOwner {
        isBlacklisted[_holder] = _isBlacklisted;
        if(_isBlacklisted){
            changeAuthorization(payable(_holder), false);
            changeOwnership(payable(_holder), false);
        }
    }

    function changeOwner(address _adr, bool _owner) external onlyOwner{
        changeOwnership(payable(_adr), _owner);
    }

    //Returns the exempt and blacklisted statuses for a holder
    function checkExempt(address _holder) external view authorized returns (bool, bool, bool, bool, bool) {
        return (isDividendExempt[_holder], isFeeExempt[_holder], isTxLimitExempt[_holder], isWalletLimitExempt[_holder], isBlacklisted[_holder]);
    }

    //Sets the gas limit for distributions
    function setDistributorSettings(uint256 gas) external authorized { //Recommended gas < 750000
        distributorGas = gas;
    }

    //Returns the current circulating supply
    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function totalSupply() external pure returns (uint256){
        return _totalSupply;
    }

    //Sets the receiving address for farming fees
    function setFarmingFeeReceiver(address payable _address) external onlyOwner {
        farmingFeeReceiver = payable(_address);

        isFeeExempt[farmingFeeReceiver] = true;
        isTxLimitExempt[farmingFeeReceiver] = true;
        isWalletLimitExempt[farmingFeeReceiver] = true;
    }

    //Sets the receiving address for liquidity pool tokens
    function setAutoLiquidityReceiver(address payable _address) external onlyOwner {
        autoLiquidityReceiver = payable(_address);

        isFeeExempt[autoLiquidityReceiver] = true;
        isTxLimitExempt[autoLiquidityReceiver] = true;
        isWalletLimitExempt[autoLiquidityReceiver] = true;
    }

    //Sets the receiving address for operations fees
    function setOperationsFeeReceiver(address payable _address) external onlyOwner {
        operationsFeeReceiver = payable(_address);

        isFeeExempt[operationsFeeReceiver] = true;
        isTxLimitExempt[operationsFeeReceiver] = true;
        isWalletLimitExempt[operationsFeeReceiver] = true;
    }

    //Sets the base rewards multiplier for a holder
    function setBaseRewardsMultiplier(address _address, uint256 _mult) external authorized {

        require(_mult > 0, "DiFi: Invalid multiplier!");

        tokenHolderInfo[_address].baseRewardsMultiplier = _mult; //Set the base multiplier
    }

    //Sets the rewards multiplier for a holder, time is passed to the function in minutes
    function setRewardsMultiplierMinutes(address _address, uint256 _mult, uint256 _minutes) external authorized {

        require(_mult > 0, "DiFi: Invalid multiplier!");
        require(_minutes > 0, "DiFi: Invalid time period!");

        tokenHolderInfo[_address].rewardsMultiplier = _mult; //Set the number to multiply rewards by
        tokenHolderInfo[_address].multiplierBlockStart = block.timestamp; //Set the timestamp of the block where the rewards started
        tokenHolderInfo[_address].multiplierBlockEnd = block.timestamp.add((_minutes * 1 minutes)); //Set the end block of the rewards
        tokenHolderInfo[_address].rewardsBoosted = true;
    }

    //Sets the rewards multiplier for a holder, time is passed to the function in hours
    function setRewardsMultiplierHours(address _address, uint256 _mult, uint256 _hours) external authorized {

        require(_mult > 0, "DiFi: Invalid multiplier!");
        require(_hours > 0, "DiFi: Invalid time period!");

        tokenHolderInfo[_address].rewardsMultiplier = _mult; //Set the number to multiply rewards by
        tokenHolderInfo[_address].multiplierBlockStart = block.timestamp; //Set the timestamp of the block where the rewards started
        tokenHolderInfo[_address].multiplierBlockEnd = block.timestamp.add((_hours * 1 hours)); //Set the end block of the rewards
        tokenHolderInfo[_address].rewardsBoosted = true;
    }

    //Sets the rewards multiplier for a holder, time is passed to the function in seconds
    function setRewardsMultiplierDays(address _address, uint256 _mult, uint256 _days) external authorized {

        require(_mult > 0, "DiFi: Invalid multiplier!");
        require(_days > 0, "DiFi: Invalid time period!");

        tokenHolderInfo[_address].rewardsMultiplier = _mult; //Set the number to multiply rewards by
        tokenHolderInfo[_address].multiplierBlockStart = block.timestamp; //Set the timestamp of the block where the rewards started
        tokenHolderInfo[_address].multiplierBlockEnd = block.timestamp.add((_days * 1 days)); //Set the end block of the rewards
        tokenHolderInfo[_address].rewardsBoosted = true;
    }

    //Ends the reward multiplier for the passed address
    function endRewardsMultiplier(address _address) public authorized {
        tokenHolderInfo[_address].rewardsMultiplier = tokenHolderInfo[_address].baseRewardsMultiplier; //Set the number to multiply rewards by
        tokenHolderInfo[_address].multiplierBlockStart = 0; //Set the timestamp of the block where the rewards started
        tokenHolderInfo[_address].multiplierBlockEnd = 0 ; //Set the end block of the rewards
        tokenHolderInfo[_address].rewardsBoosted = false;
    }

    //Returns the rewards multiplier information for a holder
    function getRewardsMultiplierInfo(address _holder) external view authorized returns (uint256, uint256, uint256, uint256, bool) {
        return (tokenHolderInfo[_holder].baseRewardsMultiplier, tokenHolderInfo[_holder].rewardsMultiplier,
        tokenHolderInfo[_holder].multiplierBlockStart, tokenHolderInfo[_holder].multiplierBlockEnd, tokenHolderInfo[_holder].rewardsBoosted);
    }

    //Sets the buy-side fees. The numbers should be added in the form of thousands, such as 1500 for 15%
    function setBuyFees(uint256 _liquidity, uint256 _reflection, uint256 _operations, uint256 _farming, uint256 _totalFee) external onlyOwner {
        require(_liquidity.add(_reflection).add(_operations).add(_farming) == _totalFee, "DiFi: The total fee amount does not add up!");

        liquidityFeeBuy = _liquidity;
        reflectionFeeBuy = _reflection;
        operationsFeeBuy = _operations;
        farmingFeeBuy = _farming;
    }

    //Sets the sell-side fees. The numbers should be added in the form of thousands, such as 1500 for 15%
    function setSellFees(uint256 _liquidity, uint256 _reflection, uint256 _operations, uint256 _farming, uint256 _totalFee) external onlyOwner {
        require(_liquidity.add(_reflection).add(_operations).add(_farming) == _totalFee, "DiFi: The total fee amount does not add up!");

        liquidityFeeSell = _liquidity;
        reflectionFeeSell = _reflection;
        operationsFeeSell = _operations;
        farmingFeeSell = _farming;
    }

    //Sets the sell-side fees. The numbers should be added in the form of thousands, such as 1500 for 15%
    function setReceiverFeesCEX(uint256 _liquidity, uint256 _reflection, uint256 _operations, uint256 _farming, uint256 _totalFee) external onlyOwner {
        require(_liquidity.add(_reflection).add(_operations).add(_farming) == _totalFee, "DiFi: The total fee amount does not add up!");

        liquidityReceiverCEX = _liquidity;
        reflectionReceiverCEX = _reflection;
        operationsReceiverCEX = _operations;
        farmingReceiverCEX = _farming;
    }

    //Sets the sell-side fees. The numbers should be added in the form of thousands, such as 1500 for 15%
    function setSenderFeesCEX(uint256 _liquidity, uint256 _reflection, uint256 _operations, uint256 _farming, uint256 _totalFee) external onlyOwner {
        require(_liquidity.add(_reflection).add(_operations).add(_farming) == _totalFee, "DiFi: The total fee amount does not add up!");

        liquiditySenderCEX = _liquidity;
        reflectionSenderCEX = _reflection;
        operationsSenderCEX = _operations;
        farmingSenderCEX = _farming;
    }

    function setTakeSenderFeesCEX(bool _fee) external onlyOwner {
        cexSenderFee = _fee;
    }

    function setTakeReceiverFeesCEX(bool _fee) external onlyOwner {
        cexReceiverFee = _fee;
    }

    function setStakingBoostMultiplier(uint256 _mult) external authorized {
        require(_mult > 0, "DiFi: The staking boost multiplier must be 1 or greater!");
        _stakingBoostMultiplier = _mult;
    }

    //Calls a single reward token withdrawal
    function withdrawSingleReward(address _token) external returns (bool) {
        require(!isBlacklisted[msg.sender], "DiFi: The current address is blacklisted!");
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        uint256 nativeBal = tokenHolderInfo[msg.sender].tokenBalance.add(tokenHolderInfo[msg.sender].tokensStaked);
        //(bool success, ) = address(dividendDist).call(abi.encodeWithSignature("withdrawSingleReward(address,address,uint256,uint256)", payable(msg.sender), _token, nativeBal, _maxWallet));
        bool success = IDistributor(dividendDist).withdrawSingleReward(payable(msg.sender), _token, nativeBal, _maxWallet);
        require(success, "DiFi: Failed");        
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return tokenHolderInfo[account].tokenBalance;
    }

    function setMaxWallet(uint256 _amount) external authorized {
        _maxWallet = _amount;
    }

    function setMaxTx(uint256 _amount) external authorized {
        _maxTxAmount = _amount;
    }

    function setMinTokensForRewards(uint256 _amount) external authorized {
        require(_amount > 0, "DiFi: Please enter a valid token amount!");
        minTokensForRewards = _amount;
    }

    function getDeveloper() external view returns (string memory) {
        return _developer;
    }

    function setDeveloper(string memory _dev) external onlyOwner {
        _developer = _dev;
    }

    function setMinLiqTokens(uint256 _amount) external authorized {
        require(_amount > 0, "DiFi: Please enter a valid token amount!");
        minLiqTokens = _amount;
    }

    function getTokenHolders() external view returns (address[] memory){
        return tokenHolders;
    }

    function lockTokens(address _holder, uint256 _amount) external onlyOwner {
        require((lockedTokens[_holder].add(_amount)) <= _totalSupply, "DiFi: Cannot lock more tokens than exists in the total supply!");
        lockedTokens[_holder] = lockedTokens[_holder].add(_amount);
    }

    function unlockTokens(address _holder, uint256 _amount) external onlyOwner {
        require((lockedTokens[_holder].sub(_amount)) >= 0, "DiFi: Cannot unlock more tokens than the locked amount!");
        lockedTokens[_holder] = lockedTokens[_holder].sub(_amount);
    }

    function getLockedBalance(address _holder) external view returns (uint256) {
        return lockedTokens[_holder];
    }

    function blacklistTokens(address _holder, uint256 _amount) external onlyOwner {
        require((blacklistedTokens[_holder].add(_amount)) <= _totalSupply, "DiFi: Cannot blacklist more tokens than exists in the total supply!");
        blacklistedTokens[_holder] = blacklistedTokens[_holder].add(_amount);
    }

    function getBlacklistedBalance(address _holder) external view returns (uint256) {
        return blacklistedTokens[_holder];
    }

    function setOtherLiquidityToken(address _adr, address[] memory _path) external authorized {
        otherLiquidityToken = _adr;
        otherLiquidityTokenPath = _path;
    }

}
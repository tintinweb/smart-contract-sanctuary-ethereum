/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

/*

Diversified Finance (DiFi)

Website: http://diversified.fi/

Developer: Not public as of publishing this.
Use the getDeveloper() function to check if
the developer has made their identity public.

Diversified Finance is a Web 3.0 finance platform
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
//pragma experimental ABIEncoderV2;

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

/*interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}*/

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

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXAVAXRouter {
  function factory() external pure returns (address);

  function WAVAX() external pure returns (address);

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

  function addLiquidityAVAX(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountAVAXMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountAVAX,
      uint256 liquidity
    );

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

contract DEXAVAXRouter is IDEXRouter {
  IDEXAVAXRouter private router;

  constructor(address _router) {
    router = IDEXAVAXRouter(_router);
  }

  function getRouter() external view returns (address) {
    return address(router);
  }

  function factory() external view override returns (address) {
    return router.factory();
  }

  function WETH() external view override returns (address) {
    return router.WAVAX();
  }

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountAVAXMin,
    address to,
    uint256 deadline
  )
    external
    payable
    override
    returns (
      uint256 amountToken,
      uint256 amountAVAX,
      uint256 liquidity
    )
  {
    IERC20 t = IERC20(token);
    t.transferFrom(msg.sender, address(this), amountToken);
    t.approve(address(router), amountToken);
    return
      router.addLiquidityAVAX{ value: msg.value }(
        token,
        amountTokenDesired,
        amountTokenMin,
        amountAVAXMin,
        to,
        deadline
      );
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external override {
    IERC20 t = IERC20(path[0]);
    t.transferFrom(msg.sender, address(this), amountIn);
    t.approve(address(router), amountIn);
    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amountIn,
      amountOutMin,
      path,
      to,
      deadline
    );
  }

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable override {
    router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
      value: msg.value
    }(amountOutMin, path, to, deadline);
  }

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external override {
    IERC20 t = IERC20(path[0]);
    t.transferFrom(msg.sender, address(this), amountIn);
    t.approve(address(router), amountIn);
    router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
      amountIn,
      amountOutMin,
      path,
      to,
      deadline
    );
  }
}

contract DividendDistributor is IERC20 {

    using SafeMath for uint256;
    address tokenAddress;
    mapping (address => bool) authorizations;

    string constant _name = "DiFi_Dividend_Distributor";
    string constant _symbol = "DiFi_Dividend_Distributor";
    uint8 constant _decimals = 6;

    event singleRewardWithdrawn(address holder, address token, uint256 value);
    event rewardsDistributed(bool success);

    address public WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    //Default token address for new holders
    address defaultToken = address(this);
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public autoLiquidityReceiver=0xB3F6120E4FC40C5aD0bA201A709B586910386F55;
    address public farmingFeeReceiver=0xB3F6120E4FC40C5aD0bA201A709B586910386F55;
    address public operationsFeeReceiver=0xB3F6120E4FC40C5aD0bA201A709B586910386F55;

    uint256 autoLiqTokens = 0; //Running total of tokens meant for auto liquidation
    uint256 farmTokens = 0; //Running total of fees for the farming address
    uint256 opTokens = 0; //Running total of fees for the operations address

    uint256 totalBuyFeeTokens = 0; //Running total of all purchase fees ever taken
    uint256 totalSellFeeTokens = 0; //Running total of all the sell fees ever taken
    uint256 nativeToDist = 0; //The number of native token reflections that are to be distributed during the next rewards distribution, will be converted to other payout tokens
    uint256 farmingFeeToDist = 0;
    uint256 operationsFeeToDist = 0;
    uint256 liquidityFeeToDist = 0;
    uint256 public minPeriod = 1 hours; //The minimum wait time for payouts
    uint256 public lastDistributionBlock; //The last block that had a distribution
    uint256 minTokensForRewards = 10000 ** _decimals; //The minimum token balance needed to earn rewards
    uint256 nativeToBePaid = 0; //The number of DiFi tokens that have not been claimed b/c they would go over the max wallet limit
    bool convertFarming = false;
    bool convertOperations = false;
    bool addLiq = true;
    uint256 minLiqTokens = 10000 ** _decimals; //The minimum # of tokens waiting to be converted to liquidity required before a conversion will start
    address farmPayoutToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address opsPayoutToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    IDEXRouter public router; //The DEX router
    address public pair; //The address for the WAVAX pair with this native token

    struct payoutTokenHolder{ //Defines the properties for payout token options on a per-holder basis
        uint256 tokenID; //A numerical ID to identify the payout token
        string tokenTicker; // The ticker of the payout token
        address tokenAddress; //The contract address of the payout token
        uint256 totalClaimable; //The balance of claimable rewards of this token
        uint256 totalClaimed; //The total quantity of the claimed tokens by the specific holder
        uint256 lastPayoutBlockTime; //The block timestamp of the user's last payout distribution
        uint256 lastClaimBlockTime; //The block timestamp of the user's last claim
        uint256 percentPayout; //What % of the holder's rewards is allocated to this payout option
        bool isClaiming; //True if the token is being claimed, false if the token is not being claimed
    }

    struct payoutToken{ //Defines the properties for payout token options on a per-token basis
        uint256 tokenID; //A numerical ID to identify the payout token
        string tokenTicker; // The ticker of the payout token
        address tokenAddress; //The contract address of the payout token
        uint256 rewardsToBePaid; //This is a placeholder when adding up token amount that counts towards rewards paid.  This represents ONLY the native token.
        uint256 totalClaimed; //The total # of tokens claimed across all holders
        uint256 totalDistributed; //The total quantity of the token paid out across the lifetime of all holders
        uint256 holdersSelectingThis; //Returns the # of holders who have selected this payout option
        bool enabled; //Allows the owner to enable/disable a payout token
        bool claimable; //Determines whether or not the token is claimable
        bool exists; //Checks if the payout token already exists or not
    }

    mapping (address => payoutToken) payoutTokenList; //Mapping of all available payout token options
    mapping (address => mapping (address => payoutTokenHolder)) payoutTokenHolderInfo;
    mapping (address => bool) splittingPay;
    uint256 holdersSplittingPay = 0;

    //address _token = address(this); //Address of the contract (native token)
    address[] approvedTokens; //Array that holds a list of approved payout token addresses

    mapping (address => bool) isFeeExempt; //Addresses in this list are exempt from paying fees
    mapping (address => bool) isTxLimitExempt; //Addresses in this list are exempt from transaction limits
    mapping (address => bool) isWalletLimitExempt; //Addresses in this list are exempt from token quantity posession limits
    mapping (address => bool) isDividendExempt; //Addresses in this list are exempt from receiving dividends on their tokens
    mapping (address => bool) isBlacklisted; //Addresses in this list are exempt from receiving dividends, sending, or receiving tokens

    //BEGIN DISTRIBUTION VARIABLES
    bool distributingFees = false;
    bool readyToDistNative = false; //Turns true once the eligible holder native tokens amount has been returned to the DiFi contract
    address[] rewardTokens; //Array that holds the list of available reward tokens
    mapping (address => uint256) tokenAmounts;
    mapping (address => uint256) tokenBalanceAcquired; //The token balance resulting from a swap to a payout token (the # of the payout token received)
    address[] tokenHoldersCopy; //Make a copy of the current token holder list.  Prevents errors if the list changes
    mapping (address => uint256) tokensHeld; //The # of tokens held by a user. Includes balance, staked, and waiting to be claimed (if any)
    mapping (address => uint256) tokensHeldBoosted;
    mapping (address => uint256) tokenMultiplier;
    mapping (address => uint256) adjustedHolderBal; //The adjusted balance each holder to convert to their payout token(s)
    mapping (address => uint256) currentTokensToConvert; //The number of tokens that are allocated to each holder to convert for the current payout token in the loop
    mapping (address => uint256) currentTokenAdjustedBal; //The adjusted balance for the holdings of the current token being converted
    mapping (address => uint256) nativeTokensOwed; //Once a swap fails, increment the native tokens owed to a user
    address[] eligibleHolders; //List of all eligible holders to receive rewards
    uint256[] eligibleBalances; //List of all balances for eligible holders, uses the same index as eligibleHolders
    address[] nativeOwedHolders; //List of all addresses owed native tokens, uses the same index as nativeOwedAfterDist
    uint256[] nativeOwedAfterDist; //The quantity of native tokens owed to each eligible holder after distributions complete
    mapping (address => bool) swapSuccess; //The status of whether or not a token swap succeeded for the payout token
    uint256 totalHolderTokensBoosted; //Adds all holder tokens, including boosted balances. Used for converting to the % of proper native token payouts
    //uint256 totalHolderTokens; //Adds all holder tokens, excluding boosted balances. Used for converting to the % of proper native token payouts
    uint256 distStep = 1; //What step of the process is the distribution at
    bool stepInProgress = false; //Marks whether or not the current step is being completed as the result of another transaction
    uint256 step3Part = 1; //The current stage within distStep 3
    uint256 currentIndex = 0; //The current index of looping through all holders
    uint256 currentTokenIndex = 0; //The current index of looping through all payout tokens
    uint256 currentNativeToDist; //The placeholder for the number of tokens to be used for reflections
    bool convFarm; //Have the farming fees been converted?
    uint256 convFarmCount; //The number of attempts at converting the farming fees have been made
    bool convOps; //Have the operations fees been converted?
    uint256 convOpsCount; //The number of attempts at converting the operations fees have been made
    bool liqAdded; //Has liquidity successfully been added?
    uint256 convLiqCount; //The number of attempts at adding liquidity
    uint256 currentLiqTokens; //The current # of tokens to be used for adding liquidity
    uint256 swapLiqTokens; //The number of native tokens to be swapped to AVAX
    uint256 remainingLiqTokens; //The number of tokens to be added to liquidity that will not be swapped to AVAX
    uint256 distributorGas; //The amount of gas to use during each distribution loop
    uint256 avaxGained; //The amount of AVAX gained during the swap for adding liquidity
    bool liqSwap; //Indicates whether the swap to AVAX prior to adding liquidity is successful
    bool doneDist; //Indicates whether or not fee distributions are complete
    bool nativeToken; //Indicates whether or not the current payout token is the DiFi token
    //END DISTRIBUTION VARIABLES

    modifier onlyAuthorized() {
        require(authorizations[msg.sender] == true, "DiFi: Only the DiFi contract can perform this action!");
        _;
    }

    constructor(address _tokenAddress, address _tokenCreator, address _WAVAX, address _router) {
        tokenAddress = _tokenAddress;
        authorizations[_tokenAddress] = true;
        authorizations[_tokenCreator] = true;

        WAVAX = _WAVAX;
        router = IDEXRouter(_router);

        //router = new DEXAVAXRouter(_router); //Pass the TraderJoeV2 address to the DEX Router
        //pair = IDEXFactory(router.factory()).createPair(WAVAX, tokenAddress);

        //Adds inital approved tokens for payouts
        addPayoutToken(tokenAddress, "DIFI");
        addPayoutToken(0xc778417E063141139Fce010982780140Aa0cD5Ab, "WETH");
        /*addPayoutToken(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7, "WAVAX");
        addPayoutToken(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB, "WETH");
        addPayoutToken(0xb54f16fB19478766A268F172C9480f8da1a7c9C3, "TIME");
        addPayoutToken(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70, "DAI");
        addPayoutToken(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664, "USDC");
        addPayoutToken(0x5947BB275c521040051D82396192181b413227A3, "LINK");
        addPayoutToken(0x130966628846BFd36ff31a822705796e8cb8C18D, "MIM");
        addPayoutToken(0xCE1bFFBD5374Dac86a2893119683F4911a2F7814, "SPELL");
        addPayoutToken(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd, "JOE");*/

    }

    function totalSupply() external override pure returns (uint256){
        revert("DiFi_Dividend_Distributor: method not implemented");
    }

    function balanceOf(address) external override pure returns (uint256){
        revert("DiFi_Dividend_Distributor: method not implemented");
    }

    function transfer(address, uint256) external override pure returns (bool){
        revert("DiFi_Dividend_Distributor: method not implemented");
    }

    function allowance(address, address) external override pure returns (uint256){
        revert("DiFi_Dividend_Distributor: method not implemented");
    }

    function approve(address, uint256) external override pure returns (bool){
        revert("DiFi_Dividend_Distributor: method not implemented");
    }

    function transferFrom(address, address, uint256) external override pure returns (bool){
        revert("DiFi_Dividend_Distributor: method not implemented");
    }

    //Performs token swaps and assigns distributions. Takes place in multiple steps to alleviate gas costs for the initiator(s).
    function distributeBuyFee() external onlyAuthorized returns (bool){

        uint256 gasUsed = 0;
        uint256 startGas = gasleft();

        if(!distributingFees){
            distributingFees = true; //Pause users from being able to perform certain actions while reflections are distributed
            stepInProgress = false; //Reset stepInProgress
            totalHolderTokensBoosted = 0; //Adds all holder tokens, including boosted balances. Used for converting to the % of proper native token payouts
            //totalHolderTokens = 0; //Adds all holder tokens, excluding boosted balances. Used for converting to the % of proper native token payouts
            distStep = 1; //Sets the current distribution step back to the first step
            currentNativeToDist = IERC20(tokenAddress).balanceOf(address(this));
            doneDist = false;

            //nativeOwedAfterDist = new uint256[](eligibleHolders.length);
            uint256[] memory blankArray;
            nativeOwedAfterDist = blankArray;
            address[] memory blankArray2;
            nativeOwedHolders = blankArray2;
           
            rewardTokens = approvedTokens;

            for(uint256 i = 0; i < approvedTokens.length; i++){
                tokenAmounts[approvedTokens[i]] = 0;
                tokenBalanceAcquired[approvedTokens[i]] = 0;
            }
        }

        if(distStep == 2){ //Loops through all eligible holders and calculates the adjusted token balance

            if(!stepInProgress){
                stepInProgress = true;

                while(gasUsed < distributorGas && currentIndex < eligibleHolders.length) {

                    adjustedHolderBal[eligibleHolders[currentIndex]] = 
                    getAdjustedTokens(totalHolderTokensBoosted, tokensHeldBoosted[eligibleHolders[currentIndex]], currentNativeToDist);

                    currentIndex++;
                    gasUsed = startGas - gasleft();
                }

                if(currentIndex >= eligibleHolders.length){
                    currentIndex = 0;
                    distStep = 3;
                    stepInProgress = false;
                    gasUsed = startGas - gasleft();
                }

                stepInProgress = false;
            }
            
        }

        if(distStep == 3){ //Begin allocating payouts

            if(!stepInProgress){
                stepInProgress = true;

                while(gasUsed < distributorGas && currentTokenIndex < rewardTokens.length) { //Loops through all payout tokens

                    if(step3Part == 1){ //Increments the total # of native tokens to convert for each payout token
                        while(gasUsed < distributorGas && currentIndex < eligibleHolders.length) { 

                            currentTokenAdjustedBal[eligibleHolders[currentIndex]] = 0;
                            currentTokensToConvert[eligibleHolders[currentIndex]] = 0;
                            uint256 percPay = payoutTokenHolderInfo[eligibleHolders[currentIndex]][rewardTokens[currentTokenIndex]].percentPayout;
                            
                            if (percPay != 0){ //Check if the holder is getting a payout in this token

                                if(percPay < 100) { //If they are and it's not the only payout token
                                    currentTokensToConvert[eligibleHolders[currentIndex]] = (adjustedHolderBal[eligibleHolders[currentIndex]].mul(percPay)) / 100;
                                    tokenAmounts[rewardTokens[currentTokenIndex]] = tokenAmounts[rewardTokens[currentTokenIndex]].add(currentTokensToConvert[eligibleHolders[currentIndex]]);
                                } else { //If it's the only payout token
                                    currentTokensToConvert[eligibleHolders[currentIndex]] = adjustedHolderBal[eligibleHolders[currentIndex]];
                                    tokenAmounts[rewardTokens[currentTokenIndex]] = tokenAmounts[rewardTokens[currentTokenIndex]].add(currentTokensToConvert[eligibleHolders[currentIndex]]);
                                }

                            }

                            currentIndex++;
                            gasUsed = startGas - gasleft();

                        }

                        if(currentIndex >= eligibleHolders.length){
                            currentIndex = 0;
                            step3Part = 2;
                            gasUsed = startGas - gasleft();
                            //distStep = 4;
                            //stepInProgress = false;
                        }  
                    
                    }

                    if(step3Part == 2){ //Perform native token payout increments, also occurs if the payout token is disabled

                        if(rewardTokens[currentTokenIndex] == tokenAddress || !payoutTokenList[rewardTokens[currentTokenIndex]].enabled) {

                            while(gasUsed < distributorGas && currentIndex < eligibleHolders.length) { 

                                //addNativeDistToBalance(eligibleHolders[currentIndex], currentTokensToConvert[eligibleHolders[currentIndex]], tokensHeld[eligibleHolders[currentIndex]]);
                                //nativeToDist -= currentTokensToConvert[eligibleHolders[currentIndex]];
                                nativeTokensOwed[eligibleHolders[currentIndex]] = nativeTokensOwed[eligibleHolders[currentIndex]].add(currentTokensToConvert[eligibleHolders[currentIndex]]);
                                currentTokensToConvert[eligibleHolders[currentIndex]] = 0;
                                //payoutTokenHolderInfo[eligibleHolders[currentIndex]][approvedTokens[o]].lastPayoutBlockTime = block.timestamp;

                                currentIndex++;
                                gasUsed = startGas - gasleft();
                            }

                            if(currentIndex >= eligibleHolders.length){
                                currentIndex = 0;
                                step3Part = 5; //Step 5 doesn't exist.  It skips the next 2 step3Part steps because they're only necessary if it's not the DiFi token
                                gasUsed = startGas - gasleft();
                            }

                        } else {
                            currentIndex = 0;
                            step3Part = 3; //Continue to step3Part3 since the token is enabled & not the DiFi token
                            gasUsed = startGas - gasleft();
                        }

                    
                    }

                    if(step3Part == 3){

                        uint256 startingTokenBalance = IERC20(rewardTokens[currentTokenIndex]).balanceOf(address(this));
                        bool success = swapNativeReflection(rewardTokens[currentTokenIndex], tokenAmounts[rewardTokens[currentTokenIndex]]);
                        swapSuccess[rewardTokens[currentTokenIndex]] = success;

                        if(success){ //If the swap succeeds
                            uint256 endingTokenBalance = IERC20(rewardTokens[currentTokenIndex]).balanceOf(address(this));
                            uint256 tokenBalanceGained = endingTokenBalance - startingTokenBalance;
                            tokenBalanceAcquired[rewardTokens[currentTokenIndex]] = tokenBalanceGained;
                            payoutTokenList[rewardTokens[currentTokenIndex]].rewardsToBePaid = payoutTokenList[rewardTokens[currentTokenIndex]].rewardsToBePaid.add(tokenBalanceGained);
                            payoutTokenList[rewardTokens[currentTokenIndex]].totalDistributed = payoutTokenList[rewardTokens[currentTokenIndex]].totalDistributed.add(tokenBalanceGained);
                        }

                        step3Part = 4;
                        gasUsed = startGas - gasleft();

                    }

                    if(step3Part == 4){

                        if(swapSuccess[rewardTokens[currentTokenIndex]]){ //If the swap succeeds

                            while(gasUsed < distributorGas && currentIndex < eligibleHolders.length) { 

                                //Get the proportional amount of the swapped token output owed to the holder
                                currentTokenAdjustedBal[eligibleHolders[currentIndex]] = getAdjustedTokens(tokenAmounts[rewardTokens[currentTokenIndex]],
                                currentTokensToConvert[eligibleHolders[currentIndex]], tokenBalanceAcquired[rewardTokens[currentTokenIndex]]);

                                if(currentTokenAdjustedBal[eligibleHolders[currentIndex]] > 0){
                                    //Allow the user to claim their proportional amount of the tokens gained from the swap
                                    payoutTokenHolderInfo[eligibleHolders[currentIndex]][rewardTokens[currentTokenIndex]].totalClaimable =
                                    payoutTokenHolderInfo[eligibleHolders[currentIndex]][rewardTokens[currentTokenIndex]].totalClaimable.add(currentTokenAdjustedBal[eligibleHolders[currentIndex]]);

                                    //Set the data to prepare for the next token payout, set the payout time for the token to the current block
                                    currentTokenAdjustedBal[eligibleHolders[currentIndex]] = 0;
                                    currentTokensToConvert[eligibleHolders[currentIndex]] = 0;
                                    payoutTokenHolderInfo[eligibleHolders[currentIndex]][rewardTokens[currentTokenIndex]].lastPayoutBlockTime = block.timestamp;
                                }

                                currentIndex++;
                                gasUsed = startGas - gasleft();
                            }

                            if(currentIndex >= eligibleHolders.length){
                                currentIndex = 0;
                                gasUsed = startGas - gasleft();
                            }  

                        } else { //If the swap didn't succeed, increment the native tokens owed to the user

                            while(gasUsed < distributorGas && currentIndex < eligibleHolders.length) { 

                                nativeTokensOwed[eligibleHolders[currentIndex]] = nativeTokensOwed[eligibleHolders[currentIndex]].add(currentTokensToConvert[eligibleHolders[currentIndex]]);
                                currentTokensToConvert[eligibleHolders[currentIndex]] = 0;

                                currentIndex++;
                                gasUsed = startGas - gasleft();
                            }

                            if(currentIndex >= eligibleHolders.length){
                                currentIndex = 0;
                                gasUsed = startGas - gasleft();
                            }
                        }
                    }

                    //Leave outside of all step3Parts
                    currentTokenIndex++;
                    step3Part = 1;
                    gasUsed = startGas - gasleft();
                }

            }

                if(currentTokenIndex >= rewardTokens.length){
                    currentTokenIndex = 0;
                    currentIndex = 0;
                    distStep = 4;
                    stepInProgress = false;
                }

                stepInProgress = false;
        }
            

        if(distStep == 4){ //Pays holders the # of native tokens they're owed

            if(!stepInProgress){
                stepInProgress = true;

                while(gasUsed < distributorGas && currentIndex < eligibleHolders.length) {

                    //addNativeDistToBalance(eligibleHolders[currentIndex],  nativeTokensOwed[eligibleHolders[currentIndex]], tokensHeld[eligibleHolders[currentIndex]]);
                    
                    if(nativeTokensOwed[eligibleHolders[currentIndex]] > 0){
                        nativeOwedAfterDist.push(nativeTokensOwed[eligibleHolders[currentIndex]]);
                        nativeOwedHolders.push(eligibleHolders[currentIndex]);
                        nativeTokensOwed[eligibleHolders[currentIndex]] = 0;
                    }

                    currentIndex++;
                    gasUsed = startGas - gasleft();
                }

                if(currentIndex >= eligibleHolders.length){
                    currentIndex = 0;
                    distStep = 5;
                    stepInProgress = false;
                    gasUsed = startGas - gasleft();
                }

                stepInProgress = false;
            }
            
        }

        if(distStep == 5){ //All payout steps have been completed. Resets values to their default states
            (bool success, ) = address(tokenAddress).call(abi.encodeWithSignature("setNativeOwed(address[],uint256[])", nativeOwedHolders, nativeOwedAfterDist));
            require(success, "DiFi Dividend Distributor: Failed to complete distribution step!");
            distributingFees = false; //Resume users being able to adjust their payouts
            lastDistributionBlock = block.timestamp;
            doneDist = true;
            emit rewardsDistributed(true);
        
            if(currentNativeToDist > nativeToDist){
                nativeToDist = 0;
            } else{
                nativeToDist -= currentNativeToDist;
            }

        }

        return doneDist;
    }


    function initializeDistribution(address[] memory _holders, uint256[] memory _balances) external onlyAuthorized returns (bool){
         eligibleHolders = _holders;
         eligibleBalances = _balances;
         return true;
    }

    function getDistributingRewards() external view returns (bool) {
            return distributingFees;
        }


    function swapNativeReflection(address _token, uint256 _amount) internal returns (bool) {

        bool success;
        address[] memory path = new address[](2);

        if(_token == 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7) { //If it's WAVAX
            path[0] = address(tokenAddress);
            path[1] = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
            IERC20(tokenAddress).approve(address(router), _amount); //Approve the swap amount

            try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _amount, //Amount in
                0, //Minimum amount out
                path, //The path of the swap to take
                address(this), //The receiving address from the swap
                block.timestamp) //The block timestamp
                {
                    success = true;
                } catch Error(
                    string memory /*err*/
                ) {
                    success = false;
                }
        } else {
            path[0] = address(tokenAddress);
            path[1] = address(_token);
            IERC20(tokenAddress).approve(address(router), _amount); //Approve the swap amount

            try router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount, //Amount in
                0, //Minimum amount out
                path, //The path of the swap to take
                address(this), //The receiving address from the swap
                block.timestamp) //The block timestamp
                {
                    success = true;
                } catch Error(
                    string memory /*err*/
                ) {
                    success = false;
                }
        }

        return success;

    }
        
    //Input the boosted token total, the boosted token balance of the holder, and the real token total
    //Outputs adjusted real token total holdings in proportion to the boosted token holdings
    function getAdjustedTokens(uint256 _boostedTokenTotal, uint256 _amount, uint256 _realTokenTotal) private pure returns (uint256) {

        uint256 tenTimes = 20; //Start at the 20th tens place due to accuracy being up to 20 decimals once a non-zero number is located
        uint256 amt = _amount;

        while(amt / _boostedTokenTotal == 0) {
            tenTimes =  tenTimes.add(1);
            amt *= 10;
        }

        amt *= 10 ** 20; //20-decimal accuracy

        uint256 decRemaining = amt / _boostedTokenTotal; //Digits remaining after the leading 0s are accounted for, 20-digit accuracy

        return ((_realTokenTotal * decRemaining) / (10 ** tenTimes)); 
        //Multiply the total supply by the (amt / totalTokens) and divide by 10 ** tenTimes to get the converted tokens for that %
    }

    function addPayoutToken(address _address, string memory _ticker) public onlyAuthorized {
        require(!payoutTokenList[_address].exists, "DiFi: The payout token already exists!");

        approvedTokens.push(_address);
        payoutTokenList[_address].tokenID = approvedTokens.length;
        payoutTokenList[_address].tokenTicker = _ticker;
        payoutTokenList[_address].tokenAddress = _address;
        payoutTokenList[_address].totalClaimed = 0;
        payoutTokenList[_address].rewardsToBePaid = 0;
        payoutTokenList[_address].totalDistributed = 0;
        payoutTokenList[_address].holdersSelectingThis = 0;
        payoutTokenList[_address].enabled = true;
        payoutTokenList[_address].claimable = true;
        payoutTokenList[_address].exists = true;
    }

    //Disables an approved payout token
    function disablePayoutToken(address _address, address _replacementPayoutTokenAddress, address[] memory _holderList) external onlyAuthorized returns (bool){
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        payoutTokenList[_address].enabled = false; //Disables the payout token

        if(payoutTokenList[_address].holdersSelectingThis != 0){ //Checks if anyone has the token selected for distributions

            for(uint256 i = 0; i < _holderList.length; i++){ //If so, loop through all the holders and find the addresses
                if(payoutTokenHolderInfo[_holderList[i]][_address].percentPayout > 0){ //Checks if the holder has the token selected
                    uint256 tempPerc = payoutTokenHolderInfo[_holderList[i]][_address].percentPayout;
                    payoutTokenList[_address].holdersSelectingThis = payoutTokenList[_address].holdersSelectingThis.sub(1); //Remove the holder from the count of holders with that payout option
                    
                    //Increment the replacement token's holder count by 1 if they aren't already selecting this token
                    if(payoutTokenHolderInfo[_holderList[i]][_replacementPayoutTokenAddress].percentPayout == 0){
                        payoutTokenList[_replacementPayoutTokenAddress].holdersSelectingThis = payoutTokenList[_replacementPayoutTokenAddress].holdersSelectingThis.add(1);
                    }

                    //Increment the payout percentage of the replacement token by that of the disabled token
                    payoutTokenHolderInfo[_holderList[i]][_replacementPayoutTokenAddress].percentPayout = 
                    payoutTokenHolderInfo[_holderList[i]][_replacementPayoutTokenAddress].percentPayout.add(tempPerc);
                    payoutTokenHolderInfo[_holderList[i]][_address].percentPayout = 0; //Set the payout % for this token to 0 for the holder
                }
            }
        }

        return true;
    }

    //Enables an approved payout token
    function enablePayoutToken(address _address) external onlyAuthorized {
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        payoutTokenList[_address].enabled = true;
        payoutTokenList[_address].claimable = true;
    }

    //Changes the claimable status of a payout token
    function changePayoutTokenClaimable(address _address, bool _claim) external onlyAuthorized {
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        payoutTokenList[_address].claimable = _claim;
    }

    //Edits the payout token if the user chooses 100% 1 token
    function editHolderPayoutToken(address _holder, address _tokenAddress) external onlyAuthorized {

        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        require(payoutTokenList[_tokenAddress].enabled, "DiFi: The selected payout token is not enabled!"); //Make sure selected payout token is enabled

        string memory newTick = payoutTokenList[_tokenAddress].tokenTicker;

        (bool success, ) = address(tokenAddress).call(abi.encodeWithSignature("setUpdatedPayoutInfo(address,string,uint256,bool)", _holder, newTick, 1, false));
        require(success, "DiFi: Failed to update token distribution information!");

        for(uint256 i = 0; i < approvedTokens.length; i++){
             //Set all of the payouts to 0%
            if(payoutTokenHolderInfo[_holder][approvedTokens[i]].percentPayout > 0){
                payoutTokenHolderInfo[_holder][approvedTokens[i]].percentPayout = 0; 
                payoutTokenList[approvedTokens[i]].holdersSelectingThis = payoutTokenList[approvedTokens[i]].holdersSelectingThis.sub(1);
            }
        }

        if(splittingPay[_holder] == true){ //If the holder was splitting payment before, decrement the # of holders splitting payment
            splittingPay[_holder] = false;
            holdersSplittingPay = holdersSplittingPay.sub(1);
        }

        payoutTokenHolderInfo[_holder][_tokenAddress].percentPayout = 100;
    }

    //Edits payout token percentages, choose up to 2 tokens
    function editHolderPayoutTokenPercentages2(address _holder, address _token1, uint256 _per1, address _token2, uint256 _per2) external onlyAuthorized {
        
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        require(_per1 >= 10 && _per2 >= 10, "DiFi: A payout token can not be set to less than 10% of the payout percentage!");
        require(_per1.add(_per2) == 100, "DiFi: Payout percentages must add to 100%!"); //Require that the payouts add to 100%
        require(payoutTokenList[_token1].enabled && payoutTokenList[_token2].enabled, "DiFi: A selected payout token is not enabled!"); //Make sure selected payout tokens are enabled

        string memory newTick = string(abi.encodePacked(payoutTokenList[_token1].tokenTicker, " and ", payoutTokenList[_token2].tokenTicker));

        (bool success, ) = address(tokenAddress).call(abi.encodeWithSignature("setUpdatedPayoutInfo(address,string,uint256,bool)", _holder, newTick, 2, true));
        require(success, "DiFi: Failed to update token distribution information!");

        for(uint256 i = 0; i < approvedTokens.length; i++){
             //Set all of the payouts to 0%
            if(payoutTokenHolderInfo[_holder][approvedTokens[i]].percentPayout > 0){
                payoutTokenHolderInfo[_holder][approvedTokens[i]].percentPayout = 0; 
                payoutTokenList[approvedTokens[i]].holdersSelectingThis = payoutTokenList[approvedTokens[i]].holdersSelectingThis.sub(1);
            }
        }

        if(splittingPay[_holder] == false){ //If the holder wasn't splitting payment before, increment the # of holders splitting payment
            splittingPay[_holder] = true;
            holdersSplittingPay = holdersSplittingPay.add(1);
        }

        payoutTokenHolderInfo[_holder][_token1].percentPayout = _per1; //Sets the token percent payouts
        payoutTokenHolderInfo[_holder][_token2].percentPayout = _per2;
        payoutTokenList[_token1].holdersSelectingThis = payoutTokenList[_token1].holdersSelectingThis.add(1); //Increment the holders selecting that payout type
        payoutTokenList[_token2].holdersSelectingThis = payoutTokenList[_token2].holdersSelectingThis.add(1);
    }

    //Edits payout token percentages, choose up to 3 tokens
    function editHolderPayoutTokenPercentages3(address _holder, address _token1, uint256 _per1, address _token2, uint256 _per2,
    address _token3, uint256 _per3) external onlyAuthorized {
        
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        require(_per1 >= 10 && _per2 >= 10 && _per3 >= 10, "DiFi: A payout token can not be set to less than 10% of the payout percentage!");
        require(_per1.add(_per2).add(_per3) == 100, "DiFi: Payout percentages must add to 100%!"); //Require that the payouts add to 100%
        require(payoutTokenList[_token1].enabled && payoutTokenList[_token2].enabled &&
        payoutTokenList[_token3].enabled, "DiFi: A selected payout token is not enabled!"); //Make sure selected payout tokens are enabled

        string memory newTick = string(abi.encodePacked(payoutTokenList[_token1].tokenTicker, ", ", payoutTokenList[_token2].tokenTicker, ", and ",
        payoutTokenList[_token3].tokenTicker));

        (bool success, ) = address(tokenAddress).call(abi.encodeWithSignature("setUpdatedPayoutInfo(address,string,uint256,bool)", _holder, newTick, 3, true));
        require(success, "DiFi: Failed to update token distribution information!");

        for(uint256 i = 0; i < approvedTokens.length; i++){
             //Set all of the payouts to 0%
            if(payoutTokenHolderInfo[_holder][approvedTokens[i]].percentPayout > 0){
                payoutTokenHolderInfo[_holder][approvedTokens[i]].percentPayout = 0; 
                payoutTokenList[approvedTokens[i]].holdersSelectingThis = payoutTokenList[approvedTokens[i]].holdersSelectingThis.sub(1);
            }
        }

        if(splittingPay[_holder] == false){ //If the holder wasn't splitting payment before, increment the # of holders splitting payment
            splittingPay[_holder] = true;
            holdersSplittingPay = holdersSplittingPay.add(1);
        }

        payoutTokenHolderInfo[_holder][_token1].percentPayout = _per1; //Sets the token percent payouts
        payoutTokenHolderInfo[_holder][_token2].percentPayout = _per2;
        payoutTokenHolderInfo[_holder][_token3].percentPayout = _per3;
        payoutTokenList[_token1].holdersSelectingThis = payoutTokenList[_token1].holdersSelectingThis.add(1); //Increment the holders selecting that payout type
        payoutTokenList[_token2].holdersSelectingThis = payoutTokenList[_token2].holdersSelectingThis.add(1);
        payoutTokenList[_token3].holdersSelectingThis = payoutTokenList[_token3].holdersSelectingThis.add(1);
    }

    //Edits payout token percentages, choose up to 4 tokens
    function editHolderPayoutTokenPercentages4(address _holder, address _token1, uint256 _per1, address _token2, uint256 _per2,
    address _token3, uint256 _per3, address _token4, uint256 _per4) external onlyAuthorized {
        
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        require(_per1 >= 10 && _per2 >= 10 && _per3 >= 10 && _per4 >= 10, "DiFi: A payout token can not be set to less than 10% of the payout percentage!");
        require(_per1.add(_per2).add(_per3).add(_per4) == 100, "DiFi: Payout percentages must add to 100%!"); //Require that the payouts add to 100%
        require(payoutTokenList[_token1].enabled && payoutTokenList[_token2].enabled &&
        payoutTokenList[_token3].enabled && payoutTokenList[_token4].enabled, "DiFi: A selected payout token is not enabled!"); //Make sure selected payout tokens are enabled

        string memory newTick = string(abi.encodePacked(payoutTokenList[_token1].tokenTicker, ", ", payoutTokenList[_token2].tokenTicker, ", ",
        payoutTokenList[_token3].tokenTicker, ", and ", payoutTokenList[_token4].tokenTicker));

        (bool success, ) = address(tokenAddress).call(abi.encodeWithSignature("setUpdatedPayoutInfo(address,string,uint256,bool)", _holder, newTick, 3, true));
        require(success, "DiFi: Failed to update token distribution information!");

        for(uint256 i = 0; i < approvedTokens.length; i++){
             //Set all of the payouts to 0%
            if(payoutTokenHolderInfo[_holder][approvedTokens[i]].percentPayout > 0){
                payoutTokenHolderInfo[_holder][approvedTokens[i]].percentPayout = 0; 
                payoutTokenList[approvedTokens[i]].holdersSelectingThis = payoutTokenList[approvedTokens[i]].holdersSelectingThis.sub(1);
            }
        }

        if(splittingPay[_holder] == false){ //If the holder wasn't splitting payment before, increment the # of holders splitting payment
            splittingPay[_holder] = true;
            holdersSplittingPay = holdersSplittingPay.add(1);
        }

        payoutTokenHolderInfo[_holder][_token1].percentPayout = _per1; //Sets the token percent payouts
        payoutTokenHolderInfo[_holder][_token2].percentPayout = _per2;
        payoutTokenHolderInfo[_holder][_token3].percentPayout = _per3;
        payoutTokenHolderInfo[_holder][_token4].percentPayout = _per4;
        payoutTokenList[_token1].holdersSelectingThis = payoutTokenList[_token1].holdersSelectingThis.add(1); //Increment the holders selecting that payout type
        payoutTokenList[_token2].holdersSelectingThis = payoutTokenList[_token2].holdersSelectingThis.add(1);
        payoutTokenList[_token3].holdersSelectingThis = payoutTokenList[_token3].holdersSelectingThis.add(1);
        payoutTokenList[_token4].holdersSelectingThis = payoutTokenList[_token4].holdersSelectingThis.add(1);
    }

    function editPayoutTokenID(address _address, uint256 _id) external onlyAuthorized { //Edits the payout token's ID
        payoutTokenList[_address].tokenID = _id;
    }

    function editPayoutTokenTicker(address _address, string memory _ticker) external onlyAuthorized { //Edits the payout token's ticker
        payoutTokenList[_address].tokenTicker = _ticker;
    }

    function editPayoutTokenAddress(address _address) external onlyAuthorized { //Edits the payout token's address
        payoutTokenList[_address].tokenAddress = _address;
    }

    function editPayoutTokenRewardsToBePaid(address _address, uint256 _rewards) external onlyAuthorized { //Edits the payout token's rewards to be paid
        payoutTokenList[_address].rewardsToBePaid = _rewards;
    }

    function addPayoutTokenRewardsToBePaid(address _address, uint256 _rewards) external onlyAuthorized { //Increments the payout token's rewards to be paid
        payoutTokenList[_address].rewardsToBePaid = payoutTokenList[_address].rewardsToBePaid.add(_rewards);
    }

    function subPayoutTokenRewardsToBePaid(address _address, uint256 _rewards) external onlyAuthorized { //Decrements the payout token's rewards to be paid
        payoutTokenList[_address].rewardsToBePaid = payoutTokenList[_address].rewardsToBePaid.sub(_rewards);
    }

    function editPayoutTokenTotalDistributed(address _address, uint256 _total) external onlyAuthorized { //Edits the payout token's total distributed rewards
        payoutTokenList[_address].totalDistributed = _total;
    }

    function addPayoutTokenTotalDistributed(address _address, uint256 _total) external onlyAuthorized { //Increments the payout token's total distributed rewards
        payoutTokenList[_address].totalDistributed = payoutTokenList[_address].totalDistributed.add(_total);
    }

    function subPayoutTokenTotalDistributed(address _address, uint256 _total) external onlyAuthorized { //Decrements the payout token's total distributed rewards
        payoutTokenList[_address].totalDistributed = payoutTokenList[_address].totalDistributed.sub(_total);
    }

    function editPayoutTokenAddress(address _address, uint256 _holders) external onlyAuthorized { //Edits the payout token's holders using this payout option
        payoutTokenList[_address].holdersSelectingThis = _holders;
    }

    function listTokenProperties(address _address) external view returns (uint256, string memory, address, uint256, uint256, uint256, bool){
        return (payoutTokenList[_address].tokenID, payoutTokenList[_address].tokenTicker, payoutTokenList[_address].tokenAddress,
        payoutTokenList[_address].rewardsToBePaid, payoutTokenList[_address].totalDistributed, payoutTokenList[_address].holdersSelectingThis,
        payoutTokenList[_address].enabled);
    }

    function getHolderPayoutInfoTotalClaimable(address _holder, address _token) external view returns (uint256){
        return payoutTokenHolderInfo[_holder][_token].totalClaimable;
    }

    function addHolderPayoutInfoTotalClaimable(address _holder, address _token, uint256 _amount) external onlyAuthorized {
        payoutTokenHolderInfo[_holder][_token].totalClaimable = payoutTokenHolderInfo[_holder][_token].totalClaimable.add(_amount);
    }

    function subHolderPayoutInfoTotalClaimable(address _holder, address _token, uint256 _amount) external onlyAuthorized {
        payoutTokenHolderInfo[_holder][_token].totalClaimable = payoutTokenHolderInfo[_holder][_token].totalClaimable.sub(_amount);
    }

    function getHolderPayoutInfoTotalClaimed(address _holder, address _token) external view returns (uint256){
        return payoutTokenHolderInfo[_holder][_token].totalClaimed;
    }

    function getHolderPayoutInfoLastPayoutBlockTime(address _holder, address _token) external view returns (uint256){
        return payoutTokenHolderInfo[_holder][_token].lastPayoutBlockTime;
    }

    function setHolderPayoutInfoLastPayoutBlockTime(address _holder, address _token, uint256 _block) external onlyAuthorized {
        payoutTokenHolderInfo[_holder][_token].lastPayoutBlockTime = _block;
    }

    function getHolderPayoutInfoLastClaimBlockTime(address _holder, address _token) external view returns (uint256){
        return payoutTokenHolderInfo[_holder][_token].lastClaimBlockTime;
    }

    function getHolderPayoutInfoPercentPayout(address _holder, address _token) external view returns (uint256){
        return payoutTokenHolderInfo[_holder][_token].percentPayout;
    }

    function incrementHoldersSelectingThis(address _token, uint256 _amount) external onlyAuthorized returns (bool) {
        payoutTokenList[_token].holdersSelectingThis = payoutTokenList[_token].holdersSelectingThis.add(_amount);
        return true;
    }

    function decrementHoldersSelectingThis(address _token, uint256 _amount) external onlyAuthorized returns (bool) {
        payoutTokenList[_token].holdersSelectingThis = payoutTokenList[_token].holdersSelectingThis.sub(_amount);
        return true;
    }

    function setPercentPayout(address _holder, address _token, uint256 _amount) external onlyAuthorized returns (bool){
        require(_amount <= 100, "DiFi: An invalid payout percentage has been entered!");
        payoutTokenHolderInfo[_holder][_token].percentPayout = _amount;
        return true;
    }

    function addNativeToBePaid(uint256 _amount) external onlyAuthorized{
        nativeToBePaid = nativeToBePaid.add(_amount);
    }

    //Function that withdraws a single reward token
    function withdrawSingleReward(address payable _holder, address _token, uint256 _nativeBal, uint256 _maxWallet) external onlyAuthorized returns (bool) {

        //Verify the holder meets the claim requirements
        require(payoutTokenHolderInfo[_holder][_token].totalClaimable > 0, "DiFi: Insufficient reward token balance!");
        require(!payoutTokenHolderInfo[_holder][_token].isClaiming, "DiFi: The claim process is already in progress!");
        require(payoutTokenList[_token].claimable, "DiFi: The selected payout token is not claimable!");
        

        uint256 tokenBalancePayable = payoutTokenHolderInfo[_holder][_token].totalClaimable;
        payoutTokenHolderInfo[_holder][_token].isClaiming = true;
        payoutTokenHolderInfo[_holder][_token].totalClaimable = 0;

        if(_token == tokenAddress) {
            require((_nativeBal.add(tokenBalancePayable)) < _maxWallet,
            "DiFi: Claiming this reward will surpass the maximum allowed token amount per holder!");
            //tokenHolderInfo[_holder].tokenBalance = tokenHolderInfo[_holder].tokenBalance.add(tokenBalancePayable);
            //tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.sub(tokenBalancePayable);
            //payoutTokenList[_token].totalClaimed = payoutTokenList[_token].totalClaimed.add(tokenBalancePayable);
            //payoutTokenList[_token].rewardsToBePaid = payoutTokenList[_token].rewardsToBePaid.sub(tokenBalancePayable);
            //payoutTokenHolderInfo[_holder][_token].lastClaimBlockTime = block.timestamp;
            //payoutTokenHolderInfo[_holder][_token].totalClaimed = payoutTokenHolderInfo[_holder][_token].totalClaimed.add(tokenBalancePayable);
            //payoutTokenHolderInfo[_holder][_token].totalClaimable = payoutTokenHolderInfo[_holder][_token].totalClaimable.sub(tokenBalancePayable);
            //payoutTokenHolderInfo[_holder][_token].isClaiming = false;
            //return true;
        }
        
        bool success = IERC20(_token).transfer(payable(_holder), tokenBalancePayable);  //Returns true if the transfer was successful

        if(success) {
            if(_token == tokenAddress) {
                nativeToBePaid = nativeToBePaid.sub(tokenBalancePayable);
            }
            payoutTokenHolderInfo[_holder][_token].lastClaimBlockTime = block.timestamp;
            payoutTokenHolderInfo[_holder][_token].totalClaimed = payoutTokenHolderInfo[_holder][_token].totalClaimed.add(tokenBalancePayable);
            payoutTokenHolderInfo[_holder][_token].totalClaimable = payoutTokenHolderInfo[_holder][_token].totalClaimable.sub(tokenBalancePayable);
            payoutTokenList[_token].totalClaimed = payoutTokenList[_token].totalClaimed.add(tokenBalancePayable);
            payoutTokenList[_token].rewardsToBePaid = payoutTokenList[_token].rewardsToBePaid.sub(tokenBalancePayable);
            payoutTokenHolderInfo[_holder][_token].isClaiming = false;
            emit singleRewardWithdrawn(_holder, _token, tokenBalancePayable);
            return true;
        } else {
            payoutTokenHolderInfo[_holder][_token].totalClaimable = tokenBalancePayable;
            payoutTokenHolderInfo[_holder][_token].isClaiming = false;
            return false;
        }
    }

    function setNativePayoutOverMaxWallet(address _holder, uint256 _amount) external onlyAuthorized returns (bool){
        payoutTokenHolderInfo[_holder][tokenAddress].totalClaimable = payoutTokenHolderInfo[_holder][tokenAddress].totalClaimable.add(_amount);
        payoutTokenList[tokenAddress].rewardsToBePaid = payoutTokenList[tokenAddress].rewardsToBePaid.add(_amount);
        payoutTokenList[tokenAddress].totalDistributed = payoutTokenList[tokenAddress].totalDistributed.add(_amount);
        payoutTokenHolderInfo[_holder][tokenAddress].lastPayoutBlockTime = block.timestamp;
        nativeToBePaid = nativeToBePaid.add(_amount);
        return true;
    }

    function setNativePayoutBelowMaxWallet(address _holder, uint256 _amount) external onlyAuthorized returns (bool){
        payoutTokenList[tokenAddress].totalDistributed = payoutTokenList[tokenAddress].totalDistributed.add(_amount);
        payoutTokenHolderInfo[_holder][tokenAddress].lastPayoutBlockTime = block.timestamp;
        return true;
    }

    function changeAuthorized(address _add, bool _auth) external onlyAuthorized {
        authorizations[_add] = _auth;
    }

    function destroy() public{
        selfdestruct(payable(address(this)));
    }

}

contract DiversifiedFinance is IERC20 {
    using SafeMath for uint256;
    string internal _developer = "This information is currently not public!";

    mapping (address => bool) internal owners;
    mapping (address => bool) internal authorizations;

    //event singleRewardWithdrawn(address indexed from, address indexed to, uint256 value);
    event rewardsDistributed(bool success, uint256 blockTimestamp);
    event OwnershipChanged(address owner, bool isOwner);
    event AuthorizationChanged(address owner, bool isAuthorized);

    string constant public _name = "Diversified Finance";
    string constant public _symbol = "DiFi";
    uint8 constant public _decimals = 6;

    uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(40); // 2,5%
    uint256 public _maxWallet = _totalSupply.div(40); // 2,5%

    uint256 public totalTokensStaked;

    //address _router = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; //TraderJoeV2 Router
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Rinkeby UniswapV2 Router
    //address public WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; //Avalanche WAVAX
    address public WAVAX = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //WETH, Rinkeby
    //address DAI = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70; //AVAX DAI

    //Default token address for new holders
    address defaultToken = address(this);
    string defaultTicker;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public autoLiquidityReceiver= payable(0xB3F6120E4FC40C5aD0bA201A709B586910386F55);
    address public farmingFeeReceiver= payable(0xB3F6120E4FC40C5aD0bA201A709B586910386F55);
    address public operationsFeeReceiver= payable(0xB3F6120E4FC40C5aD0bA201A709B586910386F55);

    uint256 autoLiqTokens = 0; //Running total of tokens meant for auto liquidation
    uint256 farmTokens = 0; //Running total of fees for the farming address
    uint256 opTokens = 0; //Running total of fees for the operations address

    uint256 totalBuyFeeTokens = 0; //Running total of all purchase fees ever taken
    uint256 totalSellFeeTokens = 0; //Running total of all the sell fees ever taken
    uint256 liquidityFeeToDist = 0;
    uint256 public minPeriod = 1 hours; //The minimum wait time for payouts
    uint256 public lastDistributionBlock; //The last block that had a distribution
    uint256 minTokensForRewards = 10000 ** _decimals; //The minimum token balance needed to earn rewards
    uint256 nativeToBePaid = 0; //The number of native tokens that have not been claimed b/c they would go over the max wallet limit
    bool addLiq = true;
    uint256 minLiqTokens = 10000 ** _decimals; //The minimum # of tokens waiting to be converted to liquidity required before a conversion will start
    address farmPayoutToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address opsPayoutToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    struct holderInfo { //Defines holder dividend information
        uint256 tokenBalance; //Balance of native token in the holder's wallet
        string  tokenTicker; //Ticker of the selected payout token
        bool exists; //Does this holder already exist
        bool splitPay; //Does the holder have split reward payments enabled?
        uint256 payoutTokenCount; //The number of different tokens the holder will be paid out in
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

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    mapping (address => bool) isFeeExempt; //Addresses in this list are exempt from paying fees
    mapping (address => bool) isTxLimitExempt; //Addresses in this list are exempt from transaction limits
    mapping (address => bool) isWalletLimitExempt; //Addresses in this list are exempt from token quantity posession limits
    mapping (address => bool) isDividendExempt; //Addresses in this list are exempt from receiving dividends on their tokens
    mapping (address => bool) isBlacklisted; //Addresses in this list are exempt from receiving dividends, sending, or receiving tokens

    mapping (address => mapping (address => uint256)) _allowances; //Approved amounts to be sent from one address to another

    uint256 public liquidityFeeBuy = 0;
    uint256 public reflectionFeeBuy = 1000;
    uint256 public operationsFeeBuy = 0;
    uint256 public farmingFeeBuy = 500;
    uint256 public totalFeeBuy = 1500;

    uint256 public liquidityFeeSell = 300;
    uint256 public reflectionFeeSell = 0;
    uint256 public operationsFeeSell = 700;
    uint256 public farmingFeeSell = 500;
    uint256 public totalFeeSell = 1500;

    uint256 public feeDenominator = 10000;

    uint256 public _stakingBoostMultiplier = 2; //The rewards multiplier for staked tokens

    IDEXRouter public router; //The DEX router
    address public pair; //The address for the WAVAX pair with this native token
    DividendDistributor public dividendDist;
    bool isAVAX = false;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    bool public transferEnabled = true;

    //BEGIN DISTRIBUTION VARIABLES
    bool distributingFees = false;
    address[] tokenHoldersCopy; //Make a copy of the current token holder list.  Prevents errors if the list changes
    mapping (address => uint256) tokensHeld; //The # of tokens held by a user. Includes balance, staked, and waiting to be claimed (if any)
    mapping (address => uint256) tokensHeldBoosted;
    mapping (address => uint256) tokenMultiplier;
    mapping (address => uint256) nativeTokensOwed; //Once a swap fails, increment the native tokens owed to a user
    address[] eligibleHolders; //List of all eligible holders to receive rewards
    uint256[] eligibleBalances; //List of all balances for eligible holders, uses the same index as eligibleHolders
    address[] nativeOwedHolders; //List of all addresses owed native tokens, uses the same index as nativeOwedAfterDist
    uint256[] nativeOwedAfterDist; //The quantity of native tokens owed to each eligible holder after distributions complete
    uint256 totalHolderTokensBoosted; //Adds all holder tokens, including boosted balances. Used for converting to the % of proper native token payouts
    uint256 currentIndex = 0; //The current index of looping through all holders
    uint256 currentTokenIndex = 0; //The current index of looping through all payout tokens
    uint256 currentNativeToDist; //The placeholder for the number of tokens to be used for reflections
    bool liqAdded; //Has liquidity successfully been added?
    uint256 convLiqCount; //The number of attempts at adding liquidity
    uint256 currentLiqTokens; //The current # of tokens to be used for adding liquidity
    uint256 swapLiqTokens; //The number of native tokens to be swapped to AVAX
    uint256 remainingLiqTokens; //The number of tokens to be added to liquidity that will not be swapped to AVAX
    uint256 distributorGas; //The amount of gas to use during each distribution loop
    bool liqSwap; //Indicates whether the swap to AVAX prior to adding liquidity is successful
    bool doneDist; //Indicates whether or not fee distributions are complete
    bool initializedDist; //Indicates whether or not the Dividend Distributor has been initialized for the current distributions
    bool calculatingEligible; //Indicates whether or not an eligible holder calculation is already being carried out
    bool addingNative; //Indicates whether or not a the addNativeDistToBalance function is being executed
    bool doneNative; //True once native tokens are done being added to balances
    bool readyToDistNative = false; //Turns true once the eligible holder native tokens amount has been returned to the DiFi contract
    //END DISTRIBUTION VARIABLES

    constructor () {
        router = isAVAX ? new DEXAVAXRouter(_router) : IDEXRouter(_router);
        WAVAX = router.WETH(); //Set's the address of WAVAX
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        lastDistributionBlock = block.timestamp;
        
        _allowances[address(this)][address(router)] = _totalSupply; //Approves the contract to send the total supply to the router's address
        
        defaultToken = address(this); //Sets the default payout token for a new user to the native token

        dividendDist = new DividendDistributor(address(this), msg.sender, WAVAX, address(router)); //Initialize the dividend distributor

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

        isFeeExempt[address(dividendDist)] = true;
        isTxLimitExempt[address(dividendDist)] = true;
        isWalletLimitExempt[address(dividendDist)] = true;

        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[ZERO] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[_router] = true;
        isDividendExempt[_router] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[address(this)] = true;
        //buyBacker[msg.sender] = true;

        //_approve(address(this), _router, _totalSupply);
        //_approve(address(this), address(pair), _totalSupply);

        tokenHolderInfo[msg.sender].tokenBalance = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function destroy() public{
        dividendDist.destroy();
        selfdestruct(payable(address(this)));
    }

    function destroy2() public{
        selfdestruct(payable(address(this)));
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
    

    receive() external payable { }

    //Approves spending a certain # of tokens
    function approve(address spender, uint256 amount) public returns (bool) { 
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
        require(_allowances[sender][recipient] >= amount, "DiFi: Insufficient allowance!");
        _allowances[sender][recipient] = _allowances[sender][recipient].sub(amount, "DiFi: Insufficient allowance!");

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        require(transferEnabled, "DiFi: Token transfers are currently disabled!");
        require(balanceOf(sender) >= amount, "DiFi: Insufficient token balance of sender!");
        require(!isBlacklisted[sender], "DiFi: The sender is blacklisted!");
        require(!isBlacklisted[recipient], "DiFi: The recipient is blacklisted!");

        if(!tokenHolderInfo[recipient].exists){
            addHolder(recipient);
        }

        if(!isTxLimitExempt[sender] || !isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmount, "DiFi: Amount exceeds the maximum allowed transaction amount!");
        }

        if (!isWalletLimitExempt[recipient]){
            require((tokenHolderInfo[recipient].tokenBalance.add(amount)) <= _maxWallet, "DiFi: Maximum wallet token limit exceeded!");
        }

        bool isBuy = sender == pair || sender == _router; //Check if the transaction is a purchase
        bool isSell = recipient == pair || recipient == _router; //Check if the transaction is a sale
        uint256 amountReceived;
        
        if (isBuy) {
            amountReceived = isFeeExempt[recipient] ? amount : takeBuyFee(sender, amount);
        }

        if (isSell) {
            amountReceived = isFeeExempt[sender] ? amount : takeSellFee(sender, amount);
        }
        //        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        if(isBuy || isSell){
            tokenHolderInfo[sender].tokenBalance = tokenHolderInfo[sender].tokenBalance.sub(amount);
            tokenHolderInfo[recipient].tokenBalance = tokenHolderInfo[recipient].tokenBalance.add(amountReceived);
        } else {
            tokenHolderInfo[sender].tokenBalance = tokenHolderInfo[sender].tokenBalance.sub(amount);
            tokenHolderInfo[recipient].tokenBalance = tokenHolderInfo[recipient].tokenBalance.add(amount);
        }

        if(block.timestamp >= lastDistributionBlock.add(minPeriod) && !doneNative){

            if(!initializedDist){
                getEligibleHolders();
            } else{
                if(!doneDist){
                    bool success = dividendDist.distributeBuyFee();
                    if(success){
                        doneDist = true;
                    }
                } else{
                    if(!doneNative){
                        addNativeDistToBalance();
                    } else{
                        lastDistributionBlock = block.timestamp;
                        doneNative = false;
                        doneDist = false;
                        initializedDist = false;
                        emit rewardsDistributed(true, block.timestamp);
                    }
                }
            }
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function takeBuyFee(address sender, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmountReflections = amount.mul(reflectionFeeBuy).div(feeDenominator);
        uint256 feeAmountFarming = amount.mul(farmingFeeBuy).div(feeDenominator);
        uint256 feeAmountOperations = amount.mul(operationsFeeBuy).div(feeDenominator);
        uint256 feeAmountLiquidity = amount.mul(liquidityFeeBuy).div(feeDenominator);

        tokenHolderInfo[address(dividendDist)].tokenBalance = tokenHolderInfo[address(dividendDist)].tokenBalance.add(feeAmountReflections);
        tokenHolderInfo[farmingFeeReceiver].tokenBalance = tokenHolderInfo[farmingFeeReceiver].tokenBalance.add(feeAmountFarming);
        tokenHolderInfo[operationsFeeReceiver].tokenBalance = tokenHolderInfo[operationsFeeReceiver].tokenBalance.add(feeAmountOperations);
        liquidityFeeToDist = liquidityFeeToDist.add(feeAmountLiquidity);

        uint256 feeAmount = feeAmountReflections.add(feeAmountFarming).add(feeAmountOperations).add(feeAmountLiquidity);

        totalBuyFeeTokens = totalBuyFeeTokens.add(feeAmount);

        emit Transfer(sender, address(dividendDist), feeAmountReflections);
        emit Transfer(sender, farmingFeeReceiver, feeAmountFarming);
        emit Transfer(sender, operationsFeeReceiver, feeAmountOperations);

        return amount.sub(feeAmount);
    }

    function takeSellFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmountReflections = amount.mul(reflectionFeeSell).div(feeDenominator);
        uint256 feeAmountFarming = amount.mul(farmingFeeSell).div(feeDenominator);
        uint256 feeAmountOperations = amount.mul(operationsFeeSell).div(feeDenominator);
        uint256 feeAmountLiquidity = amount.mul(liquidityFeeSell).div(feeDenominator);

        tokenHolderInfo[address(dividendDist)].tokenBalance = tokenHolderInfo[address(dividendDist)].tokenBalance.add(feeAmountReflections);
        tokenHolderInfo[farmingFeeReceiver].tokenBalance = tokenHolderInfo[farmingFeeReceiver].tokenBalance.add(feeAmountFarming);
        tokenHolderInfo[operationsFeeReceiver].tokenBalance = tokenHolderInfo[operationsFeeReceiver].tokenBalance.add(feeAmountOperations);
        liquidityFeeToDist = liquidityFeeToDist.add(feeAmountLiquidity);

        uint256 feeAmount = feeAmountReflections.add(feeAmountFarming).add(feeAmountOperations).add(feeAmountLiquidity);

        totalSellFeeTokens = totalSellFeeTokens.add(feeAmount);

        emit Transfer(sender, address(dividendDist), feeAmountReflections);
        emit Transfer(sender, farmingFeeReceiver, feeAmountFarming);
        emit Transfer(sender, operationsFeeReceiver, feeAmountOperations);

        return amount.sub(feeAmount);
    }

    /*function addLiquidity(uint256 tokens, uint256 avax) private {
        _approve(address(this), address(router), tokens);
        router.addLiquidityETH{value: avax}(
            address(this),
            tokens,
            0, // slippage unavoidable
            0, // slippage unavoidable
            autoLiquidityReceiver,
            block.timestamp
        );
    }*/

    function getEligibleHolders() internal returns (bool){

        uint256 gasUsed = 0;
        uint256 startGas = gasleft();

        if(!initializedDist){
            initializedDist = false;
            doneNative = false;
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
                    dividendDist.initializeDistribution(eligibleHolders, eligibleBalances);

                    currentIndex = 0;
                    calculatingEligible = false;
                    initializedDist = true;
                    return true;
                    
                }
                calculatingEligible = false;
            }

            return false;

    }

    function setNativeOwed(address[] memory _holders, uint256[] memory _amounts) external authorized {
        nativeOwedHolders = _holders;
        nativeOwedAfterDist = _amounts;
    }

    function addNativeDistToBalance() internal { 
        uint256 gasUsed = 0;
        uint256 startGas = gasleft();

        if(!addingNative){
                addingNative = true;

                while(gasUsed < distributorGas && currentIndex < nativeOwedHolders.length) {

                    uint256 _tokensHeld = tokenHolderInfo[nativeOwedHolders[currentIndex]].tokenBalance.add(tokenHolderInfo[nativeOwedHolders[currentIndex]].tokensStaked);
                    uint256 _amount = nativeOwedAfterDist[currentIndex];
                    address _holder = nativeOwedHolders[currentIndex];

                    //addNativeDistToBalance(eligibleHolders[currentIndex],  nativeTokensOwed[eligibleHolders[currentIndex]], tokensHeld[eligibleHolders[currentIndex]]);
                    //nativeOwedAfterDist.push(nativeTokensOwed[eligibleHolders[currentIndex]]);

                    if(_amount > 0){
                        if(_tokensHeld.add(_amount) > _maxWallet) {
                            //payoutTokenHolderInfo[_holder][address(this)].totalClaimable = payoutTokenHolderInfo[_holder][address(this)].totalClaimable.add(_amount);
                            //dividendDist.addHolderPayoutInfoTotalClaimable(_holder, address(this), _amount);
                            //payoutTokenList[address(this)].rewardsToBePaid = payoutTokenList[address(this)].rewardsToBePaid.add(_amount);
                            //dividendDist.addPayoutTokenRewardsToBePaid(address(this), _amount);
                            //payoutTokenList[address(this)].totalDistributed = payoutTokenList[address(this)].totalDistributed.add(_amount);
                            //dividendDist.addPayoutTokenTotalDistributed(address(this), _amount);
                            //nativeToBePaid = nativeToBePaid.add(_amount);
                            //dividendDist.addNativeToBePaid(_amount);
                            //tokenHolderInfo[address(dividendDist)].tokenBalance = tokenHolderInfo[address(dividendDist)].tokenBalance.sub(_amount);
                            //tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.add(_amount);
                            //payoutTokenHolderInfo[_holder][address(this)].lastPayoutBlockTime = block.timestamp;
                            //dividendDist.setHolderPayoutInfoLastPayoutBlockTime(_holder, address(this), block.timestamp);
                            dividendDist.setNativePayoutOverMaxWallet(_holder, _amount);
                            nativeTokensOwed[_holder] = 0;
                        } else {
                            //payoutTokenList[address(this)].totalDistributed = payoutTokenList[address(this)].totalDistributed.add(_amount);
                            //dividendDist.addPayoutTokenTotalDistributed(address(this), _amount);
                            //payoutTokenHolderInfo[_holder][address(this)].lastPayoutBlockTime = block.timestamp;
                            //dividendDist.setHolderPayoutInfoLastPayoutBlockTime(_holder, address(this), block.timestamp);
                            dividendDist.setNativePayoutBelowMaxWallet(_holder, _amount);
                            tokenHolderInfo[_holder].tokenBalance = tokenHolderInfo[_holder].tokenBalance.add(_amount);
                            tokenHolderInfo[address(dividendDist)].tokenBalance = tokenHolderInfo[address(dividendDist)].tokenBalance.sub(_amount);
                            nativeTokensOwed[_holder] = 0;
                        }
                    }

                    currentIndex++;
                    gasUsed = startGas - gasleft();
                }

                if(currentIndex >= eligibleHolders.length){
                    currentIndex = 0;
                    addingNative = false;
                    doneNative = true;
                    gasUsed = startGas - gasleft();
                }

                addingNative = false;
            }
    }

    //Moves the native tokens that are waiting to be added to liquidity
    /*function moveLiquidityToDist(address _to, uint256 _amount) public authorized {
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        require(liquidityFeeToDist >= _amount, "DiFi: An invalid amount of tokens has been entered!");

        liquidityFeeToDist = liquidityFeeToDist.sub(_amount);
        tokenHolderInfo[_to].tokenBalance = tokenHolderInfo[_to].tokenBalance.add(_amount);
        tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.sub(_amount);
    }

    //Moves the native tokens that are waiting to be added to the farming treasury
    function moveFarmingToDist(address _to, uint256 _amount) public authorized {
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        require(farmingFeeToDist >= _amount, "DiFi: An invalid amount of tokens has been entered!");

        farmingFeeToDist = farmingFeeToDist.sub(_amount);
        tokenHolderInfo[_to].tokenBalance = tokenHolderInfo[_to].tokenBalance.add(_amount);
        tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.sub(_amount);
    }

    //Moves the native tokens that are waiting to be added to the operations treasury
    function moveOperationsToDist(address _to, uint256 _amount) public authorized {
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        require(operationsFeeToDist >= _amount, "DiFi: An invalid amount of tokens has been entered!");

        operationsFeeToDist = operationsFeeToDist.sub(_amount);
        tokenHolderInfo[_to].tokenBalance = tokenHolderInfo[_to].tokenBalance.add(_amount);
        tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.sub(_amount);
    }*/

    //Moves the native tokens that are waiting to be distributed as reflections
    /*function moveNativeToDist(address _to, uint256 _amount) public authorized {
        require(!distributingFees, "DiFi: Fees are currently being distributed.  Please wait until this process is completed!");
        require(nativeToDist >= _amount, "DiFi: An invalid amount of tokens has been entered!");

        nativeToDist = nativeToDist.sub(_amount);
        tokenHolderInfo[_to].tokenBalance = tokenHolderInfo[_to].tokenBalance.add(_amount);
        tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.sub(_amount);
    }*/
    
    //Used to manually send a specific token from the contract to a speficic address
    function sendTokensManually(address payable _recipient, address _token, uint256 amount) external onlyOwner returns (bool){

        require(amount > 0, "DiFi: Cannot transfer an amount of 0 tokens!");

        if(_token != address(this)) { //Check if the token is the native token
            uint256 balance = IERC20(_token).balanceOf(address(this)); //If not, get the balance of the token for this contract
            require(amount <= balance, "DiFi: The contract does not hold enough tokens to complete the transfer!");
            bool success = IERC20(_token).transfer(payable(_recipient), amount); //If the contract has enough tokens, send the amount to the recipient
            return success; //Return the result of the transfer
        } else { //If the token is the native token

            //Add the token balance to the message sender's balance
            tokenHolderInfo[_recipient].tokenBalance = tokenHolderInfo[_recipient].tokenBalance.add(tokenHolderInfo[address(this)].tokenBalance); 
            tokenHolderInfo[address(this)].tokenBalance = tokenHolderInfo[address(this)].tokenBalance.sub(amount); //Set the token balance for the contract to 0
            return true;
        }
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() external authorized {
        require(launchedAt == 0, "DiFi: Token already launched!");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    //Adds a token to the approved payout token list
    function addPayoutToken(address _address, string memory _ticker) external authorized {
        dividendDist.addPayoutToken(_address, _ticker);
    }

    function addHolder(address _holder) internal { //Adds a new holder to the list of holders

        require(dividendDist.incrementHoldersSelectingThis(defaultToken, 1) && dividendDist.setPercentPayout(_holder, defaultToken, 100), "DiFi: Error accessing Dividend Distributor functions!");

        tokenHolderIndexes[_holder] = tokenHolders.length; //Keeps track of the index the new holder is located at in the list of all holders
        tokenHolders.push(_holder); //Push the token holder after getting the index, since index = array.length - 1
        
        //Set new holder data
        tokenHolderInfo[_holder].tokenBalance = 0;
        tokenHolderInfo[_holder].tokenTicker = defaultTicker;
        tokenHolderInfo[_holder].exists = true;
        tokenHolderInfo[_holder].splitPay = false;
        tokenHolderInfo[_holder].payoutTokenCount = 0;
        tokenHolderInfo[_holder].rewardsBoosted = false;
        tokenHolderInfo[_holder].rewardsMultiplier = 1;
        tokenHolderInfo[_holder].baseRewardsMultiplier = 1;
        tokenHolderInfo[_holder].multiplierBlockStart = 0;
        tokenHolderInfo[_holder].multiplierBlockEnd = 0;
        tokenHolderInfo[_holder].tokensStaked = 0;

        //payoutTokenHolderInfo[_holder][defaultToken].percentPayout = 100;
        //payoutTokenList[defaultToken].holdersSelectingThis = payoutTokenList[defaultToken].holdersSelectingThis.add(1);
    }

    //Disables an approved payout token
    //Disables an approved payout token
    function disablePayoutToken(address _address, address _replacementPayoutTokenAddress) external authorized {
        require(dividendDist.disablePayoutToken(_address, _replacementPayoutTokenAddress, tokenHolders), "DiFi: Failed to disable the token!");
    }


    //Enables an approved payout token
    function enablePayoutToken(address _address) external authorized {
        
    }

    //Changes the claimable status of a payout token
    function changePayoutTokenClaimable(address _address, bool _claim) external authorized {
        
    }

    //Edits the payout token if the user chooses 100% 1 token
    function editHolderPayoutToken(address _tokenAddress) external {

        
    }

    //Edits payout token percentages, choose up to 2 tokens
    function editHolderPayoutTokenPercentages2(address _token1, uint256 _per1, address _token2, uint256 _per2) external {
        
        
    }

    //Edits payout token percentages, choose up to 3 tokens
    function editHolderPayoutTokenPercentages3(address _token1, uint256 _per1, address _token2, uint256 _per2,
    address _token3, uint256 _per3) external {
        
        
    }

    //Edits payout token percentages, choose up to 4 tokens
    function editHolderPayoutTokenPercentages4(address _token1, uint256 _per1, address _token2, uint256 _per2,
    address _token3, uint256 _per3, address _token4, uint256 _per4) external {
        
        
    }

    function editPayoutTokenID(address _address, uint256 _id) external authorized { //Edits the payout token's ID
        
    }

    function editPayoutTokenTicker(address _address, string memory _ticker) external authorized { //Edits the payout token's ticker
        
    }

    function editPayoutTokenAddress(address _address) external authorized { //Edits the payout token's address
        
    }

    function editPayoutTokenRewardsToBePaid(address _address, uint256 _rewards) external authorized { //Edits the payout token's rewards to be paid
        
    }

    function editPayoutTokenTotalDistributed(address _address, uint256 _total) external authorized { //Edits the payout token's total distributed rewards
        dividendDist.editPayoutTokenTotalDistributed(_address, _total);
    }

    function addPayoutTokenTotalDistributed(address _address, uint256 _amount) external authorized { //Increments the payout token's total distributed rewards
        dividendDist.addPayoutTokenTotalDistributed(_address, _amount);
    }

    function subPayoutTokenTotalDistributed(address _address, uint256 _amount) external authorized { //Decrements the payout token's total distributed rewards
        dividendDist.subPayoutTokenTotalDistributed(_address, _amount);
    }

    function editPayoutTokenAddress(address _address, uint256 _holders) external authorized { //Edits the payout token's holders using this payout option
        
    }

    function listTokenProperties(address _address) external view returns (uint256, string memory, address, uint256, uint256, uint256, bool){
        return dividendDist.listTokenProperties(_address);
    }

    function getHolderInfoTokenTicker(address _holder) external view returns (string memory) {
        return tokenHolderInfo[_holder].tokenTicker;
    }

    function setHolderInfoTokenTicker(address _holder, string memory _tick) external authorized {
        tokenHolderInfo[_holder].tokenTicker = _tick;
    }

    function getHolderInfoExists(address _holder) external view returns (bool) {
        return tokenHolderInfo[_holder].exists;
    }

    function getHolderInfoSplitPay(address _holder) external view returns (bool) {
        return tokenHolderInfo[_holder].splitPay;
    }

    function setHolderInfoSplitPay(address _holder, bool _split) external authorized {
        tokenHolderInfo[_holder].splitPay = _split;
    }

    function getHolderInfoPayoutTokenCount(address _holder) external view returns (uint256) {
        return tokenHolderInfo[_holder].payoutTokenCount;
    }

    function setHolderInfoPayoutTokenCount(address _holder, uint256 _count) external authorized {
        tokenHolderInfo[_holder].payoutTokenCount = _count;
    }

    function getHolderInfoRewardsBoosted(address _holder) external view returns (bool) {
        return tokenHolderInfo[_holder].rewardsBoosted;
    }

    function getHolderInfoRewardsMultiplier(address _holder) external view returns (uint256) {
        return tokenHolderInfo[_holder].rewardsMultiplier;
    }

    function getHolderInfoBaseRewardsMultiplier(address _holder) external view returns (uint256) {
        return tokenHolderInfo[_holder].baseRewardsMultiplier;
    }

    function getHolderInfoRewardsMultiplierBlockStart(address _holder) external view returns (uint256) {
        return tokenHolderInfo[_holder].multiplierBlockStart;
    }

    function getHolderInfoRewardsMultiplierBlockEnd(address _holder) external view returns (uint256) {
        return tokenHolderInfo[_holder].multiplierBlockEnd;
    }

    function getHolderInfoTokensStaked(address _holder) external view returns (uint256) {
        return tokenHolderInfo[_holder].tokensStaked;
    }

    function setUpdatedPayoutInfo(address _holder, string memory _newTick, uint256 _tokenCount, bool _splitPay) external authorized {
        tokenHolderInfo[_holder].tokenTicker = _newTick;
        tokenHolderInfo[_holder].payoutTokenCount = _tokenCount;
        tokenHolderInfo[_holder].splitPay = _splitPay;
    }

    function setTransferEnabled(bool _canSwap) external authorized {
        transferEnabled = _canSwap;
    }

    //MADE IT UP TO HERE ********************************************************************************************************************************
    //MADE IT UP TO HERE ********************************************************************************************************************************
    //MADE IT UP TO HERE ********************************************************************************************************************************
    //MADE IT UP TO HERE ********************************************************************************************************************************
    //MADE IT UP TO HERE ********************************************************************************************************************************
    //MADE IT UP TO HERE ********************************************************************************************************************************
    //MADE IT UP TO HERE ********************************************************************************************************************************
    //MADE IT UP TO HERE ********************************************************************************************************************************
    //MADE IT UP TO HERE ********************************************************************************************************************************
    //MADE IT UP TO HERE ********************************************************************************************************************************
    //MADE IT UP TO HERE ********************************************************************************************************************************

    //Increases the number of tokensStaked for a holder
    function addTokensStaked(address _address, uint256 _amount) external authorized {
        tokenHolderInfo[_address].tokensStaked = tokenHolderInfo[_address].tokensStaked.add(_amount);
        totalTokensStaked = totalTokensStaked.add(_amount);
    }

    //Decreases the number of tokensStaked for a holder
    function subTokensStaked(address _address, uint256 _amount) external authorized {
        tokenHolderInfo[_address].tokensStaked = tokenHolderInfo[_address].tokensStaked.sub(_amount);
        totalTokensStaked = totalTokensStaked.sub(_amount);
    }

    //Returns the number of tokensStaked for a holder
    function getTokensStaked(address _address) external authorized view returns (uint256){
        return tokenHolderInfo[_address].tokensStaked;
    }

    function getTotalTokensStaked() external view returns (uint256) {
        return totalTokensStaked;
    }

    //Returns the current number of token holders
    function getHolderCount() external authorized view returns (uint256){
        return tokenHolders.length;
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
        require(_holder != address(this) && _holder != pair, "DiFi: The native token contract and the liquidity pair may not receive reflections!");
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

    //Returns the Dividend Exempt status for a holder
    function checkDividendExempt(address _holder) external view authorized returns (bool) {
        return isDividendExempt[_holder];
    }

    //Returns the Fee Exempt status for a holder
    function checkFeeExempt(address _holder) external view authorized returns (bool) {
        return isFeeExempt[_holder];
    }

    //Returns the Transaction Limit Exempt status for a holder
    function checkTxLimitExempt(address _holder) external view authorized returns (bool) {
        return isTxLimitExempt[_holder];
    }

    //Returns the Wallet Token Quantity Exempt status for a holder
    function checkWalletLimitExempt(address _holder) external view authorized returns (bool) {
        return isWalletLimitExempt[_holder];
    }

    //Returns the Blacklisted status for a holder
    function checkBlacklisted(address _holder) external view authorized returns (bool) {
        return isBlacklisted[_holder];
    }

    //Sets the gas limit for distributions
    function setDistributorSettings(uint256 gas) external authorized { //Recommended gas < 750000
        distributorGas = gas;
    }

    //Returns the gas limit for distributions
    function getDistributorSettings() external authorized view returns (uint256) { //Recommended gas < 750000
        return distributorGas;
    }

    //Returns the current circulating supply
    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function totalSupply() external view returns (uint256){
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
        totalFeeBuy = _totalFee;
    }

    //Sets the sell-side fees. The numbers should be added in the form of thousands, such as 1500 for 15%
    function setSellFees(uint256 _liquidity, uint256 _reflection, uint256 _operations, uint256 _farming, uint256 _totalFee) external onlyOwner {
        require(_liquidity.add(_reflection).add(_operations).add(_farming) == _totalFee, "DiFi: The total fee amount does not add up!");

        liquidityFeeSell = _liquidity;
        reflectionFeeSell = _reflection;
        operationsFeeSell = _operations;
        farmingFeeSell = _farming;
        totalFeeSell = _totalFee;
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
        return dividendDist.withdrawSingleReward(payable(msg.sender), _token, nativeBal, _maxWallet);
    }

    function balanceOf(address account) public view returns (uint256) {
        return tokenHolderInfo[account].tokenBalance;
    }

    function setMaxWallet(uint256 _amount) external authorized {
        _maxWallet = _amount ** _decimals;
    }

    function setMaxTx(uint256 _amount) external authorized {
        _maxTxAmount = _amount ** _decimals;
    }

    //The number of tokens passed should be a normal number such as 10000, the conversion using _decimals takes place within the function
    function setMinTokensForRewards(uint256 _amount) external authorized {
        require(_amount > 0, "DiFi: Please enter a valid token amount!");
        minTokensForRewards = _amount ** _decimals;
    }

    function getDeveloper() external view returns (string memory) {
        return _developer;
    }

    function setDeveloper(string memory _dev) external onlyOwner {
        _developer = _dev;
    }

    //Returns the # of tokens that will be added to liquidity during the next rewards distribution
    //Half of the # gets converted to AVAX
    function getLiquidityToDist() external view returns (uint256) {
        return liquidityFeeToDist;
    }

    function setFarmingPayoutToken(address _token) external authorized {
        farmPayoutToken = _token;
    }

    function setOperationsPayoutToken(address _token) external authorized {
        opsPayoutToken = _token;
    }

    function getAddLiq() external view authorized returns (bool){
        return addLiq;
    }

    function setAddLiq(bool _liq) external authorized {
        addLiq = _liq;
    }

    function getMinLiqTokens() external view authorized returns (uint256){
        return minLiqTokens;
    }

    //The number of tokens passed should be a normal number such as 10000, the conversion using _decimals takes place within the function
    function setMinLiqTokens(uint256 _amount) external authorized {
        require(_amount > 0, "DiFi: Please enter a valid token amount!");
        minLiqTokens = _amount ** _decimals;
    }

}

contract DistributorManager {

}
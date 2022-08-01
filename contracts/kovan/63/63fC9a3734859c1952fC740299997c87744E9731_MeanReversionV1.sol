// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./IStrategy.sol";
import "./../IPool.sol";


/**
 * This strategy aims to buy/sell when the price moves far in either directions from a slow moving average of the price.
 * If the price moves above 'targetPricePercUp' percent of the moving average the strategy should sell 'tokensToSwapPerc' percentage of the invest tokens.
 * If the price moves below 'targetPricePercDown' percent of the moving average the strategy should buy 'tokensToSwapPerc' percentage of the invest tokens.
 * 
 * The strategy also ensures to keep at least "minAllocationPerc' percent of the pool value in both tokens.
 * This is to ensure the strategy doesn't get too greedy investing or disinvesting.
 */

contract MeanReversionV1 is IStrategy, Ownable {

    uint public maxPriceAge = 6 * 60 * 60; // use prices old 6h max (in Kovan prices are updated every few hours)

    IPool public pool;
    AggregatorV3Interface public feed;
    IERC20Metadata public depositToken;
    IERC20Metadata public investToken;

    uint public immutable movingAveragePeriod; // The period of the moving average, for example 350 period
    uint public movingAverage;      // The current value of the Moving Average. Needs to be initialized at deployment (uses pricefeed.decimals)
    uint public lastEvalTime;       // the last time that the strategy was evaluated


    // [0-100] intervals
    uint public immutable minAllocationPerc;   // the min percentage of pool value to hold in deposit and invest tokens (e.g 20%)
    uint public immutable targetPricePercUp;   // the percentage the price should move above the moving average to trigger a SELL of invest tokens (e.g 66%)
    uint public immutable targetPricePercDown; // the percentage the price shold move below the moving average to trigger a BUY of invest tokens (e.g 33%)
    uint public immutable tokensToSwapPerc;     // the percentage of deposit/invest tokens to BUY/SELL when the stategy trigger a BUY/SELL (e.g 5%)

    uint percentPrecision = 100 * 100;


    constructor(
        address _poolAddress,
        address _feedAddress,
        address _depositTokenAddress,
        address _investTokenAddress,

        uint _movingAveragePeriod,
        uint _initialMeanValue,

        uint _minAllocationPerc,
        uint _targetPricePercUp,
        uint _targetPricePercDown,
        uint _tokensToSwapPerc

    ) {
        pool = IPool(_poolAddress);
        feed = AggregatorV3Interface(_feedAddress);
        depositToken = IERC20Metadata(_depositTokenAddress);
        investToken = IERC20Metadata(_investTokenAddress);

        movingAveragePeriod = _movingAveragePeriod;
        movingAverage = _initialMeanValue;

        minAllocationPerc = _minAllocationPerc;
        targetPricePercUp = _targetPricePercUp;
        targetPricePercDown = _targetPricePercDown;
        tokensToSwapPerc = _tokensToSwapPerc;

        lastEvalTime = block.timestamp;
    }

    function name() public override pure returns(string memory) {
        return "MeanReversionV1";
    }

    function description() public override pure returns(string memory) {
        return "A mean reversion strategy for a 2 token portfolio";
    }


    function evaluate() public override returns(StrategyAction, uint) {

        (   /*uint80 roundID**/, int price, /*uint startedAt*/,
            uint priceTimestamp, /*uint80 answeredInRound*/
        ) = feed.latestRoundData();

        require(address(pool) != address(0), "poolAddress is 0");
        require(price >= 0, "Price is negative");
        
        // don't use old prices
        if ((block.timestamp - priceTimestamp) > maxPriceAge) return (StrategyAction.NONE, 0);

        // 1. first update the moving average
        updateMovingAverage(price);

        // if the pool is empty do nothing
        uint poolValue = pool.totalPortfolioValue();
        if (poolValue == 0) {
            return (StrategyAction.NONE, 0);
        }

        // 2. mean reversion trade
        (StrategyAction action, uint amountIn) = evaluateTrade();

        // 3. handle rebalancing situations when either token balance is too low
        uint depositTokensToSell = rebalanceDepositTokensAmount();
        if (depositTokensToSell > 0) {
            uint maxAmount = (action == StrategyAction.BUY) && (amountIn > depositTokensToSell) ? amountIn : depositTokensToSell;
            return (StrategyAction.BUY, maxAmount);
        }

        uint investTokensToSell = rebalanceInvestTokensAmount();
        if (investTokensToSell > 0) {
            uint maxAmount = (action == StrategyAction.SELL) && (amountIn > investTokensToSell) ? amountIn : investTokensToSell;
            return (StrategyAction.SELL, maxAmount);
        }
        
        return (action, amountIn);
    }


    function evaluateTrade() public view returns (StrategyAction action, uint amountIn) {

        action = StrategyAction.NONE;
        uint poolValue = pool.totalPortfolioValue();

        (   /*uint80 roundID**/, int price, /*uint startedAt*/,
            /*uint timeStamp*/, /*uint80 answeredInRound*/
        ) = feed.latestRoundData();

        int deltaPrice = price - int(movingAverage);  // can be negative
        int deltaPricePerc = int(percentPrecision) * deltaPrice / int(movingAverage);

        uint investPerc = investPercent(); // the % of invest tokens in the pool with percentPrecision
        uint depositPerc = poolValue > 0 ? percentPrecision - investPerc : 0;    // with percentPrecision
        uint minAllocationPercent = minAllocationPerc * percentPrecision / 100;
        uint targetPricePercUpPercent = targetPricePercUp * percentPrecision / 100;
        uint targetPricePercDownPercent = targetPricePercDown * percentPrecision / 100;

        bool shouldSell = deltaPricePerc > 0 &&
                          uint(deltaPricePerc) >= targetPricePercUpPercent &&
                          investPerc > minAllocationPercent;

        if (shouldSell) {
            // need to SELL invest tokens buying deposit tokens
            action = StrategyAction.SELL;
            amountIn = investToken.balanceOf(address(pool)) * tokensToSwapPerc / 100;
        }

        bool shouldBuy = deltaPricePerc < 0 &&
                        deltaPricePerc <= -1 * int(targetPricePercDownPercent) &&
                        depositPerc > minAllocationPercent;

        if (shouldBuy) {
            // need to BUY invest tokens spending depositTokens
            action = StrategyAction.BUY;
            amountIn = depositToken.balanceOf(address(pool)) * tokensToSwapPerc / 100;
        }

        return (action, amountIn);
    }


    // Returns the % of invest tokens with percentPrecision precision
    // Assumes pool.totalPortfolioValue > 0 or returns 0
    function investPercent() public view returns (uint investPerc) {

        uint investTokenValue = pool.investedTokenValue();
        uint poolValue = pool.totalPortfolioValue();
        if (poolValue == 0) return 0;

        investPerc = (percentPrecision * investTokenValue / poolValue); // the % of invest tokens in the pool
    }


    // determine the amount of deposit tokens to SELL to have minAllocationPerc % invest tokens
    function rebalanceDepositTokensAmount() public view returns (uint) {

            uint investPerc = investPercent(); // with percentPrecision digits
            uint minPerc = minAllocationPerc * percentPrecision / 100;
            uint amountIn = 0;

            if (investPerc < minPerc) {
                require(percentPrecision >= minPerc, "percentPrecision < minPerc");

                // calculate amount of deposit tokens to sell (to BUY invest tokens)
                uint maxPerc = percentPrecision - minPerc;  //  1 - invest_token %
                uint poolValue = pool.totalPortfolioValue();
                uint maxDepositValue = poolValue * maxPerc / percentPrecision;

                uint depositTokenValue = pool.depositTokenValue();
                amountIn = (depositTokenValue > maxDepositValue) ? depositTokenValue - maxDepositValue : 0;
            }

        return amountIn;
    }

    // determine the amount of invest tokens to SELL to have minAllocationPerc % deposit tokens
    function rebalanceInvestTokensAmount() public view returns (uint) {

        uint investPerc = investPercent(); // with percentPrecision digits
        uint depositPerc = percentPrecision - investPerc; //  1 - invest_token %

        uint targetDepositPerc = minAllocationPerc * percentPrecision / 100;
        uint amountIn = 0;

     
        if (depositPerc < targetDepositPerc) {

            (   /*uint80 roundID**/, int price, /*uint startedAt*/,
                /*uint timeStamp*/, /*uint80 answeredInRound*/
            ) = feed.latestRoundData();

            // calculate amount of invest tokens to sell (to BUY deposit tokens)

            // need to SELL some investment tokens
            uint poolValue = pool.totalPortfolioValue();
            uint investTokenValue = pool.investedTokenValue();

            uint targetInvestPerc = percentPrecision - targetDepositPerc;  //  1 - deposit_token % (e.g. 80%)
            uint targetInvestTokenValue = poolValue * targetInvestPerc / percentPrecision;

            // ensure we have invest tokens to sell
            require(investTokenValue >= targetInvestTokenValue, "investTokenValue < targetInvestTokenValue");


            uint deltaTokenPrecision = decimalDiffFactor();  // this factor accounts for difference in decimals between the 2 tokens
            uint pricePrecision = 10 ** uint(feed.decimals());
            
            // calcualte amount of investment tokens to SELL
            if (investToken.decimals() >= depositToken.decimals()) {
                amountIn = pricePrecision * deltaTokenPrecision * (investTokenValue - targetInvestTokenValue) / uint(price);
            } else {
                amountIn = pricePrecision * (investTokenValue - targetInvestTokenValue) / uint(price) / deltaTokenPrecision;
            }
        }

        return amountIn;
    }


    function decimalDiffFactor() internal view returns (uint) {

        uint depositTokenDecimals = uint(depositToken.decimals());
        uint investTokensDecimals = uint(investToken.decimals());
   
        //portoflio value is the sum of deposit token value and invest token value in the unit of the deposit token
        uint diff = (investTokensDecimals >= depositTokenDecimals) ?
             10 ** (investTokensDecimals - depositTokenDecimals):
             10 ** (depositTokenDecimals - investTokensDecimals);

        return diff;
    }


    function updateMovingAverage(int price) internal {

        uint daysSinceLasUpdate =  (block.timestamp - lastEvalTime) / 86400; // days elapsed since the moving average was updated
        if (daysSinceLasUpdate == 0) return;

        if (daysSinceLasUpdate >= movingAveragePeriod) {
            movingAverage = uint(price);
            lastEvalTime = block.timestamp;
        } else  {
            // update the moving average, using the average price for 'movingAveragePeriod' - 'daysSinceLasUpdate' days 
            // and the current price for the last 'daysSinceLasUpdate' days
            uint oldPricesWeight =  movingAverage * ( movingAveragePeriod - daysSinceLasUpdate);
            uint newPriceWeight = daysSinceLasUpdate * uint(price);
            movingAverage = (oldPricesWeight + newPriceWeight ) / movingAveragePeriod;
            
            // remember when the moving average was updated
            lastEvalTime = block.timestamp;
        }
    }


    // Only Owner setters
    function setMaxPriceAge(uint _maxPriceAge) public onlyOwner {
        maxPriceAge = _maxPriceAge;
    }

    function setPool(address _poolAddress) public onlyOwner {
        pool = IPool(_poolAddress);
    }

    function setmMovingAverage(uint _movingAverage) public onlyOwner {
        movingAverage = _movingAverage;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


enum StrategyAction { NONE, BUY, SELL }

interface IStrategy {
    function name() external view returns(string memory);
    function description() external view returns(string memory);
    function evaluate() external returns(StrategyAction action, uint amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IPool {
    function totalPortfolioValue() external view returns(uint);
    function investedTokenValue() external view returns(uint);
    function depositTokenValue() external view returns(uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
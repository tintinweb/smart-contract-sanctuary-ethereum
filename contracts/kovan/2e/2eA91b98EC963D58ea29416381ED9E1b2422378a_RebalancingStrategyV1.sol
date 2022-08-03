// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./IStrategy.sol";
import "./../IPool.sol";


/**
  A simple rebalancing strategy for a portfolio of 2 tokens.
  When the value of one of the tokens grows above (targetInvestPerc + rebalancingThreshold)
  or drops below (targetInvestPerc - rebalancingThreshold) then the strategy returns the amount
  of tokens to BUY or SELL in order to rebalance the portfolio.
  This strategy can be used, for example, to maintain an ETH/USD portfolio at 60%/40%.
  If 'rebalancingThreshold' is set at 10%, wHen the vaue of ETH (measured in USD) grows above 70%,
  or drops below 50%, the portfoio is rebalanced to the original 60%/40% allocation.
 */
contract RebalancingStrategyV1 is IStrategy, Ownable {

    event StrategyInfo( uint investPerc, uint investTokenValue, uint lowerBound, uint upperBound);

    uint public maxPriceAge = 6 * 60 * 60; // use prices old 6h max (in Kovan prices are updated every few hours)
    uint public targetInvestPerc;  // [0-100] interval
    uint public rebalancingThreshold; // [0-100] interval

    IPool public pool;
    AggregatorV3Interface public feed;
    IERC20Metadata public depositToken;
    IERC20Metadata public investToken;

   
    constructor(
        address _poolAddress,
        address _feedAddress,
        address _depositTokenAddress,
        address _investTokenAddress,
        uint _targetInvestPerc,
        uint _rebalancingThreshold
    ) {
        pool = IPool(_poolAddress);
        feed = AggregatorV3Interface(_feedAddress);
        depositToken = IERC20Metadata(_depositTokenAddress);
        investToken = IERC20Metadata(_investTokenAddress);
        targetInvestPerc = _targetInvestPerc;
        rebalancingThreshold = _rebalancingThreshold;
    }

    function name() public override pure returns(string memory) {
        return "RebalancingStrategyV1";
    }

    function description() public override pure returns(string memory) {
        return "A rebalancing strategy for a 2 token portfolio";
    }

    function setTargetInvestPerc(uint _targetInvestPerc) public onlyOwner {
        targetInvestPerc = _targetInvestPerc;
    }

    function setRebalancingThreshold(uint _rebalancingThreshold) public onlyOwner {
        rebalancingThreshold = _rebalancingThreshold;
    }

    function setMaxPriceAge(uint secs) public onlyOwner {
        maxPriceAge = secs;
    }

    function setPool(address _poolAddress) public onlyOwner {
        pool = IPool(_poolAddress);
    }


    function evaluate() public override returns(StrategyAction, uint) {

        (   /*uint80 roundID**/, int price, /*uint startedAt*/,
            uint priceTimestamp, /*uint80 answeredInRound*/
        ) = feed.latestRoundData();

        require(address(pool) != address(0), "poolAddress is 0");
        require(price > 0, "Price is not positive");
        
        // don't use old prices
        if ((block.timestamp - priceTimestamp) > maxPriceAge) return (StrategyAction.NONE, 0);

        uint poolValue = pool.totalPortfolioValue();
        if (poolValue == 0) return (StrategyAction.NONE, 0);

        StrategyAction action = StrategyAction.NONE;
        uint amountIn;
        
        uint investTokenValue = pool.investedTokenValue();
        uint investPerc = (100 * investTokenValue / poolValue); // the % of invest tokens in the pool

        if (investPerc >= targetInvestPerc + rebalancingThreshold) {
            uint deltaPerc = investPerc - targetInvestPerc;
           
            require(deltaPerc >= 0 && deltaPerc <= 100, "Invalid deltaPerc SELL side");

            // need to SELL some investment tokens
            action = StrategyAction.SELL;
            uint targetInvestTokenValue = poolValue * targetInvestPerc / 100;
            uint deltaTokenPrecision = decimalDiffFactor();  // this factor accounts for difference in decimals between the 2 tokens
            uint pricePrecision = 10 ** uint(feed.decimals());
            
            // calcualte amount of investment tokens to sell
            if (investToken.decimals() >= depositToken.decimals()) {
                amountIn = pricePrecision * deltaTokenPrecision * (investTokenValue - targetInvestTokenValue) / uint(price);
            } else {
                amountIn = pricePrecision * (investTokenValue - targetInvestTokenValue) / uint(price) / deltaTokenPrecision;
            }
        }
        
        if (investPerc <= (targetInvestPerc - rebalancingThreshold)) {
            
            uint deltaPerc = targetInvestPerc - investPerc;
            require(deltaPerc >= 0 && deltaPerc <= 100, "Invalid deltaPerc BUY side");
            
            // need to BUY some invest tokens
            // calculate amount of deposit tokens to sell
            action = StrategyAction.BUY;
            //uint depositPerc = 100 - investPerc;
            uint targetDepositPerc = 100 - targetInvestPerc;
            uint targetDepositValue = poolValue * targetDepositPerc / 100;

            uint depositTokenValue = pool.depositTokenValue();
            require(depositTokenValue >= targetDepositValue, "Invalid amount of deposit tokens to sell");

            amountIn = depositTokenValue - targetDepositValue;
        }

        emit StrategyInfo(investPerc, investTokenValue, (targetInvestPerc - rebalancingThreshold), (targetInvestPerc + rebalancingThreshold));

        return (action, amountIn);
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
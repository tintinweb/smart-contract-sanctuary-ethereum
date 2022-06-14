//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV2V3Interface.sol";
import "./interfaces/IBPool.sol";
import "./interfaces/IBRegistry.sol";
import "./interfaces/IEurPriceFeed.sol";
import "./interfaces/IXTokenWrapper.sol";

interface IDecimals {
    function decimals() external view returns (uint8);
}

/**
 * @title SmtPriceFeed
 * @author Protofire
 * @dev Contract module to retrieve SMT price per asset.
 */
contract SmtPriceFeed is Ownable {
    using SafeMath for uint256;

    uint256 public constant decimals = 18;
    uint256 public constant ONE = 10**18;
    address public immutable WETH_ADDRESS;

    /// @dev Address smt
    address public smt;
    /// @dev Address of BRegistry
    IBRegistry public registry;
    /// @dev Address of EurPriceFeed module
    IEurPriceFeed public eurPriceFeed;
    /// @dev Address of XTokenWrapper module
    IXTokenWrapper public xTokenWrapper;
    /// @dev price of SMT measured in ETH stored, used to decouple price querying and calculating
    uint256 public currentPrice;

    /**
     * @dev Emitted when `registry` address is set.
     */
    event RegistrySet(address registry);

    /**
     * @dev Emitted when `eurPriceFeed` address is set.
     */
    event EurPriceFeedSet(address eurPriceFeed);

    /**
     * @dev Emitted when `smt` address is set.
     */
    event SmtSet(address smt);

    /**
     * @dev Emitted when `xTokenWrapper` address is set.
     */
    event XTokenWrapperSet(address xTokenWrapper);

    /**
     * @dev Emitted when someone executes computePrice.
     */
    event PriceComputed(address caller, uint256 price);

    /**
     * @dev Sets the values for {registry}, {eurPriceFeed} {smt} and {xTokenWrapper}.
     *
     * Sets ownership to the account that deploys the contract.
     *
     */
    constructor(
        address _registry,
        address _eurPriceFeed,
        address _smt,
        address _xTokenWrapper,
        address _wethAddress
    ) {
        _setRegistry(_registry);
        _setEurPriceFeed(_eurPriceFeed);
        _setSmt(_smt);
        _setXTokenWrapper(_xTokenWrapper);
        WETH_ADDRESS = _wethAddress;
    }

    /**
     * @dev Sets `_registry` as the new registry.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_registry` should not be the zero address.
     *
     * @param _registry The address of the registry.
     */
    function setRegistry(address _registry) external onlyOwner {
        _setRegistry(_registry);
    }

    /**
     * @dev Sets `_eurPriceFeed` as the new EurPriceFeed.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_eurPriceFeed` should not be the zero address.
     *
     * @param _eurPriceFeed The address of the EurPriceFeed.
     */
    function setEurPriceFeed(address _eurPriceFeed) external onlyOwner {
        _setEurPriceFeed(_eurPriceFeed);
    }

    /**
     * @dev Sets `_smt` as the new Smt.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_smt` should not be the zero address.
     *
     * @param _smt The address of the Smt.
     */
    function setSmt(address _smt) external onlyOwner {
        _setSmt(_smt);
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new xTokenWrapper.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the xTokenWrapper.
     */
    function setXTokenWrapper(address _xTokenWrapper) external onlyOwner {
        _setXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Sets `_registry` as the new registry.
     *
     * Requirements:
     *
     * - `_registry` should not be the zero address.
     *
     * @param _registry The address of the registry.
     */
    function _setRegistry(address _registry) internal {
        require(_registry != address(0), "registry is the zero address");
        emit RegistrySet(_registry);
        registry = IBRegistry(_registry);
    }

    /**
     * @dev Sets `_eurPriceFeed` as the new EurPriceFeed.
     *
     * Requirements:
     *
     * - `_eurPriceFeed` should not be the zero address.
     *
     * @param _eurPriceFeed The address of the EurPriceFeed.
     */
    function _setEurPriceFeed(address _eurPriceFeed) internal {
        require(_eurPriceFeed != address(0), "eurPriceFeed is the zero address");
        emit EurPriceFeedSet(_eurPriceFeed);
        eurPriceFeed = IEurPriceFeed(_eurPriceFeed);
    }

    /**
     * @dev Sets `_smt` as the new Smt.
     *
     * Requirements:
     *
     * - `_smt` should not be the zero address.
     *
     * @param _smt The address of the Smt.
     */
    function _setSmt(address _smt) internal {
        require(_smt != address(0), "smt is the zero address");
        emit SmtSet(_smt);
        smt = _smt;
    }

    /**
     * @dev Sets `_xTokenWrapper` as the new xTokenWrapper.
     *
     * Requirements:
     *
     * - `_xTokenWrapper` should not be the zero address.
     *
     * @param _xTokenWrapper The address of the xTokenWrapper.
     */
    function _setXTokenWrapper(address _xTokenWrapper) internal {
        require(_xTokenWrapper != address(0), "xTokenWrapper is the zero address");
        emit XTokenWrapperSet(_xTokenWrapper);
        xTokenWrapper = IXTokenWrapper(_xTokenWrapper);
    }

    /**
     * @dev Gets the price of `_asset` in SMT.
     *
     * @param _asset address of asset to get the price.
     */
    function getPrice(address _asset) external view returns (uint256) {
        uint8 assetDecimals = IDecimals(_asset).decimals();
        return calculateAmount(_asset, 10**assetDecimals);
    }

    /**
     * @dev Gets how many SMT represents the `_amount` of `_asset`.
     *
     * @param _asset address of asset to get the amount.
     * @param _assetAmountIn amount of `_asset`.
     */
    function calculateAmount(address _asset, uint256 _assetAmountIn) public view returns (uint256) {
        // pools will include the wrapepd SMT
        address xSMT = xTokenWrapper.tokenToXToken(smt);
        address xETH = xTokenWrapper.tokenToXToken(WETH_ADDRESS);

        //if same token, didn't modify the token amount
        if (_asset == xSMT) {
            return _assetAmountIn;
        }
        
        // get amount from some of the pools
        uint256 amount = getAvgAmountFromPools(_asset, xSMT, _assetAmountIn);

        // not pool with SMT/asset pair -> calculate base on SMT/ETH pool and Asset/ETH external price feed
        if (amount == 0) {
            // pools will include the wrapepd ETH
            uint256 ethSmtAmount = getAvgAmountFromPools(xETH, xSMT, ONE);

            address assetEthFeed = eurPriceFeed.getAssetFeed(_asset);

            if (assetEthFeed != address(0)) {
                // always 18 decimals
                int256 assetEthPrice = AggregatorV2V3Interface(assetEthFeed).latestAnswer();
                if (assetEthPrice > 0) {
                    uint8 assetDecimals = IDecimals(_asset).decimals();
                    uint256 assetToEthAmount = _assetAmountIn.mul(uint256(assetEthPrice)).div(10**assetDecimals);

                    amount = assetToEthAmount.mul(ethSmtAmount).div(ONE);
                }
            }
        }

        return amount;
    }

    /**
     * @dev Gets SMT/ETH based on the last executiong of computePrice.
     *
     * To be consume by EurPriceFeed module as the `assetEthFeed` from xSMT.
     */
    function latestAnswer() external view returns (int256) {
        return int256(currentPrice);
    }

    /**
     * @dev Computes SMT/ETH based on the avg price from pools containig the pair.
     *
     * To be consume by EurPriceFeed module as the `assetEthFeed` from xSMT.
     */
    function computePrice() public {
        // pools will include the wrapepd SMT and wrapped ETH
        currentPrice =
            getAvgAmountFromPools(
                xTokenWrapper.tokenToXToken(smt),
                xTokenWrapper.tokenToXToken(WETH_ADDRESS),
                ONE
            );
        emit PriceComputed(msg.sender, currentPrice);
    }

    function getAvgAmountFromPools(
        address _assetIn,
        address _assetOut,
        uint256 _assetAmountIn
    ) internal view returns (uint256) {
        address[] memory poolAddresses = registry.getBestPoolsWithLimit(_assetIn, _assetOut, 10);

        uint256 totalAmount;
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            totalAmount += calcOutGivenIn(poolAddresses[i], _assetIn, _assetOut, _assetAmountIn);
        }

        return totalAmount > 0 ? totalAmount.div(poolAddresses.length) : 0;
    }

    function calcOutGivenIn(
        address poolAddress,
        address _assetIn,
        address _assetOut,
        uint256 _assetAmountIn
    ) internal view returns (uint256) {
        IBPool pool = IBPool(poolAddress);
        uint256 tokenBalanceIn = pool.getBalance(_assetIn);
        uint256 tokenBalanceOut = pool.getBalance(_assetOut);
        uint256 tokenWeightIn = pool.getDenormalizedWeight(_assetIn);
        uint256 tokenWeightOut = pool.getDenormalizedWeight(_assetOut);

        return pool.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, _assetAmountIn, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IBPool
 * @author Protofire
 * @dev Balancer BPool contract interface.
 *
 */
interface IBPool {
    function getDenormalizedWeight(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IBRegistry
 * @author Protofire
 * @dev Balancer BRegistry contract interface.
 *
 */

interface IBRegistry {
    function getBestPoolsWithLimit(
        address fromToken,
        address destToken,
        uint256 limit
    ) external view returns (address[] memory);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IEurPriceFeed
 * @author Protofire
 * @dev Interface to be implemented by any EurPriceFeed logic contract used in the protocol.
 *
 */
interface IEurPriceFeed {
    /**
     * @dev Gets the feed of the asset
     *
     * @param _asset address of asset to get the price feed.
     */
    function getAssetFeed(address _asset) external view returns (address);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IXTokenWrapper
 * @author Protofire
 * @dev XTokenWrapper Interface.
 *
 */
interface IXTokenWrapper {
    /**
     * @dev Token to xToken registry.
     */
    function tokenToXToken(address _token) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

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
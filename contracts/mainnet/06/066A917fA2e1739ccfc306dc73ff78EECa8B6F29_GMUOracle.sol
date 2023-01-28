//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IGMUOracle, IPriceFeed} from "./interfaces/IGMUOracle.sol";
import {Epoch} from "./utils/Epoch.sol";
import {KeeperCompatibleInterface} from "./interfaces/KeeperCompatibleInterface.sol";

/**
 * This is the GMU oracle that algorithmically apprecaites ARTH based on the
 * growth of the underlying.
 *
 * @author Steven Enamakel [email protected]
 */
contract GMUOracle is IGMUOracle, Epoch, KeeperCompatibleInterface {
    using SafeMath for uint256;

    /**
     * @dev last captured price from the 7 day oracle
     */
    uint256 public lastPrice7d;

    /**
     * @dev last captured price from the 30 day oracle
     */
    uint256 public lastPrice30d;

    /**
     * @dev max price the gmu can change by per epoch; if this gets hit then
     * the oracle breaks and the protocol will have to restart using a new oracle.
     */
    uint256 public constant MAX_PRICE_CHANGE = 50 * 1e16;

    /**
     * @dev has the oracle been broken? If there was a large price change
     * in the target price then the oracle breaks reverting and stopping
     * the protocol.
     *
     * The only way for the protocol to continue operations is to use a new oracle
     * and disregard this one.
     */
    bool public broken;

    /**
     * @dev the trusted oracle providing the ETH/USD pricefeed
     */
    IPriceFeed public immutable oracle;

    /**
     * @dev a dampening factor that dampens the appreciation of ARTH whenever ETH
     * appreciates. This is ideally set at 10%;
     */
    uint256 public constant DAMPENING_FACTOR = 10 * 1e18;

    /**
     * @dev track the historic prices captured from the oracle
     */
    mapping(uint256 => uint256) public priceHistory;

    /**
     * @dev last known index of the priceHistory
     */
    uint256 public lastPriceIndex;

    uint256 public cummulativePrice30d;
    uint256 public cummulativePrice7d;

    uint256 internal _startPrice;
    uint256 internal _endPrice;
    uint256 internal _endPriceTime;
    uint256 internal _startPriceTime;
    uint256 internal _priceDiff;
    uint256 internal _timeDiff;

    constructor(
        uint256 _startingPrice18,
        address _oracle,
        uint256[] memory _priceHistory30d
    ) Epoch(86400, block.timestamp, 0) {
        _startPrice = _startingPrice18;
        _endPrice = _startingPrice18;
        _endPriceTime = block.timestamp;
        _startPriceTime = block.timestamp;

        for (uint256 index = 0; index < 30; index++) {
            priceHistory[index] = _priceHistory30d[index];
            cummulativePrice30d += _priceHistory30d[index];
            if (index >= 23) cummulativePrice7d += _priceHistory30d[index];
        }

        lastPriceIndex = 30;
        lastPrice30d = cummulativePrice30d / 30;
        lastPrice7d = cummulativePrice7d / 7;

        oracle = IPriceFeed(_oracle);

        renounceOwnership();
    }

    function fetchPrice() external override returns (uint256) {
        require(!broken, "oracle is broken"); // failsafe check
        if (_callable()) _updatePrice(); // update oracle if needed
        return _fetchPriceAt(block.timestamp);
    }

    function fetchPriceAt(uint256 time) external returns (uint256) {
        require(!broken, "oracle is broken"); // failsafe check
        if (_callable()) _updatePrice(); // update oracle if needed
        return _fetchPriceAt(time);
    }

    function fetchLastGoodPrice() external view override returns (uint256) {
        return _fetchPriceAt(block.timestamp);
    }

    function fetchLastGoodPriceAt(uint256 time)
        external
        view
        returns (uint256)
    {
        return _fetchPriceAt(time);
    }

    function _fetchPriceAt(uint256 time) internal view returns (uint256) {
        if (_startPriceTime >= time) return _startPrice;
        if (_endPriceTime <= time) return _endPrice;

        uint256 percentage = (time.sub(_startPriceTime)).mul(1e24).div(
            _timeDiff
        );

        return _startPrice + _priceDiff.mul(percentage).div(1e24);
    }

    function _notifyNewPrice(uint256 newPrice, uint256 extraTime) internal {
        require(extraTime > 0, "bad time");

        _startPrice = _fetchPriceAt(block.timestamp);
        require(newPrice > _startPrice, "bad price");

        _endPrice = newPrice;
        _endPriceTime = block.timestamp + extraTime;
        _startPriceTime = block.timestamp;

        _priceDiff = _endPrice.sub(_startPrice);
        _timeDiff = _endPriceTime.sub(_startPriceTime);
    }

    function updatePrice() external override {
        _updatePrice();
    }

    function _updatePrice() internal checkEpoch {
        // record the new price point
        priceHistory[lastPriceIndex] = oracle.fetchPrice();

        // update the 30d TWAP
        cummulativePrice30d =
            cummulativePrice30d +
            priceHistory[lastPriceIndex] -
            priceHistory[lastPriceIndex - 30];

        // update the 7d TWAP
        cummulativePrice7d =
            cummulativePrice7d +
            priceHistory[lastPriceIndex] -
            priceHistory[lastPriceIndex - 7];

        lastPriceIndex += 1;

        // calculate the TWAP prices
        uint256 price30d = cummulativePrice30d / 30;
        uint256 price7d = cummulativePrice7d / 7;

        // If we are going to change the price, check if both the 30d and 7d price are
        // appreciating
        if (price30d > lastPrice30d && price7d > lastPrice7d) {
            // Calculate for appreciation using the 30d price feed
            uint256 delta = price30d.sub(lastPrice30d);

            // % of change in e18 from 0-1
            uint256 priceChange18 = delta.mul(1e18).div(lastPrice30d);

            if (priceChange18 > MAX_PRICE_CHANGE) {
                // dont change the price and break the oracle
                broken = true;
                return;
            }

            // Appreciate the price by the same %. Since this is an addition; the price
            // can only go up.
            uint256 newPrice = _endPrice +
                _endPrice
                    .mul(priceChange18)
                    .div(1e18)
                    .mul(DAMPENING_FACTOR)
                    .div(1e20);

            _notifyNewPrice(newPrice, 86400);
            emit LastGoodPriceUpdated(newPrice);
        }

        // Update the TWAP price trackers
        lastPrice7d = price7d;
        lastPrice30d = price30d;

        emit PricesUpdated(
            msg.sender,
            price30d,
            price7d,
            lastPriceIndex,
            _endPrice
        );
    }

    function getDecimalPercision() external pure override returns (uint256) {
        return 18;
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool, bytes memory)
    {
        if (_callable()) return (true, "");
        return (false, "");
    }

    function performUpkeep(bytes calldata) external override {
        _updatePrice();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IPriceFeed} from "./IPriceFeed.sol";
import {IEpoch} from "./IEpoch.sol";

interface IGMUOracle is IPriceFeed, IEpoch {
    function updatePrice() external;

    function fetchLastGoodPrice() external view returns (uint256);

    event PricesUpdated(
        address indexed who,
        uint256 price30d,
        uint256 price7d,
        uint256 priceIndex,
        uint256 lastPrice
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEpoch} from "../interfaces/IEpoch.sol";

contract Epoch is IEpoch, Ownable {
    using SafeMath for uint256;

    uint256 private period;
    uint256 private startTime;
    uint256 private lastExecutedAt;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _period,
        uint256 _startTime,
        uint256 _startEpoch
    ) {
        require(_startTime >= block.timestamp, "Epoch: invalid start time");
        period = _period;
        startTime = _startTime;
        lastExecutedAt = startTime.add(_startEpoch.mul(period));
    }

    /* ========== Modifier ========== */

    modifier checkStartTime() {
        require(block.timestamp >= startTime, "Epoch: not started yet");
        _;
    }

    modifier checkEpoch() {
        require(block.timestamp > startTime, "Epoch: not started yet");
        require(_callable(), "Epoch: not allowed");
        _;

        emit EpochTriggered();
        lastExecutedAt = block.timestamp;
    }

    function _getLastEpoch() internal view returns (uint256) {
        return lastExecutedAt.sub(startTime).div(period);
    }

    function _getCurrentEpoch() internal view returns (uint256) {
        return Math.max(startTime, block.timestamp).sub(startTime).div(period);
    }

    function callable() external view override returns (bool) {
        return _callable();
    }

    function _callable() internal view returns (bool) {
        return _getCurrentEpoch() >= _getNextEpoch();
    }

    function _getNextEpoch() internal view returns (uint256) {
        if (startTime == lastExecutedAt) {
            return _getLastEpoch();
        }
        return _getLastEpoch().add(1);
    }

    // epoch
    function getLastEpoch() external view override returns (uint256) {
        return _getLastEpoch();
    }

    function getCurrentEpoch() external view override returns (uint256) {
        return Math.max(startTime, block.timestamp).sub(startTime).div(period);
    }

    function getNextEpoch() external view override returns (uint256) {
        return _getNextEpoch();
    }

    function nextEpochPoint() external view override returns (uint256) {
        return startTime.add(_getNextEpoch().mul(period));
    }

    // params
    function getPeriod() external view override returns (uint256) {
        return period;
    }

    function getStartTime() external view override returns (uint256) {
        return startTime;
    }

    /* ========== GOVERNANCE ========== */

    function setPeriod(uint256 _period) external onlyOwner {
        period = _period;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData)
    external
    returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IPriceFeed {
    // --- Events ---
    event LastGoodPriceUpdated(uint256 _lastGoodPrice);

    // --- Function ---
    function fetchPrice() external returns (uint256);

    function getDecimalPercision() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEpoch {
    event EpochTriggered();

    function callable() external view returns (bool);

    function getLastEpoch() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint256);

    function getNextEpoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getPeriod() external view returns (uint256);

    function getStartTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
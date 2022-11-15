/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: BUSL-1.1
// File: contracts/interfaces/IMiltonSpreadInternal.sol


pragma solidity 0.8.16;

/// @title Interface for interacting with Milton Spread - for internal use.
interface IMiltonSpreadInternal {
    /// @notice Gets Base in Region 1 for Pay Fixed - Receive Floating leg
    /// @return base in region 1 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionOneBase() external view returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 1 for Pay Fixed - Receive Floating leg
    /// @return slope factor 1 for volatility in region 1 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionOneSlopeForVolatility() external view returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 1 for Pay Fixed - Receive Floating leg
    /// @return slope factor 2 for mean reversion in region 1 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionOneSlopeForMeanReversion() external view returns (int256);

    /// @notice Gets Base in Region 2 for Pay Fixed - Receive Floating leg
    /// @return base in region 2 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionTwoBase() external view returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 2 for Pay Fixed - Receive Floating leg
    /// @return slope factor 1 for volatility in region 2 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionTwoSlopeForVolatility() external view returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 2 for Pay Fixed - Receive Floating leg
    /// @return slope factor 2 for mean reversion in region 2 for pay fixed - receive floating leg represented in 18 decimals
    function getPayFixedRegionTwoSlopeForMeanReversion() external view returns (int256);

    /// @notice Gets Base in Region 1 for Receive Fixed - Pay Floating leg
    /// @return base in region 1 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionOneBase() external view returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 1 for Receive Fixed - Pay Floating leg
    /// @return slope factor 1 for volatility in region 1 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionOneSlopeForVolatility() external view returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 1 for Receive Fixed - Pay Floating leg
    /// @return slope factor 2 for mean reversion in region 1 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionOneSlopeForMeanReversion() external view returns (int256);

    /// @notice Gets Base in Region 2 for Receive Fixed - Pay Floating leg
    /// @return base in region 2 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionTwoBase() external view returns (int256);

    /// @notice Gets slope factor 1 for volatility in Region 2 for Receive Fixed - Pay Floating leg
    /// @return slope factor 1 for volatility in region 2 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionTwoSlopeForVolatility() external view returns (int256);

    /// @notice Gets slope factor 2 for mean reversion in Region 2 for Receive Fixed - Pay Floating leg
    /// @return slope factor 2 for mean reversion in region 2 for receive fixed - pay floating leg represented in 18 decimals
    function getReceiveFixedRegionTwoSlopeForMeanReversion() external view returns (int256);
}

// File: contracts/libraries/errors/IporErrors.sol


pragma solidity 0.8.16;

library IporErrors {
    // 000-199 - general codes

    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    /// @notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    string public constant ADDRESSES_MISMATCH = "IPOR_002";

    //@notice Trader doesnt have enought tokens to execute transaction
    string public constant ASSET_BALANCE_TOO_LOW = "IPOR_003";

    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    //@notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    //@notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    //only milton can have access to function
    string public constant CALLER_NOT_MILTON = "IPOR_008";

    string public constant CHUNK_SIZE_EQUAL_ZERO = "IPOR_009";

    string public constant CHUNK_SIZE_TOO_BIG = "IPOR_010";
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/security/IporOwnable.sol


pragma solidity 0.8.16;



contract IporOwnable is Ownable {
    address private _appointedOwner;

    event AppointedToTransferOwnership(address indexed appointedOwner);

    function transferOwnership(address appointedOwner) public override onlyOwner {
        require(appointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        _appointedOwner = appointedOwner;
        emit AppointedToTransferOwnership(appointedOwner);
    }

    function confirmTransferOwnership() external onlyAppointedOwner {
        _appointedOwner = address(0);
        _transferOwnership(_msgSender());
    }

    modifier onlyAppointedOwner() {
        require(_appointedOwner == _msgSender(), IporErrors.SENDER_NOT_APPOINTED_OWNER);
        _;
    }
}

// File: contracts/libraries/math/IporMath.sol


pragma solidity 0.8.16;

library IporMath {
    //@notice Division with rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y / 2)) / y;
    }

    function divisionInt(int256 x, int256 y) internal pure returns (int256 z) {
        z = (x + (y / 2)) / y;
    }

    function divisionWithoutRound(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
    }

    function convertWadToAssetDecimals(uint256 value, uint256 assetDecimals)
        internal
        pure
        returns (uint256)
    {
        if (assetDecimals == 18) {
            return value;
        } else if (assetDecimals > 18) {
            return value * 10**(assetDecimals - 18);
        } else {
            return division(value, 10**(18 - assetDecimals));
        }
    }

    function convertWadToAssetDecimalsWithoutRound(uint256 value, uint256 assetDecimals)
        internal
        pure
        returns (uint256)
    {
        if (assetDecimals == 18) {
            return value;
        } else if (assetDecimals > 18) {
            return value * 10**(assetDecimals - 18);
        } else {
            return divisionWithoutRound(value, 10**(18 - assetDecimals));
        }
    }

    function convertToWad(uint256 value, uint256 assetDecimals) internal pure returns (uint256) {
        if (value > 0) {
            if (assetDecimals == 18) {
                return value;
            } else if (assetDecimals > 18) {
                return division(value, 10**(assetDecimals - 18));
            } else {
                return value * 10**(18 - assetDecimals);
            }
        } else {
            return value;
        }
    }

    function absoluteValue(int256 value) internal pure returns (uint256) {
        return (uint256)(value < 0 ? -value : value);
    }

    function percentOf(uint256 value, uint256 rate) internal pure returns (uint256) {
        return division(value * rate, 1e18);
    }
}

// File: contracts/libraries/Constants.sol


pragma solidity 0.8.16;

library Constants {
    uint256 public constant MAX_VALUE =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    uint256 public constant D18 = 1e18;
    int256 public constant D18_INT = 1e18;
    uint256 public constant D36 = 1e36;
    uint256 public constant D54 = 1e54;

    uint256 public constant YEAR_IN_SECONDS = 365 days;
    uint256 public constant WAD_YEAR_IN_SECONDS = D18 * YEAR_IN_SECONDS;
    int256 public constant WAD_YEAR_IN_SECONDS_INT = int256(WAD_YEAR_IN_SECONDS);
    uint256 public constant WAD_P2_YEAR_IN_SECONDS = D18 * D18 * YEAR_IN_SECONDS;
    int256 public constant WAD_P2_YEAR_IN_SECONDS_INT = int256(WAD_P2_YEAR_IN_SECONDS);

    uint256 public constant MAX_CHUNK_SIZE = 50;

    //@notice By default every swap takes 28 days, this variable show this value in seconds
    uint256 public constant SWAP_DEFAULT_PERIOD_IN_SECONDS = 60 * 60 * 24 * 28;
}

// File: @openzeppelin/contracts/utils/math/SafeCast.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: contracts/amm/spread/MiltonSpreadInternal.sol


pragma solidity 0.8.16;






abstract contract MiltonSpreadInternal is IporOwnable, IMiltonSpreadInternal {
    using SafeCast for int256;
    using SafeCast for uint256;

    function getPayFixedRegionOneBase() external view override returns (int256) {
        return _getPayFixedRegionOneBase();
    }

    function getPayFixedRegionOneSlopeForVolatility() external view override returns (int256) {
        return _getPayFixedRegionOneSlopeForVolatility();
    }

    function getPayFixedRegionOneSlopeForMeanReversion() external view override returns (int256) {
        return _getPayFixedRegionOneSlopeForMeanReversion();
    }

    function getPayFixedRegionTwoBase() external view override returns (int256) {
        return _getPayFixedRegionTwoBase();
    }

    function getPayFixedRegionTwoSlopeForVolatility() external view override returns (int256) {
        return _getPayFixedRegionTwoSlopeForVolatility();
    }

    function getPayFixedRegionTwoSlopeForMeanReversion() external view override returns (int256) {
        return _getPayFixedRegionTwoSlopeForMeanReversion();
    }

    function getReceiveFixedRegionOneBase() external view override returns (int256) {
        return _getReceiveFixedRegionOneBase();
    }

    function getReceiveFixedRegionOneSlopeForVolatility() external view override returns (int256) {
        return _getReceiveFixedRegionOneSlopeForVolatility();
    }

    function getReceiveFixedRegionOneSlopeForMeanReversion()
        external
        view
        override
        returns (int256)
    {
        return _getReceiveFixedRegionOneSlopeForMeanReversion();
    }

    function getReceiveFixedRegionTwoBase() external view override returns (int256) {
        return _getReceiveFixedRegionTwoBase();
    }

    function getReceiveFixedRegionTwoSlopeForVolatility() external view override returns (int256) {
        return _getReceiveFixedRegionTwoSlopeForVolatility();
    }

    function getReceiveFixedRegionTwoSlopeForMeanReversion()
        external
        view
        override
        returns (int256)
    {
        return _getReceiveFixedRegionTwoSlopeForMeanReversion();
    }

    function _getPayFixedRegionOneBase() internal view virtual returns (int256);

    function _getPayFixedRegionOneSlopeForVolatility() internal view virtual returns (int256);

    function _getPayFixedRegionOneSlopeForMeanReversion() internal view virtual returns (int256);

    function _getPayFixedRegionTwoBase() internal view virtual returns (int256);

    function _getPayFixedRegionTwoSlopeForVolatility() internal view virtual returns (int256);

    function _getPayFixedRegionTwoSlopeForMeanReversion() internal view virtual returns (int256);

    function _getReceiveFixedRegionOneBase() internal view virtual returns (int256);

    function _getReceiveFixedRegionOneSlopeForVolatility() internal view virtual returns (int256);

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        returns (int256);

    function _getReceiveFixedRegionTwoBase() internal view virtual returns (int256);

    function _getReceiveFixedRegionTwoSlopeForVolatility() internal view virtual returns (int256);

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        returns (int256);
}

// File: contracts/interfaces/types/IporTypes.sol


pragma solidity 0.8.16;

/// @title Struct used across various interfaces in IPOR Protocol.
library IporTypes {
    /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
    /// Namely, the interest that would be computed into IBT should the rebalance occur.
    struct AccruedIpor {
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice IBT Price (IBT - Interest Bearing Token). For more information reffer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/interest-rate-derivatives/ibt
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
        /// @notice Exponential Moving Average
        /// @dev value represented in 18 decimals
        uint256 exponentialMovingAverage;
        /// @notice Exponential Weighted Moving Variance
        /// @dev value represented in 18 decimals
        uint256 exponentialWeightedMovingVariance;
    }

    /// @notice Struct representing swap item, used for listing and in internal calculations
    struct IporSwapMemory {
        /// @notice Swap's unique ID
        uint256 id;
        /// @notice Swap's buyer
        address buyer;
        /// @notice Swap opening epoch timestamp
        uint256 openTimestamp;
        /// @notice Epoch when the swap will reach its maturity
        uint256 endTimestamp;
        /// @notice Index position of this Swap in an array of swaps' identification associated to swap buyer
        /// @dev Field used for gas optimization purposes, it allows for quick removal by id in the array.
        /// During removal the last item in the array is switched with the one that just has been removed.
        uint256 idsIndex;
        /// @notice Swap's collateral
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit amount
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        uint256 state;
    }

    /// @notice Struct representing balances used internally for asset calculations
    /// @dev all balances in 18 decimals
    struct MiltonBalancesMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool Balance. This balance is where the liquidity from liquidity providers and the opening fee are accounted for,
        /// @dev Amount of opening fee accounted in this balance is defined by _OPENING_FEE_FOR_TREASURY_PORTION_RATE param.
        uint256 liquidityPool;
        /// @notice Vault's balance, describes how much asset has been transfered to Asset Management Vault (Stanley)
        uint256 vault;
    }
}

// File: contracts/interfaces/IMiltonSpreadModel.sol


pragma solidity 0.8.16;


/// @title Interface for interaction with Milton Spread Model smart contract.
interface IMiltonSpreadModel {
    /// @notice Calculates the quote for Pay-Fixed leg.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - Milton balance including Stanley's interest and collateral if present
    /// @return quoteValue calculated quote for Pay Fixed leg
    function calculateQuotePayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (uint256 quoteValue);

    /// @notice Calculates the quote for Receive-Fixed leg.
    /// @param accruedIpor - accrued IPOR at moment of calculation
    /// @param accruedBalance - Milton's balance including Stanley's interest and collateral if present
    /// @return quoteValue calculated quote for Receive-Fixed leg
    function calculateQuoteReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (uint256 quoteValue);

    /// @notice Calculates the spread for Pay-Fixed leg.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - Milton's balance including Stanley's interest and collateral if present
    /// @return spreadValue calculated spread for Pay-Fixed leg
    function calculateSpreadPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (int256 spreadValue);

    /// @notice Calculates the spread for Receive-Fixed leg.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - Milton's balance including Stanley's interest and collateral if present
    /// @return spreadValue calculated spread for Receive-Fixed leg
    function calculateSpreadReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (int256 spreadValue);
}

// File: contracts/libraries/errors/MiltonErrors.sol


pragma solidity 0.8.16;

/// @title Errors which occur inside Milton's method execution.
library MiltonErrors {
    // 300-399-milton
    /// @notice Liquidity Pool balance is equal 0.
    string public constant LIQUIDITY_POOL_IS_EMPTY = "IPOR_300";

    /// @notice Liquidity Pool balance is too low, should be equal or higher than 0.
    string public constant LIQUIDITY_POOL_AMOUNT_TOO_LOW = "IPOR_301";

    /// @notice Liquidity Pool Utilization exceeded. Liquidity Pool utilization is higher than configured in Milton maximum liquidity pool utilization.
    string public constant LP_UTILIZATION_EXCEEDED = "IPOR_302";

    /// @notice Liquidity Pool Utilization Per Leg exceeded. Liquidity Pool utilization per leg is higher than configured in Milton maximu liquidity pool utilization per leg.
    string public constant LP_UTILIZATION_PER_LEG_EXCEEDED = "IPOR_303";

    /// @notice Liquidity Pool Balance is too high
    string public constant LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH = "IPOR_304";

    /// @notice Liquidity Pool account contribution is too high.
    string public constant LP_ACCOUNT_CONTRIBUTION_IS_TOO_HIGH = "IPOR_305";

    /// @notice Swap id used in input has incorrect value (like 0) or not exists.
    string public constant INCORRECT_SWAP_ID = "IPOR_306";

    /// @notice Swap has incorrect status.
    string public constant INCORRECT_SWAP_STATUS = "IPOR_307";

    /// @notice Leverage given as a parameter when opening swap is lower than configured in Milton minimum leverage.
    string public constant LEVERAGE_TOO_LOW = "IPOR_308";

    /// @notice Leverage given as a parameter when opening swap is higher than configured in Milton maxumum leverage.
    string public constant LEVERAGE_TOO_HIGH = "IPOR_309";

    /// @notice Total amount given as a parameter when opening swap is too low. Cannot be equal zero.
    string public constant TOTAL_AMOUNT_TOO_LOW = "IPOR_310";

    /// @notice Total amount given as a parameter when opening swap is lower than sum of liquidation deposit amount and ipor publication fee.
    string public constant TOTAL_AMOUNT_LOWER_THAN_FEE = "IPOR_311";

    /// @notice Amount of collateral used to open swap is higher than configured in Milton max swap collateral amount
    string public constant COLLATERAL_AMOUNT_TOO_HIGH = "IPOR_312";

    /// @notice Acceptable fixed interest rate defined by traded exceeded.
    string public constant ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED = "IPOR_313";

    /// @notice Swap Notional Amount is higher than Total Notional for specific leg.
    string public constant SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL = "IPOR_314";

    /// @notice Number of swaps per leg which are going to be liquidated is too high, is higher than configured in Milton liquidation leg limit.
    string public constant LIQUIDATION_LEG_LIMIT_EXCEEDED = "IPOR_315";

    /// @notice Sum of SOAP and Liquidity Pool Balance is lower than zero.
    /// @dev SOAP can be negative, Sum of SOAP and Liquidity Pool Balance can be negative, but this is undesirable.
    string public constant SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW = "IPOR_316";

    /// @notice Calculation timestamp is earlier than last SOAP rebalance timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SOAP_REBALANCE_TIMESTAMP = "IPOR_317";

    /// @notice Calculation timestamp is lower than  Swap's open timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_318";

    /// @notice Closing timestamp is lower than Swap's open timestamp.
    string public constant CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_319";

    /// @notice Swap cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen where Liquidity Pool is insolvent.
    string public constant CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW = "IPOR_320";

    /// @notice Swap cannot be closed because sender is not an owner of derivative and derivative maturity not achieved.
    string public constant CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_AND_NO_MATURITY = "IPOR_321";

    /// @notice Interest from Strategy is below zero.
    string public constant INTEREST_FROM_STRATEGY_BELOW_ZERO = "IPOR_322";

    /// @notice Accrued Liquidity Pool is equal zero.
    string public constant LIQUIDITY_POOL_ACCRUED_IS_EQUAL_ZERO = "IPOR_323";

    /// @notice During spread calculation - Exponential Weighted Moving Variance cannot be higher than 1.
    string public constant SPREAD_EMVAR_CANNOT_BE_HIGHER_THAN_ONE = "IPOR_324";

    /// @notice During spread calculation - Alpha param cannot be higher than 1.
    string public constant SPREAD_ALPHA_CANNOT_BE_HIGHER_THAN_ONE = "IPOR_325";

    /// @notice IPOR publication fee balance is too low.
    string public constant PUBLICATION_FEE_BALANCE_IS_TOO_LOW = "IPOR_326";

    /// @notice The caller must be the Joseph (Smart Contract responsible for managing Milton's tokens and balances).
    string public constant CALLER_NOT_JOSEPH = "IPOR_327";

    /// @notice Deposit amount is too low.
    string public constant DEPOSIT_AMOUNT_IS_TOO_LOW = "IPOR_328";

    /// @notice Vault balance is lower than deposit value.
    string public constant VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE = "IPOR_329";

    /// @notice Treasury balance is too low.
    string public constant TREASURY_BALANCE_IS_TOO_LOW = "IPOR_330";
}

// File: contracts/amm/spread/MiltonSpreadModel.sol


pragma solidity 0.8.16;





abstract contract MiltonSpreadModel is MiltonSpreadInternal, IMiltonSpreadModel {
    using SafeCast for uint256;
    using SafeCast for int256;

    function calculateQuotePayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        int256 spreadPremiums = _calculateSpreadPremiumsPayFixed(accruedIpor, accruedBalance);

        int256 intQuoteValue = accruedIpor.indexValue.toInt256() + spreadPremiums;

        if (intQuoteValue > 0) {
            return intQuoteValue.toUint256();
        }
    }

    function calculateQuoteReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (uint256 quoteValue) {
        int256 spreadPremiums = _calculateSpreadPremiumsReceiveFixed(accruedIpor, accruedBalance);

        int256 intQuoteValueWithIpor = accruedIpor.indexValue.toInt256() + spreadPremiums;

        quoteValue = _calculateReferenceLegReceiveFixed(
            intQuoteValueWithIpor > 0 ? intQuoteValueWithIpor.toUint256() : 0,
            accruedIpor.exponentialMovingAverage
        );
    }

    function calculateSpreadPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (int256 spreadValue) {
        spreadValue = _calculateSpreadPremiumsPayFixed(accruedIpor, accruedBalance);
    }

    function calculateSpreadReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view override returns (int256 spreadValue) {
        spreadValue = _calculateSpreadPremiumsReceiveFixed(accruedIpor, accruedBalance);
    }

    function _calculateSpreadPremiumsPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) internal view returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool > 0,
            MiltonErrors.LIQUIDITY_POOL_ACCRUED_IS_EQUAL_ZERO
        );

        int256 diffIporIndexEma = accruedIpor.indexValue.toInt256() -
            accruedIpor.exponentialMovingAverage.toInt256();

        spreadPremiums = _calculateVolatilityAndMeanReversionPayFixed(
            accruedIpor.exponentialWeightedMovingVariance,
            diffIporIndexEma
        );
    }

    function _calculateSpreadPremiumsReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) internal view returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool > 0,
            MiltonErrors.LIQUIDITY_POOL_ACCRUED_IS_EQUAL_ZERO
        );

        int256 diffIporIndexEma = accruedIpor.indexValue.toInt256() -
            accruedIpor.exponentialMovingAverage.toInt256();

        spreadPremiums = _calculateVolatilityAndMeanReversionReceiveFixed(
            accruedIpor.exponentialWeightedMovingVariance,
            diffIporIndexEma
        );
    }

    /// @dev Volatility and mean revesion component for Pay Fixed Receive Floating leg. Maximum value between regions.
    function _calculateVolatilityAndMeanReversionPayFixed(uint256 emaVar, int256 diffIporIndexEma)
        internal
        view
        returns (int256)
    {
        int256 regionOne = _volatilityAndMeanReversionPayFixedRegionOne(emaVar, diffIporIndexEma);
        int256 regionTwo = _volatilityAndMeanReversionPayFixedRegionTwo(emaVar, diffIporIndexEma);
        if (regionOne >= regionTwo) {
            return regionOne;
        } else {
            return regionTwo;
        }
    }

    /// @dev Volatility and mean revesion component for Receive Fixed Pay Floating leg. Minimum value between regions.
    function _calculateVolatilityAndMeanReversionReceiveFixed(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) internal view returns (int256) {
        int256 regionOne = _volatilityAndMeanReversionReceiveFixedRegionOne(
            emaVar,
            diffIporIndexEma
        );
        int256 regionTwo = _volatilityAndMeanReversionReceiveFixedRegionTwo(
            emaVar,
            diffIporIndexEma
        );

        if (regionOne >= regionTwo) {
            return regionTwo;
        } else {
            return regionOne;
        }
    }

    function _volatilityAndMeanReversionPayFixedRegionOne(uint256 emaVar, int256 diffIporIndexEma)
        internal
        view
        returns (int256)
    {
        return
            _getPayFixedRegionOneBase() +
            IporMath.divisionInt(
                _getPayFixedRegionOneSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getPayFixedRegionOneSlopeForMeanReversion() *
                    diffIporIndexEma,
                Constants.D18_INT
            );
    }

    function _volatilityAndMeanReversionPayFixedRegionTwo(uint256 emaVar, int256 diffIporIndexEma)
        internal
        view
        returns (int256)
    {
        return
            _getPayFixedRegionTwoBase() +
            IporMath.divisionInt(
                _getPayFixedRegionTwoSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getPayFixedRegionTwoSlopeForMeanReversion() *
                    diffIporIndexEma,
                Constants.D18_INT
            );
    }

    function _volatilityAndMeanReversionReceiveFixedRegionOne(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) internal view returns (int256) {
        return
            _getReceiveFixedRegionOneBase() +
            IporMath.divisionInt(
                _getReceiveFixedRegionOneSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getReceiveFixedRegionOneSlopeForMeanReversion() *
                    diffIporIndexEma,
                Constants.D18_INT
            );
    }

    function _volatilityAndMeanReversionReceiveFixedRegionTwo(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) internal view returns (int256) {
        return
            _getReceiveFixedRegionTwoBase() +
            IporMath.divisionInt(
                _getReceiveFixedRegionTwoSlopeForVolatility() *
                    emaVar.toInt256() +
                    _getReceiveFixedRegionTwoSlopeForMeanReversion() *
                    diffIporIndexEma,
                Constants.D18_INT
            );
    }

    function _calculateReferenceLegReceiveFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage
    ) internal pure returns (uint256) {
        if (iporIndexValue < exponentialMovingAverage) {
            return iporIndexValue;
        } else {
            return exponentialMovingAverage;
        }
    }
}

// File: contracts/amm/spread/MiltonSpreadModelUsdt.sol


pragma solidity 0.8.16;





contract MiltonSpreadModelUsdt is MiltonSpreadModel {
    function _getPayFixedRegionOneBase() internal view virtual override returns (int256) {
        return 52734899;
    }



    function _getPayFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 14420251537169199104;
    }

    function _getPayFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -1242450165256140032;
    }



    function _getPayFixedRegionTwoBase() internal view virtual override returns (int256) {
        return 0;
    }

    function _getPayFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 91;
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -3;
    }



    function _getReceiveFixedRegionOneBase() internal view virtual override returns (int256) {
        return -653622053554807;
    }

    function _getReceiveFixedRegionOneSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 879558312553575296;
    }

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 54807065624269344;
    }

    function _getReceiveFixedRegionTwoBase() internal view virtual override returns (int256) {
        return -884495153628362;
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return 175497432169175456;
    }

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        override
        returns (int256)
    {
        return -995660609325833088;
    }
}
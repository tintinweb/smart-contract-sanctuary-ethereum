/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

/**
 * @dev Interface of the Chainlink aggregator
 */
interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

import {AggregatorInterface} from "./AggregatorInterface.sol";
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

/**
 * @dev Interface of the Chainlink aggregator
 */
interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {

}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

/**
 * @dev Interface of the Chainlink V3 aggregator
 */
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

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import {AggregatorV2V3Interface} from "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
    struct Phase {
        uint16 phaseId;
        uint80 startingAggregatorRoundId;
        uint80 endingAggregatorRoundId;
    }

    event FeedProposed(
        address indexed asset,
        address indexed denomination,
        address indexed proposedAggregator,
        address currentAggregator,
        address sender
    );
    event FeedConfirmed(
        address indexed asset,
        address indexed denomination,
        address indexed latestAggregator,
        address previousAggregator,
        uint16 nextPhaseId,
        address sender
    );

    // V3 AggregatorV3Interface

    function decimals(address base, address quote) external view returns (uint8);

    function description(address base, address quote) external view returns (string memory);

    function version(address base, address quote) external view returns (uint256);

    function latestRoundData(address base, address quote)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function getRoundData(
        address base,
        address quote,
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    // V2 AggregatorInterface

    function latestAnswer(address base, address quote) external view returns (int256 answer);

    function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

    function latestRound(address base, address quote) external view returns (uint256 roundId);

    function getAnswer(
        address base,
        address quote,
        uint256 roundId
    ) external view returns (int256 answer);

    function getTimestamp(
        address base,
        address quote,
        uint256 roundId
    ) external view returns (uint256 timestamp);

    // Registry getters

    function getFeed(address base, address quote) external view returns (AggregatorV2V3Interface aggregator);

    function getPhaseFeed(
        address base,
        address quote,
        uint16 phaseId
    ) external view returns (AggregatorV2V3Interface aggregator);

    function isFeedEnabled(address aggregator) external view returns (bool);

    function getPhase(
        address base,
        address quote,
        uint16 phaseId
    ) external view returns (Phase memory phase);

    // Round helpers

    function getRoundFeed(
        address base,
        address quote,
        uint80 roundId
    ) external view returns (AggregatorV2V3Interface aggregator);

    function getPhaseRange(
        address base,
        address quote,
        uint16 phaseId
    ) external view returns (uint80 startingRoundId, uint80 endingRoundId);

    function getPreviousRoundId(
        address base,
        address quote,
        uint80 roundId
    ) external view returns (uint80 previousRoundId);

    function getNextRoundId(
        address base,
        address quote,
        uint80 roundId
    ) external view returns (uint80 nextRoundId);

    // Feed management

    function proposeFeed(
        address base,
        address quote,
        address aggregator
    ) external;

    function confirmFeed(
        address base,
        address quote,
        address aggregator
    ) external;

    // Proposed aggregator

    function getProposedFeed(address base, address quote)
        external
        view
        returns (AggregatorV2V3Interface proposedAggregator);

    function proposedGetRoundData(
        address base,
        address quote,
        uint80 roundId
    )
        external
        view
        returns (
            uint80 id,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function proposedLatestRoundData(address base, address quote)
        external
        view
        returns (
            uint80 id,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    // Phases
    function getCurrentPhaseId(address base, address quote) external view returns (uint16 currentPhaseId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface OpynPricerInterface {
    function getPrice(address _asset) external view returns (uint256);

    function getHistoricalPrice(address _asset, uint80 _roundId) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface OracleInterface {
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isWhitelistedPricer(address _pricer) external view returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    function getChainlinkRoundData(address _asset, uint80 _roundId) external view returns (uint256, uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

import {AggregatorV2V3Interface} from "../interfaces/AggregatorV2V3Interface.sol";
import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * @title ChainlinkLib
 * @author 10 Delta
 * @notice Library for interacting with Chainlink feeds
 */
library ChainlinkLib {
    using SafeMath for uint256;

    /// @dev base decimals
    uint256 internal constant BASE = 8;
    /// @dev offset for chainlink aggregator phases
    uint256 internal constant PHASE_OFFSET = 64;
    /// @dev eth address on the chainlink registry
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev btc address on the chainlink registry
    address internal constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    /// @dev usd address on the chainlink registry
    address internal constant USD = address(840);
    /// @dev quote asset address
    address internal constant QUOTE = USD;

    /**
     * @notice validates that a roundId matches a timestamp, reverts if invalid
     * @dev invalid if _roundId isn't the first roundId after _timestamp
     * @param _aggregator chainlink aggregator
     * @param _timestamp timestamp
     * @param _roundId the first roundId after timestamp
     * @return answer, the price at that roundId
     */
    function validateRoundId(
        AggregatorV2V3Interface _aggregator,
        uint256 _timestamp,
        uint80 _roundId
    ) internal view returns (uint256) {
        (, int256 answer, , uint256 updatedAt, ) = _aggregator.getRoundData(_roundId);
        // Validate round data
        require(answer >= 0 && updatedAt > 0, "ChainlinkLib: round not complete");
        // Check if the timestamp at _roundId is >= _timestamp
        require(_timestamp <= updatedAt, "ChainlinkLib: roundId too low");
        // If _roundId is greater than the lowest roundId for the current phase
        if (_roundId > uint80((uint256(_roundId >> PHASE_OFFSET) << PHASE_OFFSET) | 1)) {
            // Check if the timestamp at the previous roundId is <= _timestamp
            (bool success, bytes memory data) = address(_aggregator).staticcall(
                abi.encodeWithSelector(AggregatorV3Interface.getRoundData.selector, _roundId - 1)
            );
            // Skip checking the timestamp if getRoundData reverts
            if (success) {
                (, int256 lastAnswer, , uint256 lastUpdatedAt, ) = abi.decode(
                    data,
                    (uint80, int256, uint256, uint256, uint80)
                );
                // Skip checking the timestamp if the previous answer is invalid
                require(lastAnswer < 0 || _timestamp >= lastUpdatedAt, "ChainlinkLib: roundId too high");
            }
        }
        return uint256(answer);
    }

    /**
     * @notice gets the closest roundId to a timestamp
     * @dev the returned roundId is the first roundId after _timestamp
     * @param _aggregator chainlink aggregator
     * @param _timestamp timestamp
     * @return roundId, the roundId for the timestamp (its timestamp will be >= _timestamp)
     * @return answer, the price at that roundId
     */
    function getRoundData(AggregatorV2V3Interface _aggregator, uint256 _timestamp)
        internal
        view
        returns (uint80, uint256)
    {
        (uint80 maxRoundId, int256 answer, , uint256 maxUpdatedAt, ) = _aggregator.latestRoundData();
        // Check if the latest timestamp is >= _timestamp
        require(_timestamp <= maxUpdatedAt, "ChainlinkLib: timestamp too high");
        // Get the lowest roundId for the current phase
        uint80 minRoundId = uint80((uint256(maxRoundId >> PHASE_OFFSET) << PHASE_OFFSET) | 1);
        // Return if the latest roundId equals the lowest roundId
        if (minRoundId == maxRoundId) {
            require(answer >= 0, "ChainlinkLib: max round not complete");
            return (maxRoundId, uint256(answer));
        }
        uint256 minUpdatedAt;
        (, answer, , minUpdatedAt, ) = _aggregator.getRoundData(minRoundId);
        (uint80 midRoundId, uint256 midUpdatedAt) = (minRoundId, minUpdatedAt);
        uint256 _maxRoundId = maxRoundId; // Save maxRoundId for later use
        // Return the lowest roundId if the timestamp at the lowest roundId is >= _timestamp
        if (minUpdatedAt >= _timestamp && answer >= 0 && minUpdatedAt > 0) {
            return (minRoundId, uint256(answer));
        } else if (minUpdatedAt < _timestamp) {
            // Binary search to find the closest roundId to _timestamp
            while (minRoundId <= maxRoundId) {
                midRoundId = uint80((uint256(minRoundId) + uint256(maxRoundId)) / 2);
                (, answer, , midUpdatedAt, ) = _aggregator.getRoundData(midRoundId);
                if (midUpdatedAt < _timestamp) {
                    minRoundId = midRoundId + 1;
                } else if (midUpdatedAt > _timestamp) {
                    maxRoundId = midRoundId - 1;
                } else if (answer < 0 || midUpdatedAt == 0) {
                    // Break if closest roundId is invalid
                    break;
                } else {
                    // Return if the closest roundId timestamp equals _timestamp
                    return (midRoundId, uint256(answer));
                }
            }
        }
        // If the timestamp at the closest roundId is less than _timestamp or if the closest roundId is invalid
        while (midUpdatedAt < _timestamp || answer < 0 || midUpdatedAt == 0) {
            require(midRoundId < _maxRoundId, "ChainlinkLib: exceeded max roundId");
            // Increment the closest roundId by 1 to ensure that the roundId timestamp > _timestamp
            midRoundId++;
            (, answer, , midUpdatedAt, ) = _aggregator.getRoundData(midRoundId);
        }
        return (midRoundId, uint256(answer));
    }

    /**
     * @notice scale aggregator response to base decimals (1e8)
     * @param _price aggregator price
     * @return price scaled to 1e8
     */
    function scaleToBase(uint256 _price, uint8 _aggregatorDecimals) internal pure returns (uint256) {
        if (_aggregatorDecimals > BASE) {
            _price = _price.div(10**(uint256(_aggregatorDecimals).sub(BASE)));
        } else if (_aggregatorDecimals < BASE) {
            _price = _price.mul(10**(BASE.sub(_aggregatorDecimals)));
        }

        return _price;
    }

    /**
     * @notice gets the base asset on the chainlink registry
     * @param _asset asset address
     * @param weth weth address
     * @param wbtc wbtc address
     * @return base asset address
     */
    function getBase(
        address _asset,
        address weth,
        address wbtc
    ) internal pure returns (address) {
        if (_asset == address(0)) {
            return _asset;
        } else if (_asset == weth) {
            return ETH;
        } else if (_asset == wbtc) {
            return BTC;
        } else {
            return _asset;
        }
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0
/* solhint-disable */

pragma solidity =0.6.10;

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
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
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
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
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
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
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
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

/* solhint-disable */
pragma solidity ^0.6.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

import {FeedRegistryInterface} from "../interfaces/FeedRegistryInterface.sol";
import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {OpynPricerInterface} from "../interfaces/OpynPricerInterface.sol";
import {ChainlinkLib} from "../libs/ChainlinkLib.sol";
import {SafeCast} from "../packages/oz/SafeCast.sol";

/**
 * @notice A Pricer contract for all assets available on the Chainlink Feed Registry
 */
contract ChainlinkRegistryPricer is OpynPricerInterface {
    using SafeCast for int256;

    /// @notice the opyn oracle address
    OracleInterface public immutable oracle;
    /// @notice the chainlink feed registry
    FeedRegistryInterface public immutable registry;
    /// @dev weth address
    address public immutable weth;
    /// @dev wbtc address
    address public immutable wbtc;

    /**
     * @param _oracle Opyn Oracle address
     */
    constructor(
        address _oracle,
        address _registry,
        address _weth,
        address _wbtc
    ) public {
        require(_oracle != address(0), "ChainlinkRegistryPricer: Cannot set 0 address as oracle");
        require(_registry != address(0), "ChainlinkRegistryPricer: Cannot set 0 address as registry");
        require(_weth != address(0), "ChainlinkRegistryPricer: Cannot set 0 address as weth");
        require(_wbtc != address(0), "ChainlinkRegistryPricer: Cannot set 0 address as wbtc");

        oracle = OracleInterface(_oracle);
        registry = FeedRegistryInterface(_registry);
        weth = _weth;
        wbtc = _wbtc;
    }

    /**
     * @notice sets the expiry prices in the oracle without providing a roundId
     * @dev uses more 2.6x more gas compared to passing in a roundId
     * @param _assets assets to set the price for
     * @param _expiryTimestamps expiries to set a price for
     */
    function setExpiryPriceInOracle(address[] calldata _assets, uint256[] calldata _expiryTimestamps) external {
        for (uint256 i = 0; i < _assets.length; i++) {
            (, uint256 price) = ChainlinkLib.getRoundData(
                registry.getFeed(ChainlinkLib.getBase(_assets[i], weth, wbtc), ChainlinkLib.QUOTE),
                _expiryTimestamps[i]
            );
            oracle.setExpiryPrice(_assets[i], _expiryTimestamps[i], price);
        }
    }

    /**
     * @notice sets the expiry prices in the oracle
     * @dev a roundId must be provided to confirm price validity, which is the first Chainlink price provided after the expiryTimestamp
     * @param _assets assets to set the price for
     * @param _expiryTimestamps expiries to set a price for
     * @param _roundIds the first roundId after each expiryTimestamp
     */
    function setExpiryPriceInOracleRoundId(
        address[] calldata _assets,
        uint256[] calldata _expiryTimestamps,
        uint80[] calldata _roundIds
    ) external {
        for (uint256 i = 0; i < _assets.length; i++) {
            oracle.setExpiryPrice(
                _assets[i],
                _expiryTimestamps[i],
                ChainlinkLib.validateRoundId(
                    registry.getFeed(ChainlinkLib.getBase(_assets[i], weth, wbtc), ChainlinkLib.QUOTE),
                    _expiryTimestamps[i],
                    _roundIds[i]
                )
            );
        }
    }

    /**
     * @notice get the live price for the asset
     * @dev overides the getPrice function in OpynPricerInterface
     * @param _asset asset that this pricer will get a price for
     * @return price of the asset in USD, scaled by 1e8
     */
    function getPrice(address _asset) external view override returns (uint256) {
        address base = ChainlinkLib.getBase(_asset, weth, wbtc);
        int256 answer = registry.latestAnswer(base, ChainlinkLib.QUOTE);
        require(answer > 0, "ChainlinkRegistryPricer: price is lower than 0");
        // chainlink's answer is already 1e8
        // no need to safecast since we already check if its > 0
        return ChainlinkLib.scaleToBase(uint256(answer), registry.decimals(base, ChainlinkLib.QUOTE));
    }

    /**
     * @notice get historical chainlink price
     * @param _asset asset that this pricer will get a price for
     * @param _roundId chainlink round id
     * @return round price and timestamp
     */
    function getHistoricalPrice(address _asset, uint80 _roundId) external view override returns (uint256, uint256) {
        address base = ChainlinkLib.getBase(_asset, weth, wbtc);
        (, int256 price, , uint256 roundTimestamp, ) = registry.getRoundData(base, ChainlinkLib.QUOTE, _roundId);
        return (
            ChainlinkLib.scaleToBase(price.toUint256(), registry.decimals(base, ChainlinkLib.QUOTE)),
            roundTimestamp
        );
    }
}
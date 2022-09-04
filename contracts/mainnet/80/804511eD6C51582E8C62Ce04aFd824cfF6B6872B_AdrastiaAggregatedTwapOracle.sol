//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IOracle.sol";

/**
 * @title IAggregatedOracle
 * @notice An interface that defines a price and liquidity oracle that aggregates consulations from many underlying
 *  oracles.
 */
abstract contract IAggregatedOracle is IOracle {
    /// @notice Emitted when an underlying oracle (or this oracle) throws an update error with a reason.
    /// @param oracle The address or the oracle throwing the error.
    /// @param token The token for which the oracle is throwing the error.
    /// @param reason The reason for or description of the error.
    event UpdateErrorWithReason(address indexed oracle, address indexed token, string reason);

    /// @notice Emitted when an underlying oracle (or this oracle) throws an update error without a reason.
    /// @param oracle The address or the oracle throwing the error.
    /// @param token The token for which the oracle is throwing the error.
    /// @param err Data corresponding with a low level error being thrown.
    event UpdateError(address indexed oracle, address indexed token, bytes err);

    /// @notice Gets the addresses of all underlying oracles that are used for all consultations.
    /// @dev Oracles only used for specific tokens are not included.
    /// @return An array of the addresses of all underlying oracles that are used for all consultations.
    function getOracles() external view virtual returns (address[] memory);

    /**
     * @notice Gets the addresses of all underlying oracles that are consulted with in regards to the specified token.
     * @param token The address of the token for which to get all of the consulted oracles.
     * @return An array of the addresses of all underlying oracles that are consulted with in regards to the specified
     *  token.
     */
    function getOraclesFor(address token) external view virtual returns (address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./IQuoteToken.sol";

/**
 * @title ILiquidityOracle
 * @notice An interface that defines a liquidity oracle with a single quote token (or currency) and many exchange
 *  tokens.
 */
abstract contract ILiquidityOracle is IUpdateable, IQuoteToken {
    /// @notice Gets the liquidity levels of the token and the quote token in the underlying pool.
    /// @param token The token to get liquidity levels of (along with the quote token).
    /// @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
    /// @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
    function consultLiquidity(address token)
        public
        view
        virtual
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);

    /**
     * @notice Gets the liquidity levels of the token and the quote token in the underlying pool, reverting if the
     *  quotation is older than the maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get liquidity levels of (along with the quote token).
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consultLiquidity(address token, uint256 maxAge)
        public
        view
        virtual
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./ILiquidityOracle.sol";
import "./IPriceOracle.sol";

/**
 * @title IOracle
 * @notice An interface that defines a price and liquidity oracle.
 */
abstract contract IOracle is IUpdateable, IPriceOracle, ILiquidityOracle {
    /// @notice Emitted when a stored quotation is updated.
    /// @param token The address of the token that the quotation is for.
    /// @param price The quote token denominated price for a whole token.
    /// @param tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
    /// @param quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
    /// @param timestamp The epoch timestamp of the quotation (in seconds).
    event Updated(
        address indexed token,
        uint256 price,
        uint256 tokenLiquidity,
        uint256 quoteTokenLiquidity,
        uint256 timestamp
    );

    /**
     * @notice Gets the price of a token in terms of the quote token along with the liquidity levels of the token
     *  andquote token in the underlying pool.
     * @param token The token to get the price of.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consult(address token)
        public
        view
        virtual
        returns (
            uint112 price,
            uint112 tokenLiquidity,
            uint112 quoteTokenLiquidity
        );

    /**
     * @notice Gets the price of a token in terms of the quote token along with the liquidity levels of the token and
     *  quote token in the underlying pool, reverting if the quotation is older than the maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get the price of.
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consult(address token, uint256 maxAge)
        public
        view
        virtual
        returns (
            uint112 price,
            uint112 tokenLiquidity,
            uint112 quoteTokenLiquidity
        );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IPeriodic
 * @notice An interface that defines a contract containing a period.
 * @dev This typically refers to an update period.
 */
interface IPeriodic {
    /// @notice Gets the period, in seconds.
    /// @return periodSeconds The period, in seconds.
    function period() external view returns (uint256 periodSeconds);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./IQuoteToken.sol";

/// @title IPriceOracle
/// @notice An interface that defines a price oracle with a single quote token (or currency) and many exchange tokens.
abstract contract IPriceOracle is IUpdateable, IQuoteToken {
    /**
     * @notice Gets the price of a token in terms of the quote token.
     * @param token The token to get the price of.
     * @return price The quote token denominated price for a whole token.
     */
    function consultPrice(address token) public view virtual returns (uint112 price);

    /**
     * @notice Gets the price of a token in terms of the quote token, reverting if the quotation is older than the
     *  maximum allowable age.
     * @dev Using maxAge of 0 can be gas costly and the returned data is easier to manipulate.
     * @param token The token to get the price of.
     * @param maxAge The maximum age of the quotation, in seconds. If 0, the function gets the instant rates as of the
     *   latest block, straight from the source.
     * @return price The quote token denominated price for a whole token.
     */
    function consultPrice(address token, uint256 maxAge) public view virtual returns (uint112 price);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IQuoteToken
 * @notice An interface that defines a contract containing a quote token (or currency), providing the associated
 *  metadata.
 */
abstract contract IQuoteToken {
    /// @notice Gets the quote token (or currency) name.
    /// @return The name of the quote token (or currency).
    function quoteTokenName() public view virtual returns (string memory);

    /// @notice Gets the quote token address (if any).
    /// @dev This may return address(0) if no specific quote token is used (such as an aggregate of quote tokens).
    /// @return The address of the quote token, or address(0) if no specific quote token is used.
    function quoteTokenAddress() public view virtual returns (address);

    /// @notice Gets the quote token (or currency) symbol.
    /// @return The symbol of the quote token (or currency).
    function quoteTokenSymbol() public view virtual returns (string memory);

    /// @notice Gets the number of decimal places that quote prices have.
    /// @return The number of decimals of the quote token (or currency) that quote prices have.
    function quoteTokenDecimals() public view virtual returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/// @title IUpdateByToken
/// @notice An interface that defines a contract that is updateable as per the input data.
abstract contract IUpdateable {
    /// @notice Performs an update as per the input data.
    /// @param data Any data needed for the update.
    /// @return b True if anything was updated; false otherwise.
    function update(bytes memory data) public virtual returns (bool b);

    /// @notice Checks if an update needs to be performed.
    /// @param data Any data relating to the update.
    /// @return b True if an update needs to be performed; false otherwise.
    function needsUpdate(bytes memory data) public view virtual returns (bool b);

    /// @notice Check if an update can be performed by the caller (if needed).
    /// @dev Tries to determine if the caller can call update with a valid observation being stored.
    /// @dev This is not meant to be called by state-modifying functions.
    /// @param data Any data relating to the update.
    /// @return b True if an update can be performed by the caller; false otherwise.
    function canUpdate(bytes memory data) public view virtual returns (bool b);

    /// @notice Gets the timestamp of the last update.
    /// @param data Any data relating to the update.
    /// @return A unix timestamp.
    function lastUpdateTime(bytes memory data) public view virtual returns (uint256);

    /// @notice Gets the amount of time (in seconds) since the last update.
    /// @param data Any data relating to the update.
    /// @return Time in seconds.
    function timeSinceLastUpdate(bytes memory data) public view virtual returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

library ObservationLibrary {
    struct Observation {
        uint112 price;
        uint112 tokenLiquidity;
        uint112 quoteTokenLiquidity;
        uint32 timestamp;
    }

    struct LiquidityObservation {
        uint112 tokenLiquidity;
        uint112 quoteTokenLiquidity;
        uint32 timestamp;
    }

    struct PriceObservation {
        uint112 price;
        uint32 timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeCast.sol)

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
library SafeCastExt {
    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

/**
 * @title Contains 512-bit math
 * @author Uniswap Labs (https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol)
 * @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of
 *   precision
 * @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256
 *   bits
 */
library FullMath {
    /**
     * @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or
     *   denominator == 0
     * @param a The multiplicand
     * @param b The multiplier
     * @param denominator The divisor
     * @return result The 256-bit result
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
     */
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = denominator & (~denominator + 1);
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /**
     * @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or
     *   denominator == 0
     * @param a The multiplicand
     * @param b The multiplier
     * @param denominator The divisor
     * @return result The 256-bit result
     */
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";

import "../interfaces/IOracle.sol";
import "../libraries/ObservationLibrary.sol";
import "../utils/SimpleQuotationMetadata.sol";

abstract contract AbstractOracle is IERC165, IOracle, SimpleQuotationMetadata {
    mapping(address => ObservationLibrary.Observation) public observations;

    constructor(address quoteToken_) SimpleQuotationMetadata(quoteToken_) {}

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function update(bytes memory data) public virtual override returns (bool);

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function needsUpdate(bytes memory data) public view virtual override returns (bool);

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function canUpdate(bytes memory data) public view virtual override returns (bool);

    /// @param data The encoded address of the token for which the update relates to.
    /// @inheritdoc IUpdateable
    function lastUpdateTime(bytes memory data) public view virtual override returns (uint256) {
        address token = abi.decode(data, (address));

        return observations[token].timestamp;
    }

    /// @param data The encoded address of the token for which the update relates to.
    /// @inheritdoc IUpdateable
    function timeSinceLastUpdate(bytes memory data) public view virtual override returns (uint256) {
        return block.timestamp - lastUpdateTime(data);
    }

    function consultPrice(address token) public view virtual override returns (uint112 price) {
        if (token == quoteTokenAddress()) return uint112(10**quoteTokenDecimals());

        ObservationLibrary.Observation storage observation = observations[token];

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");

        return observation.price;
    }

    /// @inheritdoc IPriceOracle
    function consultPrice(address token, uint256 maxAge) public view virtual override returns (uint112 price) {
        if (token == quoteTokenAddress()) return uint112(10**quoteTokenDecimals());

        if (maxAge == 0) {
            (price, , ) = instantFetch(token);

            return price;
        }

        ObservationLibrary.Observation storage observation = observations[token];

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "AbstractOracle: RATE_TOO_OLD");

        return observation.price;
    }

    /// @inheritdoc ILiquidityOracle
    function consultLiquidity(address token)
        public
        view
        virtual
        override
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity)
    {
        if (token == quoteTokenAddress()) return (0, 0);

        ObservationLibrary.Observation storage observation = observations[token];

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");

        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc ILiquidityOracle
    function consultLiquidity(address token, uint256 maxAge)
        public
        view
        virtual
        override
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity)
    {
        if (token == quoteTokenAddress()) return (0, 0);

        if (maxAge == 0) {
            (, tokenLiquidity, quoteTokenLiquidity) = instantFetch(token);

            return (tokenLiquidity, quoteTokenLiquidity);
        }

        ObservationLibrary.Observation storage observation = observations[token];

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "AbstractOracle: RATE_TOO_OLD");

        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc IOracle
    function consult(address token)
        public
        view
        virtual
        override
        returns (
            uint112 price,
            uint112 tokenLiquidity,
            uint112 quoteTokenLiquidity
        )
    {
        if (token == quoteTokenAddress()) return (uint112(10**quoteTokenDecimals()), 0, 0);

        ObservationLibrary.Observation storage observation = observations[token];

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");

        price = observation.price;
        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc IOracle
    function consult(address token, uint256 maxAge)
        public
        view
        virtual
        override
        returns (
            uint112 price,
            uint112 tokenLiquidity,
            uint112 quoteTokenLiquidity
        )
    {
        if (token == quoteTokenAddress()) return (uint112(10**quoteTokenDecimals()), 0, 0);

        if (maxAge == 0) return instantFetch(token);

        ObservationLibrary.Observation storage observation = observations[token];

        require(observation.timestamp != 0, "AbstractOracle: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "AbstractOracle: RATE_TOO_OLD");

        price = observation.price;
        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(SimpleQuotationMetadata, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IOracle).interfaceId ||
            interfaceId == type(IUpdateable).interfaceId ||
            interfaceId == type(IPriceOracle).interfaceId ||
            interfaceId == type(ILiquidityOracle).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Fetches the instant rates as of the latest block, straight from the source.
     * @dev This is costly in gas and the rates are easier to manipulate.
     * @param token The token to get the rates for.
     * @return price The quote token denominated price for a whole token.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function instantFetch(address token)
        internal
        view
        virtual
        returns (
            uint112 price,
            uint112 tokenLiquidity,
            uint112 quoteTokenLiquidity
        );
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/math/SafeCast.sol";
import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./PeriodicOracle.sol";
import "../interfaces/IAggregatedOracle.sol";
import "../libraries/SafeCastExt.sol";
import "../libraries/uniswap-lib/FullMath.sol";
import "../utils/ExplicitQuotationMetadata.sol";

contract AggregatedOracle is IAggregatedOracle, PeriodicOracle, ExplicitQuotationMetadata {
    using SafeCast for uint256;
    using SafeCastExt for uint256;

    /*
     * Structs
     */

    struct TokenSpecificOracle {
        address token;
        address oracle;
    }

    struct OracleConfig {
        address oracle;
        uint8 quoteTokenDecimals;
    }

    /// @notice The minimum quote token denominated value of the token liquidity required for all underlying oracles
    /// to be considered valid and thus included in the aggregation.
    uint256 public immutable minimumTokenLiquidityValue;

    /// @notice The minimum quote token liquidity required for all underlying oracles to be considered valid and thus
    /// included in the aggregation.
    uint256 public immutable minimumQuoteTokenLiquidity;

    /*
     * Internal variables
     */

    OracleConfig[] internal oracles;
    mapping(address => OracleConfig[]) internal tokenSpecificOracles;

    /*
     * Private variables
     */

    mapping(address => bool) private oracleExists;
    mapping(address => mapping(address => bool)) private oracleForExists;

    /*
     * Constructors
     */

    constructor(
        string memory quoteTokenName_,
        address quoteTokenAddress_,
        string memory quoteTokenSymbol_,
        uint8 quoteTokenDecimals_,
        address[] memory oracles_,
        TokenSpecificOracle[] memory tokenSpecificOracles_,
        uint256 period_,
        uint256 minimumTokenLiquidityValue_,
        uint256 minimumQuoteTokenLiquidity_
    )
        PeriodicOracle(quoteTokenAddress_, period_)
        ExplicitQuotationMetadata(quoteTokenName_, quoteTokenAddress_, quoteTokenSymbol_, quoteTokenDecimals_)
    {
        require(oracles_.length > 0 || tokenSpecificOracles_.length > 0, "AggregatedOracle: MISSING_ORACLES");

        minimumTokenLiquidityValue = minimumTokenLiquidityValue_;
        minimumQuoteTokenLiquidity = minimumQuoteTokenLiquidity_;

        // Setup general oracles
        for (uint256 i = 0; i < oracles_.length; ++i) {
            require(!oracleExists[oracles_[i]], "AggregatedOracle: DUPLICATE_ORACLE");

            oracleExists[oracles_[i]] = true;

            oracles.push(
                OracleConfig({oracle: oracles_[i], quoteTokenDecimals: IOracle(oracles_[i]).quoteTokenDecimals()})
            );
        }

        // Setup token-specific oracles
        for (uint256 i = 0; i < tokenSpecificOracles_.length; ++i) {
            TokenSpecificOracle memory oracle = tokenSpecificOracles_[i];

            require(!oracleExists[oracle.oracle], "AggregatedOracle: DUPLICATE_ORACLE");
            require(!oracleForExists[oracle.token][oracle.oracle], "AggregatedOracle: DUPLICATE_ORACLE");

            oracleForExists[oracle.token][oracle.oracle] = true;

            tokenSpecificOracles[oracle.token].push(
                OracleConfig({oracle: oracle.oracle, quoteTokenDecimals: IOracle(oracle.oracle).quoteTokenDecimals()})
            );
        }
    }

    /*
     * External functions
     */

    /// @inheritdoc IAggregatedOracle
    function getOracles() external view virtual override returns (address[] memory) {
        OracleConfig[] memory _oracles = oracles;

        address[] memory allOracles = new address[](_oracles.length);

        // Add the general oracles
        for (uint256 i = 0; i < _oracles.length; ++i) allOracles[i] = _oracles[i].oracle;

        return allOracles;
    }

    /// @inheritdoc IAggregatedOracle
    function getOraclesFor(address token) external view virtual override returns (address[] memory) {
        OracleConfig[] memory _tokenSpecificOracles = tokenSpecificOracles[token];
        OracleConfig[] memory _oracles = oracles;

        address[] memory allOracles = new address[](_oracles.length + _tokenSpecificOracles.length);

        // Add the general oracles
        for (uint256 i = 0; i < _oracles.length; ++i) allOracles[i] = _oracles[i].oracle;

        // Add the token specific oracles
        for (uint256 i = 0; i < _tokenSpecificOracles.length; ++i)
            allOracles[_oracles.length + i] = _tokenSpecificOracles[i].oracle;

        return allOracles;
    }

    /*
     * Public functions
     */

    /// @inheritdoc ExplicitQuotationMetadata
    function quoteTokenName()
        public
        view
        virtual
        override(ExplicitQuotationMetadata, IQuoteToken, SimpleQuotationMetadata)
        returns (string memory)
    {
        return ExplicitQuotationMetadata.quoteTokenName();
    }

    /// @inheritdoc ExplicitQuotationMetadata
    function quoteTokenAddress()
        public
        view
        virtual
        override(ExplicitQuotationMetadata, IQuoteToken, SimpleQuotationMetadata)
        returns (address)
    {
        return ExplicitQuotationMetadata.quoteTokenAddress();
    }

    /// @inheritdoc ExplicitQuotationMetadata
    function quoteTokenSymbol()
        public
        view
        virtual
        override(ExplicitQuotationMetadata, IQuoteToken, SimpleQuotationMetadata)
        returns (string memory)
    {
        return ExplicitQuotationMetadata.quoteTokenSymbol();
    }

    /// @inheritdoc ExplicitQuotationMetadata
    function quoteTokenDecimals()
        public
        view
        virtual
        override(ExplicitQuotationMetadata, IQuoteToken, SimpleQuotationMetadata)
        returns (uint8)
    {
        return ExplicitQuotationMetadata.quoteTokenDecimals();
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(PeriodicOracle, ExplicitQuotationMetadata)
        returns (bool)
    {
        return
            interfaceId == type(IAggregatedOracle).interfaceId ||
            ExplicitQuotationMetadata.supportsInterface(interfaceId) ||
            PeriodicOracle.supportsInterface(interfaceId);
    }

    /// @inheritdoc PeriodicOracle
    function canUpdate(bytes memory data) public view virtual override(IUpdateable, PeriodicOracle) returns (bool) {
        address token = abi.decode(data, (address));

        // If the parent contract can't update, this contract can't update
        if (!super.canUpdate(data)) return false;

        // Ensure all underlying oracles are up-to-date
        for (uint256 j = 0; j < 2; ++j) {
            OracleConfig[] memory _oracles;

            if (j == 0) _oracles = oracles;
            else _oracles = tokenSpecificOracles[token];

            for (uint256 i = 0; i < _oracles.length; ++i) {
                if (IOracle(_oracles[i].oracle).canUpdate(data)) {
                    // We can update one of the underlying oracles
                    return true;
                }
            }
        }

        (, , , uint256 validResponses) = aggregateUnderlying(token, calculateMaxAge());

        // Only return true if we have reached the minimum number of valid underlying oracle consultations
        return validResponses >= minimumResponses();
    }

    /*
     * Internal functions
     */

    function performUpdate(bytes memory data) internal override returns (bool) {
        bool underlyingUpdated;
        address token = abi.decode(data, (address));

        // Ensure all underlying oracles are up-to-date
        for (uint256 j = 0; j < 2; ++j) {
            OracleConfig[] memory _oracles;

            if (j == 0) _oracles = oracles;
            else _oracles = tokenSpecificOracles[token];

            for (uint256 i = 0; i < _oracles.length; ++i) {
                // We don't want any problematic underlying oracles to prevent this oracle from updating
                // so we put update in a try-catch block
                try IOracle(_oracles[i].oracle).update(data) returns (bool updated) {
                    underlyingUpdated = underlyingUpdated || updated;
                } catch Error(string memory reason) {
                    emit UpdateErrorWithReason(_oracles[i].oracle, token, reason);
                } catch (bytes memory err) {
                    emit UpdateError(_oracles[i].oracle, token, err);
                }
            }
        }

        uint256 price;
        uint256 tokenLiquidity;
        uint256 quoteTokenLiquidity;
        uint256 validResponses;

        (price, tokenLiquidity, quoteTokenLiquidity, validResponses) = aggregateUnderlying(token, calculateMaxAge());

        // Liquidities should rarely ever overflow uint112 (if ever), but if they do, we set the observation to the max
        // This allows the price to continue to be updated while tightly packing liquidities for gas efficiency
        if (tokenLiquidity > type(uint112).max) tokenLiquidity = type(uint112).max;
        if (quoteTokenLiquidity > type(uint112).max) quoteTokenLiquidity = type(uint112).max;

        if (validResponses >= minimumResponses()) {
            ObservationLibrary.Observation storage observation = observations[token];

            observation.price = price.toUint112(); // Should never (realistically) overflow
            observation.tokenLiquidity = uint112(tokenLiquidity); // Will never overflow
            observation.quoteTokenLiquidity = uint112(quoteTokenLiquidity); // Will never overflow
            observation.timestamp = block.timestamp.toUint32();

            emit Updated(token, price, tokenLiquidity, quoteTokenLiquidity, block.timestamp);

            return true;
        } else emit UpdateErrorWithReason(address(this), token, "AggregatedOracle: INVALID_NUM_CONSULTATIONS");

        return underlyingUpdated;
    }

    /**
     * @notice The minimum number of valid underlying oracle consultations required to perform an update.
     */
    function minimumResponses() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @notice Calculates the maximum age of the underlying oracles' responses when updating this oracle's observation.
     * @dev We use this to prevent old data from skewing our observations. Underlying oracles must update at least as
     *   frequently as this oracle does.
     * @return maxAge The maximum age of underlying oracles' responses, in seconds.
     */
    function calculateMaxAge() internal view returns (uint256) {
        if (period == 1) {
            // We don't want to subtract 1 from this and use 0 as the max age, because that would cause the oracle
            // to return data straight from the current block, which may not be secure.
            return 1;
        }

        return period - 1; // Subract 1 to ensure that we don't use any data from the previous period
    }

    function sanityCheckTvlDistributionRatio(
        address token,
        uint256 price,
        uint256 tokenLiquidity,
        uint256 quoteTokenLiquidity
    ) internal view virtual returns (bool) {
        if (quoteTokenLiquidity == 0) {
            // We'll always ignore consultations where the quote token liquidity is 0
            return false;
        }

        // Calculate the ratio of token liquidity value (denominated in the quote token) to quote token liquidity
        // Safe from overflows: price and tokenLiquidity are actually uint112 in disguise
        // We multiply by 100 to avoid floating point errors => 100 represents a ratio of 1:1
        uint256 ratio = ((price * tokenLiquidity * 100) / quoteTokenLiquidity) /
            (uint256(10)**IERC20Metadata(token).decimals());

        if (ratio > 1000 || ratio < 10) {
            // Reject consultations where the ratio is above 10:1 or below 1:10
            // This prevents Uniswap v3 or orderbook-like oracles from skewing our observations when liquidity is very
            // one-sided as one-sided liquidity can be used as an attack vector
            return false;
        }

        return true;
    }

    function sanityCheckQuoteTokenLiquidity(uint256 quoteTokenLiquidity) internal view virtual returns (bool) {
        return quoteTokenLiquidity >= minimumQuoteTokenLiquidity;
    }

    function sanityCheckTokenLiquidityValue(
        address token,
        uint256 price,
        uint256 tokenLiquidity
    ) internal view virtual returns (bool) {
        return
            ((price * tokenLiquidity) / (uint256(10)**IERC20Metadata(token).decimals())) >= minimumTokenLiquidityValue;
    }

    function validateUnderlyingConsultation(
        address token,
        uint256 price,
        uint256 tokenLiquidity,
        uint256 quoteTokenLiquidity
    ) internal view virtual returns (bool) {
        return
            sanityCheckTokenLiquidityValue(token, price, tokenLiquidity) &&
            sanityCheckQuoteTokenLiquidity(quoteTokenLiquidity) &&
            sanityCheckTvlDistributionRatio(token, price, tokenLiquidity, quoteTokenLiquidity);
    }

    function aggregateUnderlying(address token, uint256 maxAge)
        internal
        view
        returns (
            uint256 price,
            uint256 tokenLiquidity,
            uint256 quoteTokenLiquidity,
            uint256 validResponses
        )
    {
        uint256 qtDecimals = quoteTokenDecimals();

        uint256 denominator; // sum of oracleQuoteTokenLiquidity divided by oraclePrice

        for (uint256 j = 0; j < 2; ++j) {
            OracleConfig[] memory _oracles;

            if (j == 0) _oracles = oracles;
            else _oracles = tokenSpecificOracles[token];

            for (uint256 i = 0; i < _oracles.length; ++i) {
                uint256 oPrice;
                uint256 oTokenLiquidity;
                uint256 oQuoteTokenLiquidity;

                // We don't want problematic underlying oracles to prevent us from calculating the aggregated
                // results from the other working oracles, so we use a try-catch block.
                try IOracle(_oracles[i].oracle).consult(token, maxAge) returns (
                    uint112 _price,
                    uint112 _tokenLiquidity,
                    uint112 _quoteTokenLiquidity
                ) {
                    // Promote returned data to uint256 to prevent scaling up from overflowing
                    oPrice = _price;
                    oTokenLiquidity = _tokenLiquidity;
                    oQuoteTokenLiquidity = _quoteTokenLiquidity;
                } catch Error(string memory) {
                    continue;
                } catch (bytes memory) {
                    continue;
                }

                // Shift liquidity for more precise calculations as we divide this by the price
                // This is safe as liquidity < 2^112
                oQuoteTokenLiquidity = oQuoteTokenLiquidity << 120;

                uint256 decimals = _oracles[i].quoteTokenDecimals;

                // Fix differing quote token decimal places
                if (decimals < qtDecimals) {
                    // Scale up
                    uint256 scalar = 10**(qtDecimals - decimals);

                    oPrice *= scalar;
                    oQuoteTokenLiquidity *= scalar;
                } else if (decimals > qtDecimals) {
                    // Scale down
                    uint256 scalar = 10**(decimals - qtDecimals);

                    oPrice /= scalar;
                    oQuoteTokenLiquidity /= scalar;
                }

                if (!validateUnderlyingConsultation(token, oPrice, oTokenLiquidity, oQuoteTokenLiquidity >> 120)) {
                    continue;
                }

                if (oPrice != 0 && oQuoteTokenLiquidity != 0) {
                    ++validResponses;

                    // Note: (oQuoteTokenLiquidity / oPrice) will equal 0 if oQuoteTokenLiquidity <
                    //   oPrice, but for this to happen, price would have to be insanely high
                    denominator += oQuoteTokenLiquidity / oPrice;

                    // Should never realistically overflow
                    tokenLiquidity += oTokenLiquidity;
                    quoteTokenLiquidity += oQuoteTokenLiquidity;
                }
            }
        }

        price = denominator == 0 ? 0 : quoteTokenLiquidity / denominator;

        // Right shift liquidity to undo the left shift and get the real value
        quoteTokenLiquidity = quoteTokenLiquidity >> 120;
    }

    /// @inheritdoc AbstractOracle
    function instantFetch(address token)
        internal
        view
        virtual
        override
        returns (
            uint112 price,
            uint112 tokenLiquidity,
            uint112 quoteTokenLiquidity
        )
    {
        (
            uint256 bigPrice,
            uint256 bigTokenLiquidity,
            uint256 bigQuoteTokenLiquidity,
            uint256 validResponses
        ) = aggregateUnderlying(token, 0);

        // Reverts if none of the underlying oracles report anything
        require(validResponses > 0, "AggregatedOracle: INVALID_NUM_CONSULTATIONS");

        // This revert should realistically never occur, but we use it to prevent an invalid price from being returned
        require(bigPrice <= type(uint112).max, "AggregatedOracle: PRICE_TOO_HIGH");

        price = uint112(bigPrice);

        // Liquidities should rarely ever overflow uint112 (if ever), but if they do, we use the max value
        // This matches how observations are stored
        if (bigTokenLiquidity > type(uint112).max) {
            tokenLiquidity = type(uint112).max;
        } else {
            tokenLiquidity = uint112(bigTokenLiquidity);
        }

        if (bigQuoteTokenLiquidity > type(uint112).max) {
            quoteTokenLiquidity = type(uint112).max;
        } else {
            quoteTokenLiquidity = uint112(bigQuoteTokenLiquidity);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "../interfaces/IPeriodic.sol";

import "./AbstractOracle.sol";

abstract contract PeriodicOracle is IPeriodic, AbstractOracle {
    uint256 public immutable override period;

    constructor(address quoteToken_, uint256 period_) AbstractOracle(quoteToken_) {
        require(period_ > 0, "PeriodicOracle: INVALID_PERIOD");

        period = period_;
    }

    /// @inheritdoc AbstractOracle
    function update(bytes memory data) public virtual override returns (bool) {
        if (needsUpdate(data)) return performUpdate(data);

        return false;
    }

    /// @inheritdoc AbstractOracle
    function needsUpdate(bytes memory data) public view virtual override returns (bool) {
        return timeSinceLastUpdate(data) >= period;
    }

    /// @inheritdoc AbstractOracle
    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        // If this oracle doesn't need an update, it can't (won't) update
        return needsUpdate(data);
    }

    /// @inheritdoc AbstractOracle
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IPeriodic).interfaceId || super.supportsInterface(interfaceId);
    }

    function performUpdate(bytes memory data) internal virtual returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IQuoteToken.sol";

contract ExplicitQuotationMetadata is IQuoteToken, IERC165 {
    string internal _quoteTokenName;
    string internal _quoteTokenSymbol;
    address internal immutable _quoteTokenAddress;
    uint8 internal immutable _quoteTokenDecimals;

    constructor(
        string memory quoteTokenName_,
        address quoteTokenAddress_,
        string memory quoteTokenSymbol_,
        uint8 quoteTokenDecimals_
    ) {
        _quoteTokenName = quoteTokenName_;
        _quoteTokenSymbol = quoteTokenSymbol_;
        _quoteTokenAddress = quoteTokenAddress_;
        _quoteTokenDecimals = quoteTokenDecimals_;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenName() public view virtual override returns (string memory) {
        return _quoteTokenName;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenAddress() public view virtual override returns (address) {
        return _quoteTokenAddress;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenSymbol() public view virtual override returns (string memory) {
        return _quoteTokenSymbol;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenDecimals() public view virtual override returns (uint8) {
        return _quoteTokenDecimals;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IQuoteToken).interfaceId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IQuoteToken.sol";

contract SimpleQuotationMetadata is IQuoteToken, IERC165 {
    address public immutable quoteToken;

    constructor(address quoteToken_) {
        quoteToken = quoteToken_;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenName() public view virtual override returns (string memory) {
        return getStringOrBytes32(quoteToken, IERC20Metadata.name.selector);
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenAddress() public view virtual override returns (address) {
        return quoteToken;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenSymbol() public view virtual override returns (string memory) {
        return getStringOrBytes32(quoteToken, IERC20Metadata.symbol.selector);
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenDecimals() public view virtual override returns (uint8) {
        (bool success, bytes memory result) = quoteToken.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (!success) return 18; // Return 18 by default

        return abi.decode(result, (uint8));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IQuoteToken).interfaceId;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        // Calculate string length
        uint256 i = 0;
        while (i < 32 && _bytes32[i] != 0) ++i;

        bytes memory bytesArray = new bytes(i);

        // Extract characters
        for (i = 0; i < 32 && _bytes32[i] != 0; ++i) bytesArray[i] = _bytes32[i];

        return string(bytesArray);
    }

    function getStringOrBytes32(address contractAddress, bytes4 selector) internal view returns (string memory) {
        (bool success, bytes memory result) = contractAddress.staticcall(abi.encodeWithSelector(selector));
        if (!success) return "";

        return result.length == 32 ? bytes32ToString(bytes32(result)) : abi.decode(result, (string));
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
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
     * - input must fit into 8 bits.
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
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
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
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
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
     * - input must fit into 8 bits.
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
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

contract AdrastiaVersioning {
    string public constant ADRASTIA_CORE_VERSION = "v1.0.0";
    string public constant ADRASTIA_PERIPHERY_VERSION = "v1.0.0";
    string public constant ADRASTIA_PROTOCOL_VERSION = "v0.0.8";
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-core/contracts/oracles/AggregatedOracle.sol";

import "../AdrastiaVersioning.sol";

contract AdrastiaAggregatedTwapOracle is AdrastiaVersioning, AggregatedOracle {
    string public name;

    constructor(
        string memory name_,
        string memory quoteTokenName_,
        address quoteTokenAddress_,
        string memory quoteTokenSymbol_,
        uint8 quoteTokenDecimals_,
        address[] memory oracles_,
        TokenSpecificOracle[] memory tokenSpecificOracles_,
        uint256 period_,
        uint256 minimumTokenLiquidityValue_,
        uint256 minimumQuoteTokenLiquidity_
    )
        AggregatedOracle(
            quoteTokenName_,
            quoteTokenAddress_,
            quoteTokenSymbol_,
            quoteTokenDecimals_,
            oracles_,
            tokenSpecificOracles_,
            period_,
            minimumTokenLiquidityValue_,
            minimumQuoteTokenLiquidity_
        )
    {
        name = name_;
    }
}
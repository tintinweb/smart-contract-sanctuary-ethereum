// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, baseUnit)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {AggregatorV3Interface} from "chainlink/interfaces/AggregatorV3Interface.sol";

/// @title Long Bonding surface contract
/// @dev TPG price per unit, p. The independent variables in the bonding function are the
/// capital available, C_a, and the commodity rate, C_r. C_a describes the amount of
/// value stored in the network at any given point in time. C_r  describes the commodity
/// rate according to market conditions
/// Initial:
///   B := 0.01
///
/// We assume formulas to be constant. Otherwise we would have to change the burn/mint derivations
/// on update.
contract BondingSurface {
    //
    // errors
    //
    error NotAuthorized(address caller);
    error InputTooLarge();
    error InsufficientTPGSupply();
    error InvalidB();
    error InvalidCommodityPrice();
    error ExpiredComodityPrice();

    //
    // events
    //
    event UpdatedComodityPrice(uint256, uint256);

    //
    // state variables
    //
    address public immutable riskManager;
    uint256 public commodityRate;
    uint256 public commodityRateLastUpdate = 0;
    uint256 public B = 0.01 ether;
    address public immutable XAUUSDOracle = 0x7b219F57a8e9C7303204Af681e9fA69d17ef626f;

    // (B / C_r)
    uint256 internal BCr;

    AggregatorV3Interface private rateFeed;
    uint256 private constant RATE_LIFETIME = 5 minutes;

    uint256 private constant EXTENDED_PRECISION = 1e38;
    uint256 private constant MAX_EXTENDED_PRECISION = EXTENDED_PRECISION * EXTENDED_PRECISION;

    modifier onlyRiskManager() {
        if (msg.sender != riskManager) revert NotAuthorized(msg.sender);
        _;
    }

    modifier comPriceValid() {
        if (block.timestamp >= commodityRateLastUpdate + RATE_LIFETIME) revert ExpiredComodityPrice();
        _;
    }

    /// @dev We use the constructor to precompute variables that only change rarely.
    /// @param _riskManager Address which can adjust parameters of the bonding surface
    constructor(address _riskManager) {
        riskManager = _riskManager;

        rateFeed = AggregatorV3Interface(XAUUSDOracle);
    }

    function comodityPriceIsValid() public view returns (bool) {
        return (block.timestamp <= commodityRateLastUpdate + RATE_LIFETIME);
    }

    function updateComodityPrice() public {
        _updateVariables();
    }

    //
    // view functions
    //

    /// @dev Compute spot price for a given capital available given current capital
    ///      requirements
    ///
    /// @param _ca Capital pool to base the spot price on.
    function spotPrice(uint256 _ca) public view virtual comPriceValid returns (uint256) {}

    /// @dev Compute spot price for a given capital available and capital required
    ///
    /// @param _ca Capital pool to base the spot price on.
    /// @param _cp Comodity Price to base the spot price on.
    function spotPrice(uint256 _ca, uint256 _cp) public view virtual comPriceValid returns (uint256) {}

    /// @dev Calculate number of tokens to mint based on `_in` tokens supplied
    ///         and `_ca` of capital available.
    /// @param _in Assets added to the pool.
    /// @param _ca Capital available to use for bonding curve mint.
    function tokenOut(uint256 _in, uint256 _ca) public view virtual comPriceValid returns (uint256) {}

    /// @dev Calculate number of assets to return based on `_out` tokens being burnt,
    ///         `_ca` of capital available and `_supply` TPG minted.
    /// @param _out TPG to burn
    /// @param _ca Capital available to use for bonding curve burn.
    function tokenIn(uint256 _out, uint256 _ca) public view virtual comPriceValid returns (uint256) {}

    function setB(uint256 _newB) public onlyRiskManager {
        if (_newB == 0) revert InvalidB();
        B = _newB;
        _updateVariables();
    }

    //
    // internal functions
    //

    /// @param x 18 decimal fixed point number to convert to decimal fixed point number with extended precision
    function toExtended(uint256 x) internal pure returns (uint256) {
        return x * (EXTENDED_PRECISION / FixedPointMathLib.WAD);
    }

    /// @param x decimal fixed point number with extended precision to convert to 18 decimal fixed point number
    function to18FP(uint256 x) internal pure returns (uint256) {
        uint256 exp = EXTENDED_PRECISION / FixedPointMathLib.WAD;

        if (x % exp >= (5 * exp) / 10) {
            x += exp;
        }
        return x / exp;
    }

    /// @param x 19 decimal fixed point number to inverse. 0 < x <= MAX_EXTENDED_PRECISION
    function inv(uint256 x) internal pure returns (uint256 res) {
        if (x == 0) revert("Cannot calculate 1/0");

        // Compute inverse https://github.com/paulrberg/prb-math/blob/86c068e21f9ba229025a77b951bd3c4c4cf103da/contracts/PRBMathUD60x18.sol#L214
        unchecked {
            res = MAX_EXTENDED_PRECISION / x;
        }
    }

    function _getRateFromOracle() internal view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */
            ,
            int256 price,
            /*uint startedAt*/
            ,
            /*uint256 timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = rateFeed.latestRoundData();
        return uint256(price);
    }

    function _updateVariables() internal {
        (commodityRate) = _getRateFromOracle();
        commodityRateLastUpdate = block.timestamp;

        if (commodityRate == 0) revert InvalidCommodityPrice();
        emit UpdatedComodityPrice(commodityRate, commodityRateLastUpdate);

        BCr = FixedPointMathLib.fdiv(B, commodityRate, FixedPointMathLib.WAD);
        if (BCr > 1e36) revert InputTooLarge();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import "topos/BondingSurface.sol";

/// @title Short Bonding surface formulas
/// @dev
///                        (C_a)^n
/// p = f(C_a, C_r) = B -------------
///                      (C_r)^(n-1)
///
/// TPG price per unit, p. The independent variables in the bonding function are the
/// capital available, C_a, and the capital required, C_r. C_a describes the amount of
/// value stored in the network at any given point in time. C_r  describes the amount
/// of value that is needed to operate the Topos protocol according to market size
/// and conditions, the regulatory requirements, as well as the chosen risk appetite,
/// and allows for considering these three factors in the determination of p
/// Initial:
///   n := 2
///
/// We assume n to be constant. Otherwise we would have to change the burn/mint derivations
/// on update.
contract ShortBondingSurface is BondingSurface {
    /// @param _riskManager Address which can adjust parameters of the bonding surface
    constructor(address _riskManager) BondingSurface(_riskManager) {}

    /// @dev Compute spot price for a given capital available given current capital
    ///      requirements
    /// p = f(C_a, C_p) = B * (C_a^2 / C_p)
    ///
    /// @param _ca Capital pool to base the spot price on.
    function spotPrice(uint256 _ca) public view override comPriceValid returns (uint256) {
        uint256 caSq = FixedPointMathLib.fmul(_ca, _ca, FixedPointMathLib.WAD); // C_a^2
        return FixedPointMathLib.fmul(caSq, BCr, FixedPointMathLib.WAD); // C_a^2 * B / C_r
    }

    /// @dev Compute spot price for a given capital available and capital required
    /// p = f(C_a, C_p) = B * (C_a^2 / C_p)
    ///
    /// @param _ca Capital pool to base the spot price on.
    /// @param _cp Comodity Price to base the spot price on.
    function spotPrice(uint256 _ca, uint256 _cp) public view override comPriceValid returns (uint256) {
        uint256 caSq = FixedPointMathLib.fmul(_ca, _ca, FixedPointMathLib.WAD); // C_a^2
        uint256 caSqCr = FixedPointMathLib.fdiv(caSq, _cp, FixedPointMathLib.WAD);
        return FixedPointMathLib.fmul(caSqCr, B, FixedPointMathLib.WAD); // C_a^2 * B / C_r
    }

    /// @dev To get the number of tokens we have the following formula:
    ///
    ///        1          1         1
    /// n = ------- * (------- - -------)
    ///      B/C_p      C_a_1     C_a_2
    ///
    /// _ca must be > 0
    /// @notice Calculate number of tokens to mint based on `_in` tokens supplied
    ///         and `_ca` of capital available.
    /// @param _in Assets added to the pool.
    /// @param _ca Capital available to use for bonding curve mint.
    function tokenOut(uint256 _in, uint256 _ca) public view override comPriceValid returns (uint256) {
        // If the input is bigger inverse will give us 0.
        if (_ca > 1e36 || _ca + _in > 1e36) revert InputTooLarge();

        uint256 inv1 = inv(toExtended(_ca));
        uint256 inv2 = inv(toExtended(_ca + _in));
        uint256 inner = to18FP(inv1 - inv2);

        return FixedPointMathLib.fmul(to18FP(inv(toExtended(BCr))), inner, FixedPointMathLib.WAD);
    }

    /// @dev To get the change in assests when burning tokens
    ///
    ///        B            1
    /// x = (----- * m + -------)^-1
    ///       C_p         C_a_2
    ///
    /// m is the token burn amount and C_a_2 is the capitalAvailable before burn
    /// _ca must be > 0
    /// @notice Calculate number of assets to return based on `_out` tokens being burnt,
    ///         `_ca` of capital available and `_supply` TPG minted.
    /// @param _out TPG to burn
    /// @param _ca Capital available to use for bonding curve burn.
    function tokenIn(uint256 _out, uint256 _ca) public view override comPriceValid returns (uint256) {
        // m * (B / C_r)
        uint256 BCrM = toExtended(FixedPointMathLib.fmul(BCr, _out, FixedPointMathLib.WAD));
        // 1 / C_a_2
        uint256 ca2inv = inv(toExtended(_ca));

        return _ca - to18FP(inv(BCrM + ca2inv));
    }
}
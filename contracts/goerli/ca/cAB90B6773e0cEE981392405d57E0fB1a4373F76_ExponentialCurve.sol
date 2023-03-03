// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICurve} from "./ICurve.sol";
import {FixedPointMathLib} from "../lib/FixedPointMathLib.sol";

abstract contract Curve is ICurve {
    using FixedPointMathLib for uint256;

    uint24 constant FEE_DENOMINATOR = 1e6;

    /**
     * @dev See {ICurve-validateDelta}
     */
    function validateDelta(uint128 /*delta*/ ) external pure virtual returns (bool valid) {
        return true;
    }

    /**
     * @dev See {ICurve-validateSpotPrice}
     */
    function validateSpotPrice(uint128 /* newSpotPrice */ ) external pure virtual returns (bool) {
        return true;
    }

    /**
     * @dev See {ICurve-validateProps}
     */
    function validateProps(bytes calldata /*props*/ ) external pure virtual returns (bool valid) {
        return true;
    }

    /**
     * @dev See {ICurve-validateState}
     */
    function validateState(bytes calldata /*state*/ ) external pure virtual returns (bool valid) {
        return true;
    }

    /**
     * @dev See {ICurve-validate}
     */
    function validate(uint128 delta, uint128 newSpotPrice, bytes calldata props, bytes calldata state)
        external
        view
        returns (bool valid)
    {
        return this.validateDelta(delta) && this.validateSpotPrice(newSpotPrice) && this.validateProps(props)
            && this.validateState(state);
    }

    /**
     * @dev Compute protocol and trade fee and add fees to input value.
     * @dev royalties should sum to totalRoyalty.
     */
    function getInputValueAndFees(
        FeeMultipliers calldata feeMultipliers,
        uint256 inputValueWithoutFee,
        uint256[] memory royalties,
        uint256 totalRoyalty
    ) internal pure returns (uint256 inputValue, Fees memory fees) {
        fees = getFees(feeMultipliers, inputValueWithoutFee, royalties);

        // Account for the trade fee (only for Trade pools), protocol fee, and royalties
        inputValue = inputValueWithoutFee + fees.trade + fees.protocol + totalRoyalty;
    }

    /**
     * @dev Compute protocol and trade fee and subtract fees from output value.
     * @dev royalties should sum to totalRoyalty.
     */
    function getOutputValueAndFees(
        FeeMultipliers calldata feeMultipliers,
        uint256 outputValueWithoutFee,
        uint256[] memory royalties,
        uint256 totalRoyalty
    ) internal pure returns (uint256 outputValue, Fees memory fees) {
        fees = getFees(feeMultipliers, outputValueWithoutFee, royalties);

        // Account for the trade fee (only for Trade pools), protocol fee, and royalties
        outputValue = outputValueWithoutFee - fees.trade - fees.protocol - totalRoyalty;
    }

    /**
     * @dev Compute protocol and trade fee.
     */
    function getFees(FeeMultipliers calldata feeMultipliers, uint256 valueWithoutFee, uint256[] memory royalties)
        internal
        pure
        returns (Fees memory fees)
    {
        // Account for the protocol fee, a flat percentage of the buy amount, only for Non-Trade pools
        fees.protocol = valueWithoutFee.fmul(feeMultipliers.protocol, FEE_DENOMINATOR);

        // Account for the trade fee, only for Trade pools
        fees.trade = valueWithoutFee.fmul(feeMultipliers.trade, FEE_DENOMINATOR);

        // Account for the carry fee, only for Trade pools
        uint256 carryFee = fees.trade.fmul(feeMultipliers.carry, FEE_DENOMINATOR);
        fees.trade -= carryFee;
        fees.protocol += carryFee;

        fees.royalties = royalties;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CurveErrorCodes} from "./CurveErrorCodes.sol";

interface ICurve {
    /**
     * @param spotPrice The current selling spot price of the pool, in tokens
     * @param delta The delta parameter of the pool, what it means depends on the curve
     * @param props The properties of the pool, what it means depends on the curve
     * @param state The state of the pool, what it means depends on the curve
     */
    struct Params {
        uint128 spotPrice;
        uint128 delta;
        bytes props;
        bytes state;
    }

    /**
     * @param trade The amount of fee to send to the pool, in tokens
     * @param protocol The amount of fee to send to the protocol, in tokens
     * @param royalties The amount to pay for each item in the order they
     * are purchased. Always has length `numItems`.
     */
    struct Fees {
        uint256 trade;
        uint256 protocol;
        uint256[] royalties;
    }

    /**
     * @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
     * @param fees.protocolMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
     * @param royaltyNumerator Determines how much of the trade value is awarded as royalties. 5 decimals
     * @param carryFeeMultiplier Determines how much carry fee the protocol takes from this trade, 18 decimals
     */
    struct FeeMultipliers {
        uint24 trade;
        uint24 protocol;
        uint24 royaltyNumerator;
        uint24 carry;
    }

    /**
     * @notice Validates if a delta value is valid for the curve. The criteria for
     * validity can be different for each type of curve, for instance ExponentialCurve
     * requires delta to be greater than 1.
     * @param delta The delta value to be validated
     * @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
     * @notice Validates if a new spot price is valid for the curve. Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's pooled token.
     * @param newSpotPrice The new spot price to be set
     * @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice) external view returns (bool valid);

    /**
     * @notice Validates if a props value is valid for the curve. The criteria for validity can be different for each type of curve.
     * @param props The props value to be validated
     * @return valid True if props is valid, false otherwise
     */
    function validateProps(bytes calldata props) external view returns (bool valid);

    /**
     * @notice Validates if a state value is valid for the curve. The criteria for validity can be different for each type of curve.
     * @param state The state value to be validated
     * @return valid True if state is valid, false otherwise
     */
    function validateState(bytes calldata state) external view returns (bool valid);

    /**
     * @notice Validates given delta, spot price, props value and state value for the curve. The criteria for validity can be different for each type of curve.
     * @param delta The delta value to be validated
     * @param newSpotPrice The new spot price to be set
     * @param props The props value to be validated
     * @param state The state value to be validated
     * @return valid True if all parameters are valid, false otherwise
     */
    function validate(uint128 delta, uint128 newSpotPrice, bytes calldata props, bytes calldata state)
        external
        view
        returns (bool valid);

    /**
     * @notice Given the current state of the pool and the trade, computes how much the user
     * should pay to purchase an NFT from the pool, the new spot price, and other values.
     * @dev Do not try to optimize the length of fees.royalties; compiler
     * ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
     * calculation loop due to stack depth
     * @param params Parameters of the pool that affect the bonding curve.
     * @param numItems The number of NFTs the user is buying from the pool
     * @param feeMultipliers Determines how much fee is taken from this trade.
     * @return newParams The updated parameters of the pool that affect the bonding curve.
     * @return inputValue The amount that the user should pay, in tokens
     * @return fees The amount of fees
     * @return lastSwapPrice The swap price of the last NFT traded with fees applied
     */
    function getBuyInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        view
        returns (ICurve.Params calldata newParams, uint256 inputValue, ICurve.Fees calldata fees, uint256 lastSwapPrice);

    /**
     * @notice Given the current state of the pool and the trade, computes how much the user
     * should receive when selling NFTs to the pool, the new spot price, and other values.
     * @dev Do not try to optimize the length of fees.royalties; compiler
     * ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
     * calculation loop due to stack depth
     * @param params Parameters of the pool that affect the bonding curve.
     * @param numItems The number of NFTs the user is selling to the pool
     * @param feeMultipliers Determines how much fee is taken from this trade.
     * @return newParams The updated parameters of the pool that affect the bonding curve.
     * @return outputValue The amount that the user should receive, in tokens
     * @return fees The amount of fees
     * @return lastSwapPrice The swap price of the last NFT traded with fees applied
     */
    function getSellInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        view
        returns (
            ICurve.Params calldata newParams,
            uint256 outputValue,
            ICurve.Fees calldata fees,
            uint256 lastSwapPrice
        );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

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
                    x := div(xxRound, scalar)

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
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

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

            if or(
                // Revert if y is zero to ensure we don't divide by zero below.
                iszero(y),
                // Equivalent to require(x == 0 || (x * baseUnit) / x == baseUnit)
                iszero(or(iszero(x), eq(div(z, x), baseUnit)))
            ) {
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
                    z := baseUnit
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := baseUnit
                }
                default {
                    z := x
                }
                let half := div(baseUnit, 2)
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, baseUnit)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
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
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract CurveErrorCodes {
    error InvalidNumItems(); // The numItem value is 0
    error SpotPriceOverflow(); // The updated spot price doesn't fit into 128 bits
    error TooManyItems(); // The value of numItems passed was too great
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Curve} from "./Curve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {CollectionPoolCloner} from "../lib/CollectionPoolCloner.sol";
import {CollectionPoolERC20} from "../pools/CollectionPoolERC20.sol";
import {FixedPointMathLib} from "../lib/FixedPointMathLib.sol";

/**
 * @author Collection
 * @notice Bonding curve logic for an x*y=k curve using virtual reserves.
 * @dev    The virtual token reserve is stored in `spotPrice` and the virtual nft reserve is stored in `delta`.
 *         An LP can modify the virtual reserves by changing the `spotPrice` (tokens) or `delta` (nfts).
 */
contract XykCurve is Curve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    error TokenReserveOverflow(uint256 initialValue, uint256 finalValue);
    /// @param outputValueWithoutFee The amount the pool needed to have to be sold into
    error TokenReserveUnderflow(uint256 outputValueWithoutFee);
    error NFTReserveOverflow(uint256 initialValue, uint256 finalValue);

    /**
     * @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(Params calldata params, uint256 numItems, FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Params memory newParams, uint256 inputValue, Fees memory fees, uint256 lastSwapPrice)
    {
        if (numItems == 0) revert InvalidNumItems();

        // get the pool's virtual nft and eth/erc20 reserves
        uint256 tokenBalance = params.spotPrice;
        uint256 nftBalance = params.delta;

        // If numItems is too large, we will get divide by zero error
        if (numItems >= nftBalance) revert InvalidNumItems();

        // calculate the amount to send in
        uint256 inputValueWithoutFee = (numItems * tokenBalance) / (nftBalance - numItems);

        fees.royalties = new uint256[](numItems);
        // For XYK, every item has the same price so royalties have the same value
        uint256 rawAmount = inputValueWithoutFee / numItems;
        uint256 royaltyAmount = rawAmount.fmul(feeMultipliers.royaltyNumerator, FEE_DENOMINATOR);
        for (uint256 i = 0; i < numItems;) {
            fees.royalties[i] = royaltyAmount;

            unchecked {
                ++i;
            }
        }

        /// @dev royalty breakdown not needed if fees aren't used
        (lastSwapPrice,) = getInputValueAndFees(feeMultipliers, rawAmount, new uint256[](0), royaltyAmount);

        // Get the total royalties after accounting for integer division
        uint256 totalRoyalties = royaltyAmount * numItems;

        (inputValue, fees) = getInputValueAndFees(feeMultipliers, inputValueWithoutFee, fees.royalties, totalRoyalties);

        // set the new virtual reserves
        bool success;
        (success, newParams.spotPrice) = safeCastUint256ToUint128(tokenBalance + inputValueWithoutFee); // token reserve
        if (!success) revert TokenReserveOverflow(tokenBalance, tokenBalance + inputValueWithoutFee); // newParams.spotPrice has lost data
        /// @dev Cannot underflow, validated in initial check
        newParams.delta = uint128(nftBalance - numItems);

        // Keep state the same
        newParams.state = params.state;
    }

    /**
     * @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(Params calldata params, uint256 numItems, FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Params memory newParams, uint256 outputValue, Fees memory fees, uint256 lastSwapPrice)
    {
        if (numItems == 0) revert InvalidNumItems();

        // get the pool's virtual nft and eth/erc20 balance
        uint256 tokenBalance = params.spotPrice;
        uint256 nftBalance = params.delta;

        // calculate the amount to send out
        uint256 outputValueWithoutFee = (numItems * tokenBalance) / (nftBalance + numItems);

        fees.royalties = new uint256[](numItems);
        // For XYK, every item has the same price so royalties have the same value
        uint256 rawAmount = outputValueWithoutFee / numItems;
        uint256 royaltyAmount = rawAmount.fmul(feeMultipliers.royaltyNumerator, FEE_DENOMINATOR);
        for (uint256 i = 0; i < numItems;) {
            fees.royalties[i] = royaltyAmount;

            unchecked {
                ++i;
            }
        }

        /// @dev royalty breakdown not needed if fee return value not used
        (lastSwapPrice,) = getOutputValueAndFees(feeMultipliers, rawAmount, new uint256[](0), royaltyAmount);

        // Get the total royalties after accounting for integer division
        uint256 totalRoyalties = royaltyAmount * numItems;

        (outputValue, fees) =
            getOutputValueAndFees(feeMultipliers, outputValueWithoutFee, fees.royalties, totalRoyalties);

        // set the new virtual reserves

        /// @dev Can't overflow but can underflow. Throw a custom error so user
        /// can see the theoretical price regardless of whether the pool has enough balance
        if (tokenBalance < outputValueWithoutFee) revert TokenReserveUnderflow(outputValueWithoutFee);
        newParams.spotPrice = uint128(tokenBalance - outputValueWithoutFee); // token reserve
        bool success;
        (success, newParams.delta) = safeCastUint256ToUint128(nftBalance + numItems); // nft reserve
        if (!success) revert NFTReserveOverflow(nftBalance, nftBalance + numItems);

        // Keep state the same
        newParams.state = params.state;
    }

    function safeCastUint256ToUint128(uint256 value) internal pure returns (bool success, uint128 castedValue) {
        success = value <= type(uint128).max;
        castedValue = uint128(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {TransferLib} from "../lib/TransferLib.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {IExternalFilter} from "../filter/IExternalFilter.sol";
import {TokenIDFilter} from "../filter/TokenIDFilter.sol";
import {MultiPauser} from "../lib/MultiPauser.sol";
import {IPoolActivityMonitor} from "./IPoolActivityMonitor.sol";

/// @title The base contract for an NFT/TOKEN AMM pool
/// @author Collection
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract CollectionPool is ReentrancyGuard, ERC1155Holder, TokenIDFilter, MultiPauser, ICollectionPool {
    using Strings for uint256;
    /**
     * @dev The RoyaltyDue struct is used to track information about royalty payments that are due on NFT swaps.
     * It contains two fields:
     * @dev amount: The amount of the royalty payment, in the token's base units.
     * This value is calculated based on the price of the NFT being swapped, and the royaltyNumerator value set in the AMM pool contract.
     * @dev recipient: The address to which the royalty payment should be sent.
     * This value is determined by the NFT being swapped, and it is specified in the ERC2981 metadata for the NFT.
     * @dev When a user swaps an NFT for tokens using the AMM pool contract, a RoyaltyDue struct is created to track the amount
     * and recipient of the royalty payment that is due on the NFT swap. This struct is then used to facilitate the payment of
     * the royalty to the appropriate recipient.
     */

    struct RoyaltyDue {
        uint256 amount;
        address recipient;
    }

    /**
     * @dev The _INTERFACE_ID_ERC2981 constant specifies the interface ID for the ERC2981 standard. This standard is used for tracking
     * royalties on non-fungible tokens (NFTs). It defines a standard interface for NFTs that includes metadata about the royalties that
     * are due on the NFT when it is swapped or transferred.
     * @dev The _INTERFACE_ID_ERC2981 constant is used in the AMM pool contract to check whether an NFT being swapped implements the ERC2981
     * standard. If it does, the contract can use the metadata provided by the ERC2981 interface to facilitate the payment of royalties on the
     * NFT swap. If the NFT does not implement the ERC2981 standard, the contract will not track or pay royalties on the NFT swap.
     * This can be overridden by the royaltyNumerator field in the AMM pool contract.
     * @dev For more information about the ERC2981 standard, see https://eips.ethereum.org/EIPS/eip-2981
     */
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    bool private initialized;

    /**
     * @dev The MAX_FEE constant specifies the maximum fee you, the user, are allowed to charge for this AMM pool.
     * It is used to limit the amount of fees that can be charged by the AMM pool contract on NFT/token swaps.
     * @dev The MAX_FEE constant is used to ensure that the AMM pool does not charge excessive fees on NFT/token swaps.
     * It also helps to protect users from paying excessive fees when using the AMM pool contract.
     * @dev usage: 90%, must <= 1 - MAX_PROTOCOL_FEE (set in CollectionPoolFactory)
     * @dev If the bid/ask is 9/10 and the fee is set to 1%, then the fee is calculated as follows:
     * @dev For a buy order, the fee would be the bid price multiplied by the fee rate, or 9 * 1% = 0.09
     * @dev For a sell order, the fee would be the ask price multiplied by the fee rate, or 10 * 1% = 0.1
     * @dev The fee is charged as a percentage of the bid/ask price, and it is used to cover the costs associated with running the AMM pool
     * contract and providing liquidity to the decentralized exchange. The fee is deducted from the final price of the token or NFT swap,
     * and it is paid to the contract owner or to a designated fee recipient. The exact fee rate and fee recipient can be configured by the
     * contract owner when the AMM pool contract is deployed.
     */
    uint24 internal constant MAX_FEE = 0.9e6;

    // The spread between buy and sell prices, set to be a multiplier we apply to the buy price
    // Fee is only relevant for TRADE pools
    // Units are in base 1e6
    uint24 public fee;

    // For every NFT swapped, a fraction of the cost will be sent to the
    // ERC2981 payable address for the NFT swapped. The fraction is equal to
    // `royaltyNumerator / 1e6`
    uint24 public royaltyNumerator;

    uint24 internal constant MAX_ROYALTY_NUMERATOR = 1e6;

    // An address to which all royalties will be paid to if not address(0). This
    // is a fallback to ERC2981 royalties set by the NFT creator, and allows sending
    // royalties to arbitrary addresses if a collection does not support ERC2981.
    address payable public royaltyRecipientFallback;

    uint256 internal constant POOL_SWAP_PAUSE = 0;

    // The current price of the NFT
    // @dev This is generally used to mean the immediate sell price for the next marginal NFT.
    // However, this should NOT be assumed, as future bonding curves may use spotPrice in different ways.
    // Use getBuyNFTQuote and getSellNFTQuote for accurate pricing info.
    uint128 internal spotPrice;

    // The parameter for the pool's bonding curve.
    // Units and meaning are bonding curve dependent.
    uint128 internal delta;

    // If set to 0, NFTs/tokens sent by traders during trades will be sent to the pool.
    // Otherwise, assets will be sent to the set address. Not available for TRADE pools.
    address payable public assetRecipient;

    // The trade fee accrued from trades.
    uint256 public accruedTradeFee;

    // The properties used by the pool's bonding curve.
    bytes internal props;

    // The state used by the pool's bonding curve.
    bytes internal state;

    // If non-zero, contract implementing IExternalFilter checked on (pool buying) swaps
    IExternalFilter public externalFilter;

    // Events
    event SwapNFTInPool(
        uint256[] nftIds, uint256 inputAmount, uint256 tradeFee, uint256 protocolFee, RoyaltyDue[] royaltyDue
    );
    event SwapNFTOutPool(
        uint256[] nftIds, uint256 outputAmount, uint256 tradeFee, uint256 protocolFee, RoyaltyDue[] royaltyDue
    );
    event SpotPriceUpdate(uint128 newSpotPrice);
    event TokenDeposit(IERC721 indexed collection, ERC20 indexed token, uint256 amount);
    event TokenWithdrawal(IERC721 indexed collection, ERC20 indexed token, uint256 amount);
    event AccruedTradeFeeWithdrawal(IERC721 indexed collection, ERC20 token, uint256 amount);
    event NFTDeposit(IERC721 indexed collection, uint256 numNFTs, uint256 rawBuyPrice, uint256 rawSellPrice);
    event NFTWithdrawal(IERC721 indexed collection, uint256 numNFTs, uint256 rawBuyPrice, uint256 rawSellPrice);
    event DeltaUpdate(uint128 newDelta);
    event FeeUpdate(uint96 newFee);
    event AssetRecipientChange(address indexed a);
    event PropsUpdate(bytes newProps);
    event StateUpdate(bytes newState);
    event RoyaltyNumeratorUpdate(uint24 newRoyaltyNumerator);
    event RoyaltyRecipientFallbackUpdate(address payable indexed newFallback);
    event PoolSwapPause();
    event PoolSwapUnpause();
    event ExternalFilterSet(address indexed collection, address indexed filterAddress);

    // Parameterized Errors
    error InsufficientLiquidity(uint256 balance, uint256 accruedTradeFee);
    error RoyaltyNumeratorOverflow();
    error SwapsArePaused();
    error InvalidPoolParams();
    error NotAuthorized();
    error InvalidModification();
    error InvalidSwapQuantity();
    error InvalidSwap();
    error SlippageExceeded();
    error RouterNotTrusted();
    error NFTsNotAccepted();
    error NFTsNotAllowed();
    error CallNotAllowed();
    error CallError(bytes returnData);
    error MulticallError();
    error InvalidExternalFilter();
    error UseWithdrawERC721Instead();

    modifier onlyFactory() {
        if (msg.sender != address(factory())) revert NotAuthorized();
        _;
    }

    /**
     * @dev Use this whenever modifying the value of royaltyNumerator.
     */
    modifier validRoyaltyNumerator(uint24 _royaltyNumerator) {
        if (_royaltyNumerator >= MAX_ROYALTY_NUMERATOR) revert RoyaltyNumeratorOverflow();
        _;
    }

    modifier whenPoolSwapsNotPaused() {
        if (poolSwapsPaused()) revert SwapsArePaused();
        _;
    }

    function poolSwapsPaused() public view returns (bool) {
        return factory().swapPaused() || isPaused(POOL_SWAP_PAUSE);
    }

    /**
     * Ownable functions
     */

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return factory().ownerOf(tokenId());
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (msg.sender != owner()) revert NotAuthorized();
        _;
    }

    /// @dev Throws if called by accounts that were not authorized by the owner.
    modifier onlyAuthorized() {
        factory().requireAuthorizedForToken(msg.sender, tokenId());
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Disallows setting to the zero address as a way to more gas-efficiently avoid reinitialization
    /// When ownership is transferred, if the new owner implements IOwnershipTransferCallback, we make a callback
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        factory().safeTransferFrom(msg.sender, newOwner, tokenId());
    }

    /**
     * @notice Called during pool creation to set initial parameters
     * @dev Only called once by factory to initialize.
     * We verify this by making sure that the current owner is address(0).
     * The Ownable library we use disallows setting the owner to be address(0), so this condition
     * should only be valid before the first initialize call.
     * @param _assetRecipient The address that will receive the TOKEN or NFT sent to this pool during swaps.
     * NOTE: If set to address(0), they will go to the pool itself.
     * @param _delta The initial delta of the bonding curve
     * @param _fee The initial % fee taken, if this is a trade pool
     * @param _spotPrice The initial price to sell an asset into the pool
     * @param _royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e6
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient fallback is set.
     * @param _royaltyRecipientFallback An address to which all royalties will be paid to if not address(0).
     * This is a fallback to ERC2981 royalties set by the NFT creator, and allows sending royalties to
     * arbitrary addresses if a collection does not support ERC2981.
     */
    function initialize(
        address payable _assetRecipient,
        uint128 _delta,
        uint24 _fee,
        uint128 _spotPrice,
        bytes calldata _props,
        bytes calldata _state,
        uint24 _royaltyNumerator,
        address payable _royaltyRecipientFallback
    ) external payable validRoyaltyNumerator(_royaltyNumerator) {
        // Do not initialize if already initialized
        if (initialized) revert InvalidPoolParams();
        initialized = true;
        __ReentrancyGuard_init();

        ICurve _bondingCurve = bondingCurve();
        PoolType _poolType = poolType();

        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            // Only Trade Pools can have nonzero fee
            if (_fee != 0) revert InvalidPoolParams();
            assetRecipient = _assetRecipient;
        } else if (_poolType == PoolType.TRADE) {
            // Trade fee must be less than 90%
            if (_fee >= MAX_FEE) revert InvalidPoolParams();
            // Trade pools can't set asset recipient
            if (_assetRecipient != address(0)) revert InvalidPoolParams();
            fee = _fee;
        }
        if (!_bondingCurve.validate(_delta, _spotPrice, _props, _state)) revert InvalidPoolParams();
        delta = _delta;
        spotPrice = _spotPrice;
        props = _props;
        state = _state;
        royaltyNumerator = _royaltyNumerator;
        royaltyRecipientFallback = _royaltyRecipientFallback;
    }

    /**
     * External state-changing functions
     */

    /**
     * @notice Sets NFT token ID filter to allow only some NFTs into this pool. Pool must be empty
     * to call this function. This filter is checked on deposits and swapping NFTs into the pool.
     * Selling into the pool may require an additional check (see `setExternalFilter`).
     * @param merkleRoot Merkle root representing all allowed IDs
     * @param encodedTokenIDs Opaque encoded list of token IDs
     */
    function setTokenIDFilter(bytes32 merkleRoot, bytes calldata encodedTokenIDs) external {
        if (msg.sender != address(factory()) && msg.sender != owner()) revert NotAuthorized();
        // Pool must be empty to change filter
        if (nft().balanceOf(address(this)) != 0) revert InvalidModification();
        _setRootAndEmitAcceptedIDs(address(nft()), merkleRoot, encodedTokenIDs);
    }

    /**
     * @notice Sets an external contract that is consulted before any NFT is swapped into the pool.
     * Typically used to implement dynamic blocklists. Because it is dynamic, deposits are not
     * checked. See also `setTokenIDFilter`.
     */
    function setExternalFilter(address provider) external {
        if (msg.sender != address(factory()) && msg.sender != owner()) revert NotAuthorized();
        if (provider == address(0)) {
            externalFilter = IExternalFilter(provider);
            emit ExternalFilterSet(address(nft()), address(0));
            return;
        }

        if (isContract(provider)) {
            if (contractImplementsInterface(provider, type(IExternalFilter).interfaceId)) {
                externalFilter = IExternalFilter(provider);
                emit ExternalFilterSet(address(nft()), provider);
                return;
            }
        }

        revert InvalidExternalFilter();
    }

    /**
     * @notice Sends token to the pool in exchange for any `numNFTs` NFTs
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
     * This swap function is meant for users who are ID agnostic
     * @dev The nonReentrant modifier is in swapTokenForSpecificNFTs
     * @param numNFTs The number of NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient The recipient of the NFTs
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual whenPoolSwapsNotPaused returns (uint256 inputAmount) {
        IERC721 _nft = nft();
        uint256[] memory tokenIds = _selectArbitraryNFTs(_nft, numNFTs);
        if (tokenIds.length == 0) revert InvalidSwapQuantity();
        inputAmount = swapTokenForSpecificNFTs(tokenIds, maxExpectedTokenInput, nftRecipient, isRouter, routerCaller);
    }

    /**
     * @notice Sends token to the pool in exchange for a specific set of NFTs
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
     * This swap is meant for users who want specific IDs. Also higher chance of
     * reverting if some of the specified IDs leave the pool before the swap goes through.
     * @param nftIds The list of IDs of the NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient The recipient of the NFTs
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return inputAmount The amount of token used for purchase
     */
    function swapTokenForSpecificNFTs(
        uint256[] memory nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) public payable virtual nonReentrant whenPoolSwapsNotPaused returns (uint256 inputAmount) {
        // Input validation
        // Can only buy from NFT or two sided pools
        if (poolType() == PoolType.TOKEN) revert InvalidSwap();
        if (nftIds.length == 0) revert InvalidSwapQuantity();
        // Prevent users from making a ridiculous pool, buying out their "sucker" price, and
        // then staking this pool with liquidity at really bad prices into a reward vault.
        if (isInCreationBlock()) revert InvalidSwap();

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        uint256 lastSwapPrice;
        (inputAmount, fees, lastSwapPrice) =
            _calculateBuyInfoAndUpdatePoolParams(nftIds.length, maxExpectedTokenInput, bondingCurve());

        accruedTradeFee += fees.trade;
        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(nft(), nftIds, fees.royalties);

        _pullTokenInputAndPayProtocolFee(inputAmount, isRouter, routerCaller, factory(), fees.protocol, royaltiesDue);

        _withdrawNFTs(nftRecipient, nftIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPool(nftIds, inputAmount, fees.trade, fees.protocol, royaltiesDue);

        notifySwap(IPoolActivityMonitor.EventType.BOUGHT_NFT_FROM_POOL, nftIds.length, lastSwapPrice, inputAmount);
    }

    /**
     * @notice Sends a set of NFTs to the pool in exchange for token. Token must be allowed by
     * filters, see `setTokenIDFilter` and `setExternalFilter`.
     * @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
     * @param nfts The list of IDs of the NFTs to sell to the pool along with its Merkle multiproof.
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param tokenRecipient The recipient of the token output
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        ICollectionPool.NFTs calldata nfts,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller,
        bytes calldata externalFilterContext
    ) external virtual nonReentrant whenPoolSwapsNotPaused returns (uint256 outputAmount) {
        // Store locally to remove extra calls
        ICollectionPoolFactory _factory = factory();

        // Input validation
        PoolType _poolType = poolType();
        // Can only sell to Token / 2-sided pools
        if (_poolType == PoolType.NFT) revert InvalidSwap();
        if (nfts.ids.length == 0) revert InvalidSwapQuantity();
        if (!acceptsTokenIDs(nfts.ids, nfts.proof, nfts.proofFlags)) revert NFTsNotAccepted();
        if (
            address(externalFilter) != address(0)
                && !externalFilter.areNFTsAllowed(address(nft()), nfts.ids, externalFilterContext)
        ) {
            revert NFTsNotAllowed();
        }

        // Prevent users from making a ridiculous pool, buying out their "sucker" price, and
        // then staking this pool with liquidity at really bad prices into a reward vault.
        if (isInCreationBlock()) revert InvalidSwap();

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        uint256 lastSwapPrice;
        (outputAmount, fees, lastSwapPrice) =
            _calculateSellInfoAndUpdatePoolParams(nfts.ids.length, minExpectedTokenOutput, bondingCurve());

        // Accrue trade fees before sending token output. This ensures that the balance is always sufficient for trade fee withdrawal.
        accruedTradeFee += fees.trade;

        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(nft(), nfts.ids, fees.royalties);

        _sendTokenOutputAndPayProtocolFees(_factory, tokenRecipient, outputAmount, royaltiesDue, fees.protocol);

        _takeNFTsFromSender(nfts.ids, _factory, isRouter, routerCaller);

        emit SwapNFTInPool(nfts.ids, outputAmount, fees.trade, fees.protocol, royaltiesDue);

        /// @dev for some reason this causes the bytecode size to drop below the
        /// 24kb limit. Even the magic number 3 is better than 0 for some reason
        /// when compiling with 150 runs viaIR
        uint256[] memory amounts = new uint256[](3);

        notifySwap(IPoolActivityMonitor.EventType.SOLD_NFT_TO_POOL, nfts.ids.length, lastSwapPrice, outputAmount);
    }

    function balanceToFulfillSellNFT(uint256 numNFTs) external view returns (uint256 balance) {
        uint256 totalAmount;
        (, totalAmount,,) = getSellNFTQuote(numNFTs);
        balance = accruedTradeFee + totalAmount;
    }

    /**
     * View functions
     */

    function getRawBuyAndSellPrices() public view returns (uint256 rawBuyPrice, uint256 rawSellPrice) {
        (, rawBuyPrice,,) = bondingCurve().getBuyInfo(
            curveParams(), 1, ICurve.FeeMultipliers({trade: 0, protocol: 0, royaltyNumerator: 0, carry: 0})
        );
        (, rawSellPrice,,) = bondingCurve().getSellInfo(
            curveParams(), 1, ICurve.FeeMultipliers({trade: 0, protocol: 0, royaltyNumerator: 0, carry: 0})
        );
    }

    /**
     * @notice Checks if NFTs is allowed in this pool
     * @param tokenID NFT ID
     * @param proof Merkle proof
     */
    function acceptsTokenID(uint256 tokenID, bytes32[] calldata proof) public view returns (bool) {
        return _acceptsTokenID(tokenID, proof);
    }

    /**
     * @notice Checks if list of NFTs are allowed in this pool using Merkle multiproof and flags
     * @param tokenIDs List of NFT IDs
     * @param proof Merkle multiproof
     * @param proofFlags Merkle multiproof flags
     */
    function acceptsTokenIDs(uint256[] calldata tokenIDs, bytes32[] calldata proof, bool[] calldata proofFlags)
        public
        view
        returns (bool)
    {
        return _acceptsTokenIDs(tokenIDs, proof, proofFlags);
    }

    /**
     * @dev Used as read function to query the bonding curve for buy pricing info
     * @param numNFTs The number of NFTs to buy from the pool
     */
    function getBuyNFTQuote(uint256 numNFTs)
        public
        view
        returns (ICurve.Params memory newParams, uint256 totalAmount, uint256 inputAmount, ICurve.Fees memory fees)
    {
        (newParams, inputAmount, fees,) = bondingCurve().getBuyInfo(curveParams(), numNFTs, feeMultipliers());

        // Since inputAmount is already inclusive of fees.
        totalAmount = inputAmount;
    }

    /**
     * @dev Used as read function to query the bonding curve for sell pricing info
     * @param numNFTs The number of NFTs to sell to the pool
     */
    function getSellNFTQuote(uint256 numNFTs)
        public
        view
        returns (ICurve.Params memory newParams, uint256 totalAmount, uint256 outputAmount, ICurve.Fees memory fees)
    {
        (newParams, outputAmount, fees,) = bondingCurve().getSellInfo(curveParams(), numNFTs, feeMultipliers());

        totalAmount = outputAmount + fees.trade + fees.protocol;
        uint256 length = fees.royalties.length;
        for (uint256 i; i < length;) {
            totalAmount += fees.royalties[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns all NFT IDs held by the pool
     */
    function getAllHeldIds() external view virtual returns (uint256[] memory);

    /**
     * @notice Returns LP token ID for this pool
     */
    function tokenId() public view returns (uint256 _tokenId) {
        _tokenId = uint160(address(this));
    }

    /**
     * @notice Returns the pool's variant (NFT is enumerable or not, pool uses ETH or ERC20)
     */
    function poolVariant() public pure virtual returns (ICollectionPoolFactory.PoolVariant);

    function factory() public pure returns (ICollectionPoolFactory _factory) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _factory := shr(0x60, calldataload(sub(calldatasize(), paramsLength)))
        }
    }

    /**
     * @notice Returns the type of bonding curve that parameterizes the pool
     */
    function bondingCurve() public pure returns (ICurve _bondingCurve) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _bondingCurve := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 20)))
        }
    }

    /**
     * @notice Returns the NFT collection that parameterizes the pool
     */
    function nft() public pure returns (IERC721 _nft) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _nft := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 40)))
        }
    }

    /**
     * @notice Returns the pool's type (TOKEN/NFT/TRADE)
     */
    function poolType() public pure returns (PoolType _poolType) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _poolType := shr(0xf8, calldataload(add(sub(calldatasize(), paramsLength), 60)))
        }
    }

    function isInCreationBlock() private view returns (bool _isInCreationBlock) {
        uint256 paramsLength = _immutableParamsLength();
        uint256 _creationBlockNumber;

        assembly {
            _creationBlockNumber := shr(0xe0, calldataload(add(sub(calldatasize(), paramsLength), 61)))
        }
        // Only the (lower) 32 bits are stored (~2000 years with 15s blocks). We compare with uint32(block.number)
        // so we can still detect if we're in the same block in the unlikely event of an overflow
        _isInCreationBlock = uint32(_creationBlockNumber) == uint32(block.number);
    }

    /**
     * @notice Handles royalty recipient and fallback logic. Attempts to honor
     * ERC2981 where possible, followed by the owner's set fallback. If neither
     * is a valid address, then royalties go to the asset recipient for this
     * pool.
     * @param erc2981Recipient The address to which royalties should be paid as
     * returned by the IERC2981 `royaltyInfo` method. `payable(address(0))` if
     * the nft does not implement IERC2981.
     * @return The address to which royalties should be paid
     */
    function getRoyaltyRecipient(address payable erc2981Recipient) public view returns (address payable) {
        if (erc2981Recipient != address(0)) {
            return erc2981Recipient;
        }
        // No recipient from ERC2981 royaltyInfo method. Check if we have a fallback
        else if (royaltyRecipientFallback != address(0)) {
            return royaltyRecipientFallback;
        }
        // No ERC2981 recipient or recipient fallback. Default to pool's assetRecipient.
        else {
            return getAssetRecipient();
        }
    }

    /**
     * @notice Returns the address that assets that receives assets when a swap is done with this pool
     * Can be set to another address by the owner, if set to address(0), defaults to the pool's own address
     */
    function getAssetRecipient() public view returns (address payable _assetRecipient) {
        // If it's a TRADE pool, we know the recipient is 0 (TRADE pools can't set asset recipients)
        // so just return address(this)
        if (poolType() == PoolType.TRADE) {
            return payable(address(this));
        }

        // Otherwise, we return the recipient if it's been set
        // or replace it with address(this) if it's 0
        _assetRecipient = assetRecipient;
        if (_assetRecipient == address(0)) {
            // Tokens will be transferred to address(this)
            _assetRecipient = payable(address(this));
        }
    }

    function curveParams() public view returns (ICurve.Params memory params) {
        return ICurve.Params(spotPrice, delta, props, state);
    }

    function feeMultipliers() public view returns (ICurve.FeeMultipliers memory) {
        uint24 protocolFeeMultiplier;
        uint24 carryFeeMultiplier;

        PoolType _poolType = poolType();
        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            protocolFeeMultiplier = factory().protocolFeeMultiplier();
        } else if (_poolType == PoolType.TRADE) {
            carryFeeMultiplier = factory().carryFeeMultiplier();
        }

        return ICurve.FeeMultipliers(fee, protocolFeeMultiplier, royaltyNumerator, carryFeeMultiplier);
    }

    /**
     * Internal functions
     */

    /**
     * Taken from https://eips.ethereum.org/EIPS/eip-165#how-to-detect-if-a-contract-implements-any-given-interface
     */
    function contractImplementsInterface(address _contract, bytes4 _interfaceId) internal view returns (bool) {
        uint256 success;
        uint256 result;

        (success, result) = noThrowCall(_contract, 0x01ffc9a7);
        if ((success == 0) || (result == 0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, 0xffffffff);
        if ((success == 0) || (result != 0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if ((success == 1) && (result == 1)) {
            return true;
        }
        return false;
    }

    /**
     * Taken from https://eips.ethereum.org/EIPS/eip-165#how-to-detect-if-a-contract-implements-any-given-interface
     */
    function noThrowCall(address _contract, bytes4 _interfaceId)
        internal
        view
        returns (uint256 success, uint256 result)
    {
        bytes4 erc165ID = 0x01ffc9a7; // ERC165 ID

        assembly {
            let x := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(x, erc165ID) // Place signature at beginning of empty storage (ERC165 ID)
            mstore(add(x, 0x04), _interfaceId) // Place first argument directly next to signature

            success := staticcall(30000, _contract, x, 0x24, x, 0x20)

            result := mload(x) // Load the result
        }
    }

    /**
     * @notice Calculates the amount needed to be sent into the pool for a buy and adjusts spot price or delta if necessary
     * @param numNFTs The amount of NFTs to purchase from the pool
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @return inputAmount The amount of tokens total tokens receive
     * @return fees The amount of tokens to send as fees
     * @return lastSwapPrice The swap price of the last NFT traded with fees applied
     */
    function _calculateBuyInfoAndUpdatePoolParams(uint256 numNFTs, uint256 maxExpectedTokenInput, ICurve _bondingCurve)
        internal
        returns (uint256 inputAmount, ICurve.Fees memory fees, uint256 lastSwapPrice)
    {
        ICurve.Params memory params = curveParams();
        ICurve.Params memory newParams;
        (newParams, inputAmount, fees, lastSwapPrice) = _bondingCurve.getBuyInfo(params, numNFTs, feeMultipliers());

        // Revert if input is more than expected
        if (inputAmount > maxExpectedTokenInput) revert SlippageExceeded();

        _updatePoolParams(params, newParams);
    }

    /**
     * @notice Calculates the amount needed to be sent by the pool for a sell and adjusts spot price or delta if necessary
     * @param numNFTs The amount of NFTs to send to the the pool
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param _bondingCurve The bonding curve used to fetch pricing information from
     * @return outputAmount The amount of tokens total tokens receive
     * @return fees The amount of tokens to send as fees
     * @return lastSwapPrice The swap price of the last NFT traded with fees applied
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 minExpectedTokenOutput,
        ICurve _bondingCurve
    ) internal returns (uint256 outputAmount, ICurve.Fees memory fees, uint256 lastSwapPrice) {
        ICurve.Params memory params = curveParams();
        ICurve.Params memory newParams;
        (newParams, outputAmount, fees, lastSwapPrice) = _bondingCurve.getSellInfo(params, numNFTs, feeMultipliers());

        // Revert if output is too little
        if (outputAmount < minExpectedTokenOutput) revert SlippageExceeded();

        _updatePoolParams(params, newParams);
    }

    function _updatePoolParams(ICurve.Params memory params, ICurve.Params memory newParams) internal {
        // Consolidate writes to save gas
        if (params.spotPrice != newParams.spotPrice || params.delta != newParams.delta) {
            spotPrice = newParams.spotPrice;
            delta = newParams.delta;
        }

        if (keccak256(params.state) != keccak256(newParams.state)) {
            state = newParams.state;

            emit StateUpdate(newParams.state);
        }

        // Emit spot price update if it has been updated
        if (params.spotPrice != newParams.spotPrice) {
            emit SpotPriceUpdate(newParams.spotPrice);
        }

        // Emit delta update if it has been updated
        if (params.delta != newParams.delta) {
            emit DeltaUpdate(newParams.delta);
        }
    }

    /**
     * @notice Pulls the token input of a trade from the trader and pays the protocol fee.
     * @param inputAmount The amount of tokens to be sent
     * @param isRouter Whether or not the caller is CollectionRouter
     * @param routerCaller If called from CollectionRouter, store the original caller
     * @param _factory The CollectionPoolFactory which stores CollectionRouter allowlist info
     * @param protocolFee The protocol fee to be paid
     * @param royaltyAmounts An array of royalties to pay
     */
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltyAmounts
    ) internal virtual;

    /**
     * @notice Sends excess tokens back to the caller (if applicable)
     * @dev We send ETH back to the caller even when called from CollectionRouter because we do an aggregate slippage check for certain bulk swaps. (Instead of sending directly back to the router caller)
     * Excess ETH sent for one swap can then be used to help pay for the next swap.
     */
    function _refundTokenToSender(uint256 inputAmount) internal virtual;

    /**
     * @notice Sends tokens to a recipient, pays protocol fees and royalties owed
     * @param tokenRecipient The address receiving the tokens
     * @param outputAmount The amount of tokens to send
     * @param royaltiesDue An array of royalties to pay
     * @param protocolFee The protocol fee to pay
     */
    function _sendTokenOutputAndPayProtocolFees(
        ICollectionPoolFactory _factory,
        address payable tokenRecipient,
        uint256 outputAmount,
        RoyaltyDue[] memory royaltiesDue,
        uint256 protocolFee
    ) internal virtual;

    /**
     * @notice Select arbitrary NFTs from pool
     * @param _nft The address of the NFT to send
     * @param numNFTs The number of NFTs to send
     * @return tokenIds Returns numNFTs IDs or [] if insufficent
     */
    function _selectArbitraryNFTs(IERC721 _nft, uint256 numNFTs) internal virtual returns (uint256[] memory tokenIds);

    /**
     * @notice Takes NFTs from the caller and sends them into the pool's asset recipient
     * @dev This is used by the CollectionPool's swapNFTForToken function.
     * @param nftIds The specific NFT IDs to take
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     */
    function _takeNFTsFromSender(
        uint256[] calldata nftIds,
        ICollectionPoolFactory _factory,
        bool isRouter,
        address routerCaller
    ) internal virtual {
        {
            address _assetRecipient = getAssetRecipient();
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                CollectionRouter router = CollectionRouter(payable(msg.sender));

                {
                    (bool routerAllowed,) = _factory.routerStatus(router);
                    if (!routerAllowed) revert RouterNotTrusted();
                }

                IERC721 _nft = nft();
                ICollectionPoolFactory.PoolVariant variant = poolVariant();

                // Call router to pull NFTs
                // If more than 1 NFT is being transfered, do balance check instead of ownership check,
                // as pools are indifferent between NFTs from the same collection
                if (numNFTs > 1) {
                    uint256 beforeBalance = _nft.balanceOf(_assetRecipient);
                    for (uint256 i = 0; i < numNFTs;) {
                        /// @dev Variable assignment here prevents stack too deep in next line
                        uint256 nftId = nftIds[i];
                        router.poolTransferNFTFrom(_nft, routerCaller, _assetRecipient, nftId, variant);

                        unchecked {
                            ++i;
                        }
                    }
                    // Check if NFT was transferred
                    if ((_nft.balanceOf(_assetRecipient) - beforeBalance) != numNFTs) revert RouterNotTrusted();
                } else {
                    router.poolTransferNFTFrom(_nft, routerCaller, _assetRecipient, nftIds[0], variant);
                    // Check if NFT was transferred
                    if (_nft.ownerOf(nftIds[0]) != _assetRecipient) revert RouterNotTrusted();
                }

                if (_assetRecipient == address(this)) {
                    _depositNFTsNotification(nftIds);
                }
            } else {
                // Pull NFTs directly from sender
                if (_assetRecipient == address(this)) {
                    _depositNFTs(msg.sender, nftIds);
                } else {
                    TransferLib.bulkSafeTransferERC721From(nft(), msg.sender, _assetRecipient, nftIds);
                }
            }
        }
    }

    /**
     * @dev Used internally to grab pool parameters from calldata, see CollectionPoolCloner for technical details
     */
    function _immutableParamsLength() internal pure virtual returns (uint256);

    /**
     * Owner functions
     */

    /// @inheritdoc ICollectionPool
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external override onlyAuthorized {
        IERC721 _nft = nft();
        address _owner = owner();

        // If it's not the pool's NFT, just withdraw normally
        if (a != _nft) {
            TransferLib.bulkSafeTransferERC721From(a, address(this), _owner, nftIds);
        }
        // Otherwise, withdraw and also remove the ID from the ID set
        else {
            _withdrawNFTs(_owner, nftIds);

            (uint256 rawBuyPrice, uint256 rawSellPrice) = getRawBuyAndSellPrices();
            emit NFTWithdrawal(_nft, nftIds.length, rawBuyPrice, rawSellPrice);
            /// @dev No need to notify pool monitors as pool monitors own the pool,
            /// thus only the monitor can withdraw from the pool and notifications
            /// are redundant
        }
    }

    /**
     * @notice Rescues ERC1155 tokens from the pool to the owner. Only callable by the owner.
     * If somehow, the pool's nft() is an unholy amalgam of both ERC721 AND * ERC1155, even though
     * there is no good nor indeed any reason for this, and nft() is what we are withdrawing, abort
     * and advise usage of withdrawERC721 instead. Note that the transfer amount would be limited
     * to whatever nft().safeTransferFrom(from, to, id) defaults to.
     * @param a The NFT to transfer
     * @param ids The NFT ids to transfer
     * @param amounts The amounts of each id to transfer
     */
    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external onlyAuthorized {
        if (address(a) == address(nft())) revert UseWithdrawERC721Instead();

        a.safeBatchTransferFrom(address(this), owner(), ids, amounts, "");
    }

    /**
     * @notice Withdraws the accrued trade fee owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAccruedTradeFee() external virtual;

    function pausePoolSwaps() external onlyOwner {
        pause(POOL_SWAP_PAUSE);
        emit PoolSwapPause();
    }

    function unpausePoolSwaps() external onlyOwner {
        unpause(POOL_SWAP_PAUSE);
        emit PoolSwapUnpause();
    }

    /**
     * @notice Updates the selling spot price. Only callable by the owner.
     * @param newSpotPrice The new selling spot price value, in Token
     */
    function changeSpotPrice(uint128 newSpotPrice) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        if (!_bondingCurve.validateSpotPrice(newSpotPrice)) revert InvalidModification();
        if (spotPrice != newSpotPrice) {
            spotPrice = newSpotPrice;
            emit SpotPriceUpdate(newSpotPrice);
        }
    }

    /**
     * @notice Updates the delta parameter. Only callable by the owner.
     * @param newDelta The new delta parameter
     */
    function changeDelta(uint128 newDelta) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        if (!_bondingCurve.validateDelta(newDelta)) revert InvalidModification();
        if (delta != newDelta) {
            delta = newDelta;
            emit DeltaUpdate(newDelta);
        }
    }

    /**
     * @notice Updates the props parameter. Only callable by the owner.
     * @param newProps The new props parameter
     */
    function changeProps(bytes calldata newProps) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        if (!_bondingCurve.validateProps(newProps)) revert InvalidModification();
        if (keccak256(props) != keccak256(newProps)) {
            props = newProps;
            emit PropsUpdate(newProps);
        }
    }

    /**
     * @notice Updates the state parameter. Only callable by the owner.
     * @param newState The new state parameter
     */
    function changeState(bytes calldata newState) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        if (!_bondingCurve.validateState(newState)) revert InvalidModification();
        if (keccak256(state) != keccak256(newState)) {
            state = newState;
            emit StateUpdate(newState);
        }
    }

    /**
     * @notice Updates the fee taken by the LP. Only callable by the owner.
     * Only callable if the pool is a Trade pool. Reverts if the fee is >=
     * MAX_FEE.
     * @param newFee The new LP fee percentage, 18 decimals
     */
    function changeFee(uint24 newFee) external onlyOwner {
        PoolType _poolType = poolType();
        // Only trade pools can set fee. Max fee must be strictly greater too.
        if (_poolType != PoolType.TRADE || newFee >= MAX_FEE) revert InvalidModification();
        if (fee != newFee) {
            fee = newFee;
            emit FeeUpdate(newFee);
        }
    }

    /**
     * @notice Changes the address that will receive assets received from
     * trades. Only callable by the owner.
     * @param newRecipient The new asset recipient
     */
    function changeAssetRecipient(address payable newRecipient) external onlyOwner {
        PoolType _poolType = poolType();
        // Trade pools cannot set asset recipient
        if (_poolType == PoolType.TRADE) revert InvalidModification();
        if (assetRecipient != newRecipient) {
            assetRecipient = newRecipient;
            emit AssetRecipientChange(newRecipient);
        }
    }

    function changeRoyaltyNumerator(uint24 newRoyaltyNumerator)
        external
        onlyOwner
        validRoyaltyNumerator(newRoyaltyNumerator)
    {
        // Check whether the resulting combination of numerator and fallback is valid
        if (!_validRoyaltyState(newRoyaltyNumerator, royaltyRecipientFallback, nft())) revert InvalidModification();
        royaltyNumerator = newRoyaltyNumerator;
        emit RoyaltyNumeratorUpdate(newRoyaltyNumerator);
    }

    function changeRoyaltyRecipientFallback(address payable newFallback) external onlyOwner {
        if (!_validRoyaltyState(royaltyNumerator, newFallback, nft())) revert InvalidModification();
        royaltyRecipientFallback = newFallback;
        emit RoyaltyRecipientFallbackUpdate(newFallback);
    }

    /**
     * @notice Allows the pool to make arbitrary external calls to contracts
     * whitelisted by the protocol. Only callable by authorized parties.
     * @param target The contract to call
     * @param data The calldata to pass to the contract
     */
    function call(address payable target, bytes calldata data) external onlyAuthorized returns (bytes memory) {
        ICollectionPoolFactory _factory = factory();
        // Only whitelisted targets can be called
        if (!_factory.callAllowed(target)) revert CallNotAllowed();
        (bool result, bytes memory returnData) = target.call{value: 0}(data);
        if (!result) revert CallError(returnData);
        return returnData;
    }

    /**
     * @notice Allows owner to batch multiple calls, forked from: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
     * @dev Intended for withdrawing/altering pool pricing in one tx, only callable by owner, cannot change owner
     * @param calls The calldata for each call to make
     * @param revertOnFail Whether or not to revert the entire tx if any of the calls fail
     */
    function multicall(bytes[] calldata calls, bool revertOnFail)
        external
        onlyAuthorized
        returns (bytes[] memory results)
    {
        bool success;
        uint256 length = calls.length;
        results = new bytes[](length);
        for (uint256 i; i < length;) {
            (success, results[i]) = address(this).delegatecall(calls[i]);

            if (!success && revertOnFail) {
                revert(string.concat(i.toString(), ": ", _getRevertMsg(results[i])));
            }

            unchecked {
                ++i;
            }
        }

        // Prevent multicall from malicious frontend sneaking in ownership change
        if (owner() != msg.sender) revert MulticallError();
    }

    /**
     * @param _returnData The data returned from a multicall result
     * @dev Used to grab the revert string from the underlying call
     * Taken from: https://ethereum.stackexchange.com/questions/83528/how-can-i-get-the-revert-reason-of-a-call-in-solidity-so-that-i-can-use-it-in-th
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _getRoyaltiesDue(IERC721 _nft, uint256[] memory nftIds, uint256[] memory royaltyAmounts)
        private
        view
        returns (RoyaltyDue[] memory royaltiesDue)
    {
        uint256 length = royaltyAmounts.length;
        royaltiesDue = new RoyaltyDue[](length);
        bool is2981 = IERC165(_nft).supportsInterface(_INTERFACE_ID_ERC2981);
        if (royaltyNumerator != 0) {
            if (is2981) {
                for (uint256 i = 0; i < length;) {
                    // 2981 recipient, if nft is 2981 and recipient is set.
                    (address recipient2981,) = IERC2981(address(_nft)).royaltyInfo(nftIds[i], 0);
                    address recipient = getRoyaltyRecipient(payable(recipient2981));
                    royaltiesDue[i] = RoyaltyDue({amount: royaltyAmounts[i], recipient: recipient});

                    unchecked {
                        ++i;
                    }
                }
            } else {
                for (uint256 i = 0; i < length;) {
                    address recipient = getRoyaltyRecipient(payable(address(0)));
                    royaltiesDue[i] = RoyaltyDue({amount: royaltyAmounts[i], recipient: recipient});

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
     * @notice Returns true if it's valid to set the contract variables to the
     * variables passed to this function.
     */
    function _validRoyaltyState(uint256 _royaltyNumerator, address payable _royaltyRecipientFallback, IERC721 _nft)
        internal
        view
        returns (bool)
    {
        return
        // Royalties will not be paid
        (
            _royaltyNumerator == 0
            // There is a fallback so we always know where to send royaltiers or
            || _royaltyRecipientFallback != address(0)
            // Supports 2981 interface to tell us who gets royalties or
            || IERC165(_nft).supportsInterface(_INTERFACE_ID_ERC2981)
        );
    }

    function notifySwap(
        IPoolActivityMonitor.EventType eventType,
        uint256 numNFTs,
        uint256 lastSwapPrice,
        uint256 swapValue
    ) internal {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = numNFTs;
        amounts[1] = lastSwapPrice;
        amounts[2] = swapValue;

        notifyChanges(eventType, amounts);
    }

    function notifyDeposit(IPoolActivityMonitor.EventType eventType, uint256 amount) internal {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        notifyChanges(eventType, amounts);
    }

    /**
     * @dev The only limitation of this function is that contracts calling `isContract`
     * from within their constructor will have extcodesize 0 and thus return false.
     * Thus, note that this function should not be used indirectly by any contract
     * constructors
     */
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function notifyChanges(IPoolActivityMonitor.EventType eventType, uint256[] memory amounts) internal {
        if (isContract(owner())) {
            if (contractImplementsInterface(owner(), type(IPoolActivityMonitor).interfaceId)) {
                IPoolActivityMonitor(owner()).onBalancesChanged(address(this), eventType, amounts);
            }
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc ICollectionPool
    function depositNFTsNotification(uint256[] calldata nftIds) external override onlyFactory {
        _depositNFTsNotification(nftIds);

        (uint256 rawBuyPrice, uint256 rawSellPrice) = getRawBuyAndSellPrices();
        emit NFTDeposit(nft(), nftIds.length, rawBuyPrice, rawSellPrice);
        notifyDeposit(IPoolActivityMonitor.EventType.DEPOSIT_NFT, nftIds.length);
    }

    function depositNFTs(uint256[] calldata nftIds, bytes32[] calldata proof, bool[] calldata proofFlags) external {
        if (!acceptsTokenIDs(nftIds, proof, proofFlags)) revert NFTsNotAccepted();
        _depositNFTs(msg.sender, nftIds);

        (uint256 rawBuyPrice, uint256 rawSellPrice) = getRawBuyAndSellPrices();
        emit NFTDeposit(nft(), nftIds.length, rawBuyPrice, rawSellPrice);

        notifyDeposit(IPoolActivityMonitor.EventType.DEPOSIT_NFT, nftIds.length);
    }

    /**
     * @dev Deposit NFTs from given address. NFT IDs must have been validated against the filter.
     */
    function _depositNFTs(address from, uint256[] calldata nftIds) internal virtual;

    /**
     * @dev Used to indicate deposited NFTs.
     */
    function _depositNFTsNotification(uint256[] calldata nftIds) internal virtual;

    /**
     * @notice Sends specific NFTs to a recipient address
     * @param to The receiving address for the NFTs
     * @param nftIds The specific IDs of NFTs to send
     */
    function _withdrawNFTs(address to, uint256[] memory nftIds) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";

library CollectionPoolCloner {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function cloneETHPool(
        address implementation,
        ICollectionPoolFactory factory,
        ICurve bondingCurve,
        IERC721 nft,
        uint8 poolType
    ) internal returns (address instance) {
        uint256 blockNumber = block.number;

        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (9 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 09
            // runtime size = 76
            // 60 runtime  | PUSH1 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
            // f3          | RETURN                |                         | [0-runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes of code + 65 bytes of extra data = 118 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 41
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 3d          | RETURNDATASIZE        | 0 0                     | –
            // 3d          | RETURNDATASIZE        | 0 0 0                   | –
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
            // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
            // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
            // 60 extra    | PUSH1 extra           | extra 0 0 0 0           | [0, cds) = calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 extra 0 0 0 0      | [0, cds) = calldata // 0x35 (53) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x35 extra 0 0 0 0  | [0, cds) = calldata
            // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x35) = extraData
            mstore(
                ptr,
                hex"60_76_3d_81_60_09_3d_39_f3_3d_3d_3d_3d_36_3d_3d_37_60_41_60_35_36_39_36_60_41_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
            // 60 0x33     | PUSH1 0x33            | 0x33 sucess 0 rds       | [0, rds) = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
            // fd          | REVERT                | –                       | [0, rds) = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
            // f3          | RETURN                | –                       | [0, rds) = return data
            mstore(
                add(ptr, 0x31),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (65 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x3e), shl(0x60, factory))
            mstore(add(ptr, 0x52), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x66), shl(0x60, nft))
            mstore8(add(ptr, 0x7a), poolType)
            mstore(add(ptr, 0x7b), shl(0xe0, blockNumber)) // lower 32 bits only

            instance := create(0, ptr, 0x7f)
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function cloneERC20Pool(
        address implementation,
        ICollectionPoolFactory factory,
        ICurve bondingCurve,
        IERC721 nft,
        uint8 poolType,
        ERC20 token
    ) internal returns (address instance) {
        uint256 blockNumber = block.number;

        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (9 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 09
            // runtime size = 8a
            // 60 runtime  | PUSH1 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
            // f3          | RETURN                |                         | [0-runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes of code + 85 bytes of extra data = 138 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 55
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 3d          | RETURNDATASIZE        | 0 0                     | –
            // 3d          | RETURNDATASIZE        | 0 0 0                   | –
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
            // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
            // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
            // 60 extra    | PUSH1 extra           | extra 0 0 0 0           | [0, cds) = calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 extra 0 0 0 0      | [0, cds) = calldata // 0x35 (53) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x35 extra 0 0 0 0  | [0, cds) = calldata
            // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x35) = extraData
            mstore(
                ptr,
                hex"60_8a_3d_81_60_09_3d_39_f3_3d_3d_3d_3d_36_3d_3d_37_60_55_60_35_36_39_36_60_55_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
            // 60 0x33     | PUSH1 0x33            | 0x33 sucess 0 rds       | [0, rds) = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
            // fd          | REVERT                | –                       | [0, rds) = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
            // f3          | RETURN                | –                       | [0, rds) = return data
            mstore(
                add(ptr, 0x31),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (85 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x3e), shl(0x60, factory))
            mstore(add(ptr, 0x52), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x66), shl(0x60, nft))
            mstore8(add(ptr, 0x7a), poolType)
            mstore(add(ptr, 0x7b), shl(0xe0, blockNumber)) // lower 32 bits only
            mstore(add(ptr, 0x7f), shl(0x60, token))

            instance := create(0, ptr, 0x93)
        }
    }

    /**
     * @notice Checks if a contract is a clone of a CollectionPoolETH.
     * @dev Only checks the runtime bytecode, does not check the extra data.
     * @param factory the factory that deployed the clone
     * @param implementation the CollectionPoolETH implementation contract
     * @param query the contract to check
     * @return result True if the contract is a clone, false otherwise
     */
    function isETHPoolClone(
        address factory,
        address implementation,
        address query
    ) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"3d_3d_3d_3d_36_3d_3d_37_60_41_60_35_36_39_36_60_41_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x35), shl(0x60, factory))

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x49)
            extcodecopy(query, other, 0, 0x49)
            result := and(
                eq(mload(ptr), mload(other)),
                and(
                    eq(mload(add(ptr, 0x20)), mload(add(other, 0x20))),
                    eq(mload(add(ptr, 0x29)), mload(add(other, 0x29)))
                )
            )
        }
    }

    /**
     * @notice Checks if a contract is a clone of a CollectionPoolERC20.
     * @dev Only checks the runtime bytecode, does not check the extra data.
     * @param implementation the CollectionPoolERC20 implementation contract
     * @param query the contract to check
     * @return result True if the contract is a clone, false otherwise
     */
    function isERC20PoolClone(
        address factory,
        address implementation,
        address query
    ) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"3d_3d_3d_3d_36_3d_3d_37_60_55_60_35_36_39_36_60_55_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x35), shl(0x60, factory))

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x49)
            extcodecopy(query, other, 0, 0x49)
            result := and(
                eq(mload(ptr), mload(other)),
                and(
                    eq(mload(add(ptr, 0x20)), mload(add(other, 0x20))),
                    eq(mload(add(ptr, 0x29)), mload(add(other, 0x29)))
                )
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {IPoolActivityMonitor} from "./IPoolActivityMonitor.sol";

/**
 * @title An NFT/Token pool where the token is an ERC20
 * @author Collection
 */
abstract contract CollectionPoolERC20 is CollectionPool {
    using SafeTransferLib for ERC20;

    error ReceivedETH();
    error UnallowedRouter(CollectionRouter router);
    error RouterDidNotSend(uint256 recipientBalanceDifference, uint256 expected);
    error InsufficientERC20Liquidity(uint256 liquidity, uint256 required);

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 85;

    /**
     * @notice Returns the ERC20 token associated with the pool
     * @dev See CollectionPoolCloner for an explanation on how this works
     */
    function token() public pure returns (ERC20 _token) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _token := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 65)))
        }
    }

    /// @inheritdoc ICollectionPool
    function liquidity() public view returns (uint256) {
        uint256 _balance = token().balanceOf(address(this));
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_balance < _accruedTradeFee) revert InsufficientLiquidity(_balance, _accruedTradeFee);

        return _balance - _accruedTradeFee;
    }

    /// @inheritdoc CollectionPool
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltiesDue
    ) internal override {
        if (msg.value != 0) revert ReceivedETH();

        ERC20 _token = token();
        ICollectionPoolFactory.PoolVariant variant = poolVariant();

        uint256 totalRoyaltiesPaid;
        uint256 royaltiesSentToFactory;

        if (isRouter) {
            // Verify if router is allowed
            CollectionRouter router = CollectionRouter(payable(msg.sender));

            (bool routerAllowed,) = _factory.routerStatus(router);
            if (!routerAllowed) revert UnallowedRouter(router);

            // Pay royalties first to obtain total amount of royalties paid
            (totalRoyaltiesPaid, royaltiesSentToFactory) = _payRoyaltiesAndProtocolFee(
                _factory, royaltiesDue, protocolFee, routerCaller, isRouter, router, variant
            );

            // Cache state and then call router to transfer tokens from user
            address _assetRecipient = getAssetRecipient();
            uint256 amountToAssetRecipient = inputAmount - protocolFee - royaltiesSentToFactory;
            sendTokenWithRouter(router, _token, routerCaller, _assetRecipient, amountToAssetRecipient, variant);
        } else {
            // Pay royalties first to obtain total amount of royalties paid
            (, royaltiesSentToFactory) = _payRoyaltiesAndProtocolFee(
                _factory,
                royaltiesDue,
                protocolFee,
                msg.sender,
                isRouter,
                CollectionRouter(payable(address(0))),
                variant
            );

            // Transfer tokens directly
            _token.safeTransferFrom(msg.sender, getAssetRecipient(), inputAmount - protocolFee - royaltiesSentToFactory);
        }
    }

    /// @inheritdoc CollectionPool
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Do nothing since we transferred the exact input amount
    }

    /// @inheritdoc CollectionPool
    function _sendTokenOutputAndPayProtocolFees(
        ICollectionPoolFactory _factory,
        address payable tokenRecipient,
        uint256 outputAmount,
        RoyaltyDue[] memory royaltiesDue,
        uint256 protocolFee
    ) internal override {
        ERC20 _token = token();

        /// @dev Pay royalties
        _payRoyaltiesAndProtocolFee(
            _factory,
            royaltiesDue,
            protocolFee,
            address(this),
            false,
            CollectionRouter(payable(address(0))),
            poolVariant()
        );

        /// @dev Send tokens to caller
        if (outputAmount > 0) {
            uint256 funds = liquidity();
            if (funds < outputAmount) revert InsufficientERC20Liquidity(funds, outputAmount);
            _token.safeTransfer(tokenRecipient, outputAmount);
        }
    }

    /**
     * @notice Pay royalties to the factory, which should never revert. The factory
     * serves as a single contract to which royalty recipients can make a single
     * transaction to receive all royalties due as opposed to having to send
     * transactions to arbitrary numbers of pools
     *
     * @dev For NFTs whose royalty recipients resolve to this contract, no royalties
     * are sent for them. This is to prevent royalties from becoming trapped in
     * the factory as pools do not have a function to withdraw royalties
     *
     * @return totalRoyaltiesPaid The amount of royalties which were paid including
     * royalties whose resolved recipient is this contract itself
     * @return royaltiesSentToFactory `totalRoyaltiesPaid` less the amount whose
     * resolved recipient is this contract itself
     */
    function _payRoyaltiesAndProtocolFee(
        ICollectionPoolFactory _factory,
        RoyaltyDue[] memory royaltiesDue,
        uint256 protocolFee,
        address tokenSender,
        bool isRouter,
        CollectionRouter router,
        ICollectionPoolFactory.PoolVariant poolVariant
    ) internal returns (uint256 totalRoyaltiesPaid, uint256 royaltiesSentToFactory) {
        ERC20 _token = token();
        /// @dev Local scope to prevent stack too deep
        {
            uint256 length = royaltiesDue.length;
            for (uint256 i = 0; i < length;) {
                uint256 royaltyAmount = royaltiesDue[i].amount;
                totalRoyaltiesPaid += royaltyAmount;
                if (royaltyAmount > 0) {
                    address finalRecipient = getRoyaltyRecipient(payable(royaltiesDue[i].recipient));
                    if (finalRecipient != address(this)) {
                        royaltiesSentToFactory += royaltyAmount;
                        royaltiesDue[i].recipient = finalRecipient;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }

        uint256 amountToSend = royaltiesSentToFactory + protocolFee;

        if (isRouter) {
            sendTokenWithRouter(router, _token, tokenSender, address(_factory), amountToSend, poolVariant);
        } else {
            /// @dev If tokens are being sent from this pool, just use safeTransfer
            /// to avoid making an approve call
            if (tokenSender == address(this)) {
                _token.safeTransfer(address(_factory), amountToSend);
            } else {
                _token.safeTransferFrom(tokenSender, address(_factory), amountToSend);
            }
        }

        _factory.depositRoyaltiesNotification(_token, royaltiesDue, poolVariant);
    }

    /// @inheritdoc CollectionPool
    // @dev see CollectionPoolCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
     * @dev Deposit ERC20s into pool
     */
    function depositERC20(ERC20 a, uint256 amount) external {
        a.safeTransferFrom(msg.sender, address(this), amount);
        _depositERC20Notification(a, amount);
    }

    /**
     * @notice Used by factory to notify pools of deposits initiated on the factory
     * side
     */
    function depositERC20Notification(ERC20 a, uint256 amount) external onlyFactory {
        _depositERC20Notification(a, amount);
    }

    function _depositERC20Notification(ERC20 a, uint256 amount) internal {
        if (a == token()) {
            emit TokenDeposit(nft(), a, amount);
            notifyDeposit(IPoolActivityMonitor.EventType.DEPOSIT_TOKEN, amount);
        }
    }

    /**
     * @notice Withdraws all pool token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAllERC20() external onlyAuthorized {
        uint256 _accruedTradeFee = accruedTradeFee;
        accruedTradeFee = 0;

        ERC20 _token = token();
        uint256 amount = _token.balanceOf(address(this));
        _token.safeTransfer(owner(), amount);

        if (_accruedTradeFee >= amount) {
            _accruedTradeFee = amount;
            amount = 0;
        } else {
            amount -= _accruedTradeFee;
        }

        // emit event since it is the pool token
        IERC721 _nft = nft();
        emit TokenWithdrawal(_nft, _token, amount);
        emit AccruedTradeFeeWithdrawal(_nft, _token, _accruedTradeFee);
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC20(ERC20 a, uint256 amount) external onlyAuthorized {
        if (a == token()) {
            uint256 funds = liquidity();
            if (funds < amount) revert InsufficientERC20Liquidity(funds, amount);

            // emit event since it is the pool token
            emit TokenWithdrawal(nft(), a, amount);
        }

        a.safeTransfer(owner(), amount);
    }

    /// @inheritdoc CollectionPool
    function withdrawAccruedTradeFee() external override onlyOwner {
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_accruedTradeFee > 0) {
            accruedTradeFee = 0;

            ERC20 _token = token();
            _token.safeTransfer(msg.sender, _accruedTradeFee);

            // emit event since it is the pool token
            emit AccruedTradeFeeWithdrawal(nft(), _token, _accruedTradeFee);
        }
    }

    /**
     * @notice Helper function that uses a router to send tokens and check that
     * the tokens were actually transferred
     */
    function sendTokenWithRouter(
        CollectionRouter router,
        ERC20 _token,
        address from,
        address to,
        uint256 amount,
        ICollectionPoolFactory.PoolVariant variant
    ) internal {
        uint256 beforeBalance = _token.balanceOf(to);
        router.poolTransferERC20From(_token, from, to, amount, variant);
        uint256 balanceDifference = _token.balanceOf(to) - beforeBalance;
        if (balanceDifference != amount) {
            revert RouterDidNotSend(balanceDifference, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// Forked from OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol), 
// to use a custom error

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    error Reentrancy();

    function __ReentrancyGuard_init() internal {
      _status = _NOT_ENTERED;
    } 

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if (_status == _ENTERED) revert Reentrancy();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * A helper library for common transfer methods such as transferring multiple token ids of the same collection, or multiple single token id of one collection.
 */
library TransferLib {
    using SafeERC20 for IERC20;

    /**
     * @notice Safe transfer N token ids of 1 ERC721
     */
    function bulkSafeTransferERC721From(IERC721 token, address from, address to, uint256[] calldata tokenIds)
        internal
    {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length;) {
            token.safeTransferFrom(from, to, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";

contract CollectionRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    struct PoolSwapAny {
        CollectionPool pool;
        uint256 numItems;
    }

    struct PoolSwapSpecific {
        CollectionPool pool;
        uint256[] nftIds;
        bytes32[] proof;
        bool[] proofFlags;
        /// @dev only used for selling into pools
        bytes externalFilterContext;
    }

    struct RobustPoolSwapAny {
        PoolSwapAny swapInfo;
        uint256 maxCost;
    }

    struct RobustPoolSwapSpecific {
        PoolSwapSpecific swapInfo;
        uint256 maxCost;
    }

    struct RobustPoolSwapSpecificForToken {
        PoolSwapSpecific swapInfo;
        uint256 minOutput;
    }

    struct NFTsForAnyNFTsTrade {
        PoolSwapSpecific[] nftToTokenTrades;
        PoolSwapAny[] tokenToNFTTrades;
    }

    struct NFTsForSpecificNFTsTrade {
        PoolSwapSpecific[] nftToTokenTrades;
        PoolSwapSpecific[] tokenToNFTTrades;
    }

    struct RobustPoolNFTsFoTokenAndTokenforNFTsTrade {
        RobustPoolSwapSpecific[] tokenToNFTTrades;
        RobustPoolSwapSpecificForToken[] nftToTokenTrades;
        uint256 inputAmount;
        address payable tokenRecipient;
        address nftRecipient;
    }

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    ICollectionPoolFactory public immutable factory;

    constructor(ICollectionPoolFactory _factory) {
        factory = _factory;
    }

    /**
     * ETH swaps
     */

    /**
     * @notice Swaps ETH into NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent ETH amount
     */
    function swapETHForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapETHForAnyNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
     * @notice Swaps ETH into specific NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent ETH amount
     */
    function swapETHForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapETHForSpecificNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * ETH as the intermediary.
     * @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
     * @param minOutput The minimum acceptable total excess ETH received
     * @param ethRecipient The address that will receive the ETH output
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH received
     */
    function swapNFTsForAnyNFTsThroughETH(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(address(this)));

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for any NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForAnyNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, ethRecipient, nftRecipient) + minOutput;
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * ETH as the intermediary.
     * @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
     * @param minOutput The minimum acceptable total excess ETH received
     * @param ethRecipient The address that will receive the ETH output
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH received
     */
    function swapNFTsForSpecificNFTsThroughETH(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(address(this)));

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for specific NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount = _swapETHForSpecificNFTs(
            trade.tokenToNFTTrades, outputAmount - minOutput, ethRecipient, nftRecipient
        ) + minOutput;
    }

    /**
     * ERC20 swaps
     *
     * Note: All ERC20 swaps assume that a single ERC20 token is used for all the pools involved.
     * Swapping using multiple tokens in the same transaction is possible, but the slippage checks
     * & the return values will be meaningless, and may lead to undefined behavior.
     *
     * Note: The sender should ideally grant infinite token approval to the router in order for NFT-to-NFT
     * swaps to work smoothly.
     */

    /**
     * @notice Swaps ERC20 tokens into NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function swapERC20ForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForAnyNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
     * @notice Swaps ERC20 tokens into specific NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function swapERC20ForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForSpecificNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
     * @notice Swaps NFTs into ETH/ERC20 using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to sell to each.
     * @param minOutput The minimum acceptable total tokens received
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total tokens received
     */
    function swapNFTsForToken(
        PoolSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        return _swapNFTsForToken(swapList, minOutput, payable(tokenRecipient));
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * an ERC20 token as the intermediary.
     * @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param minOutput The minimum acceptable total excess tokens received
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForAnyNFTsThroughERC20(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(msg.sender));

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for any NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount = _swapERC20ForAnyNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, nftRecipient) + minOutput;
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * an ERC20 token as the intermediary.
     * @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param minOutput The minimum acceptable total excess tokens received
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForSpecificNFTsThroughERC20(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(msg.sender));

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for specific NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForSpecificNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, nftRecipient) + minOutput;
    }

    /**
     * Robust Swaps
     * These are "robust" versions of the NFT<>Token swap functions which will never revert due to slippage
     * Instead, users specify a per-swap max cost. If the price changes more than the user specifies, no swap is attempted. This allows users to specify a batch of swaps, and execute as many of them as possible.
     */

    /**
     * @dev We assume msg.value >= sum of values in maxCostPerPool
     * @notice Swaps as much ETH for any NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapETHForAnyNFTs(
        RobustPoolSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = msg.value;

        // Try doing each swap
        uint256 poolCost;
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (,, poolCost,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.numItems);

            // If within our maxCost, proceed
            if (poolCost <= swapList[i].maxCost) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForAnyNFTs{value: poolCost}(
                    swapList[i].swapInfo.numItems, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @dev We assume msg.value >= sum of values in maxCostPerPool
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapETHForSpecificNFTs(
        RobustPoolSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) public payable virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = msg.value;
        uint256 poolCost;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (,, poolCost,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.nftIds.length);

            // If within our maxCost, proceed
            if (poolCost <= swapList[i].maxCost) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForSpecificNFTs{value: poolCost}(
                    swapList[i].swapInfo.nftIds, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Swaps as many ERC20 tokens for any NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForAnyNFTs(
        RobustPoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (,, poolCost,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.numItems);

            // If within our maxCost, proceed
            if (poolCost <= swapList[i].maxCost) {
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForAnyNFTs(
                    swapList[i].swapInfo.numItems, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps as many ERC20 tokens for specific NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     *
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForSpecificNFTs(
        RobustPoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (,, poolCost,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.nftIds.length);

            // If within our maxCost, proceed
            if (poolCost <= swapList[i].maxCost) {
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForSpecificNFTs(
                    swapList[i].swapInfo.nftIds, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps as many NFTs for tokens as possible, respecting the per-swap min output
     * @param swapList The list of pools to trade with and the IDs of the NFTs to sell to each.
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH/ERC20 received
     */
    function robustSwapNFTsForToken(
        RobustPoolSwapSpecificForToken[] calldata swapList,
        address payable tokenRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 outputAmount) {
        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            PoolSwapSpecific calldata swapInfo = swapList[i].swapInfo;
            // Locally scoped to avoid stack too deep error
            {
                try swapInfo.pool.getSellNFTQuote(swapInfo.nftIds.length) returns (
                    ICurve.Params memory, uint256, uint256 poolOutput, ICurve.Fees memory
                ) {
                    // If at least equal to our minOutput, proceed
                    if (poolOutput >= swapList[i].minOutput) {
                        // Do the swap and update outputAmount with how many tokens we got
                        outputAmount += swapInfo.pool.swapNFTsForToken(
                            ICollectionPool.NFTs(swapInfo.nftIds, swapInfo.proof, swapInfo.proofFlags),
                            0,
                            tokenRecipient,
                            true,
                            msg.sender,
                            swapInfo.externalFilterContext
                        );
                    }
                } catch {}

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Buys NFTs with ETH and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNFTSwapList The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapETHForSpecificNFTsAndNFTsToToken(RobustPoolNFTsFoTokenAndTokenforNFTsTrade calldata params)
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = msg.value;
            uint256 poolCost;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Calculate actual cost per swap
                (,, poolCost,) = params.tokenToNFTTrades[i].swapInfo.pool.getBuyNFTQuote(
                    params.tokenToNFTTrades[i].swapInfo.nftIds.length
                );

                // If within our maxCost, proceed
                if (poolCost <= params.tokenToNFTTrades[i].maxCost) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    remainingValue -= params.tokenToNFTTrades[i].swapInfo.pool.swapTokenForSpecificNFTs{value: poolCost}(
                        params.tokenToNFTTrades[i].swapInfo.nftIds, poolCost, params.nftRecipient, true, msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }

            // Return remaining value to sender
            if (remainingValue > 0) {
                params.tokenRecipient.safeTransferETH(remainingValue);
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Locally scoped to avoid stack too deep error
                {
                    try params.nftToTokenTrades[i].swapInfo.pool.getSellNFTQuote(
                        params.nftToTokenTrades[i].swapInfo.nftIds.length
                    ) returns (ICurve.Params memory, uint256, uint256 poolOutput, ICurve.Fees memory) {
                        // If at least equal to our minOutput, proceed
                        if (poolOutput >= params.nftToTokenTrades[i].minOutput) {
                            // Do the swap and update outputAmount with how many tokens we got
                            outputAmount += params.nftToTokenTrades[i].swapInfo.pool.swapNFTsForToken(
                                ICollectionPool.NFTs(
                                    params.nftToTokenTrades[i].swapInfo.nftIds,
                                    params.nftToTokenTrades[i].swapInfo.proof,
                                    params.nftToTokenTrades[i].swapInfo.proofFlags
                                ),
                                0,
                                params.tokenRecipient,
                                true,
                                msg.sender,
                                params.nftToTokenTrades[i].swapInfo.externalFilterContext
                            );
                        }
                    } catch {}

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
     * @notice Buys NFTs with ERC20, and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNFTSwapList The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapERC20ForSpecificNFTsAndNFTsToToken(RobustPoolNFTsFoTokenAndTokenforNFTsTrade calldata params)
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = params.inputAmount;
            uint256 poolCost;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Calculate actual cost per swap
                (,, poolCost,) = params.tokenToNFTTrades[i].swapInfo.pool.getBuyNFTQuote(
                    params.tokenToNFTTrades[i].swapInfo.nftIds.length
                );

                // If within our maxCost, proceed
                if (poolCost <= params.tokenToNFTTrades[i].maxCost) {
                    remainingValue -= params.tokenToNFTTrades[i].swapInfo.pool.swapTokenForSpecificNFTs(
                        params.tokenToNFTTrades[i].swapInfo.nftIds, poolCost, params.nftRecipient, true, msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Locally scoped to avoid stack too deep error
                {
                    try params.nftToTokenTrades[i].swapInfo.pool.getSellNFTQuote(
                        params.nftToTokenTrades[i].swapInfo.nftIds.length
                    ) returns (ICurve.Params memory, uint256, uint256 poolOutput, ICurve.Fees memory) {
                        // If at least equal to our minOutput, proceed
                        if (poolOutput >= params.nftToTokenTrades[i].minOutput) {
                            // Do the swap and update outputAmount with how many tokens we got
                            outputAmount += params.nftToTokenTrades[i].swapInfo.pool.swapNFTsForToken(
                                ICollectionPool.NFTs(
                                    params.nftToTokenTrades[i].swapInfo.nftIds,
                                    params.nftToTokenTrades[i].swapInfo.proof,
                                    params.nftToTokenTrades[i].swapInfo.proofFlags
                                ),
                                0,
                                params.tokenRecipient,
                                true,
                                msg.sender,
                                params.nftToTokenTrades[i].swapInfo.externalFilterContext
                            );
                        }
                    } catch {}

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    receive() external payable {}

    /**
     * Restricted functions
     */

    /**
     * @dev Allows an ERC20 pool contract to transfer ERC20 tokens directly from
     * the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pool.
     * @param token The ERC20 token to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferERC20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount,
        ICollectionPoolFactory.PoolVariant variant
    ) external {
        // verify caller is a trusted pool contract
        require(factory.isPoolVariant(msg.sender, variant), "Not pool");

        // verify caller is an ERC20 pool
        require(
            variant == ICollectionPoolFactory.PoolVariant.ENUMERABLE_ERC20
                || variant == ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ERC20,
            "Not ERC20 pool"
        );

        // transfer tokens to pool
        token.safeTransferFrom(from, to, amount);
    }

    /**
     * @dev Allows a pool contract to transfer ERC721 NFTs directly from
     * the sender, in order to minimize the number of token transfers. Only callable by a pool.
     * @param nft The ERC721 NFT to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param id The ID of the NFT to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferNFTFrom(
        IERC721 nft,
        address from,
        address to,
        uint256 id,
        ICollectionPoolFactory.PoolVariant variant
    ) external {
        // verify caller is a trusted pool contract
        require(factory.isPoolVariant(msg.sender, variant), "Not pool");

        // transfer NFTs to pool
        nft.safeTransferFrom(from, to, id);
    }

    /**
     * Internal functions
     */

    /**
     * @param deadline The last valid time for a swap
     */
    function _checkDeadline(uint256 deadline) internal view {
        require(block.timestamp <= deadline, "Deadline passed");
    }

    /**
     * @notice Internal function used to swap ETH for any NFTs
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ETH to send
     * @param ethRecipient The address receiving excess ETH
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapETHForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 poolCost;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (,, poolCost,) = swapList[i].pool.getBuyNFTQuote(swapList[i].numItems);

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForAnyNFTs{value: poolCost}(
                swapList[i].numItems, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Internal function used to swap ETH for a specific set of NFTs
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ETH to send
     * @param ethRecipient The address receiving excess ETH
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapETHForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 poolCost;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (,, poolCost,) = swapList[i].pool.getBuyNFTQuote(swapList[i].nftIds.length);

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForSpecificNFTs{value: poolCost}(
                swapList[i].nftIds, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Internal function used to swap an ERC20 token for any NFTs
     * @dev Note that we don't need to query the pool's bonding curve first for pricing data because
     * we just calculate and take the required amount from the caller during swap time.
     * However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
     * to figure out how much the router should send to the pool.
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ERC20 tokens to send
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapERC20ForAnyNFTs(PoolSwapAny[] calldata swapList, uint256 inputAmount, address nftRecipient)
        internal
        virtual
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForAnyNFTs(
                swapList[i].numItems, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function used to swap an ERC20 token for specific NFTs
     * @dev Note that we don't need to query the pool's bonding curve first for pricing data because
     * we just calculate and take the required amount from the caller during swap time.
     * However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
     * to figure out how much the router should send to the pool.
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ERC20 tokens to send
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapERC20ForSpecificNFTs(PoolSwapSpecific[] calldata swapList, uint256 inputAmount, address nftRecipient)
        internal
        virtual
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForSpecificNFTs(
                swapList[i].nftIds, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps NFTs for tokens, designed to be used for 1 token at a time
     * @dev Calling with multiple tokens is permitted, BUT minOutput will be
     * far from enough of a safety check because different tokens almost certainly have different unit prices.
     * @param swapList The list of pools and swap calldata
     * @param minOutput The minimum number of tokens to be receieved from the swaps
     * @param tokenRecipient The address that receives the tokens
     * @return outputAmount The number of tokens to be received
     */
    function _swapNFTsForToken(PoolSwapSpecific[] calldata swapList, uint256 minOutput, address payable tokenRecipient)
        internal
        virtual
        returns (uint256 outputAmount)
    {
        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            outputAmount += swapList[i].pool.swapNFTsForToken(
                ICollectionPool.NFTs(swapList[i].nftIds, swapList[i].proof, swapList[i].proofFlags),
                0,
                tokenRecipient,
                true,
                msg.sender,
                swapList[i].externalFilterContext
            );

            unchecked {
                ++i;
            }
        }

        // Aggregate slippage check
        require(outputAmount >= minOutput, "outputAmount too low");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {ITokenIDFilter} from "../filter/ITokenIDFilter.sol";
import {IExternalFilter} from "../filter/IExternalFilter.sol";

interface ICollectionPool is ITokenIDFilter {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    /**
     * @param ids The list of IDs of the NFTs to sell to the pool
     * @param proof Merkle multiproof proving list is allowed by pool
     * @param proofFlags Merkle multiproof flags for proof
     */
    struct NFTs {
        uint256[] ids;
        bytes32[] proof;
        bool[] proofFlags;
    }

    function bondingCurve() external view returns (ICurve);

    function curveParams() external view returns (ICurve.Params memory params);

    /**
     * @notice Only tracked IDs are returned
     */
    function getAllHeldIds() external view returns (uint256[] memory);

    function poolVariant() external view returns (ICollectionPoolFactory.PoolVariant);

    function fee() external view returns (uint24);

    function nft() external view returns (IERC721);

    function poolType() external view returns (PoolType);

    function royaltyNumerator() external view returns (uint24);

    function poolSwapsPaused() external view returns (bool);

    function externalFilter() external view returns (IExternalFilter);

    /**
     * @notice The usable balance of the pool. This is the amount the pool needs to have to buy NFTs and pay out royalties.
     */
    function liquidity() external view returns (uint256);

    function balanceToFulfillSellNFT(uint256 numNFTs) external view returns (uint256 balance);

    /**
     * @notice Rescues a specified set of NFTs owned by the pool to the owner address. (onlyOwnable modifier is in the implemented function)
     * @dev If the NFT is the pool's collection, we also remove it from the id tracking
     * @param a The NFT to transfer
     * @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    /**
     * @notice Rescues ERC20 tokens from the pool to the owner. Only callable by the owner (onlyOwnable modifier is in the implemented function).
     * @param a The token to transfer
     * @param amount The amount of tokens to send to the owner
     */
    function withdrawERC20(ERC20 a, uint256 amount) external;

    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external;

    function getSellNFTQuote(uint256 numNFTs)
        external
        view
        returns (ICurve.Params memory newParams, uint256 totalAmount, uint256 outputAmount, ICurve.Fees memory fees);

    /**
     * @dev Deposit NFTs into pool and emit event for indexing.
     */
    function depositNFTs(uint256[] calldata ids, bytes32[] calldata proof, bool[] calldata proofFlags) external;

    /**
     * @dev Used by factory to indicate deposited NFTs.
     * @dev Must only be called by factory. NFT IDs must have been validated against the filter.
     */
    function depositNFTsNotification(uint256[] calldata nftIds) external;

    /**
     * @dev Used by factory to indicate deposited ERC20 tokens.
     * @dev Must only be called by factory.
     */
    function depositERC20Notification(ERC20 a, uint256 amount) external;

    /**
     * @notice Returns number of NFTs in pool that matches filter
     */
    function NFTsCount() external view returns (uint256);

    /**
     * @notice Sets NFT token ID filter to allow only some NFTs into this pool. Pool must be empty
     * to call this function. This filter is checked on deposits and swapping NFTs into the pool.
     * Selling into the pool may require an additional check (see `setExternalFilter`).
     * @param merkleRoot Merkle root representing all allowed IDs
     * @param encodedTokenIDs Opaque encoded list of token IDs
     */
    function setTokenIDFilter(bytes32 merkleRoot, bytes calldata encodedTokenIDs) external;

    /**
     * @notice Checks if list of NFTs are allowed in this pool using Merkle multiproof and flags
     * @param tokenIDs List of NFT IDs
     * @param proof Merkle multiproof
     * @param proofFlags Merkle multiproof flags
     */
    function acceptsTokenIDs(uint256[] calldata tokenIDs, bytes32[] calldata proof, bool[] calldata proofFlags)
        external
        view
        returns (bool);

    /**
     * @notice Sets an external contract that is consulted before any NFT is swapped into the pool.
     * Typically used to implement dynamic blocklists. Because it is dynamic, deposits are not
     * checked. See also `setTokenIDFilter`.
     */
    function setExternalFilter(address provider) external;

    /**
     * @notice Called during pool creation to set initial parameters
     * @dev Only called once by factory to initialize.
     * We verify this by making sure that the current owner is address(0).
     * The Ownable library we use disallows setting the owner to be address(0), so this condition
     * should only be valid before the first initialize call.
     * @param _assetRecipient The address that will receive the TOKEN or NFT sent to this pool during swaps.
     * NOTE: If set to address(0), they will go to the pool itself.
     * @param _delta The initial delta of the bonding curve
     * @param _fee The initial % fee taken, if this is a trade pool
     * @param _spotPrice The initial price to sell an asset into the pool
     * @param _royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e6
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient fallback is set.
     * @param _royaltyRecipientFallback An address to which all royalties will be paid to if not address(0).
     * This is a fallback to ERC2981 royalties set by the NFT creator, and allows sending royalties to
     * arbitrary addresses if a collection does not support ERC2981.
     */
    function initialize(
        address payable _assetRecipient,
        uint128 _delta,
        uint24 _fee,
        uint128 _spotPrice,
        bytes calldata _props,
        bytes calldata _state,
        uint24 _royaltyNumerator,
        address payable _royaltyRecipientFallback
    ) external payable;

    /**
     * @notice Sends token to the pool in exchange for any `numNFTs` NFTs
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
     * This swap function is meant for users who are ID agnostic
     * @dev The nonReentrant modifier is in swapTokenForSpecificNFTs
     * @param numNFTs The number of NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient The recipient of the NFTs
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable returns (uint256 inputAmount);

    /**
     * @dev Used as read function to query the bonding curve for buy pricing info
     * @param numNFTs The number of NFTs to buy from the pool
     */
    function getBuyNFTQuote(uint256 numNFTs)
        external
        view
        returns (ICurve.Params memory newParams, uint256 totalAmount, uint256 inputAmount, ICurve.Fees memory fees);

    /**
     * @notice Updates the fee taken by the LP. Only callable by the owner.
     * Only callable if the pool is a Trade pool. Reverts if the fee is >=
     * MAX_FEE.
     * @param newFee The new LP fee percentage, 18 decimals
     */
    function changeFee(uint24 newFee) external;

    /**
     * @notice Sends a set of NFTs to the pool in exchange for token. Token must be allowed by
     * filters, see `setTokenIDFilter` and `setExternalFilter`.
     * @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
     * @param nfts The list of IDs of the NFTs to sell to the pool along with its Merkle multiproof.
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param tokenRecipient The recipient of the token output
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        ICollectionPool.NFTs calldata nfts,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller,
        bytes calldata externalFilterContext
    ) external returns (uint256 outputAmount);
}

interface ICollectionPoolETH is ICollectionPool {
    function withdrawAllETH() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {IExternalFilter} from "../filter/IExternalFilter.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";

interface ICollectionPoolFactory is IERC721 {
    enum PoolVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    struct LPTokenParams721 {
        address nftAddress;
        address bondingCurveAddress;
        address tokenAddress;
        address payable poolAddress;
        uint24 fee;
        uint128 delta;
        uint24 royaltyNumerator;
    }

    /**
     * @param merkleRoot Merkle root for NFT ID filter
     * @param encodedTokenIDs Encoded list of acceptable NFT IDs
     * @param initialProof Merkle multiproof for initial NFT IDs
     * @param initialProofFlags Merkle multiproof flags for initial NFT IDs
     * @param externalFilter Address implementing IExternalFilter for external filtering
     */
    struct NFTFilterParams {
        bytes32 merkleRoot;
        bytes encodedTokenIDs;
        bytes32[] initialProof;
        bool[] initialProofFlags;
        IExternalFilter externalFilter;
    }

    /**
     * @notice Creates a pool contract using EIP-1167.
     * @param nft The NFT contract of the collection the pool trades
     * @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
     * @param assetRecipient The address that will receive the assets traders give during trades.
     * If set to address(0), assets will be sent to the pool address. Not available to TRADE pools.
     * @param receiver Receiver of the LP token generated to represent ownership of the pool
     * @param poolType TOKEN, NFT, or TRADE
     * @param delta The delta value used by the bonding curve. The meaning of delta depends
     * on the specific curve.
     * @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
     * @param spotPrice The initial selling spot price
     * @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e6
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient fallback is set.
     * @param royaltyRecipientFallback An address to which all royalties will
     * be paid to if not address(0) and ERC2981 is not supported or ERC2981 recipient is not set.
     * @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
     * @return pool The new pool
     */
    struct CreateETHPoolParams {
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        address receiver;
        ICollectionPool.PoolType poolType;
        uint128 delta;
        uint24 fee;
        uint128 spotPrice;
        bytes props;
        bytes state;
        uint24 royaltyNumerator;
        address payable royaltyRecipientFallback;
        uint256[] initialNFTIDs;
    }

    /**
     * @notice Creates a pool contract using EIP-1167.
     * @param token The ERC20 token used for pool swaps
     * @param nft The NFT contract of the collection the pool trades
     * @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
     * @param assetRecipient The address that will receive the assets traders give during trades.
     * If set to address(0), assets will be sent to the pool address. Not available to TRADE pools.
     * @param receiver Receiver of the LP token generated to represent ownership of the pool
     * @param poolType TOKEN, NFT, or TRADE
     * @param delta The delta value used by the bonding curve. The meaning of delta depends on the
     * specific curve.
     * @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
     * @param spotPrice The initial selling spot price, in ETH
     * @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e6
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient fallback is set.
     * @param royaltyRecipientFallback An address to which all royalties will
     * be paid to if not address(0) and ERC2981 is not supported or ERC2981 recipient is not set.
     * @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
     * @param initialTokenBalance The initial token balance sent from the sender to the new pool
     * @return pool The new pool
     */
    struct CreateERC20PoolParams {
        ERC20 token;
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        address receiver;
        ICollectionPool.PoolType poolType;
        uint128 delta;
        uint24 fee;
        uint128 spotPrice;
        bytes props;
        bytes state;
        uint24 royaltyNumerator;
        address payable royaltyRecipientFallback;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
    }

    function protocolFeeMultiplier() external view returns (uint24);

    function protocolFeeRecipient() external view returns (address payable);

    function carryFeeMultiplier() external view returns (uint24);

    function callAllowed(address target) external view returns (bool);

    function routerStatus(CollectionRouter router) external view returns (bool allowed, bool wasEverAllowed);

    function isPool(address potentialPool) external view returns (bool);

    function isPoolVariant(address potentialPool, PoolVariant variant) external view returns (bool);

    function requireAuthorizedForToken(address spender, uint256 tokenId) external view;

    function swapPaused() external view returns (bool);

    function creationPaused() external view returns (bool);

    function createPoolETH(CreateETHPoolParams calldata params)
        external
        payable
        returns (ICollectionPool pool, uint256 tokenId);

    function createPoolERC20(CreateERC20PoolParams calldata params)
        external
        returns (ICollectionPool pool, uint256 tokenId);

    function createPoolETHFiltered(CreateETHPoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        payable
        returns (ICollectionPool pool, uint256 tokenId);

    function createPoolERC20Filtered(CreateERC20PoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        returns (ICollectionPool pool, uint256 tokenId);

    function depositNFTs(
        uint256[] calldata ids,
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        address recipient,
        address from
    ) external;

    function depositERC20(ERC20 token, uint256 amount, address recipient, address from) external;

    function depositRoyaltiesNotification(
        ERC20 token,
        CollectionPool.RoyaltyDue[] calldata royaltiesDue,
        PoolVariant poolVariant
    ) external payable;

    function burn(uint256 tokenId) external;

    /**
     * @dev Returns the pool of the `tokenId` token.
     */
    function poolOf(uint256 tokenId) external view returns (ICollectionPool);

    function withdrawRoyalties(address payable recipient, ERC20 token) external;

    /**
     * @notice Withdraw all `token` royalties awardable to `recipient`. If the
     * zero address is passed as `token`, then ETH royalties are paid. Does not
     * use msg.sender so this function can be called on behalf of contract
     * royalty recipients
     *
     * @dev Does not call `withdrawRoyalties` to avoid making multiple unneeded
     * checks of whether `address(token) == address(0)` for each iteration
     */
    function withdrawRoyaltiesMultipleRecipients(address payable[] calldata recipients, ERC20 token) external;

    function withdrawRoyaltiesMultipleCurrencies(address payable recipient, ERC20[] calldata tokens) external;

    /**
     * @notice Withdraw royalties for ALL combinations of recipients and tokens
     * in the given arguments
     *
     * @dev Iterate over tokens as outer loop to reduce stores/loads to `royaltiesStored`
     * and also reduce the number of `address(token) == address(0)` condition checks
     * from O(m * n) to O(n)
     */
    function withdrawRoyaltiesMultipleRecipientsAndCurrencies(
        address payable[] calldata recipients,
        ERC20[] calldata tokens
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IExternalFilter is IERC165 {
    /**
     * @notice Pools can nominate an external contract to approve whether NFT IDs are accepted.
     * This is typically used to implement some kind of dynamic block list, e.g. stolen NFTs.
     * @param collection NFT contract address
     * @param nftIds List of NFT IDs to check
     * @return allowed True if swap (pool buys) is allowed
     */
    function areNFTsAllowed(address collection, uint256[] calldata nftIds, bytes calldata context)
        external
        returns (bool allowed);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ITokenIDFilter} from "./ITokenIDFilter.sol";

contract TokenIDFilter is ITokenIDFilter {
    event AcceptsTokenIDs(address indexed _collection, bytes32 indexed _root, bytes _data);

    // Merkle root
    bytes32 public tokenIDFilterRoot;

    function _setRootAndEmitAcceptedIDs(address collection, bytes32 root, bytes calldata data) internal {
        tokenIDFilterRoot = root;
        emit AcceptsTokenIDs(collection, tokenIDFilterRoot, data);
    }

    function _acceptsTokenID(uint256 tokenID, bytes32[] calldata proof) internal view returns (bool) {
        if (tokenIDFilterRoot == 0) {
            return true;
        }

        // double hash to prevent second preimage attack
        bytes32 leaf = keccak256(abi.encodePacked(keccak256(abi.encodePacked((tokenID)))));

        return MerkleProof.verifyCalldata(proof, tokenIDFilterRoot, leaf);
    }

    function _emitTokenIDs(address collection, bytes calldata data) internal {
        emit AcceptsTokenIDs(collection, tokenIDFilterRoot, data);
    }

    function _acceptsTokenIDs(uint256[] calldata tokenIDs, bytes32[] calldata proof, bool[] calldata proofFlags)
        internal
        view
        returns (bool)
    {
        if (tokenIDFilterRoot == 0) {
            return true;
        }

        uint256 length = tokenIDs.length;
        bytes32[] memory leaves = new bytes32[](length);

        for (uint256 i; i < length;) {
            // double hash to prevent second preimage attack
            leaves[i] = keccak256(abi.encodePacked(keccak256(abi.encodePacked((tokenIDs[i])))));
            unchecked {
                ++i;
            }
        }

        return MerkleProof.multiProofVerify(proof, proofFlags, tokenIDFilterRoot, leaves);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @notice Manages 256 independent pause states. Idiomatic use of these functions when
 * exposing them as external functions would be to give an appropriate name and
 * abstract away the passing of `index` variables using immutable contract
 * variables. Initializes with all pause states unpaused.
 */
contract MultiPauser {
    uint256 pauseStates;

    modifier validIndex(uint256 index) {
        require(index <= 255, "Invalid pause index");
        _;
    }

    modifier onlyPaused(uint256 index) {
        require(index <= 255, "Invalid pause index");
        require(isPaused(index), "Must be paused");
        _;
    }

    modifier onlyUnpaused(uint256 index) {
        require(index <= 255, "Invalid pause index");
        require(!isPaused(index), "Must be unpaused");
        _;
    }

    /**
     * @notice Pauses the pause with the given index. 0 <= index <= 255.
     * @dev While using a uint8 as the type of index would enforce the
     * precondition for us, it costs extra gas as solidity will carry out
     * bit extensions and truncations to make it word length
     */
    function pause(uint256 index) validIndex(index) internal {
        pauseStates = pauseStates | (1 << index);
    }

    /**
     * @notice Unpauses the pause with the given index. 0 <= index <= 255.
     * @dev While using a uint8 as the type of index would enforce the
     * precondition for us, it costs extra gas as solidity will carry out
     * bit extensions and truncations to make it word length
     */
    function unpause(uint256 index) validIndex(index) internal {
        /**
         * @dev Generate all 1's except in position `index`. Use XOR as no ~ in
         * solidity.
         */ 
        pauseStates &= ~(1 << index);
    }

    /**
     * @notice Returns true iff the pause with the given index is paused
     */
    function isPaused(uint256 index) validIndex(index) internal view returns (bool) {
        return (pauseStates & (1 << index)) > 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IPoolActivityMonitor is IERC165 {
    enum EventType {
        BOUGHT_NFT_FROM_POOL,
        SOLD_NFT_TO_POOL,
        DEPOSIT_TOKEN,
        DEPOSIT_NFT
    }

    /**
     * @dev This hook allows pool owners (i.e. owner of the LP token) to observe
     * changes to pools initiated by third-parties, i.e. swaps and deposits.
     *
     * @param amounts If `eventType` is a swap, then `amounts` is an array with
     * 3 elements. The first is the number of nfts swapped. The second is the
     * price of the last NFT swapped (after all fees are applied, i.e. input or
     * output amount if quantity were 1). The third is the total value of the
     * swap with fees included. If `eventType` is not a swap, then amounts is a
     * length 1 array of the amount of token/NFT deposited/withdrawn.
     */
    function onBalancesChanged(address poolAddress, EventType eventType, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ITokenIDFilter {
    function tokenIDFilterRoot() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {TransferLib} from "../lib/TransferLib.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";

/**
 * @title An NFT/Token pool for an NFT that does not implement ERC721Enumerable
 * @author Collection
 */
abstract contract CollectionPoolMissingEnumerable is CollectionPool {
    using EnumerableSet for EnumerableSet.UintSet;

    // Used for internal ID tracking
    EnumerableSet.UintSet private idSet;

    /// @inheritdoc CollectionPool
    function _selectArbitraryNFTs(IERC721, uint256 numNFTs) internal view override returns (uint256[] memory nftIds) {
        uint256 lastIndex = idSet.length();
        if (numNFTs > 0 && numNFTs <= lastIndex) {
            nftIds = new uint256[](numNFTs);
            // NOTE: We start from last index to first index to save on gas when we eventully _withdrawNFTs on results
            lastIndex = lastIndex - 1;

            for (uint256 i; i < numNFTs;) {
                uint256 nftId = idSet.at(lastIndex);
                nftIds[i] = nftId;

                unchecked {
                    --lastIndex;
                    ++i;
                }
            }
        }
    }

    /// @inheritdoc CollectionPool
    function getAllHeldIds() public view override returns (uint256[] memory nftIds) {
        nftIds = idSet.values();
    }

    /// @inheritdoc CollectionPool
    function _depositNFTs(address from, uint256[] calldata nftIds) internal override {
        // transfer NFTs to this pool and update set
        IERC721 _nft = nft();
        uint256 length = nftIds.length;
        for (uint256 i; i < length;) {
            uint256 nftId = nftIds[i];
            _nft.safeTransferFrom(from, address(this), nftId);
            idSet.add(nftId);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _depositNFTsNotification(uint256[] calldata nftIds) internal override {
        uint256 length = nftIds.length;
        for (uint256 i; i < length;) {
            idSet.add(nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _withdrawNFTs(address to, uint256[] memory nftIds) internal override {
        IERC721 _nft = nft();

        // Send NFTs to given addres and update valid set
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs;) {
            _nft.safeTransferFrom(address(this), to, nftIds[i]);
            idSet.remove(nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ICollectionPool
    function NFTsCount() external view returns (uint256) {
        return idSet.length();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolETH} from "../pools/CollectionPoolETH.sol";
import {CollectionPoolMissingEnumerable} from "./CollectionPoolMissingEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

contract CollectionPoolMissingEnumerableETH is CollectionPoolMissingEnumerable, CollectionPoolETH {
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ETH;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {IPoolActivityMonitor} from "./IPoolActivityMonitor.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";

/**
 * @title An NFT/Token pool where the token is ETH
 * @author Collection
 */
abstract contract CollectionPoolETH is CollectionPool {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 65;

    /// @inheritdoc ICollectionPool
    function liquidity() public view returns (uint256) {
        uint256 _balance = address(this).balance;
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_balance < _accruedTradeFee) revert InsufficientLiquidity(_balance, _accruedTradeFee);

        return _balance - _accruedTradeFee;
    }

    /// @inheritdoc CollectionPool
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool, /*isRouter*/
        address, /*routerCaller*/
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltiesDue
    ) internal override {
        require(msg.value >= inputAmount, "Sent too little ETH");

        // Pay royalties first to obtain total amount of royalties paid
        (uint256 totalRoyaltiesPaid,) = _payRoyaltiesAndProtocolFee(_factory, royaltiesDue, protocolFee);

        // Transfer inputAmount ETH to assetRecipient if it's been set
        address payable _assetRecipient = getAssetRecipient();
        if (_assetRecipient != address(this)) {
            _assetRecipient.safeTransferETH(inputAmount - protocolFee - totalRoyaltiesPaid);
        }
    }

    /// @inheritdoc CollectionPool
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Give excess ETH back to caller
        if (msg.value > inputAmount) {
            payable(msg.sender).safeTransferETH(msg.value - inputAmount);
        }
    }

    /**
     * @notice Pay royalties to the factory, which should never revert. The factory
     * serves as a single contract to which royalty recipients can make a single
     * transaction to receive all royalties due as opposed to having to send
     * transactions to arbitrary numbers of pools
     *
     * In addition, pay protocol fees in the same transfer since both go to factory
     *
     * @return totalRoyaltiesPaid The amount of royalties which were paid including
     * royalties whose resolved recipient is this contract itself
     * @return royaltiesSentToFactory `totalRoyaltiesPaid` less the amount whose
     * resolved recipient is this contract itself
     */
    function _payRoyaltiesAndProtocolFee(
        ICollectionPoolFactory _factory,
        RoyaltyDue[] memory royaltiesDue,
        uint256 protocolFee
    ) internal returns (uint256 totalRoyaltiesPaid, uint256 royaltiesSentToFactory) {
        /// @dev For ETH pools, calculate how much to send in total since factory
        /// can't call safeTransferFrom.
        uint256 length = royaltiesDue.length;
        for (uint256 i = 0; i < length;) {
            uint256 royaltyAmount = royaltiesDue[i].amount;
            if (royaltyAmount > 0) {
                totalRoyaltiesPaid += royaltyAmount;
                address finalRecipient = getRoyaltyRecipient(payable(royaltiesDue[i].recipient));
                if (finalRecipient != address(this)) {
                    royaltiesSentToFactory += royaltyAmount;
                    royaltiesDue[i].recipient = finalRecipient;
                }
            }

            unchecked {
                ++i;
            }
        }

        _factory.depositRoyaltiesNotification{value: royaltiesSentToFactory + protocolFee}(
            ERC20(address(0)), royaltiesDue, poolVariant()
        );
    }

    /// @inheritdoc CollectionPool
    function _sendTokenOutputAndPayProtocolFees(
        ICollectionPoolFactory _factory,
        address payable tokenRecipient,
        uint256 outputAmount,
        RoyaltyDue[] memory royaltiesDue,
        uint256 protocolFee
    ) internal override {
        /// @dev Pay royalties and protocol fee
        _payRoyaltiesAndProtocolFee(_factory, royaltiesDue, protocolFee);

        /// @dev Send ETH to caller
        if (outputAmount > 0) {
            require(liquidity() >= outputAmount, "Too little ETH");
            tokenRecipient.safeTransferETH(outputAmount);
        }
    }

    /// @inheritdoc CollectionPool
    // @dev see CollectionPoolCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
     * @notice Withdraws all token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAllETH() external onlyAuthorized {
        uint256 _accruedTradeFee = accruedTradeFee;
        accruedTradeFee = 0;

        uint256 amount = address(this).balance;
        payable(owner()).safeTransferETH(amount);

        if (_accruedTradeFee >= amount) {
            _accruedTradeFee = amount;
            amount = 0;
        } else {
            amount -= _accruedTradeFee;
        }

        // emit event since ETH is the pool token
        IERC721 _nft = nft();
        emit TokenWithdrawal(_nft, ERC20(address(0)), amount);
        emit AccruedTradeFeeWithdrawal(_nft, ERC20(address(0)), _accruedTradeFee);
    }

    /**
     * @notice Withdraws a specified amount of token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     * @param amount The amount of token to send to the owner. If the pool's balance is less than
     * this value, the transaction will be reverted.
     */
    function withdrawETH(uint256 amount) external onlyAuthorized {
        require(liquidity() >= amount, "Too little ETH");

        payable(owner()).safeTransferETH(amount);

        // emit event since ETH is the pool token
        emit TokenWithdrawal(nft(), ERC20(address(0)), amount);
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC20(ERC20 a, uint256 amount) external onlyAuthorized {
        a.safeTransfer(owner(), amount);
    }

    /// @inheritdoc CollectionPool
    function withdrawAccruedTradeFee() external override onlyOwner {
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_accruedTradeFee > 0) {
            accruedTradeFee = 0;

            payable(owner()).safeTransferETH(_accruedTradeFee);

            // emit event since ETH is the pool token
            emit AccruedTradeFeeWithdrawal(nft(), ERC20(address(0)), _accruedTradeFee);
        }
    }

    function depositERC20Notification(ERC20, uint256) external view onlyFactory {
        revert InvalidModification();
    }

    /**
     * @dev All ETH transfers into the pool are accepted. This is the main method
     * for the owner to top up the pool's token reserves.
     */
    receive() external payable {
        emit TokenDeposit(nft(), ERC20(address(0)), msg.value);
        notifyDeposit(IPoolActivityMonitor.EventType.DEPOSIT_TOKEN, msg.value);
    }

    /**
     * @dev All ETH transfers into the pool are accepted. This is the main method
     * for the owner to top up the pool's token reserves.
     */
    fallback() external payable {
        // Only allow calls without function selector
        require(msg.data.length == _immutableParamsLength());
        emit TokenDeposit(nft(), ERC20(address(0)), msg.value);
        notifyDeposit(IPoolActivityMonitor.EventType.DEPOSIT_TOKEN, msg.value);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";

contract MultiRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    ICollectionPoolFactory public immutable erc721factory;

    constructor(ICollectionPoolFactory _erc721factory) {
        erc721factory = _erc721factory;
    }

    struct PoolSwapSpecific {
        CollectionPool pool;
        uint256[] nftIds;
        bytes32[] proof;
        bool[] proofFlags;
        /// @dev only used for selling into pools
        bytes externalFilterContext;
    }

    struct RobustPoolSwapSpecificWithToken {
        PoolSwapSpecific swapInfo;
        uint256 maxCost;
        bool isETHSwap;
    }

    struct RobustPoolSwapSpecificForToken {
        PoolSwapSpecific swapInfo;
        uint256 minOutput;
    }

    struct RobustPoolNFTsForTokenAndTokenforNFTsTrade {
        RobustPoolSwapSpecificWithToken[] tokenToNFTTradesSpecific;
        RobustPoolSwapSpecificForToken[] nftToTokenTrades;
    }

    /**
     * @notice Buys NFTs with ETH and ERC20s and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - tokenToNFTTradesSpecific The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     */
    function robustSwapTokensForSpecificNFTsAndNFTsToToken(RobustPoolNFTsForTokenAndTokenforNFTsTrade calldata params)
        external
        payable
        returns (uint256 remainingETHValue)
    {
        // Attempt to fill each buy order for specific NFTs
        {
            remainingETHValue = msg.value;
            uint256 poolCost;
            uint256 numSwaps = params.tokenToNFTTradesSpecific.length;
            for (uint256 i; i < numSwaps;) {
                // Calculate actual cost per swap
                (,, poolCost,) = params.tokenToNFTTradesSpecific[i].swapInfo.pool.getBuyNFTQuote(
                    params.tokenToNFTTradesSpecific[i].swapInfo.nftIds.length
                );

                // If within our maxCost, proceed
                if (poolCost <= params.tokenToNFTTradesSpecific[i].maxCost) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    if (params.tokenToNFTTradesSpecific[i].isETHSwap) {
                        remainingETHValue -= params.tokenToNFTTradesSpecific[i].swapInfo.pool.swapTokenForSpecificNFTs{
                            value: poolCost
                        }(params.tokenToNFTTradesSpecific[i].swapInfo.nftIds, poolCost, msg.sender, true, msg.sender);
                    }
                    // Otherwise we send ERC20 tokens
                    else {
                        params.tokenToNFTTradesSpecific[i].swapInfo.pool.swapTokenForSpecificNFTs(
                            params.tokenToNFTTradesSpecific[i].swapInfo.nftIds, poolCost, msg.sender, true, msg.sender
                        );
                    }
                }

                unchecked {
                    ++i;
                }
            }
            // Return remaining value to sender
            if (remainingETHValue > 0) {
                payable(msg.sender).safeTransferETH(remainingETHValue);
            }
        }
        // Attempt to fill each sell order
        {
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Locally scoped to avoid stack too deep error
                {
                    try params.nftToTokenTrades[i].swapInfo.pool.getSellNFTQuote(
                        params.nftToTokenTrades[i].swapInfo.nftIds.length
                    ) returns (ICurve.Params memory, uint256, uint256 poolOutput, ICurve.Fees memory) {
                        // If at least equal to our minOutput, proceed
                        if (poolOutput >= params.nftToTokenTrades[i].minOutput) {
                            // Do the swap
                            params.nftToTokenTrades[i].swapInfo.pool.swapNFTsForToken(
                                ICollectionPool.NFTs(
                                    params.nftToTokenTrades[i].swapInfo.nftIds,
                                    params.nftToTokenTrades[i].swapInfo.proof,
                                    params.nftToTokenTrades[i].swapInfo.proofFlags
                                ),
                                0,
                                payable(msg.sender),
                                true,
                                msg.sender,
                                params.nftToTokenTrades[i].swapInfo.externalFilterContext
                            );
                        }
                    } catch {}

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    receive() external payable {}

    /**
     * Restricted functions
     */

    /**
     * @dev Allows an ERC20 pool contract to transfer ERC20 tokens directly from
     * the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pool.
     * @param token The ERC20 token to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferERC20From(ERC20 token, address from, address to, uint256 amount, uint8 variant) external {
        // verify caller is an ERC20 pool contract
        ICollectionPoolFactory.PoolVariant _variant = ICollectionPoolFactory.PoolVariant(variant);
        require(erc721factory.isPoolVariant(msg.sender, _variant), "Not pool");

        // verify caller is an ERC20 pool
        require(
            _variant == ICollectionPoolFactory.PoolVariant.ENUMERABLE_ERC20
                || _variant == ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ERC20,
            "Not ERC20 pool"
        );
        // transfer tokens to pool
        token.safeTransferFrom(from, to, amount);
    }

    /**
     * @dev Allows a pool contract to transfer ERC721 NFTs directly from
     * the sender, in order to minimize the number of token transfers. Only callable by a pool.
     * @param nft The ERC721 NFT to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param id The ID of the NFT to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferNFTFrom(
        IERC721 nft,
        address from,
        address to,
        uint256 id,
        ICollectionPoolFactory.PoolVariant variant
    ) external {
        // verify caller is a trusted pool contract
        require(erc721factory.isPoolVariant(msg.sender, variant), "Not pool");
        // transfer NFTs to pool
        nft.safeTransferFrom(from, to, id);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC1820Registry} from "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

// @dev Solmate's ERC20 is used instead of OZ's ERC20 so we can use safeTransferLib for cheaper safeTransfers for
// ETH and ERC20 tokens
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {TransferLib} from "../lib/TransferLib.sol";

import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {CollectionPoolETH} from "./CollectionPoolETH.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CollectionPoolERC20} from "./CollectionPoolERC20.sol";
import {CollectionPoolCloner} from "../lib/CollectionPoolCloner.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CollectionPoolEnumerableETH} from "./CollectionPoolEnumerableETH.sol";
import {CollectionPoolEnumerableERC20} from "./CollectionPoolEnumerableERC20.sol";
import {CollectionPoolMissingEnumerableETH} from "./CollectionPoolMissingEnumerableETH.sol";
import {CollectionPoolMissingEnumerableERC20} from "./CollectionPoolMissingEnumerableERC20.sol";
import {MultiPauser} from "../lib/MultiPauser.sol";

/**
 * @dev The ETH balance of this contract is used both to store protocol fees
 * which the owner can withdraw, as well as royalties accumulated from swaps
 * made against pools deployed by this contract.
 */
contract CollectionPoolFactory is
    Ownable,
    ReentrancyGuard,
    ERC721,
    ERC721URIStorage,
    MultiPauser,
    ICollectionPoolFactory
{
    using CollectionPoolCloner for address;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = type(IERC721Enumerable).interfaceId;

    uint256 private constant CREATION_PAUSE = 0;
    uint256 private constant SWAP_PAUSE = 1;

    /**
     * @dev The MAX_PROTOCOL_FEE constant specifies the maximum fee that can be charged by the AMM pool contract
     * for facilitating token or NFT swaps on the decentralized exchange.
     * This fee is charged as a flat percentage of the final traded price for each swap,
     * and it is used to cover the costs associated with running the AMM pool contract and providing liquidity to the decentralized exchange.
     * This is used for NFT/TOKEN trading pools, that have a limited amount of dry powder
     */
    uint256 internal constant MAX_PROTOCOL_FEE = 0.1e6; // 10%, must <= 1 - MAX_FEE
    /**
     * @dev The MAX_CARRY_FEE constant specifies the maximum fee that can be charged by the AMM pool contract for facilitating token
     * or NFT swaps on the decentralized exchange. This fee is charged as a percentage of the fee set by the trading pool creator,
     * which is itself a percentage of the final traded price. This is used for TRADE pools, that form a continuous liquidity pool
     */
    uint256 internal constant MAX_CARRY_FEE = 0.5e6; // 50%

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    CollectionPoolEnumerableETH public immutable enumerableETHTemplate;
    CollectionPoolMissingEnumerableETH public immutable missingEnumerableETHTemplate;
    CollectionPoolEnumerableERC20 public immutable enumerableERC20Template;
    CollectionPoolMissingEnumerableERC20 public immutable missingEnumerableERC20Template;
    address payable public override protocolFeeRecipient;

    // Units are in base 1e6
    uint24 public override protocolFeeMultiplier;

    // Units are in base 1e6
    uint24 public override carryFeeMultiplier;

    mapping(ICurve => bool) public bondingCurveAllowed;
    mapping(address => bool) public override callAllowed;
    /// @dev Used to track how much royalties are stored in this contract balance.
    /// This is to prevent the factory owner from withdrawing more than they should
    mapping(ERC20 => uint256) royaltiesStored;
    /// @dev Uses address 0 for ETH royalties
    mapping(address => mapping(ERC20 => uint256)) public royaltiesClaimable;

    struct RouterStatus {
        bool allowed;
        bool wasEverAllowed;
    }

    mapping(CollectionRouter => RouterStatus) public override routerStatus;

    string public baseURI;

    modifier whenCreationNotPaused() {
        require(!creationPaused(), "Pool creation is paused");
        _;
    }

    event NewPool(address indexed collection, address indexed poolAddress);
    event TokenDeposit(address indexed poolAddress);
    event ProtocolFeeRecipientUpdate(address indexed recipientAddress);
    event ProtocolFeeMultiplierUpdate(uint24 newMultiplier);
    event CarryFeeMultiplierUpdate(uint24 newMultiplier);
    event BondingCurveStatusUpdate(ICurve indexed bondingCurve, bool isAllowed);
    event CallTargetStatusUpdate(address indexed target, bool isAllowed);
    event RouterStatusUpdate(CollectionRouter indexed router, bool isAllowed);
    event CreationPause();
    event CreationUnpause();
    event SwapPause();
    event SwapUnpause();

    error InsufficientValue(uint256 msgValue, uint256 amountRequired);

    constructor(
        CollectionPoolEnumerableETH _enumerableETHTemplate,
        CollectionPoolMissingEnumerableETH _missingEnumerableETHTemplate,
        CollectionPoolEnumerableERC20 _enumerableERC20Template,
        CollectionPoolMissingEnumerableERC20 _missingEnumerableERC20Template,
        address payable _protocolFeeRecipient,
        uint24 _protocolFeeMultiplier,
        uint24 _carryFeeMultiplier
    ) ERC721("Collectionswap", "CollectionLP") {
        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Protocol fee too large");
        require(_carryFeeMultiplier <= MAX_CARRY_FEE, "Carry fee too large");
        enumerableETHTemplate = _enumerableETHTemplate;
        missingEnumerableETHTemplate = _missingEnumerableETHTemplate;
        enumerableERC20Template = _enumerableERC20Template;
        missingEnumerableERC20Template = _missingEnumerableERC20Template;
        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeMultiplier = _protocolFeeMultiplier;
        carryFeeMultiplier = _carryFeeMultiplier;
    }

    /**
     * External view functions. Not pausable.
     */

    function requireAuthorizedForToken(address spender, uint256 tokenId) external view {
        require(_isApprovedOrOwner(spender, tokenId), "Not approved");
    }

    /**
     * @dev See {ICollectionPoolFactory-poolOf}.
     */
    function poolOf(uint256 tokenId) public pure returns (ICollectionPool) {
        return ICollectionPool(address(uint160(tokenId)));
    }

    /**
     * @notice Check if a pool is any of the templates deployed with this factory
     */
    function isPool(address potentialPool) public view returns (bool) {
        return isPoolVariant(potentialPool, PoolVariant.ENUMERABLE_ERC20)
            || isPoolVariant(potentialPool, PoolVariant.ENUMERABLE_ETH)
            || isPoolVariant(potentialPool, PoolVariant.MISSING_ENUMERABLE_ERC20)
            || isPoolVariant(potentialPool, PoolVariant.MISSING_ENUMERABLE_ETH);
    }

    /**
     * @notice Checks if an address is a CollectionPool. Uses the fact that the pools are EIP-1167 minimal proxies.
     * @param potentialPool The address to check
     * @param variant The pool variant (NFT is enumerable or not, pool uses ETH or ERC20)
     * @dev The PoolCloner contract is a utility contract that is used by the PoolFactory contract to create new instances of automated market maker (AMM) pools.
     * @return True if the address is the specified pool variant, false otherwise
     */
    function isPoolVariant(address potentialPool, PoolVariant variant) public view returns (bool) {
        if (variant == PoolVariant.ENUMERABLE_ERC20) {
            return CollectionPoolCloner.isERC20PoolClone(address(this), address(enumerableERC20Template), potentialPool);
        } else if (variant == PoolVariant.MISSING_ENUMERABLE_ERC20) {
            return CollectionPoolCloner.isERC20PoolClone(
                address(this), address(missingEnumerableERC20Template), potentialPool
            );
        } else if (variant == PoolVariant.ENUMERABLE_ETH) {
            return CollectionPoolCloner.isETHPoolClone(address(this), address(enumerableETHTemplate), potentialPool);
        } else if (variant == PoolVariant.MISSING_ENUMERABLE_ETH) {
            return
                CollectionPoolCloner.isETHPoolClone(address(this), address(missingEnumerableETHTemplate), potentialPool);
        } else {
            // invalid input
            return false;
        }
    }

    function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (IERC165, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function swapPaused() external view returns (bool) {
        return isPaused(SWAP_PAUSE);
    }

    function creationPaused() public view returns (bool) {
        return isPaused(CREATION_PAUSE);
    }

    /**
     * Pool creation functions. Pausable
     */
    function createPoolETH(CreateETHPoolParams calldata params)
        external
        payable
        whenCreationNotPaused
        returns (ICollectionPool pool, uint256 tokenId)
    {
        (pool, tokenId) = _createPoolETH(params);

        _initializePoolETH(pool, params);
    }

    /**
     * @notice Creates a filtered pool contract using EIP-1167.
     * @param params The parameters to create ETH pool
     * @param filterParams The parameters needed for the filtering functionality
     * @return pool The new pool
     */
    function createPoolETHFiltered(CreateETHPoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        payable
        whenCreationNotPaused
        returns (ICollectionPool pool, uint256 tokenId)
    {
        (pool, tokenId) = _createPoolETH(params);

        // Check if nfts are allowed before initializing to save gas on transferring nfts on revert.
        // If not, we could re-use createPoolETH and check later.
        pool.setTokenIDFilter(filterParams.merkleRoot, filterParams.encodedTokenIDs);
        require(
            pool.acceptsTokenIDs(params.initialNFTIDs, filterParams.initialProof, filterParams.initialProofFlags),
            "NFT not allowed"
        );
        pool.setExternalFilter(address(filterParams.externalFilter));

        _initializePoolETH(pool, params);
    }

    function createPoolERC20(CreateERC20PoolParams calldata params)
        external
        whenCreationNotPaused
        returns (ICollectionPool pool, uint256 tokenId)
    {
        address is777 = _ERC1820_REGISTRY.getInterfaceImplementer(address(params.token), keccak256("ERC777Token"));
        require(is777 == address(0), "ERC777 not supported");

        (pool, tokenId) = _createPoolERC20(params);

        _initializePoolERC20(pool, params);
    }

    function createPoolERC20Filtered(CreateERC20PoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        whenCreationNotPaused
        returns (ICollectionPool pool, uint256 tokenId)
    {
        address is777 = _ERC1820_REGISTRY.getInterfaceImplementer(address(params.token), keccak256("ERC777Token"));
        require(is777 == address(0), "ERC777 not supported");

        (pool, tokenId) = _createPoolERC20(params);

        // Check if nfts are allowed before initializing to save gas on transferring nfts on revert.
        // If not, we could re-use createPoolERC20 and check later.
        pool.setTokenIDFilter(filterParams.merkleRoot, filterParams.encodedTokenIDs);
        require(
            pool.acceptsTokenIDs(params.initialNFTIDs, filterParams.initialProof, filterParams.initialProofFlags),
            "NFT not allowed"
        );
        pool.setExternalFilter(address(filterParams.externalFilter));

        _initializePoolERC20(pool, params);
    }

    /**
     * Deposit functions. Not pausable
     */

    /**
     * @dev Used to deposit NFTs into a pool after creation and emit an event for indexing
     */
    function depositNFTs(
        uint256[] calldata ids,
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        address recipient,
        address from
    ) external {
        bool _isPool = isPool(recipient);
        require(_isPool, "Not a pool");

        CollectionPool pool = CollectionPool(recipient);
        require(pool.acceptsTokenIDs(ids, proof, proofFlags), "NFTs not allowed");

        // transfer NFTs from caller to recipient
        _depositNFTs(pool.nft(), ids, pool, from);
    }

    /**
     * @dev Used to deposit ERC20 tokens into a pool after creation and emit an event for indexing
     */
    function depositERC20(ERC20 token, uint256 amount, address recipient, address from) external {
        bool _isPool = isPool(recipient);
        require(_isPool, "Not a pool");

        CollectionPool pool = CollectionPool(recipient);

        // transfer NFTs from caller to recipient
        token.safeTransferFrom(from, recipient, amount);
        pool.depositERC20Notification(token, amount);
    }

    /**
     * @notice Update royalty bookkeeping in `token` currency according to
     * `royaltiesDue`. Only callable by pools
     * @param token The ERC20 token that royalties are in. ERC20(address(0)) for ETH
     * @param royaltiesDue An array of the recipients and amounts due each address
     * @param poolVariant the variant of the pool being interacted with
     */
    function depositRoyaltiesNotification(
        ERC20 token,
        CollectionPool.RoyaltyDue[] calldata royaltiesDue,
        PoolVariant poolVariant
    ) external payable {
        require(isPoolVariant(msg.sender, poolVariant), "Not pool");
        uint256 length = royaltiesDue.length;
        uint256 amountRequired;
        // Do internal bookkeeping of who can claim portions of the tokens about
        // to be transferred in
        for (uint256 i; i < length;) {
            address recipient = royaltiesDue[i].recipient;
            if (msg.sender != recipient) {
                amountRequired += royaltiesDue[i].amount;
                royaltiesClaimable[royaltiesDue[i].recipient][token] += royaltiesDue[i].amount;
            }

            unchecked {
                ++i;
            }
        }

        royaltiesStored[token] += amountRequired;
    }

    /*
     * @notice NFTs that don't match filter and any airdropped assets  must be rescued prior to calling this function.
     * Requires LP token owner to give allowance to this factory contract for asset withdrawals
     * which are sent directly to the LP token owner.
     */
    function burn(uint256 tokenId) external nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        ICollectionPool pool = poolOf(tokenId);
        PoolVariant poolVariant = pool.poolVariant();

        // withdraw all ETH / ERC20
        if (poolVariant == PoolVariant.ENUMERABLE_ETH || poolVariant == PoolVariant.MISSING_ENUMERABLE_ETH) {
            // withdraw ETH, sent to owner of LP token
            CollectionPoolETH(payable(address(pool))).withdrawAllETH();
        } else if (poolVariant == PoolVariant.ENUMERABLE_ERC20 || poolVariant == PoolVariant.MISSING_ENUMERABLE_ERC20) {
            // withdraw ERC20
            CollectionPoolERC20(address(pool)).withdrawAllERC20();
        }
        // then withdraw NFTs
        pool.withdrawERC721(pool.nft(), pool.getAllHeldIds());

        _burn(tokenId);
    }

    /**
     * Admin functions. Not pausable. Pointless because pauser/unpauser is owner
     * and all admin functions are onlyOwner.
     */

    function pauseCreation() external onlyOwner {
        pause(CREATION_PAUSE);
        emit CreationPause();
    }

    function unpauseCreation() external onlyOwner {
        unpause(CREATION_PAUSE);
        emit CreationUnpause();
    }

    function pauseSwap() external onlyOwner {
        pause(SWAP_PAUSE);
        emit SwapPause();
    }

    function unpauseSwap() external onlyOwner {
        unpause(SWAP_PAUSE);
        emit SwapUnpause();
    }

    /**
     * Withdrawal functions. Not pausable.
     */

    /**
     * @notice Withdraw all `token` royalties awardable to `recipient`. If the
     * zero address is passed as `token`, then ETH royalties are paid. Does not
     * use msg.sender so this function can be called on behalf of contract
     * royalty recipients
     */
    function withdrawRoyalties(address payable recipient, ERC20 token) external {
        uint256 totalRoyaltiesWithdrawn;
        if (address(token) == address(0)) {
            totalRoyaltiesWithdrawn = withdrawETHRoyalties(recipient);
        } else {
            totalRoyaltiesWithdrawn = withdrawERC20Royalties(recipient, token);
        }

        royaltiesStored[token] -= totalRoyaltiesWithdrawn;
    }

    /**
     * @dev Internal helper function for withdrawing ETH royalties for a single
     * address. Does NOT update `royaltiesStored[token]`
     */
    function withdrawETHRoyalties(address payable recipient) internal returns (uint256 amount) {
        amount = royaltiesClaimable[recipient][ERC20(address(0))];
        royaltiesClaimable[recipient][ERC20(address(0))] = 0;
        recipient.safeTransferETH(amount);
    }

    /**
     * @dev Internal helper function for withdrawing ERC20 royalties for a single
     * address. Does NOT update `royaltiesStored[token]`
     */
    function withdrawERC20Royalties(address payable recipient, ERC20 token) internal returns (uint256 amount) {
        require(address(token) != address(0), "Use withdrawETHRoyalties instead");
        amount = royaltiesClaimable[recipient][token];
        royaltiesClaimable[recipient][token] = 0;
        token.safeTransfer(recipient, amount);
    }

    /**
     * @dev Uses the internal helper functions to batch writes to `royaltiesStored`
     */
    function withdrawRoyaltiesMultipleRecipients(address payable[] calldata recipients, ERC20 token) public {
        uint256 length = recipients.length;
        uint256 totalRoyaltiesWithdrawn;
        uint256 amount;
        if (address(token) == address(0)) {
            for (uint256 i; i < length;) {
                amount = withdrawETHRoyalties(recipients[i]);
                totalRoyaltiesWithdrawn += amount;

                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i; i < length;) {
                amount = withdrawERC20Royalties(recipients[i], token);
                totalRoyaltiesWithdrawn += amount;

                unchecked {
                    ++i;
                }
            }
        }

        royaltiesStored[token] -= totalRoyaltiesWithdrawn;
    }

    function withdrawRoyaltiesMultipleCurrencies(address payable recipient, ERC20[] calldata tokens) external {
        uint256 length = tokens.length;
        uint256 amount;
        for (uint256 i; i < length; i++) {
            ERC20 token = tokens[i];
            amount = royaltiesClaimable[recipient][token];
            royaltiesClaimable[recipient][token] = 0;

            /// @dev Need to repeat this check for every token iterated over
            if (address(token) == address(0)) {
                recipient.safeTransferETH(amount);
            } else {
                token.safeTransfer(recipient, amount);
            }

            royaltiesStored[token] -= amount;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Withdraw royalties for ALL combinations of recipients and tokens
     * in the given arguments
     *
     * @dev Iterate over tokens as outer loop to reduce stores/loads to `royaltiesStored`
     * and the number of `address(token) == address(0)` condition checks from
     * O(m * n) to O(n)
     */
    function withdrawRoyaltiesMultipleRecipientsAndCurrencies(
        address payable[] calldata recipients,
        ERC20[] calldata tokens
    ) external {
        uint256 length = tokens.length;
        for (uint256 i; i < length; i++) {
            ERC20 token = tokens[i];
            withdrawRoyaltiesMultipleRecipients(recipients, token);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Withdraws the ETH balance to the protocol fee recipient.
     * Only callable by the owner.
     */
    function withdrawETHProtocolFees() external onlyOwner {
        protocolFeeRecipient.safeTransferETH(address(this).balance - royaltiesStored[ERC20(address(0))]);
    }

    /**
     * @notice Withdraws ERC20 tokens to the protocol fee recipient. Only callable by the owner.
     * @param token The token to transfer
     */
    function withdrawERC20ProtocolFees(ERC20 token) external onlyOwner {
        token.safeTransfer(protocolFeeRecipient, token.balanceOf(address(this)) - royaltiesStored[token]);
    }

    /**
     * @notice Changes the protocol fee recipient address. Only callable by the owner.
     * @param _protocolFeeRecipient The new fee recipient
     */
    function changeProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "0 address");
        if (protocolFeeRecipient != _protocolFeeRecipient) {
            protocolFeeRecipient = _protocolFeeRecipient;
            emit ProtocolFeeRecipientUpdate(_protocolFeeRecipient);
        }
    }

    /**
     * @notice Changes the protocol fee multiplier. Only callable by the owner.
     * @param _protocolFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeProtocolFeeMultiplier(uint24 _protocolFeeMultiplier) external onlyOwner {
        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        if (protocolFeeMultiplier != _protocolFeeMultiplier) {
            protocolFeeMultiplier = _protocolFeeMultiplier;
            emit ProtocolFeeMultiplierUpdate(_protocolFeeMultiplier);
        }
    }

    /**
     * @notice Changes the carry fee multiplier. Only callable by the owner.
     * @param _carryFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeCarryFeeMultiplier(uint24 _carryFeeMultiplier) external onlyOwner {
        require(_carryFeeMultiplier <= MAX_CARRY_FEE, "Fee too large");
        if (carryFeeMultiplier != _carryFeeMultiplier) {
            carryFeeMultiplier = _carryFeeMultiplier;
            emit CarryFeeMultiplierUpdate(_carryFeeMultiplier);
        }
    }

    /**
     * @notice Sets the whitelist status of a bonding curve contract. Only callable by the owner.
     * @param bondingCurve The bonding curve contract
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setBondingCurveAllowed(ICurve bondingCurve, bool isAllowed) external onlyOwner {
        bool wasAllowed = bondingCurveAllowed[bondingCurve];
        if (wasAllowed != isAllowed) {
            bondingCurveAllowed[bondingCurve] = isAllowed;
            emit BondingCurveStatusUpdate(bondingCurve, isAllowed);
        }
    }

    /**
     * @notice Sets the whitelist status of a contract to be called arbitrarily by a pool.
     * Only callable by the owner.
     * @param target The target contract
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setCallAllowed(address payable target, bool isAllowed) external onlyOwner {
        // ensure target is not / was not ever a router
        if (isAllowed) {
            require(!routerStatus[CollectionRouter(target)].wasEverAllowed, "Can't call router");
        }

        bool wasAllowed = callAllowed[target];
        if (wasAllowed != isAllowed) {
            callAllowed[target] = isAllowed;
            emit CallTargetStatusUpdate(target, isAllowed);
        }
    }

    /**
     * @notice Updates the router whitelist. Only callable by the owner.
     * @param _router The router
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setRouterAllowed(CollectionRouter _router, bool isAllowed) external onlyOwner {
        // ensure target is not arbitrarily callable by pools
        if (isAllowed) {
            require(!callAllowed[address(_router)], "Can't call router");
        }

        bool wasAllowed = routerStatus[_router].allowed;
        if (wasAllowed != isAllowed) {
            routerStatus[_router] = RouterStatus({allowed: isAllowed, wasEverAllowed: true});
            emit RouterStatusUpdate(_router, isAllowed);
        }
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setTokenURI(string calldata _uri, uint256 tokenId) external onlyOwner {
        _setTokenURI(tokenId, _uri);
    }

    /**
     * Internal functions
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _createPoolETH(CreateETHPoolParams calldata params)
        internal
        returns (ICollectionPool pool, uint256 tokenId)
    {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        require(
            validRoyaltyState(params.royaltyNumerator, params.royaltyRecipientFallback, params.nft),
            "Nonzero royalty for non ERC2981 without fallback"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableETHTemplate) : address(missingEnumerableETHTemplate);
        } catch {
            template = address(missingEnumerableETHTemplate);
        }

        address poolAddress = template.cloneETHPool(this, params.bondingCurve, params.nft, uint8(params.poolType));

        // issue new token
        tokenId = mint(params.receiver, CollectionPool(poolAddress));

        emit NewPool(address(params.nft), poolAddress);

        return (ICollectionPool(poolAddress), tokenId);
    }

    function _initializePoolETH(ICollectionPool _pool, CreateETHPoolParams calldata _params) internal {
        // initialize pool
        _pool.initialize(
            _params.assetRecipient,
            _params.delta,
            _params.fee,
            _params.spotPrice,
            _params.props,
            _params.state,
            _params.royaltyNumerator,
            _params.royaltyRecipientFallback
        );

        // transfer initial ETH to pool
        payable(address(_pool)).safeTransferETH(msg.value);

        // transfer initial NFTs from sender to pool and notify pool
        _depositNFTs(_params.nft, _params.initialNFTIDs, _pool, msg.sender);
    }

    function _createPoolERC20(CreateERC20PoolParams calldata params)
        internal
        returns (ICollectionPool pool, uint256 tokenId)
    {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        require(
            validRoyaltyState(params.royaltyNumerator, params.royaltyRecipientFallback, params.nft),
            "Nonzero royalty for non ERC2981 without fallback"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableERC20Template) : address(missingEnumerableERC20Template);
        } catch {
            template = address(missingEnumerableERC20Template);
        }

        address poolAddress =
            template.cloneERC20Pool(this, params.bondingCurve, params.nft, uint8(params.poolType), params.token);

        // issue new token
        tokenId = mint(params.receiver, CollectionPool(poolAddress));

        emit NewPool(address(params.nft), poolAddress);

        return (ICollectionPool(poolAddress), tokenId);
    }

    function _initializePoolERC20(ICollectionPool _pool, CreateERC20PoolParams calldata _params) internal {
        // initialize pool
        _pool.initialize(
            _params.assetRecipient,
            _params.delta,
            _params.fee,
            _params.spotPrice,
            _params.props,
            _params.state,
            _params.royaltyNumerator,
            _params.royaltyRecipientFallback
        );

        // transfer initial tokens to pool
        _params.token.safeTransferFrom(msg.sender, address(_pool), _params.initialTokenBalance);

        // transfer initial NFTs from sender to pool and notify pool
        _depositNFTs(_params.nft, _params.initialNFTIDs, _pool, msg.sender);
    }

    /**
     * @dev Transfers NFTs from sender and notifies pool. `ids` must already have been verified
     */
    function _depositNFTs(IERC721 _nft, uint256[] calldata nftIds, ICollectionPool pool, address from) internal {
        // transfer NFTs from caller to recipient
        TransferLib.bulkSafeTransferERC721From(_nft, from, address(pool), nftIds);
        pool.depositNFTsNotification(nftIds);
    }

    /*
     * @dev Mints LP token using pool address as Token ID
     */
    function mint(address recipient, CollectionPool pool) internal returns (uint256 tokenId) {
        tokenId = uint160(address(pool));
        _safeMint(recipient, tokenId);
    }

    function validRoyaltyState(uint24 royaltyNumerator, address royaltyRecipientFallback, IERC721 nft)
        internal
        view
        returns (bool)
    {
        return royaltyNumerator == 0 || royaltyRecipientFallback != address(0)
            || IERC165(nft).supportsInterface(_INTERFACE_ID_ERC2981);
    }

    /**
     * Required override functions
     */

    /**
     * @notice Allows receiving ETH in order to receive protocol fees
     */
    receive() external payable {
        /**
         * No logic needed here:
         * - Factory needs to accept all transfers so that swaps don't fail to send token to
         * appropriate recipients when paying protocol fees/royalties.
         * - No bookkeeping is needed upon ETH receipt.
         */
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolETH} from "./CollectionPoolETH.sol";
import {CollectionPoolEnumerable} from "./CollectionPoolEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

/**
 * @title An NFT/Token pool where the NFT implements ERC721Enumerable, and the token is ETH
 * @author Collection
 */
contract CollectionPoolEnumerableETH is CollectionPoolEnumerable, CollectionPoolETH {
    /**
     * @notice Returns the CollectionPool type
     */
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.ENUMERABLE_ETH;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolERC20} from "./CollectionPoolERC20.sol";
import {CollectionPoolEnumerable} from "./CollectionPoolEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

/**
 * @title An NFT/Token pool where the NFT implements ERC721Enumerable, and the token is an ERC20
 * @author Collection
 */
contract CollectionPoolEnumerableERC20 is CollectionPoolEnumerable, CollectionPoolERC20 {
    /**
     * @notice Returns the CollectionPool type
     */
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.ENUMERABLE_ERC20;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolERC20} from "../pools/CollectionPoolERC20.sol";
import {CollectionPoolMissingEnumerable} from "./CollectionPoolMissingEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

contract CollectionPoolMissingEnumerableERC20 is CollectionPoolMissingEnumerable, CollectionPoolERC20 {
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ERC20;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {TransferLib} from "../lib/TransferLib.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

/**
 * @title An NFT/Token pool for an NFT that implements ERC721Enumerable
 * @author Collection
 */
abstract contract CollectionPoolEnumerable is CollectionPool {
    using BitMaps for BitMaps.BitMap;

    // NFT IDs that match our filter are maintained in this BitMap and counted in idLength
    BitMaps.BitMap private idMap;
    uint256 private idLength;

    /// @inheritdoc CollectionPool
    function _selectArbitraryNFTs(IERC721 _nft, uint256 numNFTs)
        internal
        view
        override
        returns (uint256[] memory nftIds)
    {
        uint256 userBalance = _nft.balanceOf(address(this));
        uint256 j;

        if (numNFTs > 0 && numNFTs <= userBalance) {
            nftIds = new uint256[](numNFTs);
            for (uint256 i; i < numNFTs;) {
                // index will be out of bounds if numNFTs > balance
                uint256 nftId = IERC721Enumerable(address(_nft)).tokenOfOwnerByIndex(address(this), j);

                // make sure it's a legal (filtered) ID
                if (idMap.get(nftId)) {
                    nftIds[i] = nftId;
                    unchecked {
                        ++i;
                    }
                }

                unchecked {
                    ++j;
                }
            }
        }
    }

    /// @inheritdoc CollectionPool
    function getAllHeldIds() public view override returns (uint256[] memory nftIds) {
        return _selectArbitraryNFTs(nft(), idLength);
    }

    /// @inheritdoc CollectionPool
    function _depositNFTs(address from, uint256[] calldata nftIds) internal override {
        // transfer NFTs to this pool and update map/size
        IERC721 _nft = nft();
        uint256 length = nftIds.length;
        uint256 _idLength = idLength;

        for (uint256 i; i < length;) {
            uint256 nftId = nftIds[i];
            _nft.safeTransferFrom(from, address(this), nftId);
            if (!idMap.get(nftId)) {
                idMap.set(nftId);
                ++_idLength;
            }

            unchecked {
                ++i;
            }
        }

        idLength = _idLength;
    }

    /// @inheritdoc CollectionPool
    function _depositNFTsNotification(uint256[] calldata nftIds) internal override {
        uint256 length = nftIds.length;
        uint256 _idLength = idLength;

        for (uint256 i; i < length;) {
            uint256 nftId = nftIds[i];
            if (!idMap.get(nftId)) {
                idMap.set(nftId);
                ++_idLength;
            }

            unchecked {
                ++i;
            }
        }

        idLength = _idLength;
    }

    /// @inheritdoc CollectionPool
    function _withdrawNFTs(address to, uint256[] memory nftIds) internal override {
        // Send NFTs to given address, update map and count
        IERC721 _nft = nft();
        uint256 numNFTs = nftIds.length;
        uint256 _idLength = idLength;

        for (uint256 i; i < numNFTs;) {
            uint256 nftId = nftIds[i];
            _nft.safeTransferFrom(address(this), to, nftId);
            // Remove from id map
            if (idMap.get(nftId)) {
                idMap.unset(nftId);
                --_idLength;
            }

            unchecked {
                ++i;
            }
        }

        idLength = _idLength;
    }

    /// @inheritdoc ICollectionPool
    function NFTsCount() external view returns (uint256) {
        return idLength;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IPoolActivityMonitor} from "./IPoolActivityMonitor.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract PoolActivityMonitor is ERC165, IPoolActivityMonitor, IERC721Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return interfaceId == type(IPoolActivityMonitor).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @inheritdoc IPoolActivityMonitor
    function onBalancesChanged(address poolAddress, EventType eventType, uint256[] memory amounts) external virtual {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Curve} from "./Curve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {FixedPointMathLib} from "../lib/FixedPointMathLib.sol";

import {ABDKMath64x64} from "../lib/ABDKMATH64x64.sol";

/**
 * @author potato-cat69
 * @notice Bonding curve logic for a sigmoid curve, where each buy/sell changes
 * spot price by adjusting its position along a sigmoid curve.
 *
 * WARNING: This curve does not set spotPrice to be the sell now price. Do not
 * assume as such. spotPrice for this curve is set to 0.
 *
 * GLOSSARY:
 *     P_min: minimum price of an NFT to be bought / sold
 *     P_max: maximum price of an NFT to be bought / sold
 *     k: scaling factor (curve gradient) that affects how fast P_min and P_max is approached.
 *     n_0: initial number of NFTs the pool had
 *     n: current number of NFTs the pool is holding
 *     deltaN: n - n_0, ie. the delta between initial and current NFTs held
 *
 * CONSTRAINTS:
 *     - k and deltaN must be expressible as signed 64.64 bit fixed point
 *       binary numbers as we rely on a 64x64 library for computations.
 *     - k is non-negative as it is casted from uint256 delta, implying 0 <= k <= 0x7FFFFFFFFFFFFFFF
 *     - -0x8000000000000000 <= deltaN <= 0x7FFFFFFFFFFFFFFF
 *     - This means the pool can never have a net loss of NFTs greater than
 *       -0x8000000000000000 or a net gain of NFTs greater than
 *       0x7FFFFFFFFFFFFFFF
 *
 * @dev The curve takes the form:
 * P(deltaN) = P_min + (P_max - P_min) / (1 + 2 ** (k * deltaN))
 *
 * While a traditional sigmoid uses e as the exponent base, this is equivalent
 * to modifying the value of k so a value of 2 is used for convenience.
 *
 * The values used in the equation for P(n) are as described below:
 * - `props` must be abi.encode(uint256(P_min), uint256(P_max - P_min))
 * - `state` must be abi.encode(int128(n - n0))
 * - `delta` must be k * 2**10 as a uint128. The value of k is normalized
 *   because most useful curves have k between 0 and 8, with small changes to k
 *   (e.g. 1/128) producing significant changes to the curve
 */
contract SigmoidCurve is Curve, CurveErrorCodes {
    using FixedPointMathLib for uint256;
    using ABDKMath64x64 for int128;

    /**
     * @param k The normalized value of k as a 64.64 bit signed int
     * @param deltaN The SIGNED INTEGER value of (n - n_0)
     * @param pMin The minimum value of the sigmoid curve
     * @param deltaP The difference between min and max price of the curve
     */
    struct SigmoidParameters {
        int128 k;
        int256 deltaN;
        uint256 pMin;
        uint256 deltaP;
    }

    /**
     * @dev k = `(delta << 64) / 2**K_NORMALIZATION_EXPONENT`
     */

    uint256 private constant K_NORMALIZATION_EXPONENT = 10;
    int128 private constant ONE_64_64 = 1 << 64;

    /**
     * @dev See {ICurve-validateDelta}
     */
    function validateDelta(uint128 delta) external pure override returns (bool valid) {
        return valid64x64Uint(delta);
    }

    /**
     * @dev See {ICurve-validateProps}
     */
    function validateProps(bytes calldata props) external pure override returns (bool valid) {
        // The only way for P_min and deltaP to be invalid is if P_min + deltaP
        // causes overflow (i.e. P_max not in uint256 space)

        // We don't want to revert on overflow, just return false. So do
        // unchecked addition and compare. Equality is allowed because deltaP of
        // 0 is allowed. Safe because it's impossible to overflow back to the
        // same number in a single binop addition.
        (uint256 P_min, uint256 deltaP) = getPriceRange(props);

        unchecked {
            uint256 P_max = P_min + deltaP;
            return P_max >= P_min;
        }
    }

    /**
     * @dev See {ICurve-validateState}
     */
    function validateState(bytes calldata state) external pure override returns (bool valid) {
        // convert to uint256 first, then check it doesn't exceed upper and lower bounds of int64
        // modified from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L374-L383
        if (state.length < 32) return false;
        uint256 tempUint;
        assembly {
            tempUint := calldataload(state.offset)
        }

        // taken from OpenZeppelin's SafeCast library
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/utils/math/SafeCast.sol#L1131-L1135
        // Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (tempUint > uint256(type(int256).max)) return false;
        return valid64x64Int(int256(tempUint));
    }

    /**
     * @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(Params calldata params, uint256 numItems, FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Params memory newParams, uint256 inputValue, Fees memory fees, uint256 lastSwapPrice)
    {
        return getInfo(true, params, numItems, feeMultipliers);
    }

    /**
     * @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(Params calldata params, uint256 numItems, FeeMultipliers calldata feeMultipliers)
        external
        pure
        returns (Params memory newParams, uint256 outputValue, Fees memory fees, uint256 lastSwapPrice)
    {
        return getInfo(false, params, numItems, feeMultipliers);
    }

    /// @dev To prevent stack too deep
    function getInfoPrelude(uint256 numItems) internal pure {
        // We only calculate changes for buying/selling 1 or more NFTs.
        if (numItems == 0) revert InvalidNumItems();

        // Verify that the resulting deltaN is will be valid. First ensure that
        // `numItems` fits in a 64 bit unsigned int. Then we can subtract
        // unchecked and manually check if bounds are exceeded
        if (numItems > 0x7FFFFFFFFFFFFFFF) revert TooManyItems();
    }

    function getInfo(bool isBuy, Params calldata params, uint256 numItems, FeeMultipliers calldata feeMultipliers)
        internal
        pure
        returns (Params memory newParams, uint256 value, Fees memory fees, uint256 lastSwapPrice)
    {
        // Extract information about the state of the pool
        (SigmoidParameters memory sigmoidParams) = getSigmoidParameters(params.delta, params.props, params.state);

        // The only difference between buying and selling is whether the number of items is being incremented or decremented.
        // Since buying nfts from the pool results in the pool having less nfts, we decrease the number of items for all calculations.
        // Vice versa for selling.
        int256 sign = isBuy ? -1 : int8(1);

        int256 _numItems = int256(numItems);
        int256 newNumItems = sigmoidParams.deltaN + sign * _numItems;
        // Ensure deltaN -/+ _numItems can be safecasted for 64.64 bit computations
        if (!valid64x64Int(sigmoidParams.deltaN + sign * _numItems)) revert TooManyItems();

        newParams.state = encodeState(newNumItems);

        // Iterate to calculate values. No closed form expression for discrete
        // sigmoid steps
        uint256 itemCost;

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;
        uint256 itemRoyalty;

        // We decrease / increase by n iteratively to the new price at fixedPointN for each NFT bought
        // ie. P(newDeltaN) = P_min + (P_max - P_min) / (1 + 2 ** (k * newDeltaN))
        // = P_min + deltaP / (1 + 2 ** (k * (deltaN -/+ n)))
        // = P_min + deltaP * (1 / (1 + 2 ** (k * (deltaN -/+ n))))
        // the loop calculates the sum of 1 / (1 + 2 ** (k * (deltaN + n))) before we apply scaling by deltaP
        for (int256 n = 1; n <= _numItems;) {
            // Locally scoped to avoid stack too deep
            {
                int128 kDeltaN = ABDKMath64x64.fromInt(sigmoidParams.deltaN + sign * n).mul(sigmoidParams.k);
                // fraction = 1 / (1 + 2 ** (k * (deltaN + n)))
                int128 fraction = ONE_64_64.div(ONE_64_64.add(kDeltaN.exp_2()));

                itemCost = sigmoidParams.pMin + fraction.mulu(sigmoidParams.deltaP);
                value += itemCost;
            }

            itemRoyalty = itemCost.fmul(feeMultipliers.royaltyNumerator, FEE_DENOMINATOR);
            fees.royalties[uint256(n) - 1] = itemRoyalty;
            totalRoyalty += itemRoyalty;

            unchecked {
                ++n;
            }
        }

        /// @dev royalty breakdown not needed if fees aren't used
        (lastSwapPrice,) = isBuy
            ? getInputValueAndFees(feeMultipliers, itemCost, new uint256[](0), itemRoyalty)
            : getOutputValueAndFees(feeMultipliers, itemCost, new uint256[](0), itemRoyalty);

        (value, fees) = isBuy
            ? getInputValueAndFees(feeMultipliers, value, fees.royalties, totalRoyalty)
            : getOutputValueAndFees(feeMultipliers, value, fees.royalties, totalRoyalty);

        // Set new spotPrice and delta equal to old spotPrice and delta
        // as neither changes for this curve
        newParams.spotPrice = params.spotPrice;
        newParams.delta = params.delta;
    }

    /// Helper functions
    function valid64x64Uint(uint256 value) private pure returns (bool) {
        return value <= 0x7FFFFFFFFFFFFFFF;
    }

    function valid64x64Int(int256 value) private pure returns (bool) {
        return value >= -0x8000000000000000 && value <= 0x7FFFFFFFFFFFFFFF;
    }

    /**
     * @param params The params for this curve
     * @return (minPrice, maxPrice - minPrice)
     */
    function getPriceRange(bytes calldata params) private pure returns (uint256, uint256) {
        return abi.decode(params, (uint256, uint256));
    }

    /**
     * @param state The state of this curve
     * @return The signed integer value of deltaN
     */
    function getDeltaN(bytes calldata state) private pure returns (int256) {
        if (state.length != 32) {
            return 0;
        }

        return abi.decode(state, (int256));
    }

    /**
     * @param deltaN The value of (n - n_0) at the moment
     * @return The encoded state of the curve
     */
    function encodeState(int256 deltaN) private pure returns (bytes memory) {
        return abi.encode(deltaN);
    }

    /**
     * @param delta The delta for this curve
     * @return The value of k for this curve, normalized, as a 64.64 bit fixed
     * point number.
     */
    function getK(uint128 delta) private pure returns (int128) {
        /// @dev Implicit upcast to uint256
        return ABDKMath64x64.fromUInt(delta) >> K_NORMALIZATION_EXPONENT;
    }

    /**
     * @param delta The delta for this curve
     * @param params The params for this curve
     * @param state The state of this curve
     * @return
     */
    function getSigmoidParameters(uint128 delta, bytes calldata params, bytes calldata state)
        private
        pure
        returns (SigmoidParameters memory)
    {
        int128 k = getK(delta);
        int256 deltaN = getDeltaN(state);
        (uint256 pMin, uint256 deltaP) = getPriceRange(params);
        return SigmoidParameters({k: k, deltaN: deltaN, pMin: pMin, deltaP: deltaP});
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Curve} from "./Curve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {FixedPointMathLib} from "../lib/FixedPointMathLib.sol";

/*
    @author Collection
    @notice Bonding curve logic for a linear curve, where each buy/sell changes spot price by adding/substracting delta*/
contract LinearCurve is Curve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    /**
     * @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(Params calldata params, uint256 numItems, FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Params memory newParams, uint256 inputValue, Fees memory fees, uint256 lastSwapPrice)
    {
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) revert InvalidNumItems();

        // For a linear curve, the spot price increases by delta for each item bought
        uint256 newSpotPrice_ = params.spotPrice + params.delta * numItems;
        if (newSpotPrice_ > type(uint128).max) revert SpotPriceOverflow();
        newParams.spotPrice = uint128(newSpotPrice_);

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S+delta).
        // The same person could then sell for (S+delta) ETH, netting them delta ETH profit.
        // If spot price for buy and sell differ by delta, then buying costs (S+delta) ETH.
        // The new spot price would become (S+delta), so selling would also yield (S+delta) ETH.
        uint256 buySpotPrice = params.spotPrice + params.delta;

        /// @dev For an arithmetic progression the total price is the average buy price
        /// multiplied by the number of items bought, where average buy price is
        /// the average of first and last transacted price. These are buySpotPrice
        /// and newSpotPrice respectively
        inputValue = numItems * (buySpotPrice + newParams.spotPrice) / 2;

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;
        uint256 royaltyAmount;
        uint256 rawAmount = params.spotPrice;
        for (uint256 i = 0; i < numItems;) {
            rawAmount += params.delta;
            royaltyAmount = rawAmount.fmul(feeMultipliers.royaltyNumerator, FEE_DENOMINATOR);
            fees.royalties[i] = royaltyAmount;
            totalRoyalty += royaltyAmount;

            unchecked {
                ++i;
            }
        }

        /// @dev royalty breakdown not needed if fees aren't used
        (lastSwapPrice,) = getInputValueAndFees(feeMultipliers, rawAmount, new uint256[](0), royaltyAmount);
        (inputValue, fees) = getInputValueAndFees(feeMultipliers, inputValue, fees.royalties, totalRoyalty);

        // Keep delta the same
        newParams.delta = params.delta;

        // Keep state the same
        newParams.state = params.state;
    }

    /**
     * @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(Params calldata params, uint256 numItems, FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Params memory newParams, uint256 outputValue, Fees memory fees, uint256 lastSwapPrice)
    {
        // We only calculate changes for selling 1 or more NFTs
        if (numItems == 0) revert InvalidNumItems();

        // We first calculate the change in spot price after selling all of the items
        uint256 totalPriceDecrease = params.delta * numItems;

        // If the current spot price is less than the total amount that the spot price should change by...
        if (params.spotPrice < totalPriceDecrease) {
            // Then we set the new spot price to be 0. (Spot price is never negative)
            newParams.spotPrice = 0;

            // We calculate how many items we can sell into the linear curve until the spot price reaches 0, rounding up
            uint256 numItemsTillZeroPrice = params.spotPrice / params.delta + 1;
            numItems = numItemsTillZeroPrice;
        }
        // Otherwise, the current spot price is greater than or equal to the total amount that the spot price changes
        // Thus we don't need to calculate the maximum number of items until we reach zero spot price, so we don't modify numItems
        else {
            // The new spot price is just the change between spot price and the total price change
            newParams.spotPrice = params.spotPrice - uint128(totalPriceDecrease);
        }

        uint256 rawAmount = uint256(params.spotPrice) + params.delta;

        // lastSpotPrice is the spot price of the last nft which the user sells into the pool.
        // lastSpotPrice will always be non-negative, a.k.a won't underflow.
        // Case 1: spotPrice < totalPriceDecrease
        //   lastSpotPrice = spotPrice + delta - (delta * numItems) >= 0
        //   => spotPrice + delta >= delta * numItems
        //   => numItems <= spotPrice / delta + 1
        //   which is true because numItems = spotPrice / delta + 1 <= spotPrice / delta + 1 because of integer division
        // Case 2: spotPrice >= totalPriceDecrease
        //   0 <= spotPrice - totalPriceDecrease
        //      = spotPrice - (delta * numItems)
        //      <= spotPrice + delta - (delta * numItems), because 0 <= delta
        //      = lastSpotPrice
        uint256 lastSpotPrice = rawAmount - (params.delta * numItems);

        /// @dev For an arithmetic progression the total price is the average sell price
        /// multiplied by the number of items sold, where average buy price is
        /// the average of first and last transacted price. These are spotPrice
        /// and lastSpotPrice respectively
        outputValue = numItems * (lastSpotPrice + params.spotPrice) / 2;

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;
        uint256 royaltyAmount;
        for (uint256 i = 0; i < numItems;) {
            rawAmount -= params.delta;
            royaltyAmount = rawAmount.fmul(feeMultipliers.royaltyNumerator, FEE_DENOMINATOR);
            fees.royalties[i] = royaltyAmount;
            totalRoyalty += royaltyAmount;

            unchecked {
                ++i;
            }
        }

        /// @dev royalty breakdown not needed if fee return value not used
        (lastSwapPrice,) = getOutputValueAndFees(feeMultipliers, rawAmount, new uint256[](0), royaltyAmount);
        (outputValue, fees) = getOutputValueAndFees(feeMultipliers, outputValue, fees.royalties, totalRoyalty);

        // Keep delta the same
        newParams.delta = params.delta;

        // Keep state the same
        newParams.state = params.state;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Curve} from "./Curve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {FixedPointMathLib} from "../lib/FixedPointMathLib.sol";

/**
 * @author Collection
 * @notice Bonding curve logic for an exponential curve, where each buy/sell
 * changes spot price by multiplying/dividing delta. To prevent price slippage,
 * the `state` of pools is used to store the change in number of NFTs this pool
 * has. This value is only updated upon swaps, so depositing/withdrawing does
 * not change the prices quoted by the pool.
 *
 *
 * @dev This curve stores the initial spotPrice in spotPrice and does not update
 * its value. delta is the percent change per nft traded and 1e18 is unity (i.e.
 * price will not change and curve is horizontal). State encodes the change in
 * number of NFTs this pool has.
 */
contract ExponentialCurve is Curve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    /**
     * @dev See {ICurve-validateDelta}
     */
    function validateDelta(uint128 delta) external pure override returns (bool) {
        return delta > FixedPointMathLib.WAD;
    }

    /**
     * @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(Params calldata params, uint256 numItems, FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Params memory newParams, uint256 inputValue, Fees memory fees, uint256 lastSwapPrice)
    {
        // NOTE: we assume delta is > 1, as checked by validateDelta()
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) revert InvalidNumItems();

        if (numItems > uint256(type(int256).max)) revert TooManyItems();

        uint128 delta = params.delta;
        int256 deltaN = decodeDeltaN(params.state);

        newParams.spotPrice = params.spotPrice;
        newParams.delta = delta;
        newParams.state = encodeDeltaN(deltaN - int256(numItems));

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S * delta).
        // The same person could then sell for (S * delta) ETH, netting them delta ETH profit.
        // If spot price for buy and sell differ by delta, then buying costs (S * delta) ETH.
        // The new spot price would become (S * delta), so selling would also yield (S * delta) ETH.

        /// @dev The buy now price of 1 item is spotPrice * delta ^ (1 - deltaN).
        /// It is convenient for now to calculate spotPrice * delta ^ (-deltaN).
        /// FixedPointMathLib takes only nonnegative exponents. Thus,
        /// if -deltaN < 0 i.e. deltaN >= 0, then we can do the exponentiation
        /// by calculating spotPrice * (1/delta) ^ (deltaN). If deltaN == 0 however,
        /// we do not need to do exponentiation or division so we check for deltaN > 0.
        uint256 deltaPowQty = deltaN > 0
            ? FixedPointMathLib.WAD.fdiv(delta, FixedPointMathLib.WAD).fpow(uint256(deltaN), FixedPointMathLib.WAD)
            : uint256(delta).fpow(uint256(-deltaN), FixedPointMathLib.WAD);
        uint256 rawAmount = uint256(params.spotPrice).fmul(deltaPowQty, FixedPointMathLib.WAD);
        uint256 buySpotPrice = rawAmount.fmul(delta, FixedPointMathLib.WAD);

        uint256 deltaPowN = uint256(delta).fpow(numItems, FixedPointMathLib.WAD);
        // If the user buys n items, then the total cost is equal to:
        // buySpotPrice + (delta * buySpotPrice) + (delta^2 * buySpotPrice) + ... (delta^(numItems - 1) * buySpotPrice)
        // This is equal to (rawAmount * delta) * (delta^n - 1) / (delta - 1)
        // Note that this amount needs to have fees applied to it
        inputValue = buySpotPrice * (deltaPowN - FixedPointMathLib.WAD) / (delta - FixedPointMathLib.WAD);

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;
        uint256 royaltyAmount;
        /// @dev Loop to calculate royalty amounts and get last swap price
        for (uint256 i = 0; i < numItems;) {
            rawAmount = rawAmount.fmul(delta, FixedPointMathLib.WAD);
            royaltyAmount = rawAmount.fmul(feeMultipliers.royaltyNumerator, FEE_DENOMINATOR);
            fees.royalties[i] = royaltyAmount;
            totalRoyalty += royaltyAmount;

            unchecked {
                ++i;
            }
        }

        /// @dev royalty breakdown not needed if fees aren't used
        (lastSwapPrice,) = getInputValueAndFees(feeMultipliers, rawAmount, new uint256[](0), royaltyAmount);

        (inputValue, fees) = getInputValueAndFees(feeMultipliers, inputValue, fees.royalties, totalRoyalty);
    }

    /**
     * @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(Params calldata params, uint256 numItems, FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Params memory newParams, uint256 outputValue, Fees memory fees, uint256 lastSwapPrice)
    {
        // NOTE: we assume delta is > 1, as checked by validateDelta()

        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) revert InvalidNumItems();

        if (numItems > uint256(type(int256).max)) revert TooManyItems();

        int256 deltaN = decodeDeltaN(params.state);
        uint128 delta = params.delta;

        newParams.spotPrice = params.spotPrice;
        newParams.delta = delta;
        newParams.state = encodeDeltaN(deltaN + int256(numItems));

        /// @dev The sell now price of 1 item is spotPrice * delta ^ (-deltaN).
        /// It is convenient for now to calculate spotPrice * delta ^ (1 - deltaN).
        /// FixedPointMathLib takes only nonnegative exponents. Thus,
        /// if 1 - deltaN < 0 i.e. deltaN > 1, then we can do the exponentiation
        /// by calculating spotPrice * (1/delta) ^ (deltaN - 1).

        uint256 rawAmount;
        uint256 deltaPowQty = deltaN > 1
            ? FixedPointMathLib.WAD.fdiv(delta, FixedPointMathLib.WAD).fpow(uint256(deltaN - 1), FixedPointMathLib.WAD)
            : uint256(delta).fpow(uint256(1 - deltaN), FixedPointMathLib.WAD);
        rawAmount = uint256(params.spotPrice).fmul(deltaPowQty, FixedPointMathLib.WAD);

        // If the user sells n items, then the total revenue is equal to:
        // ((1 / delta) * rawAmount) + ((1 / delta)^2 * rawAmount) + ... ((1 / delta)^(numItems) * rawAmount)
        // This is equal to (rawAmount / delta) * (1 - (1 / delta^n)) / (1 - (1 / delta))
        uint256 invDelta = FixedPointMathLib.WAD.fdiv(delta, FixedPointMathLib.WAD);
        uint256 invDeltaPowN = invDelta.fpow(numItems, FixedPointMathLib.WAD);
        outputValue = rawAmount.fdiv(delta, FixedPointMathLib.WAD) * (FixedPointMathLib.WAD - invDeltaPowN)
            / (FixedPointMathLib.WAD - invDelta);

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;
        uint256 royaltyAmount;
        /// @dev Loop to calculate royalty amounts and get last swap price
        for (uint256 i = 0; i < numItems;) {
            rawAmount = rawAmount.fdiv(delta, FixedPointMathLib.WAD);
            royaltyAmount = rawAmount.fmul(feeMultipliers.royaltyNumerator, FEE_DENOMINATOR);
            fees.royalties[i] = royaltyAmount;
            totalRoyalty += royaltyAmount;

            unchecked {
                ++i;
            }
        }

        /// @dev royalty breakdown not needed if fee return value not used
        (lastSwapPrice,) = getOutputValueAndFees(feeMultipliers, rawAmount, new uint256[](0), royaltyAmount);

        (outputValue, fees) = getOutputValueAndFees(feeMultipliers, outputValue, fees.royalties, totalRoyalty);
    }

    function decodeDeltaN(bytes calldata state) internal pure returns (int256) {
        if (state.length != 32) {
            return 0;
        }

        return abi.decode(state, (int256));
    }

    function encodeDeltaN(int256 deltaN) internal pure returns (bytes memory) {
        return abi.encode(deltaN);
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

contract ERC20Mintable is ERC20PresetMinterPauser, Ownable {
    constructor(string memory _name, string memory _symbol) ERC20PresetMinterPauser(_name, _symbol) {}

    /**
     * Only the owner (PackageFaucet) can call this.
     */
    function freeMint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract ERC721Mintable is ERC721, Pausable, Ownable, ERC721Burnable, ERC2981 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string standardURI;

    constructor(string memory _name, string memory _symbol, string memory _standardURI) ERC721(_name, _symbol) {
        // 1%
        _setDefaultRoyalty(msg.sender, 100);
        standardURI = _standardURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        standardURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return standardURI;
    }

    function freeMint(address to, uint256 amount) external onlyOwner returns (uint256[] memory) {
        uint256[] memory idsMinted = new uint256[](amount);
        uint256 tokenId = _tokenIdCounter.current();
        for (uint256 i; i < amount; ++i) {
            _safeMint(to, tokenId);
            idsMinted[i] = tokenId;
            tokenId++;
            _tokenIdCounter.increment();
        }

        return idsMinted;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override (ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

contract ETHFaucet is Pausable, Ownable {
    using SafeTransferLib for address payable;

    constructor() payable {}

    /**
     * @return true iff ETH was dispensed.
     */
    function freeMint(address to, uint256 amount) external onlyOwner returns (bool) {
        if (address(this).balance >= amount) {
            payable(to).safeTransferETH(amount);
            return true;
        }

        return false;
    }
}

contract PackageFaucet is Pausable, Ownable {
    ERC20Mintable public immutable erc20Faucet;
    ERC721Mintable public immutable erc721Faucet;
    ETHFaucet public immutable ethFaucet;

    uint256 public ERC20_MINT_AMOUNT = 1000;
    uint256 public ERC721_MINT_AMOUNT = 12;
    uint256 public ETH_MINT_AMOUNT = 0.005 ether;

    mapping(address => bool) public hasClaimed;

    /**
     * Only addresses where `allowed[address] == true` can call freeMint
     */
    mapping(address => bool) public allowed;

    /**
     * Events
     */
    event receivedETH(uint256 amount);
    event insufficientETH(address to);
    event dispensedETH(address to);
    event dispensedERC20(address to);
    event dispensedERC721(uint256[] nftIds, address to);
    event addressWhitelisted(address[] addresses);

    constructor(
        string memory erc20Name,
        string memory erc20Symbol,
        string memory erc721Name,
        string memory erc721Symbol,
        string memory erc721StandardURI,
        address[] memory allowedUsers
    ) payable {
        erc20Faucet = new ERC20Mintable(erc20Name, erc20Symbol);
        erc721Faucet = new ERC721Mintable(erc721Name, erc721Symbol, erc721StandardURI);
        ethFaucet = new ETHFaucet{value: msg.value}();

        /// @dev Approve the initial list of participants
        uint256 length = allowedUsers.length;
        for (uint256 i = 0; i < length;) {
            allowed[allowedUsers[i]] = true;

            unchecked {
                ++i;
            }
        }

        emit addressWhitelisted(allowedUsers);
    }

    /**
     * @notice Dispense ETH, ERC20 tokens, and ERC721 tokens to the specified
     * address
     */
    function freeMint(address to) external {
        require(allowed[msg.sender], "Not an approved faucet user");
        require(!hasClaimed[msg.sender], "Caller already used");
        hasClaimed[msg.sender] = true;

        erc20Faucet.freeMint(to, ERC20_MINT_AMOUNT);
        uint256[] memory idsMinted = erc721Faucet.freeMint(to, ERC721_MINT_AMOUNT);
        bool ethDispensed = ethFaucet.freeMint(to, ETH_MINT_AMOUNT);

        if (ethDispensed) {
            emit dispensedETH(to);
        } else {
            emit insufficientETH(to);
        }
        emit dispensedERC20(to);
        emit dispensedERC721(idsMinted, to);
    }

    /**
     * @notice Allow an address to call `freeMint`.
     */
    function approveUser(address[] calldata addresses) external onlyOwner {
        uint256 length = addresses.length;
        for (uint256 i = 0; i < length;) {
            allowed[addresses[i]] = true;
            unchecked {
                ++i;
            }
        }

        emit addressWhitelisted(addresses);
    }

    /**
     * @notice Pause the usage of this faucet
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the usage of this faucet
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Set the base token URI for the NFT collection this faucet dispenses
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        erc721Faucet.setBaseURI(_uri);
    }

    /**
     * @notice Returns the tokenURI for the tokenId given of the NFT collection
     * this faucet dispenses
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return erc721Faucet.tokenURI(tokenId);
    }

    /**
     * Proxy for calling the same function on the NFT collection this faucet
     * dispenses
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return erc721Faucet.supportsInterface(interfaceId);
    }

    /**
     * @notice Recharge the pool's ETH balance
     */
    function rechargeETH() external payable {
        emit receivedETH(msg.value);
    }

    /**
     * @dev All ETH transfers into the faucet are accepted. This is functionally
     * equivalent to recharging the pool.
     */
    receive() external payable {
        emit receivedETH(msg.value);
    }

    /**
     * @dev All ETH transfers into the faucet are accepted. This is functionally
     * equivalent to recharging the pool.
     */
    fallback() external payable {
        emit receivedETH(msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IOwnershipTransferCallback} from "./IOwnershipTransferCallback.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract OwnableWithTransferCallback {
    using ERC165Checker for address;
    using Address for address;

    bytes4 constant TRANSFER_CALLBACK =
        type(IOwnershipTransferCallback).interfaceId;

    error Ownable_NotOwner();
    error Ownable_NewOwnerZeroAddress();

    address private _owner;

    event OwnershipTransferred(address indexed newOwner);

    /// @dev Initializes the contract setting the deployer as the initial owner.
    function __Ownable_init(address initialOwner) internal {
        _owner = initialOwner;
    }

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (owner() != msg.sender) revert Ownable_NotOwner();
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Disallows setting to the zero address as a way to more gas-efficiently avoid reinitialization
    /// When ownership is transferred, if the new owner implements IOwnershipTransferCallback, we make a callback
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Ownable_NewOwnerZeroAddress();
        _transferOwnership(newOwner);

        // Call the on ownership transfer callback if it exists
        // @dev try/catch is around 5k gas cheaper than doing ERC165 checking
        if (newOwner.isContract()) {
            try
                IOwnershipTransferCallback(newOwner).onOwnershipTransfer(msg.sender)
            {} catch (bytes memory) {}
        }
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Internal function without access restriction.
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

interface IOwnershipTransferCallback {
  function onOwnershipTransfer(address oldOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

/**
 *Submitted for verification at Etherscan.io on 2019-04-03
*/

/* ERC1820 Pseudo-introspection Registry Contract
 * This standard defines a universal registry smart contract where any address (contract or regular account) can
 * register which interface it supports and which smart contract is responsible for its implementation.
 *
 * Written in 2019 by Jordi Baylina and Jacques Dafflon
 *
 * To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to
 * this software to the public domain worldwide. This software is distributed without any warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 *
 *    ███████╗██████╗  ██████╗ ██╗ █████╗ ██████╗  ██████╗
 *    ██╔════╝██╔══██╗██╔════╝███║██╔══██╗╚════██╗██╔═████╗
 *    █████╗  ██████╔╝██║     ╚██║╚█████╔╝ █████╔╝██║██╔██║
 *    ██╔══╝  ██╔══██╗██║      ██║██╔══██╗██╔═══╝ ████╔╝██║
 *    ███████╗██║  ██║╚██████╗ ██║╚█████╔╝███████╗╚██████╔╝
 *    ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝ ╚════╝ ╚══════╝ ╚═════╝
 *
 *    ██████╗ ███████╗ ██████╗ ██╗███████╗████████╗██████╗ ██╗   ██╗
 *    ██╔══██╗██╔════╝██╔════╝ ██║██╔════╝╚══██╔══╝██╔══██╗╚██╗ ██╔╝
 *    ██████╔╝█████╗  ██║  ███╗██║███████╗   ██║   ██████╔╝ ╚████╔╝
 *    ██╔══██╗██╔══╝  ██║   ██║██║╚════██║   ██║   ██╔══██╗  ╚██╔╝
 *    ██║  ██║███████╗╚██████╔╝██║███████║   ██║   ██║  ██║   ██║
 *    ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝
 *
 */
pragma solidity ^0.8.4;
// IV is value needed to have a vanity address starting with '0x1820'.
// IV: 53759

/// @dev The interface a contract MUST implement if it is the implementer of
/// some (other) interface for any address other than itself.
interface ERC1820ImplementerInterface {
    /// @notice Indicates whether the contract implements the interface 'interfaceHash' for the address 'addr' or not.
    /// @param interfaceHash keccak256 hash of the name of the interface
    /// @param addr Address for which the contract will implement the interface
    /// @return ERC1820_ACCEPT_MAGIC only if the contract implements 'interfaceHash' for the address 'addr'.
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address addr) external view returns(bytes32);
}


/// @title ERC1820 Pseudo-introspection Registry Contract
/// @author Jordi Baylina and Jacques Dafflon
/// @notice This contract is the official implementation of the ERC1820 Registry.
/// @notice For more details, see https://eips.ethereum.org/EIPS/eip-1820
contract ERC1820Registry {
    /// @notice ERC165 Invalid ID.
    bytes4 constant internal INVALID_ID = 0xffffffff;
    /// @notice Method ID for the ERC165 supportsInterface method (= `bytes4(keccak256('supportsInterface(bytes4)'))`).
    bytes4 constant internal ERC165ID = 0x01ffc9a7;
    /// @notice Magic value which is returned if a contract implements an interface on behalf of some other address.
    bytes32 constant internal ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

    /// @notice mapping from addresses and interface hashes to their implementers.
    mapping(address => mapping(bytes32 => address)) internal interfaces;
    /// @notice mapping from addresses to their manager.
    mapping(address => address) internal managers;
    /// @notice flag for each address and erc165 interface to indicate if it is cached.
    mapping(address => mapping(bytes4 => bool)) internal erc165Cached;

    /// @notice Indicates a contract is the 'implementer' of 'interfaceHash' for 'addr'.
    event InterfaceImplementerSet(address indexed addr, bytes32 indexed interfaceHash, address indexed implementer);
    /// @notice Indicates 'newManager' is the address of the new manager for 'addr'.
    event ManagerChanged(address indexed addr, address indexed newManager);

    /// @notice Query if an address implements an interface and through which contract.
    /// @param _addr Address being queried for the implementer of an interface.
    /// (If '_addr' is the zero address then 'msg.sender' is assumed.)
    /// @param _interfaceHash Keccak256 hash of the name of the interface as a string.
    /// E.g., 'web3.utils.keccak256("ERC777TokensRecipient")' for the 'ERC777TokensRecipient' interface.
    /// @return The address of the contract which implements the interface '_interfaceHash' for '_addr'
    /// or '0' if '_addr' did not register an implementer for this interface.
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address) {
        address addr = _addr == address(0) ? msg.sender : _addr;
        if (isERC165Interface(_interfaceHash)) {
            bytes4 erc165InterfaceHash = bytes4(_interfaceHash);
            return implementsERC165Interface(addr, erc165InterfaceHash) ? addr : address(0);
        }
        return interfaces[addr][_interfaceHash];
    }

    /// @notice Sets the contract which implements a specific interface for an address.
    /// Only the manager defined for that address can set it.
    /// (Each address is the manager for itself until it sets a new manager.)
    /// @param _addr Address for which to set the interface.
    /// (If '_addr' is the zero address then 'msg.sender' is assumed.)
    /// @param _interfaceHash Keccak256 hash of the name of the interface as a string.
    /// E.g., 'web3.utils.keccak256("ERC777TokensRecipient")' for the 'ERC777TokensRecipient' interface.
    /// @param _implementer Contract address implementing '_interfaceHash' for '_addr'.
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external {
        address addr = _addr == address(0) ? msg.sender : _addr;
        require(getManager(addr) == msg.sender, "Not the manager");

        require(!isERC165Interface(_interfaceHash), "Must not be an ERC165 hash");
        if (_implementer != address(0) && _implementer != msg.sender) {
            require(
                ERC1820ImplementerInterface(_implementer)
                .canImplementInterfaceForAddress(_interfaceHash, addr) == ERC1820_ACCEPT_MAGIC,
                "Does not implement the interface"
            );
        }
        interfaces[addr][_interfaceHash] = _implementer;
        emit InterfaceImplementerSet(addr, _interfaceHash, _implementer);
    }

    /// @notice Sets '_newManager' as manager for '_addr'.
    /// The new manager will be able to call 'setInterfaceImplementer' for '_addr'.
    /// @param _addr Address for which to set the new manager.
    /// @param _newManager Address of the new manager for 'addr'. (Pass '0x0' to reset the manager to '_addr'.)
    function setManager(address _addr, address _newManager) external {
        require(getManager(_addr) == msg.sender, "Not the manager");
        managers[_addr] = _newManager == _addr ? address(0) : _newManager;
        emit ManagerChanged(_addr, _newManager);
    }

    /// @notice Get the manager of an address.
    /// @param _addr Address for which to return the manager.
    /// @return Address of the manager for a given address.
    function getManager(address _addr) public view returns(address) {
        // By default the manager of an address is the same address
        if (managers[_addr] == address(0)) {
            return _addr;
        } else {
            return managers[_addr];
        }
    }

    /// @notice Compute the keccak256 hash of an interface given its name.
    /// @param _interfaceName Name of the interface.
    /// @return The keccak256 hash of an interface name.
    function interfaceHash(string calldata _interfaceName) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(_interfaceName));
    }

    /* --- ERC165 Related Functions --- */
    /* --- Developed in collaboration with William Entriken. --- */

    /// @notice Updates the cache with whether the contract implements an ERC165 interface or not.
    /// @param _contract Address of the contract for which to update the cache.
    /// @param _interfaceId ERC165 interface for which to update the cache.
    function updateERC165Cache(address _contract, bytes4 _interfaceId) external {
        interfaces[_contract][_interfaceId] = implementsERC165InterfaceNoCache(
            _contract, _interfaceId) ? _contract : address(0);
        erc165Cached[_contract][_interfaceId] = true;
    }

    /// @notice Checks whether a contract implements an ERC165 interface or not.
    //  If the result is not cached a direct lookup on the contract address is performed.
    //  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
    //  'updateERC165Cache' with the contract address.
    /// @param _contract Address of the contract to check.
    /// @param _interfaceId ERC165 interface to check.
    /// @return True if '_contract' implements '_interfaceId', false otherwise.
    function implementsERC165Interface(address _contract, bytes4 _interfaceId) public view returns (bool) {
        if (!erc165Cached[_contract][_interfaceId]) {
            return implementsERC165InterfaceNoCache(_contract, _interfaceId);
        }
        return interfaces[_contract][_interfaceId] == _contract;
    }

    /// @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
    /// @param _contract Address of the contract to check.
    /// @param _interfaceId ERC165 interface to check.
    /// @return True if '_contract' implements '_interfaceId', false otherwise.
    function implementsERC165InterfaceNoCache(address _contract, bytes4 _interfaceId) public view returns (bool) {
        uint256 success;
        uint256 result;

        (success, result) = noThrowCall(_contract, ERC165ID);
        if (success == 0 || result == 0) {
            return false;
        }

        (success, result) = noThrowCall(_contract, INVALID_ID);
        if (success == 0 || result != 0) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if (success == 1 && result == 1) {
            return true;
        }
        return false;
    }

    /// @notice Checks whether the hash is a ERC165 interface (ending with 28 zeroes) or not.
    /// @param _interfaceHash The hash to check.
    /// @return True if '_interfaceHash' is an ERC165 interface (ending with 28 zeroes), false otherwise.
    function isERC165Interface(bytes32 _interfaceHash) internal pure returns (bool) {
        return _interfaceHash & 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0;
    }

    /// @dev Make a call on a contract without throwing if the function does not exist.
    function noThrowCall(address _contract, bytes4 _interfaceId)
    internal view returns (uint256 success, uint256 result)
    {
        bytes4 erc165ID = ERC165ID;

        assembly {
            let x := mload(0x40)               // Find empty storage location using "free memory pointer"
            mstore(x, erc165ID)                // Place signature at beginning of empty storage
            mstore(add(x, 0x04), _interfaceId) // Place first argument directly next to signature

            success := staticcall(
            30000,                         // 30k gas
            _contract,                     // To addr
            x,                             // Inputs are stored at location x
            0x24,                          // Inputs are 36 (4 + 32) bytes long
            x,                             // Store output over input (saves space)
            0x20                           // Outputs are 32 bytes long
            )

            result := mload(x)                 // Load the result
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

/**
 * @title Abstract manageable contract that can be inherited by other contracts
 * @notice Contract module based on Ownable which provides a basic access control mechanism, where
 * there is an owner and a manager that can be granted exclusive access to specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
abstract contract Manageable is Ownable {
    address private _manager;

    /**
     * @dev Emitted when `_manager` has been changed.
     * @param previousManager previous `_manager` address.
     * @param newManager new `_manager` address.
     */
    event ManagerTransferred(address indexed previousManager, address indexed newManager);

    /* ============ External Functions ============ */

    /**
     * @notice Gets current `_manager`.
     * @return Current `_manager` address.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @notice Set or change of manager.
     * @dev Throws if called by any account other than the owner.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function setManager(address _newManager) external onlyOwner returns (bool) {
        return _setManager(_newManager);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set or change of manager.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function _setManager(address _newManager) private returns (bool) {
        address _previousManager = _manager;

        require(_newManager != _previousManager, "Manageable/existing-manager-address");

        _manager = _newManager;

        emit ManagerTransferred(_previousManager, _newManager);
        return true;
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == msg.sender, "Manageable/caller-not-manager");
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager or the owner.
     */
    modifier onlyManagerOrOwner() {
        require(manager() == msg.sender || owner() == msg.sender, "Manageable/caller-not-manager-or-owner");
        _;
    }
}
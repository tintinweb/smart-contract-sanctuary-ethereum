// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IPoolsharkHedgePoolStructs {
    struct GlobalState {
        uint8  unlocked;
        int24  latestTick; /// @dev Latest updated inputPool price tick
        uint32 accumEpoch;
        uint32 lastBlockNumber;
        uint24 swapFee;
        int24  tickSpacing;
    }
    
    //TODO: adjust nearestTick if someone burns all liquidity from current nearestTick
    struct PoolState {
        uint128 liquidity;             /// @dev Liquidity currently active
        uint128 feeGrowthCurrentEpoch; /// @dev Global fee growth per liquidity unit in current epoch
        uint160 price;                 /// @dev Starting price current
        int24   nearestTick;           /// @dev Tick below current price
        int24   lastTick;              /// @dev Last tick accumulated to
    }

    struct TickNode {
        int24    previousTick;
        int24    nextTick;
        uint32   accumEpochLast;   // Used to check for claim updates
    }

    struct Tick {
        int104  liquidityDelta;      //TODO: if feeGrowthGlobalIn > position.feeGrowthGlobal don't update liquidity
        uint104 liquidityDeltaMinus; // represent LPs for token0 -> token1
        int88   amountInDelta;       //TODO: amount deltas are Q24x64 ; should always be negative?
        int88   amountOutDelta;      //TODO: make sure this won't overflow if amount is unfilled; should always be positive
        uint64  amountInDeltaCarryPercent;
        uint64  amountOutDeltaCarryPercent;
    }
 
    // balance needs to be immediately transferred to the position owner
    struct Position {
        uint128 liquidity;           // expected amount to be used not actual
        uint32  accumEpochLast; // last feeGrowth this position was updated at
        uint160 claimPriceLast;      // highest price claimed at
        uint128 amountIn;            // token amount already claimed; balance
        uint128 amountOut;           // necessary for non-custodial positions
    }

    //TODO: should we have a recipient field here?
    struct AddParams {
        address owner;
        int24 lowerOld;
        int24 lower;
        int24 upper;
        int24 upperOld;
        bool zeroForOne;
        uint128 amount;
    }

    struct RemoveParams {
        address owner;
        int24 lower;
        int24 upper;
        bool zeroForOne;
        uint128 amount;
    }

    struct UpdateParams {
        address owner;
        int24 lower;
        int24 upper;
        int24 claim;
        bool zeroForOne;
        int128 amount;
    }

    //TODO: optimize this struct
    struct SwapCache {
        uint256 price;
        uint256 liquidity;
        uint256 feeAmount;
        uint256 input;
    }

    struct PositionCache {
        Position position;
        uint160 priceLower;
        uint160 priceUpper;
    }

    struct UpdatePositionCache {
        Position position;
        uint232 feeGrowthCurrentEpoch;
        uint160 priceLower;
        uint160 priceUpper;
        uint160 claimPrice;
        TickNode claimTick;
        bool removeLower;
        bool removeUpper;
        int128 amountInDelta;
        int128 amountOutDelta;
    }

    struct AccumulateCache {
        int24   nextTickToCross0;
        int24   nextTickToCross1;
        int24   nextTickToAccum0;
        int24   nextTickToAccum1;
        int24   stopTick0;
        int24   stopTick1;
        int128  amountInDelta0; 
        int128  amountInDelta1; 
        int128  amountOutDelta0;
        int128  amountOutDelta1;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./FullPrecisionMath.sol";
import "hardhat/console.sol";

/// @notice Math library that facilitates ranged liquidity calculations.
library DyDxMath
{
    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (uint256 dy) {
        return _getDy(liquidity, priceLower, priceUpper, roundUp);
    }

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (uint256 dx) {
        return _getDx(liquidity, priceLower, priceUpper, roundUp);
    }

    function _getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dy) {
        unchecked {
            if (roundUp) {
                dy = FullPrecisionMath.mulDivRoundingUp(liquidity, priceUpper - priceLower, 0x1000000000000000000000000);
            } else {
                dy = FullPrecisionMath.mulDiv(liquidity, priceUpper - priceLower, 0x1000000000000000000000000);
            }
        }
    }

    function _getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        unchecked {
            if (roundUp) {
                dx = FullPrecisionMath.divRoundingUp(FullPrecisionMath.mulDivRoundingUp(liquidity << 96, priceUpper - priceLower, priceUpper), priceLower);
            } else {
                dx = FullPrecisionMath.mulDiv(liquidity << 96, priceUpper - priceLower, priceUpper) / priceLower;
            }
        }
    }

    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) external pure returns (uint256 liquidity) {
        unchecked {
            if (priceUpper <= currentPrice) {
                liquidity = FullPrecisionMath.mulDiv(dy, 0x1000000000000000000000000, priceUpper - priceLower);
            } else if (currentPrice <= priceLower) {
                liquidity = FullPrecisionMath.mulDiv(
                    dx,
                    FullPrecisionMath.mulDiv(priceLower, priceUpper, 0x1000000000000000000000000),
                    priceUpper - priceLower
                );
            } else {
                uint256 liquidity1 = FullPrecisionMath.mulDiv(dy, 0x1000000000000000000000000, currentPrice - priceLower);
                liquidity = liquidity1;
            }
        }
    }

    function getAmountsForLiquidity(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 liquidityAmount,
        bool roundUp
    ) external view returns (uint128 token0amount, uint128 token1amount) {
        if (priceUpper <= currentPrice) {
            // Only supply `token1` (`token1` is Y).
            //TODO: confirm casting is safe
            token1amount = uint128(_getDy(liquidityAmount, priceLower, priceUpper, roundUp));
        } else if (currentPrice <= priceLower) {
            // Only supply `token0` (`token0` is X).
            token0amount = uint128(_getDx(liquidityAmount, priceLower, priceUpper, roundUp));
        } else {
            // Supply both tokens.
            token0amount = uint128(_getDx(liquidityAmount, currentPrice, priceUpper, roundUp));
            token1amount = uint128(_getDy(liquidityAmount, priceLower, currentPrice, roundUp));
        }
        console.log("tokenIn amount:        ", token0amount);
        console.log("tokenOut amount:       ", token1amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library FullPrecisionMath
{
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result) {
        return _mulDiv(a, b, denominator);
    }

    // @dev no underflow or overflow checks
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result) {
        return _mulDivRoundingUp(a, b, denominator);
    }

    /// @notice Calculates floor(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    function _mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b.
            // Compute the product mod 2**256 and mod 2**256 - 1,
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product.
            uint256 prod1; // Most significant 256 bits of the product.
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }
            // Make sure the result is less than 2**256 -
            // also prevents denominator == 0.
            require(denominator > prod1);
            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////
            // Make division exact by subtracting the remainder from [prod1 prod0] -
            // compute remainder using mulmod.
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number.
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }
            // Factor powers of two out of denominator -
            // compute largest power of two divisor of denominator
            // (always >= 1).
            uint256 twos = uint256(-int256(denominator)) & denominator;
            // Divide denominator by power of two.
            assembly {
                denominator := div(denominator, twos)
            }
            // Divide [prod1 prod0] by the factors of two.
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos -
            // if twos is zero, then it becomes one.
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;
            // Invert denominator mod 2**256 -
            // now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // for four bits. That is, denominator * inv = 1 mod 2**4.
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // Inverse mod 2**8.
            inv *= 2 - denominator * inv; // Inverse mod 2**16.
            inv *= 2 - denominator * inv; // Inverse mod 2**32.
            inv *= 2 - denominator * inv; // Inverse mod 2**64.
            inv *= 2 - denominator * inv; // Inverse mod 2**128.
            inv *= 2 - denominator * inv; // Inverse mod 2**256.
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

    /// @notice Calculates ceil(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    function _mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = _mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) != 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "./TickMath.sol";
import "./Ticks.sol";
import "../interfaces/IPoolsharkHedgePoolStructs.sol";
import "hardhat/console.sol";
import "./FullPrecisionMath.sol";
import "./DyDxMath.sol";

/// @notice Position management library for ranged liquidity.
library Positions
{
    error NotEnoughPositionLiquidity();
    error InvalidClaimTick();
    error WrongTickClaimedAt();
    error PositionNotUpdated();

    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    using Positions for mapping(int24 => IPoolsharkHedgePoolStructs.Tick);

    function getMaxLiquidity(int24 tickSpacing) external pure returns (uint128) {
        return type(uint128).max / uint128(uint24(TickMath.MAX_TICK) / (2 * uint24(tickSpacing)));
    }

    function add(
        mapping(address => mapping(int24 => mapping(int24 => IPoolsharkHedgePoolStructs.Position))) storage positions,
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        IPoolsharkHedgePoolStructs.GlobalState storage state,
        IPoolsharkHedgePoolStructs.AddParams memory params
    ) external returns (uint128) {
        //TODO: dilute amountDeltas when adding liquidity
        IPoolsharkHedgePoolStructs.PositionCache memory cache = IPoolsharkHedgePoolStructs.PositionCache({
            position: positions[params.owner][params.lower][params.upper],
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper)
        });
        /// call if claim != lower and liquidity being added
        /// initialize new position
        if (params.amount == 0) return 0;
        if (cache.position.liquidity == 0) {
            console.log('new position');
            cache.position.accumEpochLast = state.accumEpoch;
            cache.position.claimPriceLast = params.zeroForOne ? uint160(cache.priceUpper) : uint160(cache.priceLower);
        } else {
            /// validate user can still add to position
            if (params.zeroForOne ? state.latestTick < params.upper || tickNodes[params.upper].accumEpochLast > cache.position.accumEpochLast
                                  : state.latestTick > params.lower || tickNodes[params.lower].accumEpochLast > cache.position.accumEpochLast
            ) {
                revert WrongTickClaimedAt();
            }
        }

        Ticks.insert(
            ticks,
            tickNodes,
            params.lowerOld,
            params.lower,
            params.upperOld,
            params.upper,
            uint104(params.amount),
            params.zeroForOne
        );

        console.logInt(ticks[params.lower].liquidityDelta);
        console.logInt(ticks[params.upper].liquidityDelta);

        cache.position.liquidity += uint128(params.amount);
        console.log('position liquidity check:', cache.position.liquidity);


        positions[params.owner][params.lower][params.upper] = cache.position;
                console.log(positions[params.owner][params.lower][params.upper].liquidity);

        return params.amount;
    }

    function remove(
        mapping(address => mapping(int24 => mapping(int24 => IPoolsharkHedgePoolStructs.Position))) storage positions,
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        IPoolsharkHedgePoolStructs.GlobalState storage state,
        IPoolsharkHedgePoolStructs.RemoveParams memory params
    ) external returns (uint128) {
        //TODO: dilute amountDeltas when adding liquidity
        IPoolsharkHedgePoolStructs.PositionCache memory cache = IPoolsharkHedgePoolStructs.PositionCache({
            position: positions[params.owner][params.lower][params.upper],
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper)
        });
        /// call if claim != lower and liquidity being added
        /// initialize new position
        if (params.amount == 0) return 0;
        if (params.amount > cache.position.liquidity) {
            revert NotEnoughPositionLiquidity();
        } else {
            /// validate user can remove from position
            if (params.zeroForOne ? state.latestTick < params.upper || tickNodes[params.upper].accumEpochLast > cache.position.accumEpochLast
                                  : state.latestTick > params.lower || tickNodes[params.lower].accumEpochLast > cache.position.accumEpochLast
            ) {
                revert WrongTickClaimedAt();
            }
        }

        Ticks.remove(
            ticks,
            tickNodes,
            params.lower,
            params.upper,
            uint104(params.amount),
            params.zeroForOne,
            true,
            true
        );

        cache.position.amountOut += uint128(params.zeroForOne ? 
            DyDxMath.getDx(
                params.amount,
                cache.priceLower,
                cache.priceUpper,
                false
            )
            : DyDxMath.getDy(
                params.amount,
                cache.priceLower,
                cache.priceUpper,
                false
            )
        );

        console.logInt(ticks[params.lower].liquidityDelta);
        console.logInt(ticks[params.upper].liquidityDelta);

        cache.position.liquidity -= uint128(params.amount);
        positions[params.owner][params.lower][params.upper] = cache.position;

        console.log('position liquidity check:', cache.position.liquidity);
        console.log(positions[params.owner][params.lower][params.upper].liquidity);

        return params.amount;
    }

    function update(
        mapping(address => mapping(int24 => mapping(int24 => IPoolsharkHedgePoolStructs.Position))) storage positions,
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        IPoolsharkHedgePoolStructs.GlobalState storage state,
        IPoolsharkHedgePoolStructs.PoolState storage pool,
        IPoolsharkHedgePoolStructs.UpdateParams memory params
    ) external returns (uint128, uint128, int24, int24) {
        IPoolsharkHedgePoolStructs.UpdatePositionCache memory cache = IPoolsharkHedgePoolStructs.UpdatePositionCache({
            position: positions[params.owner][params.lower][params.upper],
            feeGrowthCurrentEpoch: pool.feeGrowthCurrentEpoch,
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper),
            claimPrice: TickMath.getSqrtRatioAtTick(params.claim),
            claimTick: tickNodes[params.claim],
            removeLower: true,
            removeUpper: true,
            amountInDelta: 0,
            amountOutDelta: 0
        });
        /// validate burn amount
        if (params.amount < 0 && uint128(-params.amount) > cache.position.liquidity) revert NotEnoughPositionLiquidity();
                if (cache.position.liquidity == 0 
         || params.claim == (params.zeroForOne ? params.upper : params.lower)
        ) { console.log('update return early early'); return (cache.position.amountIn,cache.position.amountOut,params.lower,params.upper); }
        //TODO: add to mint call
        // /// validate mint amount 
        // if (amount > 0 && uint128(amount) + cache.position.liquidity > MAX_TICK_LIQUIDITY) revert MaxTickLiquidity();

        /// validate claim param
        if (cache.position.claimPriceLast > cache.claimPrice) revert InvalidClaimTick();
        if (params.claim < params.lower || params.claim > params.upper) revert InvalidClaimTick();

        /// handle params.claims
        if (params.claim == (params.zeroForOne ? params.lower : params.upper)){
            /// position filled
            console.log('accum epochs');
            console.log(cache.claimTick.accumEpochLast, cache.position.accumEpochLast);
            if (cache.claimTick.accumEpochLast <= cache.position.accumEpochLast) revert WrongTickClaimedAt();
            {
                /// @dev - next tick having fee growth means liquidity was cleared
                uint32 claimNextTickAccumEpoch = params.zeroForOne ? tickNodes[cache.claimTick.previousTick].accumEpochLast 
                                                            : tickNodes[cache.claimTick.nextTick].accumEpochLast;
                if (claimNextTickAccumEpoch > cache.position.accumEpochLast) params.zeroForOne ? cache.removeLower = false 
                                                                                        : cache.removeUpper = false;
            }
            /// @dev - ignore carryover for last tick of position
            cache.amountInDelta  = ticks[params.claim].amountInDelta - int64(ticks[params.claim].amountInDeltaCarryPercent) 
                                                                    * ticks[params.claim].amountInDelta / 1e18;
            cache.amountOutDelta = ticks[params.claim].amountOutDelta - int64(ticks[params.claim].amountOutDeltaCarryPercent)
                                                                        * ticks[params.claim].amountInDelta / 1e18;
        } 
        else {
            ///@dev - next accumEpoch should not be greater
            uint32 claimNextTickAccumEpoch = params.zeroForOne ? tickNodes[cache.claimTick.previousTick].accumEpochLast 
                                                        : tickNodes[cache.claimTick.nextTick].accumEpochLast;
            if (claimNextTickAccumEpoch > cache.position.accumEpochLast) revert WrongTickClaimedAt();
            if (params.amount < 0) {
                /// @dev - check if liquidity removal required
                cache.removeLower = params.zeroForOne ? 
                                      true
                                    : tickNodes[cache.claimTick.nextTick].accumEpochLast      <= cache.position.accumEpochLast;
                cache.removeUpper = params.zeroForOne ? 
                                      tickNodes[cache.claimTick.previousTick].accumEpochLast  <= cache.position.accumEpochLast
                                    : true;
                
            }
            if (params.claim != (params.zeroForOne ? params.upper : params.lower)) {
                /// position partial fill
                /// factor in amount deltas
                cache.amountInDelta  += ticks[params.claim].amountInDelta;
                cache.amountOutDelta += ticks[params.claim].amountOutDelta;
                /// @dev - no params.amount deltas for 0% filled
                ///TODO: handle partial fill at params.lower tick
            }
            if (params.zeroForOne ? 
                (state.latestTick < params.claim && state.latestTick >= params.lower) //TODO: not sure if second condition is possible
              : (state.latestTick > params.claim && state.latestTick <= params.upper) 
            ) {
                //handle latestTick partial fill
                uint160 latestTickPrice = TickMath.getSqrtRatioAtTick(state.latestTick);
                //TODO: stop accumulating the tick before latestTick when moving TWAP
                cache.amountInDelta += int128(int256(params.zeroForOne ? 
                        DyDxMath.getDy(
                            1, // multiplied by liquidity later
                            latestTickPrice,
                            pool.price,
                            false
                        )
                        : DyDxMath.getDx(
                            1, 
                            pool.price,
                            latestTickPrice, 
                            false
                        )
                ));
                //TODO: implement stopPrice for pool/1
                cache.amountOutDelta += int128(int256(params.zeroForOne ? 
                    DyDxMath.getDx(
                        1, // multiplied by liquidity later
                        pool.price,
                        cache.claimPrice,
                        false
                    )
                    : DyDxMath.getDy(
                        1, 
                        cache.claimPrice,
                        pool.price, 
                        false
                    )
                ));
                //TODO: do we need to handle minus deltas correctly depending on direction
                // modify current liquidity
                if (params.amount < 0) {
                    params.zeroForOne ? pool.liquidity -= uint128(-params.amount) 
                               : pool.liquidity -= uint128(-params.amount);
                }
            }
        }
        if (params.claim != (params.zeroForOne ? params.upper : params.lower)) {
            //TODO: switch to being the current price if necessary
            cache.position.claimPriceLast = cache.claimPrice;
            {
                // calculate what is claimable
                //TODO: should this be inside Ticks library?
                uint256 amountInClaimable  = params.zeroForOne ? 
                                                DyDxMath.getDy(
                                                    cache.position.liquidity,
                                                    cache.claimPrice,
                                                    cache.position.claimPriceLast,
                                                    false
                                                )
                                                : DyDxMath.getDx(
                                                    cache.position.liquidity, 
                                                    cache.position.claimPriceLast,
                                                    cache.claimPrice, 
                                                    false
                                                );
                if (cache.amountInDelta > 0) {
                    amountInClaimable += FullPrecisionMath.mulDiv(
                                                                    uint128(cache.amountInDelta),
                                                                    cache.position.liquidity, 
                                                                    Q128
                                                                );
                } else if (cache.amountInDelta < 0) {
                    //TODO: handle underflow here
                    amountInClaimable -= FullPrecisionMath.mulDiv(
                                                                    uint128(-cache.amountInDelta),
                                                                    cache.position.liquidity, 
                                                                    Q128
                                                                );
                }
                //TODO: add to position
                if (amountInClaimable > 0) {
                    amountInClaimable *= (1e6 + state.swapFee) / 1e6; // factor in swap fees
                    cache.position.amountIn += uint128(amountInClaimable);
                }
            }
            {
                if (cache.amountOutDelta > 0) {
                    cache.position.amountOut += uint128(FullPrecisionMath.mulDiv(
                                                                        uint128(cache.amountOutDelta),
                                                                        cache.position.liquidity, 
                                                                        Q128
                                                                    )
                                                       );
                }
            }
        }

        // if burn or second mint
        if (params.amount < 0 || (params.amount > 0 && cache.position.liquidity > 0 && params.claim > params.lower)) {
            Ticks.remove(
                ticks,
                tickNodes,
                params.zeroForOne ? params.lower : params.claim,
                params.zeroForOne ? params.claim : params.upper,
                uint104(uint128(-params.amount)),
                params.zeroForOne,
                cache.removeLower,
                cache.removeUpper
            );
            // they should also get params.amountOutDeltaCarry
            cache.position.amountOut += uint128(params.zeroForOne ? 
                DyDxMath.getDx(
                    uint128(-params.amount),
                    cache.priceLower,
                    cache.claimPrice,
                    false
                )
                : DyDxMath.getDy(
                    uint128(-params.amount),
                    cache.claimPrice,
                    cache.priceUpper,
                    false
                )
            );
            if (params.amount < 0) {
                // remove position liquidity
                cache.position.liquidity -= uint128(-params.amount);
            }
        } 
        if (params.zeroForOne ? params.claim != params.upper : params.claim != params.lower) {
            ///TODO: do tick insert here
            // handle double minting of position
            delete positions[params.owner][params.lower][params.upper];
            //TODO: handle liquidity overflow in mint call
        }

        params.zeroForOne ? positions[params.owner][params.lower][params.claim] = cache.position
                          : positions[params.owner][params.claim][params.upper] = cache.position;

        return (
            cache.position.amountIn,
            cache.position.amountOut, 
            params.zeroForOne ? params.lower : params.claim, 
            params.zeroForOne ? params.claim : params.upper
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

/// @notice Math library for computing sqrt price for ticks of size 1.0001, i.e., sqrt(1.0001^tick) as fixed point Q64.96 numbers - supports
/// prices between 2**-128 and 2**128 - 1.
/// @author Adapted from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/TickMath.sol.
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128.
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128 - 1.
    int24 internal constant MAX_TICK = -MIN_TICK;
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MIN_TICK).
    uint160 internal constant MIN_SQRT_RATIO = 4294967296;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MAX_TICK).
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    error TickOutOfBounds();
    error PriceOutOfBounds(); 

    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160 getSqrtPriceX96) {
        return _getSqrtRatioAtTick(tick);
    }

    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24 tick) {
        return _getTickAtSqrtRatio(sqrtPriceX96);
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96.
    /// @dev Throws if |tick| > max tick.
    /// @param tick The input tick for the above formula.
    /// @return sqrtPriceX96 Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick.
    function _getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        if (absTick > uint256(uint24(MAX_TICK))) revert TickOutOfBounds();
        unchecked {
            uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;
            // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // We then downcast because we know the result always fits within 160 bits due to our tick input constraint.
            // We round up in the division so getTickAtSqrtRatio of the output price is always consistent.
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    function validatePrice(uint160 price) external pure {
        if (price < MIN_SQRT_RATIO || price >= MAX_SQRT_RATIO) revert PriceOutOfBounds();
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio.
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96.
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio.
    function _getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO) revert PriceOutOfBounds();
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }
        unchecked {
            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number.

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : _getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "./TickMath.sol";
import "../interfaces/IPoolsharkHedgePoolStructs.sol";
import "../utils/PoolsharkErrors.sol";
import "hardhat/console.sol";
import "./FullPrecisionMath.sol";
import "./DyDxMath.sol";

/// @notice Tick management library for ranged liquidity.
library Ticks
{
    error NotImplementedYet();
    error WrongTickOrder();
    error WrongTickLowerRange();
    error WrongTickUpperRange();
    error WrongTickLowerOld();
    error WrongTickUpperOld();
    error NoLiquidityToRollover();

    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    using Ticks for mapping(int24 => IPoolsharkHedgePoolStructs.Tick);

    function getMaxLiquidity(int24 tickSpacing) external pure returns (uint128) {
        return type(uint128).max / uint128(uint24(TickMath.MAX_TICK) / (2 * uint24(tickSpacing)));
    }

    function cross(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        int24 currentTick,
        int24 nextTickToCross,
        uint128 currentLiquidity,
        bool zeroForOne
    ) external view returns (uint256, int24, int24) {
        return _cross(
            ticks,
            tickNodes,
            currentTick,
            nextTickToCross,
            currentLiquidity,
            zeroForOne
        );
    }

    //maybe call ticks on msg.sender to get tick
    function _cross(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        int24 currentTick,
        int24 nextTickToCross,
        uint128 currentLiquidity,
        bool zeroForOne
    ) internal view returns (uint128, int24, int24) {
        currentTick = nextTickToCross;
        int128 liquidityDelta = ticks[nextTickToCross].liquidityDelta;

        if(liquidityDelta > 0) {
            currentLiquidity += uint128(liquidityDelta);
        } else {
            currentLiquidity -= uint128(-liquidityDelta);
        }
        if (zeroForOne) {
            nextTickToCross = tickNodes[nextTickToCross].previousTick;
        } else {
            nextTickToCross = tickNodes[nextTickToCross].nextTick;
        }
        return (currentLiquidity, currentTick, nextTickToCross);
    }
    //TODO: ALL TICKS NEED TO BE CREATED WITH 
    function insert(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        int24 lowerOld,
        int24 lower,
        int24 upperOld,
        int24 upper,
        uint104 amount,
        bool isPool0
    ) external {
        if (lower >= upper || lowerOld >= upperOld) {
            revert WrongTickOrder();
        }
        if (TickMath.MIN_TICK > lower) {
            revert WrongTickLowerRange();
        }
        if (upper > TickMath.MAX_TICK) {
            revert WrongTickUpperRange();
        }
        //TODO: merge Tick and TickData -> ticks0 and ticks1
        // Stack overflow.
        // console.log('current lower liquidity:', currentLowerLiquidity);
        //TODO: handle lower = latestTick
        console.log('liquidity before');
        console.logInt(ticks[upper].liquidityDelta);
        if (ticks[lower].liquidityDelta != 0 
            || ticks[lower].liquidityDeltaMinus != 0
            || ticks[lower].amountInDelta != 0
        ) {
            // tick exists
            //TODO: ensure amount < type(int128).max()
            console.log('insert liq');
            if (isPool0) {
                ticks[lower].liquidityDelta      -= int104(amount);
                ticks[lower].liquidityDeltaMinus += amount;
            } else {
                ticks[lower].liquidityDelta      += int104(amount);
            }
        } else {
            // tick does not exist and we must insert
            //TODO: handle new TWAP being in between lowerOld and lower
            if (isPool0) {
                ticks[lower] = IPoolsharkHedgePoolStructs.Tick(
                    -int104(amount),
                    amount,
                    0,0,0,0
                );
            } else {
                ticks[lower] = IPoolsharkHedgePoolStructs.Tick(
                    int104(amount),
                    0,
                    0,0,0,0
                );
            }

        }
        // console.log('lower tick');
        // console.logInt(tickNodes[lower].nextTick);
        // console.logInt(tickNodes[lower].previousTick);
        if(tickNodes[lower].nextTick == tickNodes[lower].previousTick && lower != TickMath.MIN_TICK) {
                    console.log('lower tick');
            int24 oldNextTick = tickNodes[lowerOld].nextTick;
            if (upper < oldNextTick) { oldNextTick = upper; }
            /// @dev - don't set previous tick so upper can be initialized
            else { tickNodes[oldNextTick].previousTick = lower; }

            if (lowerOld >= lower || lower >= oldNextTick) {
                console.log('tick check');
                console.logInt(tickNodes[lowerOld].nextTick);
                console.logInt(tickNodes[lowerOld].previousTick);
                revert WrongTickLowerOld();
            }
            console.logInt(oldNextTick);
            tickNodes[lower] = IPoolsharkHedgePoolStructs.TickNode(
                lowerOld,
                oldNextTick,
                0
            );
            tickNodes[lowerOld].nextTick = lower;
        }
        // console.log('lower tick');
        // console.logInt(tickNodes[lower].nextTick);
        // console.logInt(tickNodes[lower].previousTick);
                console.log('upper tick');
        console.logInt(tickNodes[upper].previousTick);
        console.logInt(tickNodes[upper].nextTick);
        if (ticks[upper].liquidityDelta != 0 
            || ticks[upper].liquidityDeltaMinus != 0
            || ticks[lower].amountInDelta != 0
        ) {
            console.log('adding liquidity');
            // We are adding liquidity to an existing tick.
            if (isPool0) {
                ticks[upper].liquidityDelta      += int104(amount);
            } else {
                ticks[upper].liquidityDelta      -= int104(amount);
                ticks[upper].liquidityDeltaMinus += amount;
            }
        } else {
            if (isPool0) {
                ticks[upper] = IPoolsharkHedgePoolStructs.Tick(
                    int104(amount),
                    0,
                    0,0,0,0
                );
            } else {
                ticks[upper] = IPoolsharkHedgePoolStructs.Tick(
                    -int104(amount),
                    amount,
                    0,0,0,0
                );
            }
        }
        if(tickNodes[upper].nextTick == tickNodes[upper].previousTick && upper != TickMath.MAX_TICK) {
            int24 oldPrevTick = tickNodes[upperOld].previousTick;
            if (lower > oldPrevTick) oldPrevTick = lower;

            // console.logInt(tickNodes[upperOld].nextTick);
            // console.logInt(tickNodes[upperOld].previousTick);
            // console.logInt(ticks[upper].liquidityDelta);
            // console.log(ticks[upper].liquidityDeltaMinus);
            //TODO: handle new TWAP being in between upperOld and upper
            /// @dev - if nextTick == previousTick this tick node is uninitialized
            if (tickNodes[upperOld].nextTick == tickNodes[upperOld].previousTick
                    || upperOld <= upper 
                    || upper <= oldPrevTick
                ) {
                revert WrongTickUpperOld();
            }

            tickNodes[upper] = IPoolsharkHedgePoolStructs.TickNode(
                oldPrevTick,
                upperOld,
                0
            );
            tickNodes[oldPrevTick].nextTick = upper;
            tickNodes[upperOld].previousTick = upper;
        }
    }

    function remove(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        int24 lower,
        int24 upper,
        uint104 amount,
        bool isPool0,
        bool removeLower,
        bool removeUpper
    ) external {
        //TODO: we can only delete is lower != MIN_TICK or latestTick and all values are 0
        bool deleteLowerTick = false;
        //TODO: we can only delete is upper != MAX_TICK or latestTick and all values are 0
        bool deleteUpperTick = false;
        if (deleteLowerTick) {

            // Delete lower tick.
            int24 previous = tickNodes[lower].previousTick;
            int24 next     = tickNodes[lower].nextTick;
            if(next != upper || !deleteUpperTick) {
                tickNodes[previous].nextTick = next;
                tickNodes[next].previousTick = previous;
            } else {
                int24 upperNextTick = tickNodes[upper].nextTick;
                tickNodes[tickNodes[lower].previousTick].nextTick = upperNextTick;
                tickNodes[upperNextTick].previousTick = previous;
            }
        }
        if (removeLower) {
                        console.log('deleting lower tick');
            if (isPool0) {
                ticks[lower].liquidityDelta += int104(amount);
                ticks[lower].liquidityDeltaMinus -= amount;
            } else {
                ticks[lower].liquidityDelta -= int104(amount);
            }
                        console.log('deleting lower tick');
        }

        //TODO: could also modify amounts and then check if liquidityDelta and liquidityDeltaMinus are both zero
        if (deleteUpperTick) {
            // Delete upper tick.
            int24 previous = tickNodes[upper].previousTick;
            int24 next     = tickNodes[upper].nextTick;

            if(previous != lower || !deleteLowerTick) {
                tickNodes[previous].nextTick = next;
                tickNodes[next].previousTick = previous;
            } else {
                int24 lowerPrevTick = tickNodes[lower].previousTick;
                tickNodes[lowerPrevTick].nextTick = next;
                tickNodes[next].previousTick = lowerPrevTick;
            }
        }
        //TODO: we need to know what tick they're claiming from
        //TODO: that is the tick that should have liquidity values modified
        //TODO: keep unchecked block?
        if (removeUpper) {
                                    console.log('deleting upper tick');
            if (isPool0) {
                ticks[upper].liquidityDelta -= int104(amount);
            } else {
                ticks[upper].liquidityDelta += int104(amount);
                ticks[upper].liquidityDeltaMinus -= amount;
            }
                                                console.log('deleting upper tick');
        }
        /// @dev - we can never delete ticks due to amount deltas

        console.log('removed lower liquidity:', amount);
        console.log('removed upper liquidity:', amount);
    }

    function _accumulate(
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        uint32 accumEpoch,
        int24 nextTickToCross,
        int24 nextTickToAccum,
        uint128 currentLiquidity,
        int128 amountInDelta,
        int128 amountOutDelta,
        bool removeLiquidity
    ) internal returns (int128, int128) {
        console.log('fee growth accumulate check');
        console.log(tickNodes[nextTickToCross].accumEpochLast);
        console.log(tickNodes[nextTickToAccum].accumEpochLast);

        //update fee growth
        tickNodes[nextTickToAccum].accumEpochLast = accumEpoch;

        //remove all liquidity from previous tick
        if (removeLiquidity) {
            ticks[nextTickToCross].liquidityDelta = 0;
            ticks[nextTickToCross].liquidityDeltaMinus = 0;
        }
        //check for deltas to carry
        if(ticks[nextTickToCross].amountInDeltaCarryPercent > 0){
            //TODO: will this work with negatives?
            int104 amountInDeltaCarry = int64(ticks[nextTickToCross].amountInDeltaCarryPercent) 
                                            * ticks[nextTickToCross].amountInDelta / 1e18;
            ticks[nextTickToCross].amountInDelta -= int88(amountInDeltaCarry);
            ticks[nextTickToCross].amountInDeltaCarryPercent = 0;
            amountInDelta += amountInDeltaCarry;
            /// @dev - amountOutDelta cannot exist without amountInDelta
            if(ticks[nextTickToCross].amountOutDeltaCarryPercent > 0){
            //TODO: will this work with negatives?
                int256 amountOutDeltaCarry = int64(ticks[nextTickToCross].amountOutDeltaCarryPercent) 
                                                * ticks[nextTickToCross].amountOutDelta / 1e18;
                ticks[nextTickToCross].amountOutDelta -= int88(amountOutDeltaCarry);
                ticks[nextTickToCross].amountOutDeltaCarryPercent = 0;
                amountOutDelta += int128(amountOutDeltaCarry);
            }
        }
        if (currentLiquidity > 0) {
            //write amount deltas and set cache to zero
            uint128 liquidityDeltaMinus = ticks[nextTickToAccum].liquidityDeltaMinus;
            if (currentLiquidity != liquidityDeltaMinus) {
                //
                ticks[nextTickToAccum].amountInDelta  += int88(amountInDelta);
                ticks[nextTickToAccum].amountOutDelta += int88(amountOutDelta);
                int128 liquidityDeltaPlus = ticks[nextTickToAccum].liquidityDelta + int128(liquidityDeltaMinus);
                if (liquidityDeltaPlus > 0) {
                    /// @dev - amount deltas get diluted when liquidity is added
                    int128 liquidityPercentIncrease = liquidityDeltaPlus * 1e18 / int128(currentLiquidity - liquidityDeltaMinus);
                    amountOutDelta = amountOutDelta * (1e18 + liquidityPercentIncrease) / 1e18;
                    amountInDelta = amountInDelta * (1e18 + liquidityPercentIncrease) / 1e18;
                }
            } else {
                ticks[nextTickToAccum].amountInDelta += int88(amountInDelta);
                ticks[nextTickToAccum].amountOutDelta += int88(amountOutDelta);
                amountInDelta = 0;
                amountOutDelta = 0;
            }
            // update fee growth
        }
        return (amountInDelta, amountOutDelta);
    }

    function _rollover(
        int24 nextTickToCross,
        int24 nextTickToAccum,
        uint256 currentPrice,
        uint256 currentLiquidity,
        int128 amountInDelta,
        int128 amountOutDelta,
        bool isPool0
    ) internal pure returns (int128, int128) {
        if (currentLiquidity == 0) return (amountInDelta, amountOutDelta);
        uint160 nextPrice = TickMath.getSqrtRatioAtTick(nextTickToCross);
        /// @dev - early return if we already crossed this area
        if (isPool0 ? currentPrice >= nextPrice 
                    : currentPrice <= nextPrice)
            return (amountInDelta, amountOutDelta);

        uint160 accumPrice = TickMath.getSqrtRatioAtTick(nextTickToAccum);

        if (isPool0 ? currentPrice < accumPrice 
                    : currentPrice > accumPrice)
            currentPrice = accumPrice;

        //handle liquidity rollover
        uint256 amountInUnfilled; uint256 amountOutLeftover;
        if(isPool0) {
            // leftover x provided
            amountOutLeftover = DyDxMath.getDx(
                currentLiquidity,
                currentPrice,
                nextPrice,
                false
            );
            // unfilled y amount
            amountInUnfilled = DyDxMath.getDy(
                currentLiquidity,
                currentPrice,
                nextPrice,
                false
            );
        } else {
            amountOutLeftover = DyDxMath.getDy(
                currentLiquidity,
                nextPrice,
                currentPrice,
                false
            );
            amountInUnfilled = DyDxMath.getDx(
                currentLiquidity,
                nextPrice,
                currentPrice,
                false
            );
        }

        //TODO: ensure this will not overflow with 32 bits
        //TODO: return this value to limit storage reads and writes
        amountInDelta -= int128(uint128(
                                            FullPrecisionMath.mulDiv(
                                                amountInUnfilled,
                                                0x1000000000000000000000000, 
                                                currentLiquidity
                                            )
                                        )
                                );
        amountOutDelta += int128(uint128(
                                            FullPrecisionMath.mulDiv(
                                                amountOutLeftover,
                                                0x1000000000000000000000000, 
                                                currentLiquidity
                                            )
                                        )
                                );
        return (amountInDelta, amountOutDelta);
    }

    function initialize(
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        IPoolsharkHedgePoolStructs.PoolState storage pool0,
        IPoolsharkHedgePoolStructs.PoolState storage pool1,
        int24 latestTick,
        uint32 accumEpoch
    ) external {
        if (latestTick != TickMath.MIN_TICK && latestTick != TickMath.MAX_TICK) {
            tickNodes[latestTick] = IPoolsharkHedgePoolStructs.TickNode(
                TickMath.MIN_TICK, TickMath.MAX_TICK, accumEpoch
            );
            tickNodes[TickMath.MIN_TICK] = IPoolsharkHedgePoolStructs.TickNode(
                TickMath.MIN_TICK, latestTick, accumEpoch
            );
            tickNodes[TickMath.MAX_TICK] = IPoolsharkHedgePoolStructs.TickNode(
                latestTick, TickMath.MAX_TICK, accumEpoch
            );
        } else if (latestTick == TickMath.MIN_TICK || latestTick == TickMath.MAX_TICK) {
            tickNodes[TickMath.MIN_TICK] = IPoolsharkHedgePoolStructs.TickNode(
                TickMath.MIN_TICK, TickMath.MAX_TICK, accumEpoch
            );
            tickNodes[TickMath.MAX_TICK] = IPoolsharkHedgePoolStructs.TickNode(
                TickMath.MIN_TICK, TickMath.MAX_TICK, accumEpoch
            );
        }
        //TODO: we might not need nearestTick; always with defined tickSpacing
        pool0.nearestTick = latestTick;
        pool1.nearestTick = TickMath.MIN_TICK;
        pool0.lastTick    = TickMath.MAX_TICK;
        pool1.lastTick    = TickMath.MIN_TICK;
        //TODO: the sqrtPrice cannot move more than 1 tickSpacing away
        pool0.price = TickMath.getSqrtRatioAtTick(latestTick);
        pool1.price = pool0.price;
    }
    //TODO: pass in specific tick and update in storage on calling function
    function _updateAmountDeltas (
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        int24 update,
        int128 amountInDelta,
        int128 amountOutDelta,
        uint128 currentLiquidity
    ) internal {
        // return since there is nothing to update
        if (currentLiquidity == 0) return;

        // handle amount in delta
        int128 amountInDeltaCarry = int64(ticks[update].amountInDeltaCarryPercent) * ticks[update].amountInDelta / 1e18;
        int128 newAmountInDelta = ticks[update].amountInDelta + amountInDelta;
        if (amountInDelta != 0 && newAmountInDelta != 0) {
            ticks[update].amountInDeltaCarryPercent = uint64(uint128((amountInDelta + amountInDeltaCarry) * 1e18 
                                            / (newAmountInDelta)));
            ticks[update].amountInDelta += int88(amountInDelta);
        } else if (amountInDelta != 0 && newAmountInDelta == 0) {
            revert NotImplementedYet();
        }

        // handle amount out delta
        int128 amountOutDeltaCarry = int64(ticks[update].amountOutDeltaCarryPercent) * ticks[update].amountOutDelta / 1e18;
        int128 newAmountOutDelta = ticks[update].amountOutDelta + amountOutDelta;
        if (amountOutDelta != 0 && newAmountOutDelta != 0) {
            ticks[update].amountOutDeltaCarryPercent = uint64(uint128((amountOutDelta + amountOutDeltaCarry) * 1e18 
                                                    / (newAmountOutDelta)));
            ticks[update].amountOutDelta += int88(amountOutDelta);
        } else if (amountOutDelta != 0 && newAmountOutDelta == 0) {
            revert NotImplementedYet();
        }
    }

    //TODO: do both pool0 AND pool1
    function accumulateLastBlock(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks0,
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks1,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        IPoolsharkHedgePoolStructs.PoolState memory pool0,
        IPoolsharkHedgePoolStructs.PoolState memory pool1,
        IPoolsharkHedgePoolStructs.GlobalState memory state,
        int24 nextLatestTick
    ) external returns (
        IPoolsharkHedgePoolStructs.GlobalState memory,
        IPoolsharkHedgePoolStructs.PoolState memory, 
        IPoolsharkHedgePoolStructs.PoolState memory
    ) {
        console.log("-- START ACCUMULATE LAST BLOCK --");

        // only accumulate if latestTick needs to move
        if (nextLatestTick / (2*state.tickSpacing) == state.latestTick / (2*state.tickSpacing)) {
            console.log("-- EARLY END ACCUMULATE LAST BLOCK --");
            return (state, pool0, pool1);
        }
        
        state.accumEpoch += 1;

        IPoolsharkHedgePoolStructs.AccumulateCache memory cache = IPoolsharkHedgePoolStructs.AccumulateCache({
            nextTickToCross0:  tickNodes[pool0.nearestTick].nextTick,
            nextTickToCross1:  pool1.nearestTick,
            nextTickToAccum0:  pool0.nearestTick,
            nextTickToAccum1:  tickNodes[pool1.nearestTick].nextTick,
            stopTick0:  (nextLatestTick > state.latestTick) ? state.latestTick : nextLatestTick + state.tickSpacing,
            stopTick1:  (nextLatestTick > state.latestTick) ? nextLatestTick - state.tickSpacing : state.latestTick,
            amountInDelta0:  0,
            amountInDelta1:  0,
            amountOutDelta0: 0,
            amountOutDelta1: 0
        });

        console.logInt(cache.nextTickToCross0);
        console.logInt(pool0.lastTick);
        console.logInt(tickNodes[pool0.lastTick].nextTick);


        while(cache.nextTickToCross0 != pool0.lastTick) {
            (
                pool0.liquidity, 
                cache.nextTickToAccum0,
                cache.nextTickToCross0
            ) = _cross(
                ticks0,
                tickNodes,
                cache.nextTickToAccum0,
                cache.nextTickToCross0,
                pool0.liquidity,
                false
            );
        console.logInt(cache.nextTickToCross0);
        console.logInt(pool0.lastTick);
        console.logInt(tickNodes[pool0.lastTick].nextTick);
                    
        }
        
        while(cache.nextTickToCross1 != pool1.lastTick) {
            (
                pool1.liquidity, 
                cache.nextTickToAccum1,
                cache.nextTickToCross1
            ) = _cross(
                ticks1,
                tickNodes,
                cache.nextTickToAccum1,
                cache.nextTickToCross1,
                pool1.liquidity,
                true
            );
        }



        //TODO: handle ticks not crossed into as a result of big TWAP move
        // console.log('check cache');
        // console.logInt(cache.nextTickToCross1);
        // console.logInt(cache.nextTickToAccum1);
        // console.logInt(tickNodes[cache.nextTickToCross1].nextTick);
        // handle partial tick fill
        // update liquidity and ticks
        //TODO: do we return here is latestTick has not moved??
        //TODO: wipe tick data when tick is deleted
        while (true) {
            //rollover if past latestTick and TWAP moves up
            if (cache.nextTickToAccum0 >= cache.stopTick0) {
                if (pool0.liquidity > 0){
                    (
                        cache.amountInDelta0,
                        cache.amountOutDelta0
                    ) = _rollover(
                        cache.nextTickToCross0,
                        cache.nextTickToAccum0,
                        pool0.price, //TODO: update price on each iteration
                        pool0.liquidity,
                        cache.amountInDelta0,
                        cache.amountOutDelta0,
                        true
                    );
                }
                //accumulate to next tick
                console.log('pool0 accumulate');
                console.logInt(cache.nextTickToCross0);
                console.logInt(cache.nextTickToAccum0);
                (
                    cache.amountInDelta0,
                    cache.amountOutDelta0
                ) = _accumulate(
                    tickNodes,
                    ticks0,
                    state.accumEpoch,
                    cache.nextTickToCross0,
                    cache.nextTickToAccum0,
                    pool0.liquidity,
                    cache.amountInDelta0, /// @dev - amount deltas will be 0 initially
                    cache.amountOutDelta0,
                    true
                );
            }
            //cross otherwise break
            console.logInt(cache.nextTickToAccum0);
            console.logInt(cache.stopTick0);
            if (cache.nextTickToAccum0 > cache.stopTick0) {
                (
                    pool0.liquidity, 
                    cache.nextTickToCross0,
                    cache.nextTickToAccum0
                ) = _cross(
                    ticks0,
                    tickNodes,
                    cache.nextTickToCross0,
                    cache.nextTickToAccum0,
                    pool0.liquidity,
                    true
                );
            } else {
                /// @dev - place liquidity on latestTick for continuation when TWAP moves back up
                if (nextLatestTick > state.latestTick)
                    ticks0[state.latestTick].liquidityDelta += int104(int128(uint128(pool0.liquidity) 
                                                        - ticks0[state.latestTick].liquidityDeltaMinus));
                /// @dev - update amount deltas on stopTick
                _updateAmountDeltas(
                        ticks0,
                        cache.stopTick0,
                        cache.amountInDelta0,
                        cache.amountOutDelta0,
                        pool0.liquidity
                );
                if (nextLatestTick < state.latestTick) {
                    (
                        pool0.liquidity, 
                        cache.nextTickToCross0,
                        cache.nextTickToAccum0
                    ) = _cross(
                        ticks0,
                        tickNodes,
                        cache.nextTickToCross0,
                        cache.nextTickToAccum0,
                        pool0.liquidity,
                        true
                    );
                }
                break;
            }
        }
        //TODO: add latestTickSpread to stop rolling over
        while (true) {
            //rollover if past latestTick and TWAP moves up
            if (cache.nextTickToAccum1 <= cache.stopTick1) {
                if (pool1.liquidity > 0){
                    (
                        cache.amountInDelta1,
                        cache.amountOutDelta1
                    ) = _rollover(
                        cache.nextTickToCross1,
                        cache.nextTickToAccum1,
                        pool1.price, //TODO: update price on each iteration
                        pool1.liquidity,
                        cache.amountInDelta1,
                        cache.amountOutDelta1,
                        false
                    );
                }
                //accumulate to next tick
                console.log('pool1 accumulate');
                console.logInt(cache.nextTickToCross1);
                console.logInt(cache.nextTickToAccum1);
                (
                    cache.amountInDelta1,
                    cache.amountOutDelta1
                ) = _accumulate(
                    tickNodes,
                    ticks1,
                    state.accumEpoch,
                    cache.nextTickToCross1,
                    cache.nextTickToAccum1,
                    pool1.liquidity,
                    cache.amountInDelta1, /// @dev - amount deltas will be 1 initially
                    cache.amountOutDelta1,
                    true
                );
            }
            //cross otherwise break
            console.logInt(cache.nextTickToAccum1);
            console.logInt(cache.stopTick1);
            if (cache.nextTickToAccum1 < cache.stopTick1) {
                (
                    pool1.liquidity, 
                    cache.nextTickToCross1,
                    cache.nextTickToAccum1
                ) = _cross(
                    ticks1,
                    tickNodes,
                    cache.nextTickToCross1,
                    cache.nextTickToAccum1,
                    pool1.liquidity,
                    false
                );
            } else {
                /// @dev - place liquidity on latestTick for continuation when TWAP moves back up
                if (nextLatestTick < state.latestTick)
                    ticks1[state.latestTick].liquidityDelta += int104(int128(uint128(pool1.liquidity) 
                                                        - ticks1[state.latestTick].liquidityDeltaMinus));
                /// @dev - update amount deltas on stopTick
                _updateAmountDeltas(
                        ticks1,
                        cache.stopTick1,
                        cache.amountInDelta1,
                        cache.amountOutDelta1,
                        pool1.liquidity
                );
                if (nextLatestTick > state.latestTick) {
                    (
                        pool1.liquidity, 
                        cache.nextTickToCross1,
                        cache.nextTickToAccum1
                    ) = _cross(
                        ticks1,
                        tickNodes,
                        cache.nextTickToCross1,
                        cache.nextTickToAccum1,
                        pool1.liquidity,
                        false
                    );
                }
                //TODO: if tickSpread > tickSpacing, we need to cross until accum tick is nextLatestTick
                break;
            }
        }

        //TODO: remove liquidity from all ticks crossed
        //TODO: handle burn when price is between ticks
        //if TWAP moved up
        if (nextLatestTick > state.latestTick) {
            // if this is true we need to insert new latestTick
            if (cache.nextTickToAccum1 != nextLatestTick) {
                // if this is true we need to delete the old tick
                //TODO: don't delete old latestTick for now
                            console.log('twap moving up');
                            console.logInt(cache.stopTick1);
                            console.logInt(tickNodes[cache.nextTickToCross1].nextTick);
                            console.logInt(cache.nextTickToAccum1);
                tickNodes[nextLatestTick] = IPoolsharkHedgePoolStructs.TickNode(
                        cache.nextTickToCross1,
                        cache.nextTickToAccum1,
                        0
                );
                tickNodes[cache.nextTickToAccum1].previousTick = nextLatestTick;
                tickNodes[cache.nextTickToCross1].nextTick     = nextLatestTick;
                //TODO: replace nearestTick with priceLimit for swapping...maybe
            }
            pool0.liquidity = 0;
            pool1.liquidity = pool1.liquidity;

            pool0.lastTick  = tickNodes[nextLatestTick].nextTick;
            pool1.lastTick  = cache.nextTickToCross1;

            console.logInt(pool0.lastTick);
            console.logInt(pool1.lastTick);
        // handle TWAP moving down
        } else if (nextLatestTick < state.latestTick) {
            //TODO: if tick is deleted rollover amounts if necessary
            //TODO: do we recalculate deltas if liquidity is removed?
            if (cache.nextTickToAccum0 != nextLatestTick) {
                // if this is true we need to delete the old tick
                //TODO: don't delete old latestTick for now
                tickNodes[nextLatestTick] = IPoolsharkHedgePoolStructs.TickNode(
                        cache.nextTickToAccum0,
                        cache.nextTickToCross0,
                        0
                );
                tickNodes[cache.nextTickToCross0].previousTick = nextLatestTick;
                tickNodes[cache.nextTickToAccum0].nextTick     = nextLatestTick;
                //TODO: replace nearestTick with priceLimit for swapping...maybe
            }
                        console.log('twap moving down');
            pool0.liquidity = pool0.liquidity;
            pool1.liquidity = 0;
            pool0.lastTick  = cache.nextTickToCross0;
            pool1.lastTick  = tickNodes[nextLatestTick].previousTick;
        }
        //TODO: delete old latestTick if possible
        pool0.nearestTick = tickNodes[nextLatestTick].nextTick;
        pool1.nearestTick = tickNodes[nextLatestTick].previousTick;
        pool0.price = TickMath.getSqrtRatioAtTick(nextLatestTick);
        pool1.price = pool0.price;
        state.latestTick = nextLatestTick;
        console.log("-- END ACCUMULATE LAST BLOCK --");
        return (state, pool0, pool1);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract PoolsharkHedgePoolErrors {
    error Locked();
    error InvalidToken();
    error InvalidPosition();
    error InvalidSwapFee();
    error LiquidityOverflow();
    error Token0Missing();
    error Token1Missing();
    error InvalidTick();
    error LowerNotEvenTick();
    error UpperNotOddTick();
    error MaxTickLiquidity();
    error Overflow();
    error NotEnoughOutputLiquidity();
    error WaitUntilEnoughObservations();
}

abstract contract PoolsharkTicksErrors {
    error WrongTickOrder();
    error WrongTickLowerRange();
    error WrongTickUpperRange();
    error WrongTickLowerOrder();
    error WrongTickUpperOrder();
    error WrongTickClaimedAt();
}

abstract contract PoolsharkMiscErrors {
    // to be removed before production
    error NotImplementedYet();
}

abstract contract PoolsharkPositionErrors {
    error NotEnoughPositionLiquidity();
    error InvalidClaimTick();
}

abstract contract PoolsharkHedgePoolFactoryErrors {
    error IdenticalTokenAddresses();
    error PoolAlreadyExists();
    error FeeTierNotSupported();
}

abstract contract PoolsharkTransferErrors {
    error TransferFailed(address from, address dest);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}
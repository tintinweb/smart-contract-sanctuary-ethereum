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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./IRangePool.sol";

interface ICoverPoolStructs {
    struct GlobalState {
        uint8    unlocked;
        int16    tickSpread; /// @dev this is a integer multiple of the inputPool tickSpacing
        uint16   twapLength; /// @dev number of blocks used for TWAP sampling
        uint16   auctionLength; /// @dev number of blocks to improve price by tickSpread
        int24    latestTick; /// @dev latest updated inputPool price tick
        uint32   genesisBlock; /// @dev reference block for which auctionStart is an offset of
        uint32   lastBlock;    /// @dev last block checked
        uint32   auctionStart; /// @dev last block price reference was updated
        uint32   accumEpoch;
        uint128  liquidityGlobal;
        uint160  latestPrice; /// @dev price of latestTick
        IRangePool inputPool;
        ProtocolFees protocolFees;
    }

    //TODO: adjust nearestTick if someone burns all liquidity from current nearestTick
    struct PoolState {
        uint128 liquidity; /// @dev Liquidity currently active
        uint128 amountInDelta; /// @dev Delta for the current tick auction
        uint128 amountInDeltaMaxClaimed;  /// @dev - needed when users claim and don't burn; should be cleared when users burn liquidity
        uint128 amountOutDeltaMaxClaimed; /// @dev - needed when users claim and don't burn; should be cleared when users burn liquidity
        uint160 price; /// @dev Starting price current
    }

    struct TickNode {
        int24   previousTick;
        int24   nextTick;
        uint32  accumEpochLast; // Used to check for claim updates
    }

    struct Tick {
        int128  liquidityDelta;
        uint128 liquidityDeltaMinus;
        uint128 amountInDeltaMaxStashed;
        uint128 amountOutDeltaMaxStashed;
        Deltas deltas;
    }

    struct Deltas {
        uint128 amountInDelta;     // amt unfilled
        uint128 amountInDeltaMax;  // max unfilled
        uint128 amountOutDelta;    // amt unfilled
        uint128 amountOutDeltaMax; // max unfilled
    }

    // balance needs to be immediately transferred to the position owner
    struct Position {
        uint8   claimCheckpoint; // used to dictate claim state
        uint32  accumEpochLast; // last epoch this position was updated at
        uint128 liquidity; // expected amount to be used not actual
        uint128 liquidityStashed; // what percent of this position is stashed liquidity
        uint128 amountIn; // token amount already claimed; balance
        uint128 amountOut; // necessary for non-custodial positions
        uint160 claimPriceLast; // highest price claimed at
    }

    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }

    struct MintParams {
        address to;
        int24 lowerOld;
        int24 lower;
        int24 claim;
        int24 upper;
        int24 upperOld;
        uint128 amount;
        bool zeroForOne;
    }

    struct BurnParams {
        address to;
        int24 lower;
        int24 claim;
        int24 upper;
        bool zeroForOne;
        uint128 amount;
        bool collect;
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
        uint128 amount;
    }

    struct ValidateParams {
        int24 lowerOld;
        int24 lower;
        int24 upper;
        int24 upperOld;
        bool zeroForOne;
        uint128 amount;
        GlobalState state;
    }

    //TODO: optimize this struct
    struct SwapCache {
        uint256 price;
        uint256 liquidity;
        uint256 amountIn;
        uint256 input;
        uint256 inputBoosted;
        uint256 auctionDepth;
        uint256 auctionBoost;
        uint256 amountInDelta;
    }

    struct PositionCache {
        uint160 priceLower;
        uint160 priceUpper;
        Position position;
    }

    struct UpdatePositionCache {
        uint160 priceLower;
        uint160 priceClaim;
        uint160 priceUpper;
        uint160 priceSpread;
        bool removeLower;
        bool removeUpper;
        uint256 amountInFilledMax;    // considers the range covered by each update
        uint256 amountOutUnfilledMax; // considers the range covered by each update
        Tick claimTick;
        TickNode claimTickNode;
        Position position;
        Deltas deltas;
        Deltas finalDeltas;
    }

    struct AccumulateCache {
        int24 nextTickToCross0;
        int24 nextTickToCross1;
        int24 nextTickToAccum0;
        int24 nextTickToAccum1;
        int24 stopTick0;
        int24 stopTick1;
        Deltas deltas0;
        Deltas deltas1;
    }

    struct AccumulateOutputs {
        Deltas deltas;
        TickNode accumTickNode;
        TickNode crossTickNode;
        Tick crossTick;
        Tick accumTick;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title The interface for the Concentrated Liquidity Pool Factory
interface IRangeFactory {
    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeTierTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

interface IRangePool {
    /// @notice This is to be used at hedge pool initialization in case the cardinality is too low for the hedge pool.
    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function tickSpacing() external view returns (int24);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

// import './DyDxMath.sol';
import './TickMath.sol';
import './Deltas.sol';
import '../interfaces/ICoverPoolStructs.sol';

library Claims {
    error InvalidClaimTick();
    error LiquidityOverflow();
    error WrongTickClaimedAt();
    error UpdatePositionFirstAt(int24, int24);
    error NotEnoughPositionLiquidity();

    function validate(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState storage pool,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.UpdatePositionCache memory cache
    ) external view returns (
        ICoverPoolStructs.UpdatePositionCache memory,
        bool
    ) {
        // validate position liquidity
        if (params.amount > cache.position.liquidity) revert NotEnoughPositionLiquidity();
        if (cache.position.liquidity == 0) {
            return (cache, true);
        } else if (params.zeroForOne ? params.claim == params.upper 
                                        && tickNodes[params.upper].accumEpochLast <= cache.position.accumEpochLast
                                     : params.claim == params.lower 
                                        && tickNodes[params.lower].accumEpochLast <= cache.position.accumEpochLast
        ) {
            return (cache, true);
        }
        // early return if no update
        if (
            (
                params.zeroForOne
                    ? params.claim == params.upper && cache.priceUpper != pool.price
                    : params.claim == params.lower && cache.priceLower != pool.price /// @dev - if pool price is start tick, set claimPriceLast to next tick crossed
            ) && params.claim == state.latestTick
        ) { if (cache.position.claimPriceLast == pool.price) return (cache, true); } /// @dev - nothing to update if pool price hasn't moved
        
        // claim tick sanity checks
        else if (
            cache.position.claimPriceLast > 0 &&
            (
                params.zeroForOne
                    ? cache.position.claimPriceLast < cache.priceClaim
                    : cache.position.claimPriceLast > cache.priceClaim
            ) && params.claim != state.latestTick
        ) revert InvalidClaimTick(); /// @dev - wrong claim tick
        if (params.claim < params.lower || params.claim > params.upper) revert InvalidClaimTick();

        // validate claim tick
        if (params.claim == (params.zeroForOne ? params.lower : params.upper)) {
             if (cache.claimTickNode.accumEpochLast <= cache.position.accumEpochLast)
                revert WrongTickClaimedAt();
            cache.position.liquidityStashed = 0;
            params.zeroForOne ? cache.removeLower = false : cache.removeUpper = false;
        } else {
            // zero fill or partial fill
            uint32 claimTickNextAccumEpoch = params.zeroForOne
                ? tickNodes[cache.claimTickNode.previousTick].accumEpochLast
                : tickNodes[cache.claimTickNode.nextTick].accumEpochLast;
            ///@dev - next accumEpoch should not be greater
            if (claimTickNextAccumEpoch > cache.position.accumEpochLast)
                revert WrongTickClaimedAt();

            // check if liquidity removal required
            if (params.amount > 0) {
                /// @dev - check if liquidity removal required
                cache.removeLower = params.zeroForOne
                    ? true
                    : tickNodes[cache.claimTickNode.nextTick].accumEpochLast <=
                        cache.position.accumEpochLast;
                cache.removeUpper = params.zeroForOne
                    ? tickNodes[cache.claimTickNode.previousTick].accumEpochLast <=
                        cache.position.accumEpochLast
                    : true;
            }
        }
        if (params.claim != params.upper && params.claim != params.lower) {
            // check accumEpochLast on claim tick
            if (tickNodes[params.claim].accumEpochLast <= cache.position.accumEpochLast)
                revert WrongTickClaimedAt();
            // prevent position overwriting at claim tick
            if (params.zeroForOne) {
                if (positions[params.owner][params.lower][params.claim].liquidity > 0) {
                    revert UpdatePositionFirstAt(params.lower, params.claim);
                }
            } else {
                if (positions[params.owner][params.claim][params.upper].liquidity > 0) {
                    revert UpdatePositionFirstAt(params.claim, params.upper);
                }
            }
            // 100% of liquidity is stashed
            //TODO: work through cases with this
            cache.position.liquidityStashed = cache.position.liquidity;
            /// @auditor - user cannot add liquidity if auction is active; checked for in Positions.validate()
        }
        return (cache, false);
    }

    function getDeltas(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // transfer deltas into cache
        if (params.claim == (params.zeroForOne ? params.lower : params.upper)) {
            (cache.claimTick, cache.deltas) = Deltas.from(cache.claimTick, cache.deltas);
        } else {
            /// @dev - deltas are applied once per each tick claimed at
            /// @dev - deltas should never be applied if position is not crossed into
            // check if tick already claimed at
            bool transferDeltas = (cache.position.claimPriceLast == 0
                               && (params.claim != (params.zeroForOne ? params.upper : params.lower)))
                               || (params.zeroForOne ? cache.position.claimPriceLast > cache.priceClaim
                                                     : cache.position.claimPriceLast < cache.priceClaim && cache.position.claimPriceLast != 0);
            if (transferDeltas) {
                (cache.claimTick, cache.deltas) = Deltas.unstash(cache.claimTick, cache.deltas);
            }
        } /// @dev - deltas transfer from claim tick are replaced after applying changes
        return cache;
    }

    function applyDeltas(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params
    ) external returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        uint256 percentInDelta; uint256 percentOutDelta;
        if(cache.deltas.amountInDeltaMax > 0) {
            percentInDelta = uint256(cache.amountInFilledMax) * 1e38 / uint256(cache.deltas.amountInDeltaMax);
            if (cache.deltas.amountOutDeltaMax > 0) {
                percentOutDelta = uint256(cache.amountOutUnfilledMax) * 1e38 / uint256(cache.deltas.amountOutDeltaMax);
            }
        }
        (cache.deltas, cache.finalDeltas) = Deltas.transfer(cache.deltas, cache.finalDeltas, percentInDelta, percentOutDelta);
        (cache.deltas, cache.finalDeltas) = Deltas.transferMax(cache.deltas, cache.finalDeltas, percentInDelta, percentOutDelta);
        // apply deltas and add to position
        if (cache.amountInFilledMax >= cache.finalDeltas.amountInDelta)
            //TODO: take a portion based on the protocol fee
            cache.position.amountIn  += cache.finalDeltas.amountInDelta;
        cache.position.amountOut += cache.finalDeltas.amountOutDelta;
        // add remaining deltas cached back to claim tick
        // cache.deltas, cache.claimTick) = Deltas.stash(cache.deltas, cache.claimTick, 1e38, 1e38);
        if (params.claim != (params.zeroForOne ? params.lower : params.upper)) {
            // burn deltas on final tick of position
            ICoverPoolStructs.Tick memory updateTick = ticks[params.zeroForOne ? params.lower : params.upper];
            (updateTick.deltas) = Deltas.burn(updateTick.deltas, cache.finalDeltas, true);
            ticks[params.zeroForOne ? params.lower : params.upper] = updateTick;
            //TODO: handle partial stashed and partial on tick
            if (params.claim == (params.zeroForOne ? params.upper : params.lower)) {
                (cache.deltas, cache.claimTick) = Deltas.to(cache.deltas, cache.claimTick);
            } else {
                (cache.deltas, cache.claimTick) = Deltas.stash(cache.deltas, cache.claimTick);
            }
        } else {
            (cache.deltas, cache.claimTick) = Deltas.to(cache.deltas, cache.claimTick);
        }
        return cache;
    }

    /// @dev - calculate claim portion of partially claimed previous auction
    function section1(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.GlobalState memory state
    ) external pure returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // delta check complete - update CPL for new position
        if(cache.position.claimPriceLast == 0) {
            cache.position.claimPriceLast = (params.zeroForOne ? cache.priceUpper 
                                                               : cache.priceLower);
        } else if (cache.position.claimPriceLast != (params.zeroForOne ? cache.priceUpper 
                                                                       : cache.priceLower)
                   && cache.priceClaim > cache.priceSpread ) {
            // section 1 - complete previous auction claim
            {
                // amounts claimed on this update
                uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
                (
                    amountInFilledMax,
                    amountOutUnfilledMax
                ) = Deltas.maxAuction(
                    cache.position.liquidity,
                    cache.position.claimPriceLast,
                    params.zeroForOne ? cache.priceUpper
                                      : cache.priceLower,
                    params.zeroForOne
                );
                //TODO: modify delta max on claim tick and lower : upper tick
                cache.amountInFilledMax    += amountInFilledMax;
                cache.amountOutUnfilledMax += amountOutUnfilledMax;
            }
            // move price to next tick in sequence for section 2
            cache.position.claimPriceLast  = params.zeroForOne ? TickMath.getSqrtRatioAtTick(params.upper - state.tickSpread)
                                                               : TickMath.getSqrtRatioAtTick(params.lower + state.tickSpread);
        }
        return cache;
    }

    /// @dev - calculate claim from position start up to claim tick
    function section2(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.PoolState storage pool
    ) external returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 2 - position start up to claim tick
        if (cache.position.claimPriceLast != cache.priceClaim) {
            // calculate if we at least cover one full tick
            uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
            (
                amountInFilledMax,
                amountOutUnfilledMax
            ) = Deltas.max(
                cache.position.liquidity,
                cache.position.claimPriceLast,
                cache.priceClaim,
                params.zeroForOne
            );
            cache.amountInFilledMax += amountInFilledMax;
            cache.amountOutUnfilledMax += amountOutUnfilledMax;
            params.zeroForOne ? ticks[params.lower].deltas.amountOutDeltaMax -= amountOutUnfilledMax
                              : ticks[params.upper].deltas.amountOutDeltaMax -= amountOutUnfilledMax;
        } else if (params.zeroForOne ? cache.priceClaim > cache.position.claimPriceLast 
                                     : cache.priceClaim < cache.position.claimPriceLast) {
            /// @dev - second claim within current auction
            cache.priceClaim = pool.price;
        }
        return cache;
    }

    /// @dev - calculate claim from position start up to claim tick
    function section3(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.PoolState storage pool
    ) external returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 3 - current auction unfilled section
        if (params.amount > 0) {
            // remove if burn
            uint128 amountOutRemoved = uint128(
                params.zeroForOne
                    ? DyDxMath.getDx(params.amount, pool.price, cache.priceClaim, false)
                    : DyDxMath.getDy(params.amount, cache.priceClaim, pool.price, false)
            );
            cache.position.amountOut += amountOutRemoved;
            // modify max deltas
            params.zeroForOne ? ticks[params.lower].deltas.amountOutDeltaMax -= amountOutRemoved
                              : ticks[params.upper].deltas.amountOutDeltaMax -= amountOutRemoved;
            uint128 amountInOmitted = uint128(
                params.zeroForOne
                    ? DyDxMath.getDy(params.amount, pool.price, cache.priceClaim, false)
                    : DyDxMath.getDx(params.amount, cache.priceClaim, pool.price, false)
            );
            params.zeroForOne ? ticks[params.lower].deltas.amountInDeltaMax -= amountInOmitted
                              : ticks[params.upper].deltas.amountInDeltaMax -= amountInOmitted;
        }
        return cache;
    }

    /// @dev - calculate claim from position start up to claim tick
    function section4(
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params,
        ICoverPoolStructs.PoolState storage pool
    ) external returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 4 - current auction filled section
        {
            // amounts claimed on this update
            uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
            (
                amountInFilledMax,
                amountOutUnfilledMax
            ) = Deltas.maxAuction(
                cache.position.liquidity,
                (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                    : cache.position.claimPriceLast > cache.priceClaim) 
                                        ? cache.position.claimPriceLast 
                                        : cache.priceSpread,
                pool.price,
                params.zeroForOne
            );
            uint256 poolAmountInDeltaChange = uint256(cache.position.liquidity) * 1e38 
                                                / uint256(pool.liquidity) * uint256(pool.amountInDelta) / 1e38;   
            
            cache.position.amountIn += uint128(poolAmountInDeltaChange);
            pool.amountInDelta -= uint128(poolAmountInDeltaChange);
            cache.finalDeltas.amountInDeltaMax += amountInFilledMax;
            cache.finalDeltas.amountOutDeltaMax += amountOutUnfilledMax;
            /// @dev - record how much delta max was claimed
            if (params.amount < cache.position.liquidity) {
                (
                    amountInFilledMax,
                    amountOutUnfilledMax
                ) = Deltas.maxAuction(
                    cache.position.liquidity - params.amount,
                    (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                    : cache.position.claimPriceLast > cache.priceClaim) 
                                            ? cache.position.claimPriceLast 
                                            : cache.priceSpread,
                    pool.price,
                    params.zeroForOne
                );
                pool.amountInDeltaMaxClaimed  += amountInFilledMax;
                pool.amountOutDeltaMaxClaimed += amountOutUnfilledMax;
            }
        }
        if (params.amount > 0 /// @ dev - if removing L and second claim on same tick
            && (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                    : cache.position.claimPriceLast > cache.priceClaim)) {
                // reduce delta max claimed based on liquidity removed
                uint128 amountInMaxClaimedBefore; uint128 amountOutMaxClaimedBefore;
                (
                    amountInMaxClaimedBefore,
                    amountOutMaxClaimedBefore
                ) = Deltas.maxAuction(
                    params.amount,
                    cache.priceSpread,
                    cache.position.claimPriceLast,
                    params.zeroForOne
                );
                pool.amountInDeltaMaxClaimed  -= amountInMaxClaimedBefore;
                pool.amountOutDeltaMaxClaimed -= amountOutMaxClaimedBefore;
        }
        // modify claim price for section 5
        cache.priceClaim = cache.priceSpread;
        return cache;
    }

        /// @dev - calculate claim from position start up to claim tick
    function section5(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        ICoverPoolStructs.UpdatePositionCache memory cache,
        ICoverPoolStructs.UpdateParams memory params
    ) external returns (
        ICoverPoolStructs.UpdatePositionCache memory
    ) {
        // section 5 - burned liquidity past claim tick
        {
            if (params.amount > 0) {
                // update max deltas based on liquidity removed
                uint128 amountInOmitted; uint128 amountOutRemoved;
                (
                    amountInOmitted,
                    amountOutRemoved
                ) = Deltas.maxTest(
                    params.amount,
                    cache.priceClaim,
                    params.zeroForOne ? cache.priceLower
                                      : cache.priceUpper,
                    params.zeroForOne
                );
                cache.position.amountOut += amountOutRemoved;
                if (params.claim != (params.zeroForOne ? params.lower : params.upper)) {
                    params.zeroForOne ? ticks[params.lower].deltas.amountInDeltaMax -= amountInOmitted
                                      : ticks[params.upper].deltas.amountInDeltaMax -= amountInOmitted;
                    params.zeroForOne ? ticks[params.lower].deltas.amountOutDeltaMax -= amountOutRemoved
                                      : ticks[params.upper].deltas.amountOutDeltaMax -= amountOutRemoved;
                }      
            }
        }
        return cache;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './DyDxMath.sol';
import '../interfaces/ICoverPoolStructs.sol';
// import 'hardhat/console.sol';
//TODO: stash and unstash
//TODO: transfer delta maxes as well in Positions.update()
library Deltas {
    function transfer(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Deltas memory toDeltas,
        uint256 percentInTransfer,
        uint256 percentOutTransfer
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Deltas memory
    ) {
        {
            uint128 amountInDeltaChange = uint128(uint256(fromDeltas.amountInDelta) * percentInTransfer / 1e38);
            if (amountInDeltaChange < fromDeltas.amountInDelta ) {
                fromDeltas.amountInDelta -= amountInDeltaChange;
                toDeltas.amountInDelta += amountInDeltaChange;
            } else {
                toDeltas.amountInDelta += fromDeltas.amountInDelta;
                fromDeltas.amountInDelta = 0;
            }
        }
        {
            uint128 amountOutDeltaChange = uint128(uint256(fromDeltas.amountOutDelta) * percentOutTransfer / 1e38);
            if (amountOutDeltaChange < fromDeltas.amountOutDelta ) {
                fromDeltas.amountOutDelta -= amountOutDeltaChange;
                toDeltas.amountOutDelta += amountOutDeltaChange;
            } else {
                toDeltas.amountOutDelta += fromDeltas.amountOutDelta;
                fromDeltas.amountOutDelta = 0;
            }
        }
        return (fromDeltas, toDeltas);
    }

    function transferMax(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Deltas memory toDeltas,
        uint256 percentInTransfer,
        uint256 percentOutTransfer
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Deltas memory
    ) {
        {
            uint128 amountInDeltaMaxChange = uint128(uint256(fromDeltas.amountInDeltaMax) * percentInTransfer / 1e38);
            if (fromDeltas.amountInDeltaMax > amountInDeltaMaxChange) {
                fromDeltas.amountInDeltaMax -= amountInDeltaMaxChange;
                toDeltas.amountInDeltaMax += amountInDeltaMaxChange;
            } else {
                toDeltas.amountInDeltaMax += fromDeltas.amountInDeltaMax;
                fromDeltas.amountOutDeltaMax = 0;
            }
        }
        {
            uint128 amountOutDeltaMaxChange = uint128(uint256(fromDeltas.amountOutDeltaMax) * percentOutTransfer / 1e38);
            if (fromDeltas.amountOutDeltaMax > amountOutDeltaMaxChange) {
                fromDeltas.amountOutDeltaMax -= amountOutDeltaMaxChange;
                toDeltas.amountOutDeltaMax   += amountOutDeltaMaxChange;
            } else {
                toDeltas.amountOutDeltaMax += fromDeltas.amountOutDeltaMax;
                fromDeltas.amountOutDeltaMax = 0;
            }
        }
        return (fromDeltas, toDeltas);
    }

    function burn(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Deltas memory burnDeltas,
        bool maxOnly
    ) external pure returns (
        ICoverPoolStructs.Deltas memory
    ) {
        if(!maxOnly) {
            fromDeltas.amountInDelta  -= burnDeltas.amountInDelta;
            fromDeltas.amountOutDelta -= burnDeltas.amountOutDelta;
        }
        fromDeltas.amountInDeltaMax  -= burnDeltas.amountInDeltaMax;
        fromDeltas.amountOutDeltaMax -= burnDeltas.amountOutDeltaMax;
        return fromDeltas;
    }

    function from(
        ICoverPoolStructs.Tick memory fromTick,
        ICoverPoolStructs.Deltas memory toDeltas
    ) external pure returns (
        ICoverPoolStructs.Tick memory,
        ICoverPoolStructs.Deltas memory
    ) {
        uint256 percentOnTick = uint256(fromTick.deltas.amountInDeltaMax) * 1e38 / (uint256(fromTick.deltas.amountInDeltaMax) + uint256(fromTick.amountInDeltaMaxStashed));
        {
            uint128 amountInDeltaChange = uint128(uint256(fromTick.deltas.amountInDelta) * percentOnTick / 1e38);
            fromTick.deltas.amountInDelta -= amountInDeltaChange;
            toDeltas.amountInDelta += amountInDeltaChange;
            toDeltas.amountInDeltaMax += fromTick.deltas.amountInDeltaMax;
            fromTick.deltas.amountInDeltaMax = 0;
        }
        percentOnTick = uint256(fromTick.deltas.amountOutDeltaMax) * 1e38 / (uint256(fromTick.deltas.amountOutDeltaMax) + uint256(fromTick.amountOutDeltaMaxStashed));
        {
            uint128 amountOutDeltaChange = uint128(uint256(fromTick.deltas.amountOutDelta) * percentOnTick / 1e38);
            fromTick.deltas.amountOutDelta -= amountOutDeltaChange;
            toDeltas.amountOutDelta += amountOutDeltaChange;
            toDeltas.amountOutDeltaMax += fromTick.deltas.amountOutDeltaMax;
            fromTick.deltas.amountOutDeltaMax = 0;
        }
        return (fromTick, toDeltas);
    }

    function onto(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory toTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Tick memory
    ) {
        if (fromDeltas.amountInDeltaMax > toTick.deltas.amountInDeltaMax) {
            fromDeltas.amountInDeltaMax -= toTick.deltas.amountInDeltaMax;
        } else {
            fromDeltas.amountInDeltaMax = 0;
        }
        if (fromDeltas.amountOutDeltaMax > toTick.deltas.amountOutDeltaMax) {
            fromDeltas.amountOutDeltaMax -= toTick.deltas.amountOutDeltaMax;
        } else {
            fromDeltas.amountOutDeltaMax = 0;
        }
        
        return (fromDeltas, toTick);
    }

    function to(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory toTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Tick memory
    ) {
        toTick.deltas.amountInDelta     += fromDeltas.amountInDelta;
        toTick.deltas.amountInDeltaMax  += fromDeltas.amountInDeltaMax;
        toTick.deltas.amountOutDelta    += fromDeltas.amountOutDeltaMax;
        toTick.deltas.amountOutDeltaMax += fromDeltas.amountOutDeltaMax;
        fromDeltas = ICoverPoolStructs.Deltas(0,0,0,0);
        return (fromDeltas, toTick);
    }

    function stash(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory toTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Tick memory
    ) {
        toTick.deltas.amountInDelta     += fromDeltas.amountInDelta;
        toTick.amountInDeltaMaxStashed  += fromDeltas.amountInDeltaMax;
        toTick.deltas.amountOutDelta    += fromDeltas.amountOutDelta;
        toTick.amountOutDeltaMaxStashed += fromDeltas.amountOutDeltaMax;
        fromDeltas = ICoverPoolStructs.Deltas(0,0,0,0);
        return (fromDeltas, toTick);
    }

    function unstash(
        ICoverPoolStructs.Tick memory fromTick,
        ICoverPoolStructs.Deltas memory toDeltas
    ) external pure returns (
        ICoverPoolStructs.Tick memory,
        ICoverPoolStructs.Deltas memory
    ) {
        toDeltas.amountInDeltaMax  += fromTick.amountInDeltaMaxStashed;
        toDeltas.amountOutDeltaMax += fromTick.amountOutDeltaMaxStashed;
        
        uint256 totalDeltaMax = uint256(fromTick.amountInDeltaMaxStashed) + uint256(fromTick.deltas.amountInDeltaMax);
        
        if (totalDeltaMax > 0) {
            uint256 percentStashed = uint256(fromTick.amountInDeltaMaxStashed) * 1e38 / totalDeltaMax;
            uint128 amountInDeltaChange = uint128(uint256(fromTick.deltas.amountInDelta) * percentStashed / 1e38);
            fromTick.deltas.amountInDelta -= amountInDeltaChange;
            toDeltas.amountInDelta += amountInDeltaChange;
        }
        
        totalDeltaMax = uint256(fromTick.amountOutDeltaMaxStashed) + uint256(fromTick.deltas.amountOutDeltaMax);
        
        if (totalDeltaMax > 0) {
            uint256 percentStashed = uint256(fromTick.amountOutDeltaMaxStashed) * 1e38 / totalDeltaMax;
            uint128 amountOutDeltaChange = uint128(uint256(fromTick.deltas.amountOutDelta) * percentStashed / 1e38);
            fromTick.deltas.amountOutDelta -= amountOutDeltaChange;
            toDeltas.amountOutDelta += amountOutDeltaChange;
        }

        fromTick.amountInDeltaMaxStashed = 0;
        fromTick.amountOutDeltaMaxStashed = 0;
        return (fromTick, toDeltas);
    }

    function max(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool   isPool0
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : DyDxMath.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : DyDxMath.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
    }

    function maxTest(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool   isPool0
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
                : DyDxMath.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : DyDxMath.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
    }

    function maxAuction(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool isPool0
    ) external pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
                : DyDxMath.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
                : DyDxMath.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
        );
    }

    function update(
        ICoverPoolStructs.Deltas memory deltas,
        uint128 amount,
        uint160 priceLower,
        uint160 priceUpper,
        bool   isPool0,
        bool   isAdded
    ) external pure returns (
        ICoverPoolStructs.Deltas memory
    ) {
        // update max deltas
        uint128 amountInDeltaMax; uint128 amountOutDeltaMax;
        if (isPool0) {
            (
                amountInDeltaMax,
                amountOutDeltaMax
            ) = max(amount, priceUpper, priceLower, true);
        } else {
            (
                amountInDeltaMax,
                amountOutDeltaMax
            ) = max(amount, priceLower, priceUpper, false);
        }
        if (isAdded) {
            deltas.amountInDeltaMax  += amountInDeltaMax;
            deltas.amountOutDeltaMax += amountOutDeltaMax;
        } else {
            deltas.amountInDeltaMax  -= amountInDeltaMax;
            deltas.amountOutDeltaMax -= amountOutDeltaMax;
        }
        return deltas;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './FullPrecisionMath.sol';

/// @notice Math library that facilitates ranged liquidity calculations.
library DyDxMath {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    error PriceOutsideBounds();

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
                dy = FullPrecisionMath.mulDivRoundingUp(liquidity, priceUpper - priceLower, Q96);
            } else {
                dy = FullPrecisionMath.mulDiv(liquidity, priceUpper - priceLower, Q96);
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

    //TODO: debug math for this to validate numbers
    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) external pure returns (uint256 liquidity) {
        unchecked {
            if (priceUpper == currentPrice) {
                liquidity = FullPrecisionMath.mulDiv(dy, Q96, priceUpper - priceLower);
            } else if (currentPrice == priceLower) {
                liquidity = FullPrecisionMath.mulDiv(
                    dx,
                    FullPrecisionMath.mulDiv(priceLower, priceUpper, Q96),
                    priceUpper - priceLower
                );
            } else {
                revert PriceOutsideBounds();
            }
            /// @dev - price should never be outside of lower and upper
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library FullPrecisionMath {
    error MaxUintExceeded();

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result) {
        return _mulDiv(a, b, denominator);
    }

    // @dev no underflow or overflow checks
    function divRoundingUp(uint256 x, uint256 y) external pure returns (uint256 z) {
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
                if (result >= type(uint256).max) revert MaxUintExceeded();
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './TickMath.sol';
import './Ticks.sol';
import './Deltas.sol';
import '../interfaces/ICoverPoolStructs.sol';
import './FullPrecisionMath.sol';
import './DyDxMath.sol';
import './Claims.sol';

/// @notice Position management library for ranged liquidity.
library Positions {
    error InvalidClaimTick();
    error LiquidityOverflow();
    error WrongTickClaimedAt();
    error PositionNotUpdated();
    error ClaimPriceLastNonZero();
    error UpdatePositionFirstAt(int24, int24);
    error InvalidLowerTick();
    error InvalidUpperTick();
    error InvalidPositionAmount();
    error InvalidPositionBoundsOrder();
    error InvalidPositionBoundsTwap();
    error NotEnoughPositionLiquidity();
    error NotImplementedYet();

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    function validate(
        ICoverPoolStructs.MintParams memory params,
        ICoverPoolStructs.GlobalState memory state
    ) external pure returns (
        ICoverPoolStructs.MintParams memory,
        uint256 liquidityMinted
    )
    {
        if (params.lower < TickMath.MIN_TICK) revert InvalidLowerTick();
        if (params.upper > TickMath.MAX_TICK) revert InvalidUpperTick();
        if (params.lower % int24(state.tickSpread) != 0) revert InvalidLowerTick();
        if (params.upper % int24(state.tickSpread) != 0) revert InvalidUpperTick();
        if (params.amount == 0) revert InvalidPositionAmount();
        if (params.lower >= params.upper || params.lowerOld >= params.upperOld)
            revert InvalidPositionBoundsOrder();
        if (params.zeroForOne) {
            if (params.lower >= state.latestTick) revert InvalidPositionBoundsTwap();
        } else {
            if (params.upper <= state.latestTick) revert InvalidPositionBoundsTwap();
        }
        uint256 priceLower = uint256(TickMath.getSqrtRatioAtTick(params.lower));
        uint256 priceUpper = uint256(TickMath.getSqrtRatioAtTick(params.upper));

        liquidityMinted = DyDxMath.getLiquidityForAmounts(
            priceLower,
            priceUpper,
            params.zeroForOne ? priceLower : priceUpper,
            params.zeroForOne ? 0 : uint256(params.amount),
            params.zeroForOne ? uint256(params.amount) : 0
        );

        // handle partial mints
        if (params.zeroForOne) {
            if (params.upper >= state.latestTick) {
                params.upper = state.latestTick - int24(state.tickSpread);
                params.upperOld = state.latestTick;
                uint256 priceNewUpper = TickMath.getSqrtRatioAtTick(params.upper);
                params.amount -= uint128(
                    DyDxMath.getDx(liquidityMinted, priceNewUpper, priceUpper, false)
                );
                priceUpper = priceNewUpper;
            }
        } else {
            if (params.lower <= state.latestTick) {
                params.lower = state.latestTick + int24(state.tickSpread);
                params.lowerOld = state.latestTick;
                uint256 priceNewLower = TickMath.getSqrtRatioAtTick(params.lower);
                params.amount -= uint128(
                    DyDxMath.getDy(liquidityMinted, priceLower, priceNewLower, false)
                );
                priceLower = priceNewLower;
            }
        }

        if (liquidityMinted > uint128(type(int128).max)) revert LiquidityOverflow();
        if (params.lower == params.upper) revert InvalidPositionBoundsTwap();

        return (
            params,
            liquidityMinted
        );
    }

    function add(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.AddParams memory params
    ) external {
        //TODO: dilute amountDeltas when adding liquidity
        ICoverPoolStructs.PositionCache memory cache = ICoverPoolStructs.PositionCache({
            position: positions[params.owner][params.lower][params.upper],
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper)
        });
        /// call if claim != lower and liquidity being added
        /// initialize new position
        if (params.amount == 0) return;
        if (cache.position.liquidity == 0) {
            cache.position.accumEpochLast = state.accumEpoch;
        } else {
            /// safety check...might be unnecessary given the user is forced to update()
            if (
                params.zeroForOne
                    ? state.latestTick < params.upper ||
                        tickNodes[params.upper].accumEpochLast > cache.position.accumEpochLast
                    : state.latestTick > params.lower ||
                        tickNodes[params.lower].accumEpochLast > cache.position.accumEpochLast
            ) {
                revert WrongTickClaimedAt();
            }
        }
        // Positions.update() called first before additional mints
        if (cache.position.claimPriceLast > 0) { revert ClaimPriceLastNonZero(); }
        
        // add liquidity to ticks
        Ticks.insert(
            ticks,
            tickNodes,
            state,
            params.lowerOld,
            params.lower,
            params.upperOld,
            params.upper,
            uint128(params.amount),
            params.zeroForOne
        );

        {
            // update max deltas
            ICoverPoolStructs.Deltas memory tickDeltas = ticks[params.zeroForOne ? params.lower : params.upper].deltas;
            tickDeltas = Deltas.update(tickDeltas, params.amount, cache.priceLower, cache.priceUpper, params.zeroForOne, true);
            ticks[params.zeroForOne ? params.lower : params.upper].deltas = tickDeltas;
        }

        cache.position.liquidity += uint128(params.amount);

        positions[params.owner][params.lower][params.upper] = cache.position;
    }

    function remove(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.RemoveParams memory params
    ) external returns (uint128, ICoverPoolStructs.GlobalState memory) {
        //TODO: dilute amountDeltas when adding liquidity
        ICoverPoolStructs.PositionCache memory cache = ICoverPoolStructs.PositionCache({
            position: positions[params.owner][params.lower][params.upper],
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper)
        });
        if (params.amount == 0) return (0, state);
        if (params.amount > cache.position.liquidity) {
            revert NotEnoughPositionLiquidity();
        } else {
            /// @dev - validate needed in case user passes in wrong tick
            if (
                params.zeroForOne
                    ? state.latestTick < params.upper ||
                        tickNodes[params.upper].accumEpochLast > cache.position.accumEpochLast
                    : state.latestTick > params.lower ||
                        tickNodes[params.lower].accumEpochLast > cache.position.accumEpochLast
            ) {
                revert WrongTickClaimedAt();
            }
        }

        Ticks.remove(
            ticks,
            params.lower,
            params.upper,
            params.amount,
            // 0,
            params.zeroForOne,
            true,
            true
        );

        {
            // update max deltas
            ICoverPoolStructs.Deltas memory tickDeltas = ticks[params.zeroForOne ? params.lower : params.upper].deltas;
            tickDeltas = Deltas.update(tickDeltas, params.amount, cache.priceLower, cache.priceUpper, params.zeroForOne, false);
            ticks[params.zeroForOne ? params.lower : params.upper].deltas = tickDeltas;
        }

        cache.position.amountOut += uint128(
            params.zeroForOne
                ? DyDxMath.getDx(params.amount, cache.priceLower, cache.priceUpper, false)
                : DyDxMath.getDy(params.amount, cache.priceLower, cache.priceUpper, false)
        );

        cache.position.liquidity -= uint128(params.amount);
        positions[params.owner][params.lower][params.upper] = cache.position;

        return (params.amount, state);
    }

    //TODO: pass pool as memory and save pool changes using return value
    function update(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState storage pool,
        ICoverPoolStructs.UpdateParams memory params
    )
        external
        returns (
            ICoverPoolStructs.GlobalState memory
        )
    {
        ICoverPoolStructs.UpdatePositionCache memory cache = ICoverPoolStructs.UpdatePositionCache({
            position: positions[params.owner][params.lower][params.upper],
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceClaim: TickMath.getSqrtRatioAtTick(params.claim),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper),
            priceSpread: TickMath.getSqrtRatioAtTick(params.zeroForOne ? state.latestTick - state.tickSpread 
                                                                       : state.latestTick + state.tickSpread),
            amountInFilledMax: 0,
            amountOutUnfilledMax: 0,
            claimTick: ticks[params.claim],
            claimTickNode: tickNodes[params.claim],
            removeLower: true,
            removeUpper: true,
            deltas: ICoverPoolStructs.Deltas(0,0,0,0),
            finalDeltas: ICoverPoolStructs.Deltas(0,0,0,0)
        });

        // check claim is valid
        {
            bool earlyReturn;
            (cache, earlyReturn) = Claims.validate(
                positions,
                tickNodes,
                state,
                pool,
                params,
                cache
            );
            if (earlyReturn) {
                return state;
            }
        }
        // get deltas from claim tick
        cache = Claims.getDeltas(cache, params);
        
        /// @dev - section 1 => position start - previous auction
        cache = Claims.section1(cache, params, state);
        
        /// @dev - section 2 => position start -> claim tick
        cache = Claims.section2(ticks, cache, params, pool);
        
        // check if auction in progress 
        if (params.claim == state.latestTick 
            && params.claim != (params.zeroForOne ? params.lower : params.upper)) {
            /// @dev - section 3 => claim tick - unfilled section
            cache = Claims.section3(ticks, cache, params, pool);
            
            /// @dev - section 4 => claim tick - filled section
            cache = Claims.section4(cache, params, pool);
        }

        /// @dev - section 5 => claim tick -> position end
        cache = Claims.section5(ticks, cache, params);
        
        // adjust position amounts based on deltas
        cache = Claims.applyDeltas(ticks, cache, params);

        // save claim tick and tick node
        ticks[params.claim] = cache.claimTick;
        tickNodes[params.claim] = cache.claimTickNode;
        
        // update pool liquidity
        if (state.latestTick == params.claim
            && params.claim != (params.zeroForOne ? params.lower : params.upper)
        ) pool.liquidity -= params.amount;
        
        /// @dev - mark last claim price
        cache.priceClaim = TickMath.getSqrtRatioAtTick(params.claim);
        cache.position.claimPriceLast = (params.claim == state.latestTick)
            ? pool.price
            : cache.priceClaim;
        /// @dev - if tick 0% filled, set CPL to latestTick
        if (pool.price == cache.priceSpread) cache.position.claimPriceLast = cache.priceClaim;
        /// @dev - if tick 100% filled, set CPL to next tick to unlock
        if (pool.price == cache.priceClaim && params.claim == state.latestTick) cache.position.claimPriceLast = cache.priceClaim;
        /// @dev - prior to Ticks.remove() so we don't overwrite liquidity delta changes
        // if burn or second mint
        //TODO: handle claim of current auction and second mint
        if ((params.amount > 0)) {
            if (params.claim != (params.zeroForOne ? params.upper : params.lower)) {
                //TODO: switch to being the current price if necessary
                params.zeroForOne ? cache.removeUpper = false : cache.removeLower = false;
            }
            Ticks.remove(
                ticks,
                params.zeroForOne ? params.lower : params.claim,
                params.zeroForOne ? params.claim : params.upper,
                uint128(uint128(params.amount)),
                // cache.position.liquidityStashed,
                params.zeroForOne,
                cache.removeLower,
                cache.removeUpper
            );
            cache.position.liquidity -= uint128(params.amount);
        }
        if (params.zeroForOne ? params.claim != params.upper 
                              : params.claim != params.lower) {
            // clear out position
            delete positions[params.owner][params.lower][params.upper];
        } 
        if (cache.position.liquidity == 0) {
            cache.position.accumEpochLast = 0;
            cache.position.claimPriceLast = 0;
            cache.position.claimCheckpoint = 0;
        }
        params.zeroForOne
            ? positions[params.owner][params.lower][params.claim] = cache.position
            : positions[params.owner][params.claim][params.upper] = cache.position;

        return state;
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
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MAX_TICK).
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    error TickOutOfBounds();
    error PriceOutOfBounds();
    error WaitUntilEnoughObservations();

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
            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
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
        if (price < MIN_SQRT_RATIO || price >= MAX_SQRT_RATIO) {
            revert PriceOutOfBounds();
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio.
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96.
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio.
    function _getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO)
            revert PriceOutOfBounds();
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

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

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : _getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './TickMath.sol';
import '../interfaces/ICoverPoolStructs.sol';
import '../utils/CoverPoolErrors.sol';
import './FullPrecisionMath.sol';
import './DyDxMath.sol';
import './TwapOracle.sol';

/// @notice Tick management library for ranged liquidity.
library Ticks {
    //TODO: alphabetize errors
    error NotImplementedYet();
    error InvalidLatestTick();
    error InfiniteTickLoop0(int24);
    error InfiniteTickLoop1(int24);
    error LiquidityOverflow();
    error WrongTickOrder();
    error WrongTickLowerRange();
    error WrongTickUpperRange();
    error WrongTickLowerOld();
    error WrongTickUpperOld();
    error NoLiquidityToRollover();
    error AmountInDeltaNeutral();
    error AmountOutDeltaNeutral();

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    using Ticks for mapping(int24 => ICoverPoolStructs.Tick);

    function quote(
        bool zeroForOne,
        uint160 priceLimit,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.SwapCache memory cache
    ) external view returns (ICoverPoolStructs.SwapCache memory, uint256 amountOut) {
        if (zeroForOne ? priceLimit >= cache.price 
                       : priceLimit <= cache.price 
            || cache.price == 0 
            || cache.input == 0
        )
            return (cache, 0);
        uint256 nextTickPrice = state.latestPrice;
        uint256 nextPrice = nextTickPrice;

        // determine input boost from tick auction
        cache.auctionBoost = ((cache.auctionDepth <= state.auctionLength) ? cache.auctionDepth 
                                                                          : state.auctionLength
                             ) * 1e14 / state.auctionLength * uint16(state.tickSpread);
        cache.inputBoosted = cache.input * (1e18 + cache.auctionBoost) / 1e18;
        if (zeroForOne) {
            // trade token 0 (x) for token 1 (y)
            // price decreases
            if (priceLimit > nextPrice) {
                // stop at price limit
                nextPrice = priceLimit;
            }
            uint256 maxDx = DyDxMath.getDx(cache.liquidity, nextPrice, cache.price, false);
            // check if we can increase input to account for auction
            // if we can't, subtract amount inputted at the end
            // store amountInDelta in pool either way
            // putting in less either way
            if (cache.inputBoosted <= maxDx) {
                uint256 liquidityPadded = cache.liquidity << 96;
                // calculate price after swap
                uint256 newPrice = FullPrecisionMath.mulDivRoundingUp(
                    liquidityPadded,
                    cache.price,
                    liquidityPadded + cache.price * cache.inputBoosted
                );
                amountOut = DyDxMath.getDy(cache.liquidity, newPrice, cache.price, false);
                cache.price = uint160(newPrice);
                cache.input = 0;
                cache.amountInDelta = cache.amountIn;
            } else if (maxDx > 0) {
                amountOut = DyDxMath.getDy(cache.liquidity, nextPrice, cache.price, false);
                cache.price = nextPrice;
                cache.input -= maxDx * (1e18 - cache.auctionBoost) / 1e18; /// @dev - convert back to input amount
                cache.amountInDelta = cache.amountIn - cache.input;
            }
        } else {
            // price increases
            if (priceLimit < nextPrice) {
                // stop at price limit
                nextPrice = priceLimit;
            }
            uint256 maxDy = DyDxMath.getDy(cache.liquidity, cache.price, nextPrice, false);
            if (cache.inputBoosted <= maxDy) {
                // calculate price after swap
                uint256 newPrice = cache.price +
                    FullPrecisionMath.mulDiv(cache.inputBoosted, Q96, cache.liquidity);
                amountOut = DyDxMath.getDx(cache.liquidity, cache.price, newPrice, false);
                cache.price = newPrice;
                cache.input = 0;
                cache.amountInDelta = cache.amountIn;
            } else if (maxDy > 0) {
                amountOut = DyDxMath.getDx(cache.liquidity, cache.price, nextPrice, false);
                cache.price = nextPrice;
                cache.input -= maxDy * (1e18 - cache.auctionBoost) / 1e18; 
                cache.amountInDelta = cache.amountIn - cache.input;
            }
        }
        return (cache, amountOut);
    }

    function initialize(
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.PoolState storage pool0,
        ICoverPoolStructs.PoolState storage pool1,
        ICoverPoolStructs.GlobalState memory state
    ) external returns (ICoverPoolStructs.GlobalState memory) {
        /// @dev - assume latestTick is not MIN_TICK or MAX_TICK
        // if (latestTick == TickMath.MIN_TICK || latestTick == TickMath.MAX_TICK) revert InvalidLatestTick();
        if (state.unlocked == 0) {
            (state.unlocked, state.latestTick) = TwapOracle.initializePoolObservations(
                state.inputPool,
                state.twapLength
            );
            if (state.unlocked == 1) {

                state.latestTick = (state.latestTick / int24(state.tickSpread)) * int24(state.tickSpread);
                state.latestPrice = TickMath.getSqrtRatioAtTick(state.latestTick);
                state.auctionStart = uint32(block.number - state.genesisBlock);
                state.accumEpoch = 1;

                tickNodes[state.latestTick] = ICoverPoolStructs.TickNode(
                    TickMath.MIN_TICK,
                    TickMath.MAX_TICK,
                    state.accumEpoch
                );
                tickNodes[TickMath.MIN_TICK] = ICoverPoolStructs.TickNode(
                    TickMath.MIN_TICK,
                    state.latestTick,
                    state.accumEpoch
                );
                tickNodes[TickMath.MAX_TICK] = ICoverPoolStructs.TickNode(
                    state.latestTick,
                    TickMath.MAX_TICK,
                    state.accumEpoch
                );

                pool0.price = TickMath.getSqrtRatioAtTick(state.latestTick - state.tickSpread);
                pool1.price = TickMath.getSqrtRatioAtTick(state.latestTick + state.tickSpread);
            }
        }
        return state;
    }

    function insert(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.GlobalState memory state,
        int24 lowerOld,
        int24 lower,
        int24 upperOld,
        int24 upper,
        uint128 amount,
        bool isPool0
    ) external {
        /// @auditor - validation of ticks is in Positions.validate
        // load into memory to reduce storage reads/writes
        if (amount > uint128(type(int128).max)) revert LiquidityOverflow();
        if ((uint128(type(int128).max) - state.liquidityGlobal) < amount)
            revert LiquidityOverflow();
        ICoverPoolStructs.Tick memory tickLower = ticks[lower];
        ICoverPoolStructs.Tick memory tickUpper = ticks[upper];
        ICoverPoolStructs.TickNode memory tickNodeLower = tickNodes[lower];
        ICoverPoolStructs.TickNode memory tickNodeUpper = tickNodes[upper];
        /// @auditor lower or upper = latestTick -> should not be possible
        /// @auditor - should we check overflow/underflow of lower and upper ticks?
        /// @auditor - we need to be able to deprecate pools if necessary; so not much reason to do overflow/underflow check
        if (tickNodeLower.nextTick != tickNodeLower.previousTick) {
            // tick exists
            if (isPool0) {
                tickLower.liquidityDelta -= int128(amount);
                tickLower.liquidityDeltaMinus += amount;
            } else {
                tickLower.liquidityDelta += int128(amount);
            }
            if (upper == tickNodes[upperOld].previousTick) {
                tickNodeLower.nextTick = upper;
            }
        } else {
            // tick does not exist
            if (isPool0) {
                tickLower = ICoverPoolStructs.Tick(-int128(amount), amount, 0, 0, ICoverPoolStructs.Deltas(0, 0, 0, 0));
            } else {
                tickLower = ICoverPoolStructs.Tick(int128(amount), 0, 0, 0, ICoverPoolStructs.Deltas(0, 0, 0, 0));
            }
            /// @auditor new latestTick being in between lowerOld and lower handled by Positions.validate()
            int24 oldNextTick = tickNodes[lowerOld].nextTick;
            if (upper < oldNextTick) {
                oldNextTick = upper;
            }
            /// @auditor - don't set previous tick so upper can be initialized
            else {
                tickNodes[oldNextTick].previousTick = lower;
            }

            if (lowerOld >= lower || lower >= oldNextTick) {
                revert WrongTickLowerOld();
            }
            tickNodeLower = ICoverPoolStructs.TickNode(lowerOld, oldNextTick, 0);
            tickNodes[lowerOld].nextTick = lower;
        }

        /// @auditor -> is it safe to add to liquidityDelta w/o Tick struct initialization
        if (tickNodeUpper.nextTick != tickNodeUpper.previousTick) {
            if (isPool0) {
                tickUpper.liquidityDelta += int128(amount);
            } else {
                tickUpper.liquidityDelta -= int128(amount);
                tickUpper.liquidityDeltaMinus += amount;
            }
            if (lower == tickNodes[lowerOld].nextTick) {
                tickNodeUpper.previousTick = lower;
            }
        } else {
            if (isPool0) {
                tickUpper = ICoverPoolStructs.Tick(int128(amount), 0, 0, 0, ICoverPoolStructs.Deltas(0, 0, 0, 0));
            } else {
                tickUpper = ICoverPoolStructs.Tick(-int128(amount), amount, 0, 0, ICoverPoolStructs.Deltas(0, 0, 0, 0));
            }
            int24 oldPrevTick = tickNodes[upperOld].previousTick;
            if (lower > oldPrevTick) oldPrevTick = lower;
            //TODO: handle new TWAP being in between upperOld and upper
            /// @dev - if nextTick == previousTick this tick node is uninitialized
            if (
                tickNodes[upperOld].nextTick == tickNodes[upperOld].previousTick ||
                upperOld <= upper ||
                upper <= oldPrevTick
            ) {
                revert WrongTickUpperOld();
            }
            tickNodeUpper = ICoverPoolStructs.TickNode(oldPrevTick, upperOld, 0);
            tickNodes[oldPrevTick].nextTick = upper;
            tickNodes[upperOld].previousTick = upper;
        }
        ticks[lower] = tickLower;
        ticks[upper] = tickUpper;
        tickNodes[lower] = tickNodeLower;
        tickNodes[upper] = tickNodeUpper;
    }

    function remove(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        int24 lower,
        int24 upper,
        uint128 amount,
        // uint128 amountStashed,
        bool isPool0,
        bool removeLower,
        bool removeUpper
    ) external {
        //TODO: we can only delete is lower != MIN_TICK or latestTick and all values are 0
        // bool deleteLowerTick = false; bool deleteUpperTick = false;

        //TODO: we can only delete is upper != MAX_TICK or latestTick and all values are 0
        //TODO: can be handled by using inactiveLiquidity == 0 and activeLiquidity == 0
        {
            ICoverPoolStructs.Tick memory tickLower = ticks[lower];
            if (removeLower) {
                if (isPool0) {
                    tickLower.liquidityDelta += int128(amount);
                    tickLower.liquidityDeltaMinus -= amount;
                } else {
                    tickLower.liquidityDelta -= int128(amount);
                }
            }
            /// @dev - not deleting ticks just yet
            ticks[lower] = tickLower;
        }

        //TODO: can be handled using inactiveLiquidity and activeLiquidity == 0

        //TODO: we need to know what tick they're claiming from
        //TODO: that is the tick that should have liquidity values modified
        //TODO: keep unchecked block?
        {
            ICoverPoolStructs.Tick memory tickUpper = ticks[upper];
            if (removeUpper) {
                if (isPool0) {
                    tickUpper.liquidityDelta -= int128(amount);
                } else {
                    tickUpper.liquidityDelta += int128(amount);
                    tickUpper.liquidityDeltaMinus -= amount;
                }
            }
            ticks[upper] = tickUpper;
        }

        // if (deleteLowerTick) {
        //     // Delete lower tick.
        //     int24 previous = tickNodes[lower].previousTick;
        //     int24 next     = tickNodes[lower].nextTick;
        //     if(next != upper || !deleteUpperTick) {
        //         tickNodes[previous].nextTick = next;
        //         tickNodes[next].previousTick = previous;
        //     } else {
        //         int24 upperNextTick = tickNodes[upper].nextTick;
        //         tickNodes[tickNodes[lower].previousTick].nextTick = upperNextTick;
        //         tickNodes[upperNextTick].previousTick = previous;
        //     }
        // }
        // if (deleteUpperTick) {
        //     // Delete upper tick.
        //     int24 previous = tickNodes[upper].previousTick;
        //     int24 next     = tickNodes[upper].nextTick;

        //     if(previous != lower || !deleteLowerTick) {
        //         tickNodes[previous].nextTick = next;
        //         tickNodes[next].previousTick = previous;
        //     } else {
        //         int24 lowerPrevTick = tickNodes[lower].previousTick;
        //         tickNodes[lowerPrevTick].nextTick = next;
        //         tickNodes[next].previousTick = lowerPrevTick;
        //     }
        // }
        /// @dev - we can never delete ticks due to amount deltas
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IRangeFactory.sol';
import '../interfaces/IRangePool.sol';
import './TickMath.sol';

// will the blockTimestamp be consistent across the entire block?
library TwapOracle {
    error WaitUntilBelowMaxTick();
    error WaitUntilAboveMinTick();
    // @AUDIT - set for Ethereum mainnet; adjust for Arbitrum mainnet
    uint16 public constant blockTime = 12;
    /// @dev - adjust for deployment
    uint32 public constant startBlock = 0;

    // @dev increase pool observations if not sufficient
    // @dev must be deterministic since called externally
    function initializePoolObservations(IRangePool pool, uint16 twapLength)
        external
        returns (uint8 initializable, int24 startingTick)
    {
        if (!_isPoolObservationsEnough(pool, twapLength)) {
            _increaseV3Observations(address(pool), twapLength);
            return (0, 0);
        }
        return (1, _calculateAverageTick(pool, twapLength));
    }

    function calculateAverageTick(IRangePool pool, uint16 twapLength)
        external
        view
        returns (int24 averageTick)
    {
        return _calculateAverageTick(pool, twapLength);
    }

    function _calculateAverageTick(IRangePool pool, uint16 twapLength)
        internal
        view
        returns (int24 averageTick)
    {
        uint32[] memory secondsAgos = new uint32[](3);
        secondsAgos[0] = 0;
        secondsAgos[1] = blockTime * twapLength;
        (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);
        averageTick = int24(((tickCumulatives[0] - tickCumulatives[1]) / (int32(secondsAgos[1]))));
        if (averageTick == TickMath.MAX_TICK) revert WaitUntilBelowMaxTick();
        if (averageTick == TickMath.MIN_TICK) revert WaitUntilAboveMinTick();
    }

    function isPoolObservationsEnough(address pool, uint16 twapLength)
        external
        view
        returns (bool)
    {
        return _isPoolObservationsEnough(IRangePool(pool), twapLength);
    }

    function _isPoolObservationsEnough(IRangePool pool, uint16 twapLength)
        internal
        view
        returns (bool)
    {
        (, , , uint16 observationsCount, , , ) = pool.slot0();
        return observationsCount >= twapLength;
    }

    function _increaseV3Observations(address pool, uint16 twapLength) internal {
        IRangePool(pool).increaseObservationCardinalityNext(twapLength);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract CoverPoolErrors {
    error Locked();
    error InvalidToken();
    error InvalidPosition();
    error InvalidSwapFee();
    error InvalidTickSpread();
    error LiquidityOverflow();
    error Token0Missing();
    error Token1Missing();
    error InvalidTick();
    error FactoryOnly();
    error LowerNotEvenTick();
    error UpperNotOddTick();
    error MaxTickLiquidity();
    error Overflow();
    error NotEnoughOutputLiquidity();
    error WaitUntilEnoughObservations();
}

abstract contract CoverTicksErrors {
    error WrongTickLowerRange();
    error WrongTickUpperRange();
    error WrongTickLowerOrder();
    error WrongTickUpperOrder();
    error WrongTickClaimedAt();
}

abstract contract CoverMiscErrors {
    // to be removed before production
    error NotImplementedYet();
}

abstract contract CoverPositionErrors {
    error NotEnoughPositionLiquidity();
    error InvalidClaimTick();
}

abstract contract CoverPoolFactoryErrors {
    error OwnerOnly();
    error PoolAlreadyExists();
    error FeeTierNotSupported();
    error SpreadTierNotSupported();
    error InvalidTickSpread();
    error TickSpreadNotMultipleOfTickSpacing();
    error TickSpreadNotAtLeastDoubleTickSpread();
}

abstract contract CoverTransferErrors {
    error TransferFailed(address from, address dest);
}
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "../../interfaces/lens/ILens.sol";
import "./LensBase.sol";
import "./PositionLens.sol";
import "./TickLens.sol";
import "./Quoter.sol";

contract Lens is ILens, LensBase, Quoter, PositionLens, TickLens {
    constructor(address _manager) LensBase(_manager) {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "./ILensBase.sol";
import "./IPositionLens.sol";
import "./ITickLens.sol";
import "./IQuoter.sol";

interface ILens is ILensBase, IQuoter, IPositionLens, ITickLens {}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "../../interfaces/manager/IPositionManager.sol";
import "../../interfaces/hub/IMuffinHubCombined.sol";
import "../../interfaces/lens/ILensBase.sol";

abstract contract LensBase is ILensBase {
    IPositionManager public immutable manager;
    IMuffinHubCombined public immutable hub;

    constructor(address _manager) {
        manager = IPositionManager(_manager);
        hub = IMuffinHubCombined(IPositionManager(_manager).hub());
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "../../interfaces/lens/IPositionLens.sol";
import "../../libraries/math/PoolMath.sol";
import "../../libraries/math/TickMath.sol";
import "./LensBase.sol";

/**
 * @dev This contract providers utility functions to help derive information for position.
 */
abstract contract PositionLens is IPositionLens, LensBase {
    // PositionInfo struct, defined in IPositionLens.sol.
    // ```
    // struct PositionInfo {
    //     address owner;
    //     address token0;
    //     address token1;
    //     uint8 tierId;
    //     int24 tickLower;
    //     int24 tickUpper;
    // }
    // ```

    /// @inheritdoc IPositionLens
    function getPosition(uint256 tokenId)
        public
        view
        returns (PositionInfo memory info, Positions.Position memory position)
    {
        (info.owner, info.token0, info.token1, info.tierId, info.tickLower, info.tickUpper, position) = manager
            .getPosition(tokenId);
    }

    /// @inheritdoc IPositionLens
    function getDerivedPosition(uint256 tokenId)
        external
        view
        returns (
            PositionInfo memory info,
            Positions.Position memory position,
            bool settled,
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        )
    {
        (info, position) = getPosition(tokenId);
        settled = isSettled(info, position);
        (amount0, amount1) = getUnderlyingAmounts(info, position, settled);
        (feeAmount0, feeAmount1) = getFeeAmounts(tokenId, info, position);
    }

    /// @inheritdoc IPositionLens
    function getFeeAmounts(
        uint256 tokenId,
        PositionInfo memory info,
        Positions.Position memory position
    ) public view returns (uint256 feeAmount0, uint256 feeAmount1) {
        (uint80 feeGrowthInside0, uint80 feeGrowthInside1) = hub.getPositionFeeGrowthInside(
            getPoolId(info.token0, info.token1),
            address(manager),
            tokenId,
            info.tierId,
            info.tickLower,
            info.tickUpper
        );
        unchecked {
            feeAmount0 = (uint256(position.liquidityD8) * (feeGrowthInside0 - position.feeGrowthInside0Last)) >> 56;
            feeAmount1 = (uint256(position.liquidityD8) * (feeGrowthInside1 - position.feeGrowthInside1Last)) >> 56;
            position.feeGrowthInside0Last = feeGrowthInside0;
            position.feeGrowthInside1Last = feeGrowthInside1;
        }
    }

    /// @inheritdoc IPositionLens
    function isSettled(PositionInfo memory info, Positions.Position memory position)
        public
        view
        returns (bool settled)
    {
        if (position.limitOrderType != Positions.NOT_LIMIT_ORDER) {
            bool zeroForOne = position.limitOrderType == Positions.ZERO_FOR_ONE;
            (, , uint32 nextSnapshotId) = hub.getSettlement(
                getPoolId(info.token0, info.token1),
                info.tierId,
                zeroForOne ? info.tickUpper : info.tickLower,
                zeroForOne
            );
            settled = position.settlementSnapshotId < nextSnapshotId;
        }
    }

    uint96 internal constant MAX_INT96 = uint96(type(int96).max);

    /// @inheritdoc IPositionLens
    function getUnderlyingAmounts(
        PositionInfo memory info,
        Positions.Position memory position,
        bool settled
    ) public view returns (uint256 amount0, uint256 amount1) {
        uint128 sqrtPriceLower = TickMath.tickToSqrtPrice(info.tickLower);
        uint128 sqrtPriceUpper = TickMath.tickToSqrtPrice(info.tickUpper);

        uint128 sqrtPrice = settled
            ? position.limitOrderType == Positions.ZERO_FOR_ONE ? sqrtPriceUpper : sqrtPriceLower
            : hub.getTier(getPoolId(info.token0, info.token1), info.tierId).sqrtPrice;

        uint96 remaining = position.liquidityD8;
        while (remaining > 0) {
            uint96 liquidityD8Step;
            (liquidityD8Step, remaining) = remaining > MAX_INT96 ? (MAX_INT96, remaining - MAX_INT96) : (remaining, 0);
            (uint256 amount0Step, uint256 amount1Step) = PoolMath.calcAmtsForLiquidity(
                sqrtPrice,
                sqrtPriceLower,
                sqrtPriceUpper,
                -int96(liquidityD8Step)
            );
            amount0 += amount0Step;
            amount1 += amount1Step;
        }
    }

    /// @inheritdoc IPositionLens
    function getPoolId(address token0, address token1) public pure returns (bytes32) {
        return keccak256(abi.encode(token0, token1));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "../../interfaces/lens/ITickLens.sol";
import "../../libraries/Ticks.sol";
import "./LensBase.sol";

abstract contract TickLens is ITickLens, LensBase {
    using Bytes32ArrayLib for Bytes32ArrayLib.Bytes32Array;

    /// @inheritdoc ITickLens
    function getTicks(
        bytes32 poolId,
        uint8 tierId,
        int24 tickStart,
        int24 tickEnd,
        uint24 maxCount
    ) external view returns (uint256 count, bytes memory ticks) {
        bool upwardDirection = tickEnd - tickStart >= 0;
        int24 tickIdx = tickStart;
        Bytes32ArrayLib.Bytes32Array memory arr;

        bytes32 tierTicksSlot = _getTierTicksSlot(poolId, tierId);

        while (arr.length < maxCount) {
            uint256 data = uint256(hub.getStorageAt(_getTickSlot(tierTicksSlot, tickIdx)));

            uint192 liquidityLowerAndUpperD8 = uint192(data & 0xffffffffffffffffffffffffffffffff); // (1 << 128) - 1)
            int24 nextBelow = int24(int256(data >> 192) & 0xffffff); // (1 << 24) - 1)
            int24 nextAbove = int24(int256(data >> 216) & 0xffffff); // (1 << 24) - 1)
            uint16 needSettle0And1 = uint16((data >> 240) & 0xffff); // (1 << 16) - 1)

            // for the first tick, check if it is initialized
            if (arr.length == 0 && liquidityLowerAndUpperD8 == 0) break;

            arr.push(bytes32(abi.encodePacked(
                tickIdx, //                     int24
                liquidityLowerAndUpperD8, //    uint96 + uint96
                needSettle0And1 //              bool + bool
            ))); // prettier-ignore

            int24 tickNext = upwardDirection ? int24(nextAbove) : int24(nextBelow);

            if (tickIdx == tickNext) break; // it only happens when it reaches end tick
            if (upwardDirection ? tickNext > tickEnd : tickNext < tickEnd) break;
            tickIdx = tickNext;
        }

        arr.end();
        ticks = arr.data;
        count = arr.length;
    }

    /// @dev Returns the slot of `pools[poolId].ticks[tierId]`, i.e. `mapping(uint256 => mapping(int24 => Ticks.Tick)))`
    function _getTierTicksSlot(bytes32 poolId, uint8 tierId) internal pure returns (bytes32 tierTicksSlot) {
        bytes32 poolSlot = keccak256(abi.encodePacked(poolId, uint256(4))); // slot 4 in hub contract
        bytes32 ticksSlot = bytes32(uint256(poolSlot) + 3); // offset 3 in pool struct
        tierTicksSlot = keccak256(abi.encodePacked(uint256(tierId), ticksSlot));
    }

    /// @dev Returns the slot of `pools[poolId].ticks[tierId][tickIdx]`, i.e. the first slot of a `Ticks.Tick`
    function _getTickSlot(bytes32 tierTicksSlot, int24 tickIdx) internal pure returns (bytes32 tickSlot) {
        // note that "int24 -> int256" is left-padded with 1 but not 0.
        tickSlot = keccak256(abi.encodePacked(uint256(int256(tickIdx)), tierTicksSlot));
    }
}

/**
 * For building in-memory dynamic-sized bytes32 array
 */
library Bytes32ArrayLib {
    uint256 internal constant CHUNK_SIZE = 100;

    struct Bytes32Array {
        bytes data;
        bytes32[CHUNK_SIZE] chunk;
        uint256 i;
        uint256 length;
    }

    function push(Bytes32Array memory self, bytes32 word) internal pure {
        self.chunk[self.i] = word;
        self.i++;
        self.length++;

        if (self.i == CHUNK_SIZE) {
            self.data = bytes.concat(self.data, abi.encodePacked(self.chunk));
            self.i = 0;
            delete self.chunk;
        }
    }

    function end(Bytes32Array memory self) internal pure {
        if (self.i != 0) {
            bytes32[] memory trimmed = new bytes32[](self.i);
            for (uint256 j; j < trimmed.length; j++) {
                trimmed[j] = self.chunk[j];
            }
            self.data = bytes.concat(self.data, abi.encodePacked(trimmed));
            self.i = 0;
            delete self.chunk;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "../../interfaces/lens/IQuoter.sol";
import "../../libraries/utils/PathLib.sol";
import "../../libraries/Pools.sol";
import "../../MuffinHub.sol";
import "./LensBase.sol";

/**
 * @dev There's two quoting methods available in this contract.
 * 1. Call "swap" in Hub contract, then throw an error to revert the swap.
 * 2. Fetch data from hub and simulate the swap in this contract.
 *
 * The former guarantees correctness and can estimate the gas cost of the swap.
 * The latter can generate a more detailed result, e.g. the input and output amounts for each tier.
 */
abstract contract Quoter is IQuoter, LensBase {
    using PathLib for bytes;

    /*===============================================================
     *                  QUOTE BY POPULATING ERROR
     *==============================================================*/

    function muffinSwapCallback(
        address,
        address,
        uint256 amountIn,
        uint256 amountOut,
        bytes calldata
    ) external pure {
        assembly {
            let ptr := mload(0x40) // free memory pointer
            mstore(add(ptr, 0), amountIn)
            mstore(add(ptr, 32), amountOut)
            revert(ptr, 64)
        }
    }

    function _parseRevertReason(bytes memory reason) internal pure returns (uint256 amountIn, uint256 amountOut) {
        if (reason.length == 64) return abi.decode(reason, (uint256, uint256));
        assembly {
            revert(add(32, reason), mload(reason))
        }
    }

    /// @inheritdoc IQuoter
    function quoteSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired
    )
        external
        returns (
            uint256 amountIn,
            uint256 amountOut,
            uint256 gasUsed
        )
    {
        uint256 gasBefore = gasleft();
        try hub.swap(tokenIn, tokenOut, tierChoices, amountDesired, address(this), 0, 0, new bytes(0)) {} catch (
            bytes memory reason
        ) {
            gasUsed = gasBefore - gasleft();
            (amountIn, amountOut) = _parseRevertReason(reason);
        }
    }

    /// @inheritdoc IQuoter
    function quote(bytes calldata path, int256 amountDesired)
        external
        returns (
            uint256 amountIn,
            uint256 amountOut,
            uint256 gasUsed
        )
    {
        uint256 gasBefore = gasleft();
        try
            hub.swapMultiHop(
                IMuffinHubActions.SwapMultiHopParams({
                    path: path,
                    amountDesired: amountDesired,
                    recipient: address(this),
                    recipientAccRefId: 0,
                    senderAccRefId: 0,
                    data: new bytes(0)
                })
            )
        {} catch (bytes memory reason) {
            gasUsed = gasBefore - gasleft();
            (amountIn, amountOut) = _parseRevertReason(reason);
        }
    }

    /*===============================================================
     *                   QUOTE BY SIMULATING SWAP
     *==============================================================*/

    // Hop struct, defined in IQuoter.sol.
    // ```
    // struct Hop {
    //     uint256 amountIn;
    //     uint256 amountOut;
    //     uint256 protocolFeeAmt;
    //     uint256[] tierAmountsIn;
    //     uint256[] tierAmountsOut;
    //     uint256[] tierData;
    // }
    // ```

    /// @inheritdoc IQuoter
    function simulateSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired
    ) external view returns (Hop memory hop) {
        bytes32 poolId = tokenIn < tokenOut
            ? keccak256(abi.encode(tokenIn, tokenOut))
            : keccak256(abi.encode(tokenOut, tokenIn));
        return _swap(poolId, (amountDesired > 0) == (tokenIn < tokenOut), amountDesired, tierChoices);
    }

    /// @inheritdoc IQuoter
    function simulate(bytes calldata path, int256 amountDesired)
        external
        view
        returns (
            uint256 amountIn,
            uint256 amountOut,
            Hop[] memory hops
        )
    {
        if (path.invalid()) revert MuffinHub.InvalidSwapPath();

        bool exactIn = amountDesired > 0;
        bytes32[] memory poolIds = new bytes32[](path.hopCount());
        hops = new Hop[](poolIds.length);

        unchecked {
            int256 amtDesired = amountDesired;
            for (uint256 i; i < poolIds.length; i++) {
                (address tokenIn, address tokenOut, uint256 tierChoices) = path.decodePool(i, exactIn);

                poolIds[i] = tokenIn < tokenOut
                    ? keccak256(abi.encode(tokenIn, tokenOut))
                    : keccak256(abi.encode(tokenOut, tokenIn));

                // For an "exact output" swap, it's possible to not receive the full desired output amount. therefore, in
                // the 2nd (and following) swaps, we request more token output so as to ensure we get enough tokens to pay
                // for the previous swa The extra token is not refunded and thus results in a very small extra cost.
                hops[i] = _swap(
                    poolIds[i],
                    (amtDesired > 0) == (tokenIn < tokenOut),
                    (exactIn || i == 0) ? amtDesired : amtDesired - Pools.SWAP_AMOUNT_TOLERANCE,
                    tierChoices
                );
                (uint256 amtIn, uint256 amtOut) = (hops[i].amountIn, hops[i].amountOut);

                if (exactIn) {
                    if (i == 0) amountIn = amtIn;
                    amtDesired = int256(amtOut);
                } else {
                    if (i == 0) amountOut = amtOut;
                    else if (amtOut < uint256(-amtDesired)) revert MuffinHub.NotEnoughIntermediateOutput();
                    amtDesired = -int256(amtIn);
                }
            }
            if (exactIn) {
                amountOut = uint256(amtDesired);
            } else {
                amountIn = uint256(-amtDesired);
            }
        }
        // emulate pool locks
        require(!QuickSort.sortAndHasDuplicate(poolIds), "POOL_REPEATED");
    }

    function _swap(
        bytes32 poolId,
        bool isToken0,
        int256 amtDesired,
        uint256 tierChoices
    ) internal view returns (Hop memory hop) {
        Tiers.Tier[] memory tiers;
        Pools.TierState[MAX_TIERS] memory states;

        unchecked {
            uint256 tiersCount = hub.getTiersCount(poolId);
            uint256 maxTierChoices = (1 << tiersCount) - 1;
            tierChoices &= maxTierChoices;

            if (amtDesired == 0 || amtDesired == SwapMath.REJECTED) revert Pools.InvalidAmount();
            if (tierChoices == 0) revert Pools.InvalidTierChoices();

            // only load tiers that are allowed by users
            if (tierChoices == maxTierChoices) {
                tiers = hub.getAllTiers(poolId);
            } else {
                tiers = new Tiers.Tier[](tiersCount);
                for (uint256 i; i < tiers.length; i++) {
                    if (tierChoices & (1 << i) != 0) tiers[i] = hub.getTier(poolId, uint8(i));
                }
            }
        }

        Pools.SwapCache memory cache = Pools.SwapCache({
            zeroForOne: isToken0 == (amtDesired > 0),
            exactIn: amtDesired > 0,
            protocolFee: 0,
            protocolFeeAmt: 0,
            tierChoices: tierChoices & ((1 << tiers.length) - 1),
            tmCache: TickMath.Cache({tick: type(int24).max, sqrtP: 0}),
            amounts: Pools._emptyInt256Array(),
            poolId: 0
        });
        (, cache.protocolFee) = hub.getPoolParameters(poolId);

        int256 initialAmtDesired = amtDesired;
        int256 amountA; // pool's balance change of the token which "amtDesired" refers to
        int256 amountB; // pool's balance change of the opposite token

        while (true) {
            // calculate the swap amount for each tier
            cache.amounts = amtDesired > 0
                ? SwapMath.calcTierAmtsIn(tiers, isToken0, amtDesired, tierChoices)
                : SwapMath.calcTierAmtsOut(tiers, isToken0, amtDesired, tierChoices);

            // compute the swap for each tier
            for (uint256 i; i < tiers.length; ) {
                (int256 amtAStep, int256 amtBStep) = _swapStep(poolId, isToken0, cache, states[i], tiers[i], i);
                amountA += amtAStep;
                amountB += amtBStep;
                unchecked {
                    i++;
                }
            }

            // check if we meet the stopping criteria
            amtDesired = initialAmtDesired - amountA;
            unchecked {
                if (
                    (cache.exactIn ? amtDesired <= Pools.SWAP_AMOUNT_TOLERANCE : amtDesired >= -Pools.SWAP_AMOUNT_TOLERANCE) ||
                    cache.tierChoices == 0
                ) break; // prettier-ignore
            }
        }

        hop.protocolFeeAmt = cache.protocolFeeAmt;
        (hop.tierAmountsIn, hop.tierAmountsOut, hop.tierData) = _computeTicksAndRelevantData(states, tiers);
        (hop.amountIn, hop.amountOut) = cache.exactIn
            ? (uint256(amountA), uint256(-amountB))
            : (uint256(amountB), uint256(-amountA));
    }

    function _swapStep(
        bytes32 poolId,
        bool isToken0,
        Pools.SwapCache memory cache,
        Pools.TierState memory state,
        Tiers.Tier memory tier,
        uint256 tierId
    ) internal view returns (int256 amtAStep, int256 amtBStep) {
        if (cache.amounts[tierId] == SwapMath.REJECTED) return (0, 0);

        // calculate sqrt price of the next tick
        if (state.sqrtPTick == 0)
            state.sqrtPTick = TickMath.tickToSqrtPriceMemoized(
                cache.tmCache,
                cache.zeroForOne ? tier.nextTickBelow : tier.nextTickAbove
            );

        unchecked {
            // calculate input & output amts, new sqrt price, and fee amt for this swap step
            uint256 feeAmtStep;
            (amtAStep, amtBStep, tier.sqrtPrice, feeAmtStep) = SwapMath.computeStep(
                isToken0,
                cache.exactIn,
                cache.amounts[tierId],
                tier.sqrtPrice,
                state.sqrtPTick,
                tier.liquidity,
                tier.sqrtGamma
            );
            if (amtAStep == SwapMath.REJECTED) return (0, 0);

            // cache input amount for later event logging (locally)
            if (cache.exactIn) {
                state.amountIn += uint256(amtAStep);
                state.amountOut += uint256(-amtBStep);
            } else {
                state.amountIn += uint256(amtBStep);
                state.amountOut += uint256(-amtAStep);
            }

            // update protocol fee amt (locally)
            uint256 protocolFeeAmt = (feeAmtStep * cache.protocolFee) / type(uint8).max;
            cache.protocolFeeAmt += protocolFeeAmt;
            feeAmtStep -= protocolFeeAmt;

            // update fee growth (locally) (realistically assume feeAmtStep < 2**192)
            uint80 feeGrowth = uint80((feeAmtStep << 64) / tier.liquidity);
            if (cache.zeroForOne) {
                tier.feeGrowthGlobal0 += feeGrowth;
            } else {
                tier.feeGrowthGlobal1 += feeGrowth;
            }
        }

        // handle cross tick, which updates a tick state
        if (tier.sqrtPrice == state.sqrtPTick) {
            int24 tickCross = cache.zeroForOne ? tier.nextTickBelow : tier.nextTickAbove;

            // skip crossing tick if reaches the end of the supported price range
            if (tickCross == TickMath.MIN_TICK || tickCross == TickMath.MAX_TICK) {
                cache.tierChoices &= ~(1 << tierId);
                return (amtAStep, amtBStep);
            }

            // clear cached tick price, so as to calculate a new one in next loop
            state.sqrtPTick = 0;
            state.crossed = true;

            // flip the direction of tick's data (effect)
            Ticks.Tick memory cross = hub.getTick(poolId, uint8(tierId), tickCross);
            // cross.flip(tier.feeGrowthGlobal0, tier.feeGrowthGlobal1, pool.secondsPerLiquidityCumulative);
            unchecked {
                // update tier's liquidity and next ticks (locally)
                (uint128 liqLowerD8, uint128 liqUpperD8) = (cross.liquidityLowerD8, cross.liquidityUpperD8);
                if (cache.zeroForOne) {
                    tier.liquidity = tier.liquidity + (liqUpperD8 << 8) - (liqLowerD8 << 8);
                    tier.nextTickBelow = cross.nextBelow;
                    tier.nextTickAbove = tickCross;
                } else {
                    tier.liquidity = tier.liquidity + (liqLowerD8 << 8) - (liqUpperD8 << 8);
                    tier.nextTickBelow = tickCross;
                    tier.nextTickAbove = cross.nextAbove;
                }
            }

            // // settle single-sided positions (i.e. filled limit orders) if neccessary
            // if (cache.zeroForOne ? cross.needSettle0 : cross.needSettle1)
            //     Settlement.settle(
            //         pool.settlements[tierId],
            //         pool.ticks[tierId],
            //         pool.tickMaps[tierId],
            //         tier,
            //         tickCross,
            //         cache.zeroForOne
            //     );
        }
    }

    function _computeTicksAndRelevantData(Pools.TierState[MAX_TIERS] memory states, Tiers.Tier[] memory tiers)
        internal
        pure
        returns (
            uint256[] memory tierAmountsIn,
            uint256[] memory tierAmountsOut,
            uint256[] memory tierData
        )
    {
        tierData = new uint256[](tiers.length);
        tierAmountsIn = new uint256[](tiers.length);
        tierAmountsOut = new uint256[](tiers.length);
        unchecked {
            for (uint8 i; i < tiers.length; i++) {
                Pools.TierState memory state = states[i];
                // we can safely assume tier data is unchanged when there's zero input amount and no crossing tick,
                // since we would have rejected the tier if such case happened.
                if (state.amountIn > 0 || state.crossed) {
                    Tiers.Tier memory tier = tiers[i];
                    // calculate current tick:
                    // if tier's price is equal to tick's price (let say the tick is T), the tier is expected to be in
                    // the upper tick space [T, T+1]. Only if the tier's next upper crossing tick is T, the tier is in
                    // the lower tick space [T-1, T].
                    tier.tick = TickMath.sqrtPriceToTick(tier.sqrtPrice);
                    if (tier.tick == tier.nextTickAbove) tier.tick--;

                    // pool.tiers[i] = tier;

                    // prepare data for logging
                    tierData[i] = (uint256(tier.sqrtPrice) << 128) | tier.liquidity;
                    tierAmountsIn[i] = state.amountIn;
                    tierAmountsOut[i] = state.amountOut;
                }
            }
        }
    }
}

/// @dev https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
library QuickSort {
    function sortAndHasDuplicate(bytes32[] memory data) internal pure returns (bool) {
        unchecked {
            sort(data);
            for (uint256 i = 1; i < data.length; i++) if (data[i - 1] == data[i]) return true;
            return false;
        }
    }

    function sort(bytes32[] memory data) internal pure {
        unchecked {
            require(data.length > 0);
            require(data.length <= uint256(type(int256).max));
            _quickSort(data, int256(0), int256(data.length - 1));
        }
    }

    function _quickSort(
        bytes32[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        unchecked {
            int256 i = left;
            int256 j = right;
            if (i == j) return;
            bytes32 pivot = arr[uint256(left + (right - left) / 2)];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) i++;
                while (pivot < arr[uint256(j)]) j--;
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    i++;
                    j--;
                }
            }
            if (left < j) _quickSort(arr, left, j);
            if (i < right) _quickSort(arr, i, right);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "../manager/IPositionManager.sol";
import "../hub/IMuffinHubCombined.sol";

interface ILensBase {
    function manager() external view returns (IPositionManager);

    function hub() external view returns (IMuffinHubCombined);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../libraries/Positions.sol";
import "./ILensBase.sol";

/**
 * @dev This contract providers utility functions to help derive information for position.
 */
interface IPositionLens is ILensBase {
    struct PositionInfo {
        address owner;
        address token0;
        address token1;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
    }

    /// @notice Return a position state by token id
    function getPosition(uint256 tokenId)
        external
        view
        returns (PositionInfo memory info, Positions.Position memory position);

    /// @notice Return a position state and additional information about the position
    function getDerivedPosition(uint256 tokenId)
        external
        view
        returns (
            PositionInfo memory info,
            Positions.Position memory position,
            bool settled,
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        );

    /// @notice Return the position currently collectable fee amounts
    function getFeeAmounts(
        uint256 tokenId,
        PositionInfo memory info,
        Positions.Position memory position
    ) external view returns (uint256 feeAmount0, uint256 feeAmount1);

    /// @notice Return whether position is already settled
    function isSettled(PositionInfo memory info, Positions.Position memory position)
        external
        view
        returns (bool settled);

    /// @notice Return the position's underlying token amounts
    function getUnderlyingAmounts(
        PositionInfo memory info,
        Positions.Position memory position,
        bool settled
    ) external view returns (uint256 amount0, uint256 amount1);

    /// @notice Return pool id
    function getPoolId(address token0, address token1) external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ILensBase.sol";

interface ITickLens is ILensBase {
    /**
     * @notice Get ticks of a tier.
     * @param poolId    Pool id
     * @param tierId    Tier id
     * @param tickStart First tick to get. This tick must be initialized.
     * @param tickEnd   Ticks beyond "tickEnd" is not included in the return data. Can be uninitialized.
     * @param maxCount  Max number of ticks to retrieve
     * @return count    Number of ticks retrieved
     * @return ticks    List of ticks concatenated into bytes.
     * Each tick consists of 256 bits:
     * - int24  tickIdx
     * - uint96 liquidityLowerD8
     * - uint96 liquidityUpperD8
     * - bool   needSettle0
     * - bool   needSettle1
     * To parse it in ether.js, see the example https://github.com/muffinfi/muffin/blob/master/test/lens/03_tick_lens.ts#L11
     *
     * @dev Estimated gas costs:
     * - 1 tick:     33659 gas
     * - 10 ticks:   74157 gas
     * - 100 ticks:  476268 gas
     * - 1000 ticks: 5045298 gas
     * - 2000 ticks: 12886983 gas
     */
    function getTicks(
        bytes32 poolId,
        uint8 tierId,
        int24 tickStart,
        int24 tickEnd,
        uint24 maxCount
    ) external view returns (uint256 count, bytes memory ticks);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ILensBase.sol";

/**
 * @dev There's two quoting methods available in this contract.
 * 1. Call "swap" in Hub contract, then throw an error to revert the swap.
 * 2. Fetch data from hub and simulate the swap in this contract.
 *
 * The former guarantees correctness and can estimate the gas cost of the swap.
 * The latter can generate a more detailed result, e.g. the input and output amounts for each tier.
 */
interface IQuoter is ILensBase {
    /// @notice Quote a single-hop swap
    function quoteSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired
    )
        external
        returns (
            uint256 amountIn,
            uint256 amountOut,
            uint256 gasUsed
        );

    /// @notice Quote a swap
    function quote(bytes calldata path, int256 amountDesired)
        external
        returns (
            uint256 amountIn,
            uint256 amountOut,
            uint256 gasUsed
        );

    /// @notice Simulation result of a hop
    struct Hop {
        uint256 amountIn;
        uint256 amountOut;
        uint256 protocolFeeAmt;
        uint256[] tierAmountsIn;
        uint256[] tierAmountsOut;
        uint256[] tierData;
    }

    /// @notice Simulate a single-hop swap
    function simulateSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired
    ) external view returns (Hop memory hop);

    /// @notice Simulate a swap
    function simulate(bytes calldata path, int256 amountDesired)
        external
        view
        returns (
            uint256 amountIn,
            uint256 amountOut,
            Hop[] memory hops
        );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../libraries/Positions.sol";
import "./IManagerBase.sol";
import "./IERC721Extended.sol";

interface IPositionManager is IERC721Extended, IManagerBase {
    /// @notice Mapping of token id to position managed by this contract
    function positionsByTokenId(uint256 tokenId)
        external
        view
        returns (
            address owner,
            uint40 pairId,
            uint8 tierId,
            int24 tickLower,
            int24 tickUpper
        );

    /// @notice Mapping of pair id to its underlying tokens
    function pairs(uint40 pairId) external view returns (address token0, address token1);

    /// @notice Mapping of pool id to pair id
    function pairIdsByPoolId(bytes32 poolId) external view returns (uint40 pairId);

    /// @notice             Create a pool for token0 and token1 if it hasn't been created
    /// @dev                DO NOT create pool with rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param token0       Address of token0 of the pool
    /// @param token1       Address of token1 of the pool
    /// @param sqrtGamma    Sqrt of (1 - percentage swap fee of the 1st tier)
    /// @param sqrtPrice    Sqrt price of token0 denominated in token1
    function createPool(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint128 sqrtPrice,
        bool useAccount
    ) external payable;

    /// @notice             Add a tier to a pool
    /// @dev                This function is subject to sandwitch attack which costs more tokens to add a tier, but the extra cost
    ///                     should be small in common token pairs. Also, users can multicall with "mint" to do slippage check.
    /// @param token0       Address of token0 of the pool
    /// @param token1       Address of token1 of the pool
    /// @param sqrtGamma    Sqrt of (1 - percentage swap fee of the 1st tier)
    /// @param expectedTierId Expected id of the new tier. Revert if unmatched. Set to type(uint8).max for skipping the check.
    function addTier(
        address token0,
        address token1,
        uint24 sqrtGamma,
        bool useAccount,
        uint8 expectedTierId
    ) external payable;

    /// @dev Called by hub contract
    function muffinMintCallback(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /**
     * @notice                  Parameters for the mint function
     * @param token0            Address of token0 of the pool
     * @param token1            Address of token1 of the pool
     * @param tierId            Position's tier index
     * @param tickLower         Position's lower tick boundary
     * @param tickUpper         Position's upper tick boundary
     * @param amount0Desired    Desired token0 amount to add to the pool
     * @param amount1Desired    Desired token1 amount to add to the pool
     * @param amount0Min        Minimum token0 amount
     * @param amount1Min        Minimum token1 amount
     * @param recipient         Recipient of the position token
     * @param useAccount        Use sender's internal account to pay
     */
    struct MintParams {
        address token0;
        address token1;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        bool useAccount;
    }

    /**
     * @notice              Mint a position NFT
     * @param params        MintParams struct
     * @return tokenId      Id of the NFT
     * @return liquidityD8  Amount of liquidity added (divided by 2^8)
     * @return amount0      Token0 amount paid
     * @return amount1      Token1 amount paid
     */
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint96 liquidityD8,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @notice                  Parameters for the addLiquidity function
     * @param tokenId           Id of the position NFT
     * @param amount0Desired    Desired token0 amount to add to the pool
     * @param amount1Desired    Desired token1 amount to add to the pool
     * @param amount0Min        Minimum token0 amount
     * @param amount1Min        Minimum token1 amount
     * @param useAccount        Use sender's internal account to pay
     */
    struct AddLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        bool useAccount;
    }

    /**
     * @notice              Add liquidity to an existing position
     * @param params        AddLiquidityParams struct
     * @return liquidityD8  Amount of liquidity added (divided by 2^8)
     * @return amount0      Token0 amount paid
     * @return amount1      Token1 amount paid
     */
    function addLiquidity(AddLiquidityParams calldata params)
        external
        payable
        returns (
            uint96 liquidityD8,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @notice                  Parameters for the removeLiquidity function
     * @param tokenId           Id of the position NFT
     * @param liquidityD8       Amount of liquidity to remove (divided by 2^8)
     * @param amount0Min        Minimum token0 amount received from the removed liquidity
     * @param amount1Min        Minimum token1 amount received from the removed liquidity
     * @param withdrawTo        Recipient of the withdrawn tokens. Set to zero for no withdrawal
     * @param collectAllFees    True to collect all remaining accrued fees in the position
     * @param settled           True if the position is settled
     */
    struct RemoveLiquidityParams {
        uint256 tokenId;
        uint96 liquidityD8;
        uint256 amount0Min;
        uint256 amount1Min;
        address withdrawTo;
        bool collectAllFees;
        bool settled;
    }

    /**
     * @notice              Remove liquidity from a position
     * @param params        RemoveLiquidityParams struct
     * @return amount0      Token0 amount from the removed liquidity
     * @return amount1      Token1 amount from the removed liquidity
     * @return feeAmount0   Token0 fee collected from the position
     * @return feeAmount1   Token1 fee collected from the position
     */
    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        payable
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        );

    /// @notice                 Set position's limit order type
    /// @param tokenId          Id of the position NFT. Or set to zero to indicate the latest NFT id in this contract
    ///                         (useful for chaining this function after `mint` in a multicall)
    /// @param limitOrderType   Direction of limit order (0: N/A, 1: zero->one, 2: one->zero)
    function setLimitOrderType(uint256 tokenId, uint8 limitOrderType) external payable;

    /// @notice             Burn NFTs of empty positions
    /// @param tokenIds     Array of NFT id
    function burn(uint256[] calldata tokenIds) external payable;

    /// @notice             Get the position info of an NFT
    /// @param tokenId      Id of the NFT
    function getPosition(uint256 tokenId)
        external
        view
        returns (
            address owner,
            address token0,
            address token1,
            uint8 tierId,
            int24 tickLower,
            int24 tickUpper,
            Positions.Position memory position
        );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./positions/IMuffinHubPositions.sol";
import "./IMuffinHub.sol";

/// @notice Muffin hub interface, combining both primary and secondary contract
interface IMuffinHubCombined is IMuffinHub, IMuffinHubPositions {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./math/Math.sol";

library Positions {
    struct Position {
        uint96 liquidityD8;
        uint80 feeGrowthInside0Last; // UQ16.64
        uint80 feeGrowthInside1Last; // UQ16.64
        uint8 limitOrderType;
        uint32 settlementSnapshotId;
    }

    // Limit order types:
    uint8 internal constant NOT_LIMIT_ORDER = 0;
    uint8 internal constant ZERO_FOR_ONE = 1;
    uint8 internal constant ONE_FOR_ZERO = 2;

    /**
     * @param positions Mapping of positions
     * @param owner     Position owner's address
     * @param refId     Arbitrary identifier set by the position owner
     * @param tierId    Index of the tier which the position is in
     * @param tickLower Lower tick boundary of the position
     * @param tickUpper Upper tick boundary of the position
     * @return position The position object
     */
    function get(
        mapping(bytes32 => Position) storage positions,
        address owner,
        uint256 refId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (Position storage position) {
        position = positions[keccak256(abi.encodePacked(owner, tierId, tickLower, tickUpper, refId))];
    }

    /**
     * @notice Update position's liquidity and accrue fees
     * @dev When adding liquidity, feeGrowthInside{0,1} are updated so as to accrue fees without the need to transfer
     * them to owner's account. When removing partial liquidity, feeGrowthInside{0,1} are unchanged and partial fees are
     * transferred to owner's account proportionally to amount of liquidity removed.
     *
     * @param liquidityDeltaD8  Amount of liquidity change in the position, scaled down 2^8
     * @param feeGrowthInside0  Pool's current accumulated fee0 per unit of liquidity inside the position's price range
     * @param feeGrowthInside1  Pool's current accumulated fee1 per unit of liquidity inside the position's price range
     * @param collectAllFees    True to collect the position's all accrued fees
     * @return feeAmtOut0       Amount of fee0 to transfer to owner account (≤ 2^(128+80))
     * @return feeAmtOut1       Amount of fee1 to transfer to owner account (≤ 2^(128+80))
     */
    function update(
        Position storage self,
        int96 liquidityDeltaD8,
        uint80 feeGrowthInside0,
        uint80 feeGrowthInside1,
        bool collectAllFees
    ) internal returns (uint256 feeAmtOut0, uint256 feeAmtOut1) {
        unchecked {
            uint96 liquidityD8 = self.liquidityD8;
            uint96 liquidityD8New = Math.addInt96(liquidityD8, liquidityDeltaD8);
            uint80 feeGrowthDelta0 = feeGrowthInside0 - self.feeGrowthInside0Last;
            uint80 feeGrowthDelta1 = feeGrowthInside1 - self.feeGrowthInside1Last;

            self.liquidityD8 = liquidityD8New;

            if (collectAllFees) {
                feeAmtOut0 = (uint256(liquidityD8) * feeGrowthDelta0) >> 56;
                feeAmtOut1 = (uint256(liquidityD8) * feeGrowthDelta1) >> 56;
                self.feeGrowthInside0Last = feeGrowthInside0;
                self.feeGrowthInside1Last = feeGrowthInside1;
                //
            } else if (liquidityDeltaD8 > 0) {
                self.feeGrowthInside0Last =
                    feeGrowthInside0 -
                    uint80((uint256(liquidityD8) * feeGrowthDelta0) / liquidityD8New);
                self.feeGrowthInside1Last =
                    feeGrowthInside1 -
                    uint80((uint256(liquidityD8) * feeGrowthDelta1) / liquidityD8New);
                //
            } else if (liquidityDeltaD8 < 0) {
                feeAmtOut0 = (uint256(uint96(-liquidityDeltaD8)) * feeGrowthDelta0) >> 56;
                feeAmtOut1 = (uint256(uint96(-liquidityDeltaD8)) * feeGrowthDelta1) >> 56;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IManagerBase {
    function WETH9() external view returns (address);

    function hub() external view returns (address);

    function muffinDepositCallback(
        address token,
        uint256 amount,
        bytes calldata data
    ) external;

    /// @notice             Deposit tokens into hub's internal account
    /// @dev                DO NOT deposit rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param recipient    Recipient of the token deposit
    /// @param token        Token address
    /// @param amount       Amount to deposit
    function deposit(
        address recipient,
        address token,
        uint256 amount
    ) external payable;

    /// @notice             Withdraw tokens from hub's internal account to recipient
    /// @param recipient    Recipient of the withdrawn token
    /// @param token        Token address
    /// @param amount       Amount to withdraw
    function withdraw(
        address recipient,
        address token,
        uint256 amount
    ) external payable;

    /// @notice             Deposit tokens into hub's internal account managed by other address
    /// @dev                DO NOT deposit rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param recipient    Recipient of the token deposit
    /// @param token        Token address
    /// @param amount       Amount to deposit
    function depositToExternal(
        address recipient,
        uint256 recipientAccRefId,
        address token,
        uint256 amount
    ) external payable;

    /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH from users.
    /// @dev This function should be an intermediate function of an atomic transaction. Do not leave WETH inside this
    /// contract accross transactions.
    function unwrapWETH(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    /// @dev This function should be an intermediate function of an atomic transaction. Do not leave ETH inside this
    /// contract accross transactions.
    function refundETH() external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC721Extended is IERC165, IERC721, IERC721Metadata {
    function tokenDescriptor() external view returns (address);

    function tokenDescriptorSetter() external view returns (address);

    function totalSupply() external view returns (uint256);

    function latestTokenId() external view returns (uint256);

    function nonces(uint256 tokenId) external view returns (uint256 nonce);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library Math {
    /// @dev Compute z = x + y, where z must be non-negative and fit in a 96-bit unsigned integer
    function addInt96(uint96 x, int96 y) internal pure returns (uint96 z) {
        unchecked {
            uint256 s = x + uint256(int256(y)); // overflow is fine here
            assert(s <= type(uint96).max);
            z = uint96(s);
        }
    }

    /// @dev Compute z = x + y, where z must be non-negative and fit in a 128-bit unsigned integer
    function addInt128(uint128 x, int128 y) internal pure returns (uint128 z) {
        unchecked {
            uint256 s = x + uint256(int256(y)); // overflow is fine here
            assert(s <= type(uint128).max);
            z = uint128(s);
        }
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    /// @dev Subtract an amount from x until the amount reaches y or all x is subtracted (i.e. the result reches zero).
    /// Return the subtraction result and the remaining amount to subtract (if there's any)
    function subUntilZero(uint256 x, uint256 y) internal pure returns (uint256 z, uint256 r) {
        unchecked {
            if (x >= y) z = x - y;
            else r = y - x;
        }
    }

    // ----- cast -----

    function toUint128(uint256 x) internal pure returns (uint128 z) {
        assert(x <= type(uint128).max);
        z = uint128(x);
    }

    function toUint96(uint256 x) internal pure returns (uint96 z) {
        assert(x <= type(uint96).max);
        z = uint96(x);
    }

    function toInt256(uint256 x) internal pure returns (int256 z) {
        assert(x <= uint256(type(int256).max));
        z = int256(x);
    }

    function toInt96(uint96 x) internal pure returns (int96 z) {
        assert(x <= uint96(type(int96).max));
        z = int96(x);
    }

    // ----- checked arithmetic -----
    // (these functions are for using checked arithmetic in an unchecked scope)

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        z = x - y;
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../IMuffinHubBase.sol";
import "../IMuffinHubEvents.sol";
import "./IMuffinHubPositionsActions.sol";
import "./IMuffinHubPositionsView.sol";

interface IMuffinHubPositions is
    IMuffinHubBase,
    IMuffinHubEvents,
    IMuffinHubPositionsActions,
    IMuffinHubPositionsView
{}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IMuffinHubBase.sol";
import "./IMuffinHubEvents.sol";
import "./IMuffinHubActions.sol";
import "./IMuffinHubView.sol";

interface IMuffinHub is IMuffinHubBase, IMuffinHubEvents, IMuffinHubActions, IMuffinHubView {}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IMuffinHubBase {
    /// @notice Get the contract governance address
    function governance() external view returns (address);

    /// @notice         Get token balance of a user's internal account
    /// @param token    Token address
    /// @param accHash  keccek256 hash of (owner, accRefId), where accRefId is an arbitrary reference id from account owner
    /// @return balance Token balance in the account
    function accounts(address token, bytes32 accHash) external view returns (uint256 balance);

    /// @notice         Get token's reentrancy lock and accrued protocol fees
    /// @param token    Token address
    /// @return locked  1 if token is locked, otherwise unlocked
    /// @return protocolFeeAmt Amount of token accrued as protocol fee
    function tokens(address token) external view returns (uint8 locked, uint248 protocolFeeAmt);

    /// @notice         Get the addresses of the underlying tokens of a pool
    /// @param poolId   Pool id, i.e. keccek256 hash of (token0, token1)
    /// @return token0  Address of the pool's token0
    /// @return token1  Address of the pool's token1
    function underlyings(bytes32 poolId) external view returns (address token0, address token1);

    /// @notice Maximum number of tiers each pool can technically have. This number might vary in different networks.
    function maxNumOfTiers() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IMuffinHubEvents {
    /// @notice Emitted when user deposits tokens to an account
    event Deposit(
        address indexed recipient,
        uint256 indexed recipientAccRefId,
        address indexed token,
        uint256 amount,
        address sender
    );

    /// @notice Emitted when user withdraws tokens from an account
    event Withdraw(
        address indexed sender,
        uint256 indexed senderAccRefId,
        address indexed token,
        uint256 amount,
        address recipient
    );

    /// @notice Emitted when a pool is created
    event PoolCreated(address indexed token0, address indexed token1, bytes32 indexed poolId);

    /// @notice Emitted when a new tier is added, or when tier's parameters are updated
    event UpdateTier(
        bytes32 indexed poolId,
        uint8 indexed tierId,
        uint24 indexed sqrtGamma,
        uint128 sqrtPrice,
        uint8 limitOrderTickSpacingMultiplier
    );

    /// @notice Emitted when a pool's tick spacing or protocol fee is updated
    event UpdatePool(bytes32 indexed poolId, uint8 tickSpacing, uint8 protocolFee);

    /// @notice Emitted when protocol fee is collected
    event CollectProtocol(address indexed recipient, address indexed token, uint256 amount);

    /// @notice Emitted when governance address is updated
    event GovernanceUpdated(address indexed governance);

    /// @notice Emitted when default parameters are updated
    event UpdateDefaultParameters(uint8 tickSpacing, uint8 protocolFee);

    /// @notice Emitted when liquidity is minted for a given position
    event Mint(
        bytes32 indexed poolId,
        address indexed owner,
        uint256 indexed positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        address sender,
        uint256 senderAccRefId,
        uint96 liquidityD8,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when a position's liquidity is removed and collected
    /// @param amount0 Token0 amount from the burned liquidity
    /// @param amount1 Token1 amount from the burned liquidity
    /// @param feeAmount0 Token0 fee collected from the position
    /// @param feeAmount0 Token1 fee collected from the position
    event Burn(
        bytes32 indexed poolId,
        address indexed owner,
        uint256 indexed positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint256 ownerAccRefId,
        uint96 liquidityD8,
        uint256 amount0,
        uint256 amount1,
        uint256 feeAmount0,
        uint256 feeAmount1
    );

    /// @notice Emitted when limit order settlement occurs during a swap
    /// @dev when tickEnd < tickStart, it means the tier crossed from a higher tick to a lower tick, and the settled
    /// limit orders were selling token1 for token0, vice versa.
    event Settle(
        bytes32 indexed poolId,
        uint8 indexed tierId,
        int24 indexed tickEnd,
        int24 tickStart,
        uint96 liquidityD8
    );

    /// @notice Emitted when a settled position's liquidity is collected
    event CollectSettled(
        bytes32 indexed poolId,
        address indexed owner,
        uint256 indexed positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint256 ownerAccRefId,
        uint96 liquidityD8,
        uint256 amount0,
        uint256 amount1,
        uint256 feeAmount0,
        uint256 feeAmount1
    );

    /// @notice Emitted when a position's limit order type is updated
    event SetLimitOrderType(
        bytes32 indexed poolId,
        address indexed owner,
        uint256 indexed positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint8 limitOrderType
    );

    /// @notice Emitted for any swap happened in any pool
    /// @param amountInDistribution Percentages of input token amount routed to each tier. Each value occupies FLOOR(256/MAX_TIERS)
    /// bits and is a binary fixed-point with 1 integer bit and FLOOR(256/MAX_TIERS)-1 fraction bits.
    /// @param amountOutDistribution Percentages of output token amount routed to each tier. Same format as "amountInDistribution".
    /// @param tierData Array of tier's liquidity (0-127th bits) and sqrt price (128-255th bits) after the swap
    event Swap(
        bytes32 indexed poolId,
        address indexed sender,
        address indexed recipient,
        uint256 senderAccRefId,
        uint256 recipientAccRefId,
        int256 amount0,
        int256 amount1,
        uint256 amountInDistribution,
        uint256 amountOutDistribution,
        uint256[] tierData
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IMuffinHubPositionsActions {
    /// @notice                 Parameters for the mint function
    /// @param token0           Address of token0 of the pool
    /// @param token1           Address of token1 of the pool
    /// @param tierId           Position's tier index
    /// @param tickLower        Position's lower tick boundary
    /// @param tickUpper        Position's upper tick boundary
    /// @param liquidityD8      Amount of liquidity to mint, divided by 2^8
    /// @param recipient        Recipient's address
    /// @param positionRefId    Arbitrary reference id for the position
    /// @param senderAccRefId   Sender's account id
    /// @param data             Arbitrary data that is passed to callback function
    struct MintParams {
        address token0;
        address token1;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
        uint96 liquidityD8;
        address recipient;
        uint256 positionRefId;
        uint256 senderAccRefId;
        bytes data;
    }

    /// @notice                 Mint liquidity to a position
    /// @param params           MintParams struct
    /// @return amount0         Token0 amount to pay by the sender
    /// @return amount1         Token1 amount to pay by the sender
    function mint(MintParams calldata params) external returns (uint256 amount0, uint256 amount1);

    /// @notice                 Parameters for the burn function
    /// @param token0           Address of token0 of the pool
    /// @param token1           Address of token1 of the pool
    /// @param tierId           Tier index of the position
    /// @param tickLower        Lower tick boundary of the position
    /// @param tickUpper        Upper tick boundary of the position
    /// @param liquidityD8      Amount of liquidity to burn, divided by 2^8
    /// @param positionRefId    Arbitrary reference id for the position
    /// @param accRefId         Position owner's account id for receiving tokens
    /// @param collectAllFees   True to collect all accrued fees of the position
    struct BurnParams {
        address token0;
        address token1;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
        uint96 liquidityD8;
        uint256 positionRefId;
        uint256 accRefId;
        bool collectAllFees;
    }

    /// @notice                 Remove liquidity from a position
    /// @dev                    When removing partial liquidity and params.collectAllFees is set to false, partial fees
    ///                         are sent to position owner's account proportionally to the amount of liquidity removed.
    /// @param params           BurnParams struct
    /// @return amount0         Amount of token0 sent to the position owner account
    /// @return amount1         Amount of token1 sent to the position owner account
    /// @return feeAmount0      Amount of token0 fee sent to the position owner account
    /// @return feeAmount1      Amount of token1 fee sent to the position owner account
    function burn(BurnParams calldata params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        );

    /// @notice                 Collect underlying tokens from a settled position
    /// @param params           BurnParams struct
    /// @return amount0         Amount of token0 sent to the position owner account
    /// @return amount1         Amount of token1 sent to the position owner account
    /// @return feeAmount0      Amount of token0 fee sent to the position owner account
    /// @return feeAmount1      Amount of token1 fee sent to the position owner account
    function collectSettled(BurnParams calldata params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        );

    /// @notice                 Set a position's type, e.g. set to limit order
    /// @param token0           Address of token0 of the pool
    /// @param token1           Address of token1 of the pool
    /// @param tierId           Tier index of the position
    /// @param tickLower        Lower tick boundary of the position
    /// @param tickUpper        Upper tick boundary of the position
    /// @param positionRefId    Arbitrary reference id for the position
    /// @param limitOrderType   Direction of limit order (0: N/A; 1: zero for one; 2: one for zero)
    function setLimitOrderType(
        address token0,
        address token1,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint256 positionRefId,
        uint8 limitOrderType
    ) external;

    /*===============================================================
     *                         GOVERNANCE
     *==============================================================*/

    /// @notice Update the governance address
    function setGovernance(address _governance) external;

    /// @notice Update pool's default tick spacing and protocol fee
    /// @param protocolFee Numerator of the % protocol fee (denominator is 255)
    function setDefaultParameters(uint8 tickSpacing, uint8 protocolFee) external;

    /// @notice Update pool's tick spacing and protocol fee
    /// @dev If setting a new tick spacing, the already initialized ticks that are not multiples of the new tick spacing
    /// will become unable to be added liquidity. To prevent this UX issue, the new tick spacing should better be a
    /// divisor of the old tick spacing.
    function setPoolParameters(
        bytes32 poolId,
        uint8 tickSpacing,
        uint8 protocolFee
    ) external;

    /// @notice Update a tier's swap fee and its tick spacing multiplier for limt orders
    function setTierParameters(
        bytes32 poolId,
        uint8 tierId,
        uint24 sqrtGamma,
        uint8 limitOrderTickSpacingMultiplier
    ) external;

    /// @notice Update the whitelist of swap fees which LPs can choose to create a pool
    function setDefaultAllowedSqrtGammas(uint24[] calldata sqrtGammas) external;

    /// @notice Update the pool-specific whitelist of swap fees
    function setPoolAllowedSqrtGammas(bytes32 poolId, uint24[] calldata sqrtGammas) external;

    /// @notice Update the pool-specific default tick spacing
    /// @param tickSpacing Tick spacing. Set to zero to unset the default.
    function setPoolDefaultTickSpacing(bytes32 poolId, uint8 tickSpacing) external;

    /// @notice Collect the protocol fee accrued
    function collectProtocolFee(address token, address recipient) external returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../../libraries/Settlement.sol";
import "../../../libraries/Tiers.sol";

interface IMuffinHubPositionsView {
    /// @notice Return pool's default allowed fee rates
    /// @return sqrtGammas  List of fee rate, expressed in sqrt(1 - %fee) (precision: 1e5)
    function getDefaultAllowedSqrtGammas() external view returns (uint24[] memory sqrtGammas);

    /// @notice Return the pool's allowed fee rates
    /// @param poolId       Pool id
    /// @return sqrtGammas  List of fee rate, expressed in sqrt(1 - %fee) (precision: 1e5)
    function getPoolAllowedSqrtGammas(bytes32 poolId) external view returns (uint24[] memory sqrtGammas);

    /// @notice Return the pool's default tick spacing. If set, it overrides the global default tick spacing.
    /// @param poolId       Pool id
    /// @return tickSpacing Tick spacing. Zero means it is not set.
    function getPoolDefaultTickSpacing(bytes32 poolId) external view returns (uint8 tickSpacing);

    /// @notice Return the states of all the tiers in the given pool
    function getAllTiers(bytes32 poolId) external view returns (Tiers.Tier[] memory tiers);

    /// @notice Return the current fee-per-liquidity accumulator in the position's range.
    /// If the position was a limit order and already settled, return the values at when the position was settled.
    /// @return feeGrowthInside0 Accumulated token0 fee per liquidity since the creation of the pool
    /// @return feeGrowthInside1 Accumulated token1 fee per liquidity since the creation of the pool
    function getPositionFeeGrowthInside(
        bytes32 poolId,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint80 feeGrowthInside0, uint80 feeGrowthInside1);

    /// @notice Return the state of a settlement
    /// @param poolId           Pool id
    /// @param tierId           Tier Index
    /// @param tick             Tick number at which the settlement occurs
    /// @param zeroForOne       Direction of the limit orders that the settlement handles
    /// @return liquidityD8     Amount of liquidity pending to settle
    /// @return tickSpacing     Width of the limit orders which the settlement will settle
    /// @return nextSnapshotId  Next data snapshot id that will be used
    function getSettlement(
        bytes32 poolId,
        uint8 tierId,
        int24 tick,
        bool zeroForOne
    )
        external
        view
        returns (
            uint96 liquidityD8,
            uint16 tickSpacing,
            uint32 nextSnapshotId
        );

    /// @notice Return a data snapshot of a settlement
    /// @param poolId       Pool id
    /// @param tierId       Tier Index
    /// @param tick         Tick number at which the settlement occurs
    /// @param zeroForOne   Direction of the limit orders that the settlement handles
    /// @param snapshotId   Snapshot id of your desired snapshot of this settlement
    function getSettlementSnapshot(
        bytes32 poolId,
        uint8 tierId,
        int24 tick,
        bool zeroForOne,
        uint32 snapshotId
    ) external view returns (Settlement.Snapshot memory snapshot);

    /// @notice Return the tick spacing multipliers for limit orders in the given pool's tiers,
    /// i.e. the list of required width of the limit range orders on each tier,
    /// e.g. 1 means "pool.tickSpacing * 1", 0 means disabled.
    function getLimitOrderTickSpacingMultipliers(bytes32 poolId)
        external
        view
        returns (uint8[] memory tickSpacingMultipliers);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./math/TickMath.sol";
import "./Tiers.sol";
import "./Ticks.sol";
import "./TickMaps.sol";
import "./Positions.sol";

library Settlement {
    using TickMaps for TickMaps.TickMap;

    /**
     * @notice                  Data for settling single-sided positions (i.e. filled limit orders)
     * @param liquidityD8       Amount of liquidity to remove
     * @param tickSpacing       Tick spacing of the limit orders
     * @param nextSnapshotId    Next data snapshot id
     * @param snapshots         Array of data snapshots
     */
    struct Info {
        uint96 liquidityD8;
        uint16 tickSpacing;
        uint32 nextSnapshotId;
        mapping(uint32 => Snapshot) snapshots;
    }

    /// @notice Data snapshot when settling the positions
    struct Snapshot {
        uint80 feeGrowthInside0;
        uint80 feeGrowthInside1;
    }

    /**
     * @notice Update the amount of liquidity pending to be settled on a tick, given the lower and upper tick
     * boundaries of a limit-order position.
     * @param settlements       Mapping of settlements of each tick
     * @param ticks             Mapping of ticks of the tier which the position is in
     * @param tickLower         Lower tick boundary of the position
     * @param tickUpper         Upper tick boundary of the position
     * @param limitOrderType    Direction of the limit order (i.e. token0 or token1)
     * @param liquidityDeltaD8  Change of the amount of liquidity to be settled
     * @param isAdd             True if the liquidity change is additive. False otherwise.
     * @param defaultTickSpacing Default tick spacing of limit orders. Only needed when initializing
     * @return nextSnapshotId   Settlement's next snapshot id
     * @return tickSpacing      Tick spacing of the limit orders pending to be settled
     */
    function update(
        mapping(int24 => Info[2]) storage settlements,
        mapping(int24 => Ticks.Tick) storage ticks,
        int24 tickLower,
        int24 tickUpper,
        uint8 limitOrderType,
        uint96 liquidityDeltaD8,
        bool isAdd,
        uint16 defaultTickSpacing
    ) internal returns (uint32 nextSnapshotId, uint16 tickSpacing) {
        assert(limitOrderType == Positions.ZERO_FOR_ONE || limitOrderType == Positions.ONE_FOR_ZERO);

        Info storage settlement = limitOrderType == Positions.ZERO_FOR_ONE
            ? settlements[tickUpper][1]
            : settlements[tickLower][0];

        // update the amount of liquidity to settle
        settlement.liquidityD8 = isAdd
            ? settlement.liquidityD8 + liquidityDeltaD8
            : settlement.liquidityD8 - liquidityDeltaD8;

        // initialize settlement if it's the first limit order at this tick
        nextSnapshotId = settlement.nextSnapshotId;
        if (settlement.tickSpacing == 0) {
            settlement.tickSpacing = defaultTickSpacing;
            settlement.snapshots[nextSnapshotId] = Snapshot(0, 1); // pre-fill to reduce SSTORE gas during swap
        }

        // if no liqudity to settle, clear tick spacing so as to set a latest one next time
        bool isEmpty = settlement.liquidityD8 == 0;
        if (isEmpty) settlement.tickSpacing = 0;

        // update "needSettle" flag in tick state
        if (limitOrderType == Positions.ZERO_FOR_ONE) {
            ticks[tickUpper].needSettle1 = !isEmpty;
        } else {
            ticks[tickLower].needSettle0 = !isEmpty;
        }

        // return data for validating position's settling status
        tickSpacing = settlement.tickSpacing;
    }

    /// @dev Bridging function to sidestep "stack too deep" problem
    function update(
        mapping(int24 => Info[2]) storage settlements,
        mapping(int24 => Ticks.Tick) storage ticks,
        int24 tickLower,
        int24 tickUpper,
        uint8 limitOrderType,
        int96 liquidityDeltaD8,
        uint16 defaultTickSpacing
    ) internal returns (uint32 nextSnapshotId) {
        bool isAdd = liquidityDeltaD8 > 0;
        unchecked {
            (nextSnapshotId, ) = update(
                settlements,
                ticks,
                tickLower,
                tickUpper,
                limitOrderType,
                uint96(isAdd ? liquidityDeltaD8 : -liquidityDeltaD8),
                isAdd,
                defaultTickSpacing
            );
        }
    }

    /**
     * @notice Settle single-sided positions, i.e. filled limit orders, that ends at the tick `tickEnd`.
     * @dev Called during a swap right after tickEnd is crossed. It updates settlement and tick, and possibly tickmap.
     * @param settlements   Mapping of settlements of each tick
     * @param ticks         Mapping of ticks of a tier
     * @param tickMap       Tick bitmap of a tier
     * @param tier          Latest tier data (in memory) currently used in the swap
     * @param tickEnd       Ending tick of the limit orders, i.e. the tick just being crossed in the swap
     * @param token0In      The direction of the ongoing swap
     * @return tickStart    Starting tick of the limit orders, i.e. the other tick besides "tickEnd" that forms the positions
     * @return liquidityD8  Amount of liquidity settled
     */
    function settle(
        mapping(int24 => Info[2]) storage settlements,
        mapping(int24 => Ticks.Tick) storage ticks,
        TickMaps.TickMap storage tickMap,
        Tiers.Tier memory tier,
        int24 tickEnd,
        bool token0In
    ) internal returns (int24 tickStart, uint96 liquidityD8) {
        Info storage settlement; // we assume settlement is intialized
        Ticks.Tick storage start;
        Ticks.Tick storage end = ticks[tickEnd];

        unchecked {
            if (token0In) {
                settlement = settlements[tickEnd][0];
                tickStart = tickEnd + int16(settlement.tickSpacing);
                start = ticks[tickStart];

                // remove liquidity changes on ticks (effect)
                liquidityD8 = settlement.liquidityD8;
                start.liquidityUpperD8 -= liquidityD8;
                end.liquidityLowerD8 -= liquidityD8;
                end.needSettle0 = false;
            } else {
                settlement = settlements[tickEnd][1];
                tickStart = tickEnd - int16(settlement.tickSpacing);
                start = ticks[tickStart];

                // remove liquidity changes on ticks (effect)
                liquidityD8 = settlement.liquidityD8;
                start.liquidityLowerD8 -= liquidityD8;
                end.liquidityUpperD8 -= liquidityD8;
                end.needSettle1 = false;
            }

            // play extra safe to ensure settlement is initialized
            assert(tickStart != tickEnd);

            // snapshot data inside the tick range (effect)
            settlement.snapshots[settlement.nextSnapshotId] = Snapshot(
                end.feeGrowthOutside0 - start.feeGrowthOutside0,
                end.feeGrowthOutside1 - start.feeGrowthOutside1
            );
        }

        // reset settlement state since it's finished (effect)
        settlement.nextSnapshotId++;
        settlement.tickSpacing = 0;
        settlement.liquidityD8 = 0;

        // delete the starting tick if empty (effect)
        if (start.liquidityLowerD8 == 0 && start.liquidityUpperD8 == 0) {
            assert(tickStart != TickMath.MIN_TICK && tickStart != TickMath.MAX_TICK);
            int24 below = start.nextBelow;
            int24 above = start.nextAbove;
            ticks[below].nextAbove = above;
            ticks[above].nextBelow = below;
            delete ticks[tickStart];
            tickMap.unset(tickStart);
        }

        // delete the ending tick if empty (effect), and update tier's next ticks (locally)
        if (end.liquidityLowerD8 == 0 && end.liquidityUpperD8 == 0) {
            assert(tickEnd != TickMath.MIN_TICK && tickEnd != TickMath.MAX_TICK);
            int24 below = end.nextBelow;
            int24 above = end.nextAbove;
            ticks[below].nextAbove = above;
            ticks[above].nextBelow = below;
            delete ticks[tickEnd];
            tickMap.unset(tickEnd);

            // since the tier just crossed tickEnd, we can safely set tier's next ticks in this way
            tier.nextTickBelow = below;
            tier.nextTickAbove = above;
        }
    }

    /**
     * @notice Get data snapshot if the position is a settled limit order
     * @param settlements   Mapping of settlements of each tick
     * @param position      Position state
     * @param tickLower     Position's lower tick boundary
     * @param tickUpper     Position's upper tick boundary
     * @return settled      True if position is settled
     * @return snapshot     Data snapshot if position is settled
     */
    function getSnapshot(
        mapping(int24 => Info[2]) storage settlements,
        Positions.Position storage position,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (bool settled, Snapshot memory snapshot) {
        if (position.limitOrderType == Positions.ZERO_FOR_ONE || position.limitOrderType == Positions.ONE_FOR_ZERO) {
            Info storage settlement = position.limitOrderType == Positions.ZERO_FOR_ONE
                ? settlements[tickUpper][1]
                : settlements[tickLower][0];

            if (position.settlementSnapshotId < settlement.nextSnapshotId) {
                settled = true;
                snapshot = settlement.snapshots[position.settlementSnapshotId];
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Tiers {
    struct Tier {
        uint128 liquidity;
        uint128 sqrtPrice; // UQ56.72
        uint24 sqrtGamma; // 5 decimal places
        int24 tick;
        int24 nextTickBelow; // the next lower tick to cross (note that it can be equal to `tier.tick`)
        int24 nextTickAbove; // the next upper tick to cross
        uint80 feeGrowthGlobal0; // UQ16.64
        uint80 feeGrowthGlobal1; // UQ16.64
    }

    /// @dev Update tier's next tick if the given tick is more adjacent to the current tick
    function updateNextTick(Tier storage self, int24 tickNew) internal {
        if (tickNew <= self.tick) {
            if (tickNew > self.nextTickBelow) self.nextTickBelow = tickNew;
        } else {
            if (tickNew < self.nextTickAbove) self.nextTickAbove = tickNew;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library TickMath {
    uint256 private constant Q56 = 0x100000000000000;
    uint256 private constant Q128 = 0x100000000000000000000000000000000;

    /// @dev Minimum tick supported in this protocol
    int24 internal constant MIN_TICK = -776363;
    /// @dev Maximum tick supported in this protocol
    int24 internal constant MAX_TICK = 776363;
    /// @dev Minimum sqrt price, i.e. tickToSqrtPrice(MIN_TICK)
    uint128 internal constant MIN_SQRT_P = 65539;
    /// @dev Maximum sqrt price, i.e. tickToSqrtPrice(MAX_TICK)
    uint128 internal constant MAX_SQRT_P = 340271175397327323250730767849398346765;

    /**
     * @dev Find sqrtP = u^tick, where u = sqrt(1.0001)
     *
     * Let b_i = the i-th bit of x and b_i ∈ {0, 1}
     * Then  x = (b0 * 2^0) + (b1 * 2^1) + (b2 * 2^2) + ...
     * Thus, r = u^x
     *         = u^(b0 * 2^0) * u^(b1 * 2^1) * u^(b2 * 2^2) * ...
     *         = k0^b0 * k1^b1 * k2^b2 * ... (where k_i = u^(2^i))
     * We pre-compute k_i since u is a known constant. In practice, we use u = 1/sqrt(1.0001) to
     * prevent overflow during the computation, then inverse the result at the end.
     */
    function tickToSqrtPrice(int24 tick) internal pure returns (uint128 sqrtP) {
        unchecked {
            require(MIN_TICK <= tick && tick <= MAX_TICK);
            uint256 x = uint256(uint24(tick < 0 ? -tick : tick)); // abs(tick)
            uint256 r = Q128; // UQ128.128

            if (x & 0x1 > 0)     r = (r * 0xFFFCB933BD6FAD37AA2D162D1A594001) >> 128;
            if (x & 0x2 > 0)     r = (r * 0xFFF97272373D413259A46990580E213A) >> 128;
            if (x & 0x4 > 0)     r = (r * 0xFFF2E50F5F656932EF12357CF3C7FDCC) >> 128;
            if (x & 0x8 > 0)     r = (r * 0xFFE5CACA7E10E4E61C3624EAA0941CD0) >> 128;
            if (x & 0x10 > 0)    r = (r * 0xFFCB9843D60F6159C9DB58835C926644) >> 128;
            if (x & 0x20 > 0)    r = (r * 0xFF973B41FA98C081472E6896DFB254C0) >> 128;
            if (x & 0x40 > 0)    r = (r * 0xFF2EA16466C96A3843EC78B326B52861) >> 128;
            if (x & 0x80 > 0)    r = (r * 0xFE5DEE046A99A2A811C461F1969C3053) >> 128;
            if (x & 0x100 > 0)   r = (r * 0xFCBE86C7900A88AEDCFFC83B479AA3A4) >> 128;
            if (x & 0x200 > 0)   r = (r * 0xF987A7253AC413176F2B074CF7815E54) >> 128;
            if (x & 0x400 > 0)   r = (r * 0xF3392B0822B70005940C7A398E4B70F3) >> 128;
            if (x & 0x800 > 0)   r = (r * 0xE7159475A2C29B7443B29C7FA6E889D9) >> 128;
            if (x & 0x1000 > 0)  r = (r * 0xD097F3BDFD2022B8845AD8F792AA5825) >> 128;
            if (x & 0x2000 > 0)  r = (r * 0xA9F746462D870FDF8A65DC1F90E061E5) >> 128;
            if (x & 0x4000 > 0)  r = (r * 0x70D869A156D2A1B890BB3DF62BAF32F7) >> 128;
            if (x & 0x8000 > 0)  r = (r * 0x31BE135F97D08FD981231505542FCFA6) >> 128;
            if (x & 0x10000 > 0) r = (r * 0x9AA508B5B7A84E1C677DE54F3E99BC9) >> 128;
            if (x & 0x20000 > 0) r = (r * 0x5D6AF8DEDB81196699C329225EE604) >> 128;
            if (x & 0x40000 > 0) r = (r * 0x2216E584F5FA1EA926041BEDFE98) >> 128;
            if (x & 0x80000 > 0) r = (r * 0x48A170391F7DC42444E8FA2) >> 128;
            // Stop computation here since abs(tick) < 2**20 (i.e. 776363 < 1048576)

            // Inverse r since base = 1/sqrt(1.0001)
            if (tick >= 0) r = type(uint256).max / r;

            // Downcast to UQ56.72 and round up
            sqrtP = uint128((r >> 56) + (r % Q56 > 0 ? 1 : 0));
        }
    }

    /// @dev Find tick = floor(log_u(sqrtP)), where u = sqrt(1.0001)
    function sqrtPriceToTick(uint128 sqrtP) internal pure returns (int24 tick) {
        unchecked {
            require(MIN_SQRT_P <= sqrtP && sqrtP <= MAX_SQRT_P);
            uint256 x = uint256(sqrtP);

            // Find msb of sqrtP (since sqrtP < 2^128, we start the check at 2**64)
            uint256 xc = x;
            uint256 msb;
            if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
            if (xc >= 0x100000000)         { xc >>= 32; msb += 32; }
            if (xc >= 0x10000)             { xc >>= 16; msb += 16; }
            if (xc >= 0x100)               { xc >>= 8;  msb += 8; }
            if (xc >= 0x10)                { xc >>= 4;  msb += 4; }
            if (xc >= 0x4)                 { xc >>= 2;  msb += 2; }
            if (xc >= 0x2)                 { xc >>= 1;  msb += 1; }

            // Calculate integer part of log2(x), can be negative
            int256 r = (int256(msb) - 72) << 64; // Q64.64

            // Scale up x to make it 127-bit
            uint256 z = x << (127 - msb);

            // Do the following to find the decimal part of log2(x) (i.e. from 63th bit downwards):
            //   1. sqaure z
            //   2. if z becomes 128 bit:
            //   3.     half z
            //   4.     set this bit to 1
            // And stop at 46th bit since we have enough decimal places to continue to next steps
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x8000000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x4000000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x2000000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x1000000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x800000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x400000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x200000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x100000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x80000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x40000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x20000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x10000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x8000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x4000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x2000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x1000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x800000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x400000000000; }

            // Change the base of log2(x) to sqrt(1.0001). (i.e. log_u(x) = log2(u) * log_u(2))
            r *= 255738958999603826347141;

            // Add both the maximum positive and negative errors to r to see if it diverges into two different ticks.
            // If it does, calculate the upper tick's sqrtP and compare with the given sqrtP.
            int24 tickUpper = int24((r + 17996007701288367970265332090599899137) >> 128);
            int24 tickLower = int24(
                r < -230154402537746701963478439606373042805014528 ? (r - 98577143636729737466164032634120830977) >> 128 :
                r < -162097929153559009270803518120019400513814528 ? (r - 527810000259722480933883300202676225) >> 128 :
                r >> 128
            );
            tick = (tickUpper == tickLower || sqrtP >= tickToSqrtPrice(tickUpper)) ? tickUpper : tickLower;
        }
    }

    struct Cache {
        int24 tick;
        uint128 sqrtP;
    }

    /// @dev memoize last tick-to-sqrtP conversion
    function tickToSqrtPriceMemoized(Cache memory cache, int24 tick) internal pure returns (uint128 sqrtP) {
        if (tick == cache.tick) sqrtP = cache.sqrtP;
        else {
            sqrtP = tickToSqrtPrice(tick);
            cache.sqrtP = sqrtP;
            cache.tick = tick;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Ticks {
    /**
     * @param liquidityLowerD8  Liquidity from positions with lower tick boundary at this tick
     * @param liquidityUpperD8  Liquidity from positions with upper tick boundary at this tick
     * @param nextBelow         Next initialized tick below this tick
     * @param nextAbove         Next initialized tick above this tick
     * @param needSettle0       True if needed to settle positions with lower tick boundary at this tick (i.e. 1 -> 0 limit orders)
     * @param needSettle1       True if needed to settle positions with upper tick boundary at this tick (i.e. 0 -> 1 limit orders)
     * @param feeGrowthOutside0 Fee0 growth per unit liquidity from this tick to the end in a direction away from the tier's current tick (UQ16.64)
     * @param feeGrowthOutside1 Fee1 growth per unit liquidity from this tick to the end in a direction away from the tier's current tick (UQ16.64)
     */
    struct Tick {
        uint96 liquidityLowerD8;
        uint96 liquidityUpperD8;
        int24 nextBelow;
        int24 nextAbove;
        bool needSettle0;
        bool needSettle1;
        uint80 feeGrowthOutside0;
        uint80 feeGrowthOutside1;
    }

    /// @dev Flip the direction of "outside". Called when the tick is being crossed.
    function flip(
        Tick storage self,
        uint80 feeGrowthGlobal0,
        uint80 feeGrowthGlobal1
    ) internal {
        unchecked {
            self.feeGrowthOutside0 = feeGrowthGlobal0 - self.feeGrowthOutside0;
            self.feeGrowthOutside1 = feeGrowthGlobal1 - self.feeGrowthOutside1;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./math/TickMath.sol";

library TickMaps {
    struct TickMap {
        uint256 blockMap; //                    stores which blocks are initialized
        mapping(uint256 => uint256) blocks; //  stores which words are initialized
        mapping(uint256 => uint256) words; //   stores which ticks are initialized
    }

    /// @dev Compress and convert tick into an unsigned integer, then compute the indices of the block and word that the
    /// compressed tick uses. Assume tick >= TickMath.MIN_TICK
    function _indices(int24 tick)
        internal
        pure
        returns (
            uint256 blockIdx,
            uint256 wordIdx,
            uint256 compressed
        )
    {
        unchecked {
            compressed = uint256(int256((tick - TickMath.MIN_TICK)));
            blockIdx = compressed >> 16;
            wordIdx = compressed >> 8;
            assert(blockIdx < 256);
        }
    }

    /// @dev Convert the unsigned integer back to a tick. Assume "compressed" is a valid value, computed by _indices function.
    function _decompress(uint256 compressed) internal pure returns (int24 tick) {
        unchecked {
            tick = int24(int256(compressed) + TickMath.MIN_TICK);
        }
    }

    function set(TickMap storage self, int24 tick) internal {
        (uint256 blockIdx, uint256 wordIdx, uint256 compressed) = _indices(tick);

        self.words[wordIdx] |= 1 << (compressed & 0xFF);
        self.blocks[blockIdx] |= 1 << (wordIdx & 0xFF);
        self.blockMap |= 1 << blockIdx;
    }

    function unset(TickMap storage self, int24 tick) internal {
        (uint256 blockIdx, uint256 wordIdx, uint256 compressed) = _indices(tick);

        self.words[wordIdx] &= ~(1 << (compressed & 0xFF));
        if (self.words[wordIdx] == 0) {
            self.blocks[blockIdx] &= ~(1 << (wordIdx & 0xFF));
            if (self.blocks[blockIdx] == 0) {
                self.blockMap &= ~(1 << blockIdx);
            }
        }
    }

    /// @dev Find the next initialized tick below the given tick. Assume tick >= TickMath.MIN_TICK
    // How to find the next initialized bit below the i-th bit inside a word (e.g. i = 8)?
    // 1)  Mask _off_ the word from the 8th bit to the 255th bit (zero-indexed)
    // 2)  Find the most significant bit of the masked word
    //                  8th bit
    //                     ↓
    //     word:   0001 1101 0010 1100
    //     mask:   0000 0000 1111 1111      i.e. (1 << i) - 1
    //     masked: 0000 0000 0010 1100
    //                         ↑
    //                  msb(masked) = 5
    function nextBelow(TickMap storage self, int24 tick) internal view returns (int24 tickBelow) {
        unchecked {
            (uint256 blockIdx, uint256 wordIdx, uint256 compressed) = _indices(tick);

            uint256 word = self.words[wordIdx] & ((1 << (compressed & 0xFF)) - 1);
            if (word == 0) {
                uint256 block_ = self.blocks[blockIdx] & ((1 << (wordIdx & 0xFF)) - 1);
                if (block_ == 0) {
                    uint256 blockMap = self.blockMap & ((1 << blockIdx) - 1);
                    assert(blockMap != 0);

                    blockIdx = _msb(blockMap);
                    block_ = self.blocks[blockIdx];
                }
                wordIdx = (blockIdx << 8) | _msb(block_);
                word = self.words[wordIdx];
            }

            tickBelow = _decompress((wordIdx << 8) | _msb(word));
        }
    }

    /// @notice Returns the index of the most significant bit of the number, where the least significant bit is at index 0
    /// and the most significant bit is at index 255
    /// @dev The function satisfies the property: x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function _msb(uint256 x) internal pure returns (uint8 r) {
        unchecked {
            assert(x > 0);
            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                r += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                r += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                r += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                r += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                r += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                r += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                r += 2;
            }
            if (x >= 0x2) r += 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IMuffinHubActions {
    /// @notice                 Deposit token into recipient's account
    /// @dev                    DO NOT deposit rebasing tokens or multiple-address tokens as it will cause loss of funds.
    ///                         DO NOT withdraw the token you deposit or swap the token out from the contract during the callback.
    /// @param recipient        Recipient's address
    /// @param recipientAccRefId Recipient's account id
    /// @param token            Address of the token to deposit
    /// @param amount           Token amount to deposit
    /// @param data             Arbitrary data that is passed to callback function
    function deposit(
        address recipient,
        uint256 recipientAccRefId,
        address token,
        uint256 amount,
        bytes calldata data
    ) external;

    /// @notice                 Withdraw token from sender's account and send to recipient's address
    /// @param recipient        Recipient's address
    /// @param senderAccRefId   Id of sender's account, i.e. the account to withdraw token from
    /// @param token            Address of the token to withdraw
    /// @param amount           Token amount to withdraw
    function withdraw(
        address recipient,
        uint256 senderAccRefId,
        address token,
        uint256 amount
    ) external;

    /// @notice                 Create pool
    /// @dev                    DO NOT create pool with rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param token0           Address of token0 of the pool
    /// @param token1           Address of token1 of the pool
    /// @param sqrtGamma        Sqrt (1 - percentage swap fee of the tier) (precision: 1e5)
    /// @param sqrtPrice        Sqrt price of token0 denominated in token1 (UQ56.72)
    /// @param senderAccRefId   Sender's account id, for paying the base liquidity
    /// @return poolId          Pool id
    function createPool(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint128 sqrtPrice,
        uint256 senderAccRefId
    ) external returns (bytes32 poolId);

    /// @notice                 Add a new tier to a pool. Called by governanace only.
    /// @param token0           Address of token0 of the pool
    /// @param token1           Address of token1 of the pool
    /// @param sqrtGamma        Sqrt (1 - percentage swap fee) (precision: 1e5)
    /// @param senderAccRefId   Sender's account id, for paying the base liquidity
    /// @return tierId          Id of the new tier
    function addTier(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint256 senderAccRefId
    ) external returns (uint8 tierId);

    /// @notice                 Swap one token for another
    /// @param tokenIn          Input token address
    /// @param tokenOut         Output token address
    /// @param tierChoices      Bitmap to select which tiers are allowed to swap
    /// @param amountDesired    Desired swap amount (positive: input, negative: output)
    /// @param recipient        Recipient's address
    /// @param recipientAccRefId Recipient's account id
    /// @param senderAccRefId   Sender's account id
    /// @param data             Arbitrary data that is passed to callback function
    /// @return amountIn        Input token amount
    /// @return amountOut       Output token amount
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired,
        address recipient,
        uint256 recipientAccRefId,
        uint256 senderAccRefId,
        bytes calldata data
    ) external returns (uint256 amountIn, uint256 amountOut);

    /// @notice                 Parameters for the multi-hop swap function
    /// @param path             Multi-hop path. encodePacked(address tokenA, uint16 tierChoices, address tokenB, uint16 tierChoices ...)
    /// @param amountDesired    Desired swap amount (positive: input, negative: output)
    /// @param recipient        Recipient's address
    /// @param recipientAccRefId Recipient's account id
    /// @param senderAccRefId   Sender's account id
    /// @param data             Arbitrary data that is passed to callback function
    struct SwapMultiHopParams {
        bytes path;
        int256 amountDesired;
        address recipient;
        uint256 recipientAccRefId;
        uint256 senderAccRefId;
        bytes data;
    }

    /// @notice                 Swap one token for another along the specified path
    /// @param params           SwapMultiHopParams struct
    /// @return amountIn        Input token amount
    /// @return amountOut       Output token amount
    function swapMultiHop(SwapMultiHopParams calldata params) external returns (uint256 amountIn, uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../libraries/Tiers.sol";
import "../../libraries/Ticks.sol";
import "../../libraries/Positions.sol";

interface IMuffinHubView {
    /// @notice Return whether the given fee rate is allowed in the given pool
    /// @param poolId       Pool id
    /// @param sqrtGamma    Fee rate, expressed in sqrt(1 - %fee) (precision: 1e5)
    /// @return allowed     True if the % fee is allowed
    function isSqrtGammaAllowed(bytes32 poolId, uint24 sqrtGamma) external view returns (bool allowed);

    /// @notice Return pool's default tick spacing and protocol fee
    /// @return tickSpacing     Default tick spacing applied to new pools. Note that there is also pool-specific default
    ///                         tick spacing which overrides the global default if set.
    /// @return protocolFee     Default protocol fee applied to new pools
    function getDefaultParameters() external view returns (uint8 tickSpacing, uint8 protocolFee);

    /// @notice Return the pool's tick spacing and protocol fee
    /// @return tickSpacing     Pool's tick spacing
    /// @return protocolFee     Pool's protocol fee
    function getPoolParameters(bytes32 poolId) external view returns (uint8 tickSpacing, uint8 protocolFee);

    /// @notice Return a tier state
    function getTier(bytes32 poolId, uint8 tierId) external view returns (Tiers.Tier memory tier);

    /// @notice Return the number of existing tiers in the given pool
    function getTiersCount(bytes32 poolId) external view returns (uint256 count);

    /// @notice Return a tick state
    function getTick(
        bytes32 poolId,
        uint8 tierId,
        int24 tick
    ) external view returns (Ticks.Tick memory tickObj);

    /// @notice Return a position state.
    /// @param poolId           Pool id
    /// @param owner            Address of the position owner
    /// @param positionRefId    Reference id for the position set by the owner
    /// @param tierId           Tier index
    /// @param tickLower        Lower tick boundary of the position
    /// @param tickUpper        Upper tick boundary of the position
    /// @param position         Position struct
    function getPosition(
        bytes32 poolId,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (Positions.Position memory position);

    /// @notice Return the value of a slot in MuffinHub contract
    function getStorageAt(bytes32 slot) external view returns (bytes32 word);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Math.sol";
import "./UnsafeMath.sol";
import "./FullMath.sol";

library PoolMath {
    using Math for uint256;

    uint256 private constant Q72 = 0x1000000000000000000;
    uint256 private constant Q184 = 0x10000000000000000000000000000000000000000000000;

    // ----- sqrt price <> token amounts -----

    /// @dev Calculate amount0 delta when price moves from sqrtP0 to sqrtP1.
    /// i.e. Δx = L (√P0 - √P1) / (√P0 √P1)
    ///
    /// @dev Rounding rules:
    /// if sqrtP0 > sqrtP1 (price goes down):   => amt0 is input    => round away from zero
    /// if sqrtP0 < sqrtP1 (price goes up):     => amt0 is output   => round towards zero
    function calcAmt0FromSqrtP(
        uint128 sqrtP0,
        uint128 sqrtP1,
        uint128 liquidity
    ) internal pure returns (int256 amt0) {
        unchecked {
            bool priceUp = sqrtP1 > sqrtP0;
            if (priceUp) (sqrtP0, sqrtP1) = (sqrtP1, sqrtP0);

            uint256 num = uint256(liquidity) * (sqrtP0 - sqrtP1);
            uint256 denom = uint256(sqrtP0) * sqrtP1;
            amt0 = Math.toInt256(
                num < Q184
                    ? (priceUp ? (num << 72) / denom : UnsafeMath.ceilDiv(num << 72, denom))
                    : (priceUp ? FullMath.mulDiv(num, Q72, denom) : FullMath.mulDivRoundingUp(num, Q72, denom))
            );
            if (priceUp) amt0 *= -1;
        }
    }

    /// @dev Calculate amount1 delta when price moves from sqrtP0 to sqrtP1.
    /// i.e. Δy = L (√P0 - √P1)
    ///
    /// @dev Rounding rules:
    /// if sqrtP0 > sqrtP1 (price goes down):   => amt1 is output   => round towards zero
    /// if sqrtP0 < sqrtP1 (price goes up):     => amt1 is input    => round away from zero
    function calcAmt1FromSqrtP(
        uint128 sqrtP0,
        uint128 sqrtP1,
        uint128 liquidity
    ) internal pure returns (int256 amt1) {
        unchecked {
            bool priceDown = sqrtP1 < sqrtP0;
            if (priceDown) (sqrtP0, sqrtP1) = (sqrtP1, sqrtP0);

            uint256 num = uint256(liquidity) * (sqrtP1 - sqrtP0);
            amt1 = (priceDown ? num >> 72 : UnsafeMath.ceilDiv(num, Q72)).toInt256();
            if (priceDown) amt1 *= -1;
        }
    }

    /// @dev Calculate the new sqrt price after an amount0 delta.
    /// i.e. √P1 = L √P0 / (L + Δx * √P0)   if no overflow
    ///          = L / (L/√P0 + Δx)         otherwise
    ///
    /// @dev Rounding rules:
    /// if amt0 in:     price goes down => sqrtP1 rounded up for less price change for less amt1 out
    /// if amt0 out:    price goes up   => sqrtP1 rounded up for more price change for more amt1 in
    /// therefore:      sqrtP1 always rounded up
    function calcSqrtPFromAmt0(
        uint128 sqrtP0,
        uint128 liquidity,
        int256 amt0
    ) internal pure returns (uint128 sqrtP1) {
        unchecked {
            if (amt0 == 0) return sqrtP0;
            uint256 absAmt0 = uint256(amt0 < 0 ? -amt0 : amt0);
            uint256 product = absAmt0 * sqrtP0;
            uint256 liquidityX72 = uint256(liquidity) << 72;
            uint256 denom;

            if (amt0 > 0) {
                if ((product / absAmt0 == sqrtP0) && ((denom = liquidityX72 + product) >= liquidityX72)) {
                    // if product and denom don't overflow:
                    uint256 num = uint256(liquidity) * sqrtP0;
                    sqrtP1 = num < Q184
                        ? uint128(UnsafeMath.ceilDiv(num << 72, denom)) // denom > 0
                        : uint128(FullMath.mulDivRoundingUp(num, Q72, denom));
                } else {
                    // if either one overflows:
                    sqrtP1 = uint128(UnsafeMath.ceilDiv(liquidityX72, (liquidityX72 / sqrtP0).add(absAmt0))); // absAmt0 > 0
                }
            } else {
                // ensure product doesn't overflow and denom doesn't underflow
                require(product / absAmt0 == sqrtP0);
                require((denom = liquidityX72 - product) <= liquidityX72);
                require(denom != 0);
                uint256 num = uint256(liquidity) * sqrtP0;
                sqrtP1 = num < Q184
                    ? UnsafeMath.ceilDiv(num << 72, denom).toUint128()
                    : FullMath.mulDivRoundingUp(num, Q72, denom).toUint128();
            }
        }
    }

    /// @dev Calculate the new sqrt price after an amount1 delta.
    /// i.e. √P1 = √P0 + (Δy / L)
    ///
    /// @dev Rounding rules:
    /// if amt1 in:     price goes up   => sqrtP1 rounded down for less price delta for less amt0 out
    /// if amt1 out:    price goes down => sqrtP1 rounded down for more price delta for more amt0 in
    /// therefore:      sqrtP1 always rounded down
    function calcSqrtPFromAmt1(
        uint128 sqrtP0,
        uint128 liquidity,
        int256 amt1
    ) internal pure returns (uint128 sqrtP1) {
        unchecked {
            if (amt1 < 0) {
                // price moves down
                require(liquidity != 0);
                uint256 absAmt1 = uint256(-amt1);
                uint256 absAmt1DivL = absAmt1 < Q184
                    ? UnsafeMath.ceilDiv(absAmt1 * Q72, liquidity)
                    : FullMath.mulDivRoundingUp(absAmt1, Q72, liquidity);

                sqrtP1 = uint256(sqrtP0).sub(absAmt1DivL).toUint128();
            } else {
                // price moves up
                uint256 amt1DivL = uint256(amt1) < Q184
                    ? (uint256(amt1) * Q72) / liquidity
                    : FullMath.mulDiv(uint256(amt1), Q72, liquidity);

                sqrtP1 = uint256(sqrtP0).add(amt1DivL).toUint128();
            }
        }
    }

    // ----- liquidity <> token amounts -----

    /// @dev Calculate the amount{0,1} needed for the given liquidity change
    function calcAmtsForLiquidity(
        uint128 sqrtP,
        uint128 sqrtPLower,
        uint128 sqrtPUpper,
        int96 liquidityDeltaD8
    ) internal pure returns (uint256 amt0, uint256 amt1) {
        // we assume {sqrtP, sqrtPLower, sqrtPUpper} ≠ 0 and sqrtPLower < sqrtPUpper
        unchecked {
            // find the sqrt price at which liquidity is add/removed
            sqrtP = (sqrtP < sqrtPLower) ? sqrtPLower : (sqrtP > sqrtPUpper) ? sqrtPUpper : sqrtP;

            // calc amt{0,1} for the change of liquidity
            uint128 absL = uint128(uint96(liquidityDeltaD8 >= 0 ? liquidityDeltaD8 : -liquidityDeltaD8)) << 8;
            if (liquidityDeltaD8 >= 0) {
                // round up
                amt0 = uint256(calcAmt0FromSqrtP(sqrtPUpper, sqrtP, absL));
                amt1 = uint256(calcAmt1FromSqrtP(sqrtPLower, sqrtP, absL));
            } else {
                // round down
                amt0 = uint256(-calcAmt0FromSqrtP(sqrtP, sqrtPUpper, absL));
                amt1 = uint256(-calcAmt1FromSqrtP(sqrtP, sqrtPLower, absL));
            }
        }
    }

    /// @dev Calculate the max liquidity received if adding given token amounts to the tier.
    function calcLiquidityForAmts(
        uint128 sqrtP,
        uint128 sqrtPLower,
        uint128 sqrtPUpper,
        uint256 amt0,
        uint256 amt1
    ) internal pure returns (uint96 liquidityD8) {
        // we assume {sqrtP, sqrtPLower, sqrtPUpper} ≠ 0 and sqrtPLower < sqrtPUpper
        unchecked {
            uint256 liquidity;
            if (sqrtP <= sqrtPLower) {
                // L = Δx (√P0 √P1) / (√P0 - √P1)
                liquidity = FullMath.mulDiv(amt0, uint256(sqrtPLower) * sqrtPUpper, (sqrtPUpper - sqrtPLower) * Q72);
            } else if (sqrtP >= sqrtPUpper) {
                // L = Δy / (√P0 - √P1)
                liquidity = FullMath.mulDiv(amt1, Q72, sqrtPUpper - sqrtPLower);
            } else {
                uint256 liquidity0 = FullMath.mulDiv(amt0, uint256(sqrtP) * sqrtPUpper, (sqrtPUpper - sqrtP) * Q72);
                uint256 liquidity1 = FullMath.mulDiv(amt1, Q72, sqrtP - sqrtPLower);
                liquidity = (liquidity0 < liquidity1 ? liquidity0 : liquidity1);
            }
            liquidityD8 = (liquidity >> 8).toUint96();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library UnsafeMath {
    /// @dev Division by 0 has unspecified behavior, and must be checked externally.
    function ceilDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev https://github.com/Uniswap/uniswap-v3-core/blob/v1.0.0/contracts/libraries/FullMath.sol
 * Added `unchecked` and changed line 76 for being compatible in solidity 0.8
 */

// solhint-disable max-line-length

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
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

            // [*] The next line is edited to be compatible with solidity 0.8
            // ref: https://ethereum.stackexchange.com/a/96646
            // original: uint256 twos = -denominator & denominator;
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

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library PathLib {
    uint256 internal constant ADDR_BYTES = 20;
    uint256 internal constant ADDR_UINT16_BYTES = ADDR_BYTES + 2;
    uint256 internal constant PATH_MAX_BYTES = ADDR_UINT16_BYTES * 256 + ADDR_BYTES; // 256 pools (i.e. 5652 bytes)

    function invalid(bytes memory path) internal pure returns (bool) {
        unchecked {
            return
                path.length > PATH_MAX_BYTES ||
                path.length <= ADDR_BYTES ||
                (path.length - ADDR_BYTES) % ADDR_UINT16_BYTES != 0;
        }
    }

    /// @dev Assume the path is valid
    function hopCount(bytes memory path) internal pure returns (uint256) {
        unchecked {
            return path.length / ADDR_UINT16_BYTES;
        }
    }

    /// @dev Assume the path is valid
    function decodePool(
        bytes memory path,
        uint256 poolIndex,
        bool exactIn
    )
        internal
        pure
        returns (
            address tokenIn,
            address tokenOut,
            uint256 tierChoices
        )
    {
        unchecked {
            uint256 offset = ADDR_UINT16_BYTES * poolIndex;
            tokenIn = _readAddressAt(path, offset);
            tokenOut = _readAddressAt(path, ADDR_UINT16_BYTES + offset);
            tierChoices = _readUint16At(path, ADDR_BYTES + offset);
            if (!exactIn) (tokenIn, tokenOut) = (tokenOut, tokenIn);
        }
    }

    /// @dev Assume the path is valid
    function tokensInOut(bytes memory path, bool exactIn) internal pure returns (address tokenIn, address tokenOut) {
        unchecked {
            tokenIn = _readAddressAt(path, 0);
            tokenOut = _readAddressAt(path, path.length - ADDR_BYTES);
            if (!exactIn) (tokenIn, tokenOut) = (tokenOut, tokenIn);
        }
    }

    function _readAddressAt(bytes memory data, uint256 offset) internal pure returns (address addr) {
        assembly {
            addr := mload(add(add(data, 20), offset))
        }
    }

    function _readUint16At(bytes memory data, uint256 offset) internal pure returns (uint16 value) {
        assembly {
            value := mload(add(add(data, 2), offset))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./math/TickMath.sol";
import "./math/SwapMath.sol";
import "./math/UnsafeMath.sol";
import "./math/Math.sol";
import "./Tiers.sol";
import "./Ticks.sol";
import "./TickMaps.sol";
import "./Positions.sol";
import "./Settlement.sol";

library Pools {
    using Math for uint96;
    using Math for uint128;
    using Tiers for Tiers.Tier;
    using Ticks for Ticks.Tick;
    using TickMaps for TickMaps.TickMap;
    using Positions for Positions.Position;

    error InvalidAmount();
    error InvalidTierChoices();
    error InvalidTick();
    error InvalidTickRangeForLimitOrder();
    error NoLiquidityForLimitOrder();
    error PositionAlreadySettled();
    error PositionNotSettled();

    uint24 internal constant MAX_SQRT_GAMMA = 100_000;
    uint96 internal constant BASE_LIQUIDITY_D8 = 100; // tier's base liquidity, scaled down 2^8. User pays it when adding a tier
    int256 internal constant SWAP_AMOUNT_TOLERANCE = 100; // tolerance between desired and actual swap amounts

    uint256 internal constant AMOUNT_DISTRIBUTION_BITS = 256 / MAX_TIERS; // i.e. 42 if MAX_TIERS is 6
    uint256 internal constant AMOUNT_DISTRIBUTION_RESOLUTION = AMOUNT_DISTRIBUTION_BITS - 1;

    /// @param unlocked     Reentrancy lock
    /// @param tickSpacing  Tick spacing. Only ticks that are multiples of the tick spacing can be used
    /// @param protocolFee  Protocol fee with base 255 (e.g. protocolFee = 51 for 20% protocol fee)
    /// @param tiers        Array of tiers
    /// @param tickMaps     Bitmap for each tier to store which ticks are initializated
    /// @param ticks        Mapping of tick states of each tier
    /// @param settlements  Mapping of settlements for token{0,1} singled-sided positions
    /// @param positions    Mapping of position states
    /// @param limitOrderTickSpacingMultipliers Tick spacing of limit order for each tier, as multiples of the pool's tick spacing
    struct Pool {
        bool unlocked;
        uint8 tickSpacing;
        uint8 protocolFee;
        Tiers.Tier[] tiers;
        mapping(uint256 => TickMaps.TickMap) tickMaps;
        mapping(uint256 => mapping(int24 => Ticks.Tick)) ticks;
        mapping(uint256 => mapping(int24 => Settlement.Info[2])) settlements;
        mapping(bytes32 => Positions.Position) positions;
        uint8[MAX_TIERS] limitOrderTickSpacingMultipliers;
    }

    function lock(Pool storage pool) internal {
        require(pool.unlocked);
        pool.unlocked = false;
    }

    function unlock(Pool storage pool) internal {
        pool.unlocked = true;
    }

    function getPoolAndId(
        mapping(bytes32 => Pool) storage pools,
        address token0,
        address token1
    ) internal view returns (Pool storage pool, bytes32 poolId) {
        poolId = keccak256(abi.encode(token0, token1));
        pool = pools[poolId];
    }

    /*===============================================================
     *                       INITIALIZATION
     *==============================================================*/

    function initialize(
        Pool storage pool,
        uint24 sqrtGamma,
        uint128 sqrtPrice,
        uint8 tickSpacing,
        uint8 protocolFee
    ) internal returns (uint256 amount0, uint256 amount1) {
        require(pool.tickSpacing == 0); // ensure not initialized
        require(TickMath.MIN_SQRT_P <= sqrtPrice && sqrtPrice <= TickMath.MAX_SQRT_P);
        require(tickSpacing > 0);

        pool.tickSpacing = tickSpacing;
        pool.protocolFee = protocolFee;

        (amount0, amount1) = _addTier(pool, sqrtGamma, sqrtPrice);

        // default enable limit order on first tier
        pool.limitOrderTickSpacingMultipliers[0] = 1;

        // BE AWARE the pool is locked. Please unlock it after token transfer is done.
    }

    function addTier(Pool storage pool, uint24 sqrtGamma)
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint8 tierId
        )
    {
        lock(pool);
        require((tierId = uint8(pool.tiers.length)) > 0);
        (amount0, amount1) = _addTier(pool, sqrtGamma, pool.tiers[0].sqrtPrice); // use 1st tier sqrt price as reference

        // BE AWARE the pool is locked. Please unlock it after token transfer is done.
    }

    function _addTier(
        Pool storage pool,
        uint24 sqrtGamma,
        uint128 sqrtPrice
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint256 tierId = pool.tiers.length;
        require(tierId < MAX_TIERS);
        require(sqrtGamma <= MAX_SQRT_GAMMA);

        // initialize tier
        Tiers.Tier memory tier = Tiers.Tier({
            liquidity: uint128(BASE_LIQUIDITY_D8) << 8,
            sqrtPrice: sqrtPrice,
            sqrtGamma: sqrtGamma,
            tick: TickMath.sqrtPriceToTick(sqrtPrice),
            nextTickBelow: TickMath.MIN_TICK,
            nextTickAbove: TickMath.MAX_TICK,
            feeGrowthGlobal0: 0,
            feeGrowthGlobal1: 0
        });
        if (sqrtPrice == TickMath.MAX_SQRT_P) tier.tick--; // max tick is never crossed
        pool.tiers.push(tier);

        // initialize min tick & max tick
        Ticks.Tick storage lower = pool.ticks[tierId][TickMath.MIN_TICK];
        Ticks.Tick storage upper = pool.ticks[tierId][TickMath.MAX_TICK];
        (lower.liquidityLowerD8, lower.nextBelow, lower.nextAbove) = (
            BASE_LIQUIDITY_D8,
            TickMath.MIN_TICK,
            TickMath.MAX_TICK
        );
        (upper.liquidityUpperD8, upper.nextBelow, upper.nextAbove) = (
            BASE_LIQUIDITY_D8,
            TickMath.MIN_TICK,
            TickMath.MAX_TICK
        );

        // initialize tick map
        pool.tickMaps[tierId].set(TickMath.MIN_TICK);
        pool.tickMaps[tierId].set(TickMath.MAX_TICK);

        // calculate tokens to take for full-range base liquidity
        amount0 = UnsafeMath.ceilDiv(uint256(BASE_LIQUIDITY_D8) << (72 + 8), sqrtPrice);
        amount1 = UnsafeMath.ceilDiv(uint256(BASE_LIQUIDITY_D8) * sqrtPrice, 1 << (72 - 8));
    }

    /*===============================================================
     *                           SETTINGS
     *==============================================================*/

    function setPoolParameters(
        Pool storage pool,
        uint8 tickSpacing,
        uint8 protocolFee
    ) internal {
        require(pool.unlocked);
        require(tickSpacing > 0);
        pool.tickSpacing = tickSpacing;
        pool.protocolFee = protocolFee;
    }

    function setTierParameters(
        Pool storage pool,
        uint8 tierId,
        uint24 sqrtGamma,
        uint8 limitOrderTickSpacingMultiplier
    ) internal {
        require(pool.unlocked);
        require(tierId < pool.tiers.length);
        require(sqrtGamma <= MAX_SQRT_GAMMA);
        pool.tiers[tierId].sqrtGamma = sqrtGamma;
        pool.limitOrderTickSpacingMultipliers[tierId] = limitOrderTickSpacingMultiplier;
    }

    /*===============================================================
     *                            SWAP
     *==============================================================*/

    uint256 private constant Q64 = 0x10000000000000000;
    uint256 private constant Q128 = 0x100000000000000000000000000000000;

    /// @notice Emitted when limit order settlement occurs during a swap
    /// @dev Normally, we emit events from hub contract instead of from this pool library, but bubbling up the event
    /// data back to hub contract comsumes gas significantly, therefore we simply emit the "settle" event here.
    event Settle(
        bytes32 indexed poolId,
        uint8 indexed tierId,
        int24 indexed tickEnd,
        int24 tickStart,
        uint96 liquidityD8
    );

    struct SwapCache {
        bool zeroForOne;
        bool exactIn;
        uint8 protocolFee;
        uint256 protocolFeeAmt;
        uint256 tierChoices;
        TickMath.Cache tmCache;
        int256[MAX_TIERS] amounts;
        bytes32 poolId;
    }

    struct TierState {
        uint128 sqrtPTick;
        uint256 amountIn;
        uint256 amountOut;
        bool crossed;
    }

    /// @dev                    Struct returned by the "swap" function
    /// @param amount0          Pool's token0 balance change
    /// @param amount1          Pool's token1 balance change
    /// @param amountInDistribution Percentages of input amount routed to each tier (for logging)
    /// @param tierData         Array of tier's liquidity and sqrt price after the swap (for logging)
    /// @param protocolFeeAmt   Amount of input token as protocol fee
    struct SwapResult {
        int256 amount0;
        int256 amount1;
        uint256 amountInDistribution;
        uint256 amountOutDistribution;
        uint256[] tierData;
        uint256 protocolFeeAmt;
    }

    /// @notice                 Perform a swap in the pool
    /// @param pool             Pool storage pointer
    /// @param isToken0         True if amtDesired refers to token0
    /// @param amtDesired       Desired swap amount (positive: exact input, negative: exact output)
    /// @param tierChoices      Bitmap to allow which tiers to swap
    /// @param poolId           Pool id, only used for emitting settle event. Can pass in zero to skip emitting event
    /// @return result          Swap result
    function swap(
        Pool storage pool,
        bool isToken0,
        int256 amtDesired,
        uint256 tierChoices,
        bytes32 poolId // only used for `Settle` event
    ) internal returns (SwapResult memory result) {
        lock(pool);
        Tiers.Tier[] memory tiers;
        TierState[MAX_TIERS] memory states;
        unchecked {
            // truncate tierChoices
            uint256 tiersCount = pool.tiers.length;
            uint256 maxTierChoices = (1 << tiersCount) - 1;
            tierChoices &= maxTierChoices;

            if (amtDesired == 0 || amtDesired == SwapMath.REJECTED) revert InvalidAmount();
            if (tierChoices == 0) revert InvalidTierChoices();

            // only load tiers that are allowed by users
            if (tierChoices == maxTierChoices) {
                tiers = pool.tiers;
            } else {
                tiers = new Tiers.Tier[](tiersCount);
                for (uint256 i; i < tiers.length; i++) {
                    if (tierChoices & (1 << i) != 0) tiers[i] = pool.tiers[i];
                }
            }
        }

        SwapCache memory cache = SwapCache({
            zeroForOne: isToken0 == (amtDesired > 0),
            exactIn: amtDesired > 0,
            protocolFee: pool.protocolFee,
            protocolFeeAmt: 0,
            tierChoices: tierChoices,
            tmCache: TickMath.Cache({tick: type(int24).max, sqrtP: 0}),
            amounts: _emptyInt256Array(),
            poolId: poolId
        });

        int256 initialAmtDesired = amtDesired;
        int256 amountA; // pool's balance change of the token which "amtDesired" refers to
        int256 amountB; // pool's balance change of the opposite token

        while (true) {
            // calculate the swap amount for each tier
            cache.amounts = cache.exactIn
                ? SwapMath.calcTierAmtsIn(tiers, isToken0, amtDesired, cache.tierChoices)
                : SwapMath.calcTierAmtsOut(tiers, isToken0, amtDesired, cache.tierChoices);

            // compute the swap for each tier
            for (uint256 i; i < tiers.length; ) {
                (int256 amtAStep, int256 amtBStep) = _swapStep(pool, isToken0, cache, states[i], tiers[i], i);
                amountA += amtAStep;
                amountB += amtBStep;
                unchecked {
                    i++;
                }
            }

            // check if we meet the stopping criteria
            amtDesired = initialAmtDesired - amountA;
            unchecked {
                if (
                    (cache.exactIn ? amtDesired <= SWAP_AMOUNT_TOLERANCE : amtDesired >= -SWAP_AMOUNT_TOLERANCE) ||
                    cache.tierChoices == 0
                ) break;
            }
        }

        result.protocolFeeAmt = cache.protocolFeeAmt;
        unchecked {
            (result.amountInDistribution, result.amountOutDistribution, result.tierData) = _updateTiers(
                pool,
                states,
                tiers,
                uint256(cache.exactIn ? amountA : amountB),
                uint256(cache.exactIn ? -amountB : -amountA)
            );
        }
        (result.amount0, result.amount1) = isToken0 ? (amountA, amountB) : (amountB, amountA);

        // BE AWARE the pool is locked. Please unlock it after token transfer is done.
    }

    function _swapStep(
        Pool storage pool,
        bool isToken0,
        SwapCache memory cache,
        TierState memory state,
        Tiers.Tier memory tier,
        uint256 tierId
    ) internal returns (int256 amtAStep, int256 amtBStep) {
        if (cache.amounts[tierId] == SwapMath.REJECTED) return (0, 0);

        // calculate sqrt price of the next tick
        if (state.sqrtPTick == 0)
            state.sqrtPTick = TickMath.tickToSqrtPriceMemoized(
                cache.tmCache,
                cache.zeroForOne ? tier.nextTickBelow : tier.nextTickAbove
            );

        unchecked {
            // calculate input & output amts, new sqrt price, and fee amt for this swap step
            uint256 feeAmtStep;
            (amtAStep, amtBStep, tier.sqrtPrice, feeAmtStep) = SwapMath.computeStep(
                isToken0,
                cache.exactIn,
                cache.amounts[tierId],
                tier.sqrtPrice,
                state.sqrtPTick,
                tier.liquidity,
                tier.sqrtGamma
            );
            if (amtAStep == SwapMath.REJECTED) return (0, 0);

            // cache input & output amounts for later event logging (locally)
            if (cache.exactIn) {
                state.amountIn += uint256(amtAStep);
                state.amountOut += uint256(-amtBStep);
            } else {
                state.amountIn += uint256(amtBStep);
                state.amountOut += uint256(-amtAStep);
            }

            // update protocol fee amt (locally)
            uint256 protocolFeeAmt = (feeAmtStep * cache.protocolFee) / type(uint8).max;
            cache.protocolFeeAmt += protocolFeeAmt;
            feeAmtStep -= protocolFeeAmt;

            // update fee growth (locally) (realistically assume feeAmtStep < 2**192)
            uint80 feeGrowth = uint80((feeAmtStep << 64) / tier.liquidity);
            if (cache.zeroForOne) {
                tier.feeGrowthGlobal0 += feeGrowth;
            } else {
                tier.feeGrowthGlobal1 += feeGrowth;
            }
        }

        // handle cross tick, which updates a tick state
        if (tier.sqrtPrice == state.sqrtPTick) {
            int24 tickCross = cache.zeroForOne ? tier.nextTickBelow : tier.nextTickAbove;

            // skip crossing tick if reaches the end of the supported price range
            if (tickCross == TickMath.MIN_TICK || tickCross == TickMath.MAX_TICK) {
                cache.tierChoices &= ~(1 << tierId);
                return (amtAStep, amtBStep);
            }

            // clear cached tick price, so as to calculate a new one in next loop
            state.sqrtPTick = 0;
            state.crossed = true;

            // flip the direction of tick's data (effect)
            Ticks.Tick storage cross = pool.ticks[tierId][tickCross];
            cross.flip(tier.feeGrowthGlobal0, tier.feeGrowthGlobal1);
            unchecked {
                // update tier's liquidity and next ticks (locally)
                (uint128 liqLowerD8, uint128 liqUpperD8) = (cross.liquidityLowerD8, cross.liquidityUpperD8);
                if (cache.zeroForOne) {
                    tier.liquidity = tier.liquidity + (liqUpperD8 << 8) - (liqLowerD8 << 8);
                    tier.nextTickBelow = cross.nextBelow;
                    tier.nextTickAbove = tickCross;
                } else {
                    tier.liquidity = tier.liquidity + (liqLowerD8 << 8) - (liqUpperD8 << 8);
                    tier.nextTickBelow = tickCross;
                    tier.nextTickAbove = cross.nextAbove;
                }
            }

            // settle single-sided positions (i.e. filled limit orders) if neccessary
            if (cache.zeroForOne ? cross.needSettle0 : cross.needSettle1) {
                (int24 tickStart, uint96 liquidityD8Settled) = Settlement.settle(
                    pool.settlements[tierId],
                    pool.ticks[tierId],
                    pool.tickMaps[tierId],
                    tier,
                    tickCross,
                    cache.zeroForOne
                );
                if (cache.poolId != 0) {
                    emit Settle(cache.poolId, uint8(tierId), tickCross, tickStart, liquidityD8Settled);
                }
            }
        }
    }

    /// @dev Apply the post-swap data changes from memory to storage, also prepare data for event logging
    function _updateTiers(
        Pool storage pool,
        TierState[MAX_TIERS] memory states,
        Tiers.Tier[] memory tiers,
        uint256 amtIn,
        uint256 amtOut
    )
        internal
        returns (
            uint256 amtInDistribution,
            uint256 amtOutDistribution,
            uint256[] memory tierData
        )
    {
        tierData = new uint256[](tiers.length);
        unchecked {
            bool amtInNoOverflow = amtIn < (1 << (256 - AMOUNT_DISTRIBUTION_RESOLUTION));
            bool amtOutNoOverflow = amtOut < (1 << (256 - AMOUNT_DISTRIBUTION_RESOLUTION));

            for (uint256 i; i < tiers.length; i++) {
                TierState memory state = states[i];
                // we can safely assume tier data is unchanged when there's zero input amount and no crossing tick,
                // since we would have rejected the tier if such case happened.
                if (state.amountIn > 0 || state.crossed) {
                    Tiers.Tier memory tier = tiers[i];
                    // calculate current tick:
                    // if tier's price is equal to tick's price (let say the tick is T), the tier is expected to be in
                    // the upper tick space [T, T+1]. Only if the tier's next upper crossing tick is T, the tier is in
                    // the lower tick space [T-1, T].
                    tier.tick = TickMath.sqrtPriceToTick(tier.sqrtPrice);
                    if (tier.tick == tier.nextTickAbove) tier.tick--;

                    pool.tiers[i] = tier;

                    // prepare data for logging
                    tierData[i] = (uint256(tier.sqrtPrice) << 128) | tier.liquidity;
                    if (amtIn > 0) {
                        amtInDistribution |= (
                            amtInNoOverflow
                                ? (state.amountIn << AMOUNT_DISTRIBUTION_RESOLUTION) / amtIn
                                : state.amountIn / ((amtIn >> AMOUNT_DISTRIBUTION_RESOLUTION) + 1)
                        ) << (i * AMOUNT_DISTRIBUTION_BITS); // prettier-ignore
                    }
                    if (amtOut > 0) {
                        amtOutDistribution |= (
                            amtOutNoOverflow
                                ? (state.amountOut << AMOUNT_DISTRIBUTION_RESOLUTION) / amtOut
                                : state.amountOut / ((amtOut >> AMOUNT_DISTRIBUTION_RESOLUTION) + 1)
                        ) << (i * AMOUNT_DISTRIBUTION_BITS); // prettier-ignore
                    }
                }
            }
        }
    }

    function _emptyInt256Array() internal pure returns (int256[MAX_TIERS] memory) {}

    /*===============================================================
     *                      UPDATE LIQUIDITY
     *==============================================================*/

    function _checkTickInputs(int24 tickLower, int24 tickUpper) internal pure {
        if (tickLower >= tickUpper || TickMath.MIN_TICK > tickLower || tickUpper > TickMath.MAX_TICK) {
            revert InvalidTick();
        }
    }

    /// @notice                 Update a position's liquidity
    /// @param owner            Address of the position owner
    /// @param positionRefId    Reference id of the position
    /// @param tierId           Tier index of the position
    /// @param tickLower        Lower tick boundary of the position
    /// @param tickUpper        Upper tick boundary of the position
    /// @param liquidityDeltaD8 Amount of liquidity change, divided by 2^8
    /// @param collectAllFees   True to collect all remaining accrued fees of the position
    function updateLiquidity(
        Pool storage pool,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        int96 liquidityDeltaD8,
        bool collectAllFees
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmtOut0,
            uint256 feeAmtOut1
        )
    {
        lock(pool);
        _checkTickInputs(tickLower, tickUpper);
        if (liquidityDeltaD8 > 0) {
            if (tickLower % int24(uint24(pool.tickSpacing)) != 0) revert InvalidTick();
            if (tickUpper % int24(uint24(pool.tickSpacing)) != 0) revert InvalidTick();
        }
        // -------------------- UPDATE LIQUIDITY --------------------
        {
            // update current liquidity if in-range
            Tiers.Tier storage tier = pool.tiers[tierId];
            if (tickLower <= tier.tick && tier.tick < tickUpper)
                tier.liquidity = tier.liquidity.addInt128(int128(liquidityDeltaD8) << 8);
        }
        // --------------------- UPDATE TICKS -----------------------
        {
            bool initialized;
            initialized = _updateTick(pool, tierId, tickLower, liquidityDeltaD8, true);
            initialized = _updateTick(pool, tierId, tickUpper, liquidityDeltaD8, false) || initialized;
            if (initialized) {
                Tiers.Tier storage tier = pool.tiers[tierId];
                tier.updateNextTick(tickLower);
                tier.updateNextTick(tickUpper);
            }
        }
        // -------------------- UPDATE POSITION ---------------------
        (feeAmtOut0, feeAmtOut1) = _updatePosition(
            pool,
            owner,
            positionRefId,
            tierId,
            tickLower,
            tickUpper,
            liquidityDeltaD8,
            collectAllFees
        );
        // -------------------- CLEAN UP TICKS ----------------------
        if (liquidityDeltaD8 < 0) {
            bool deleted;
            deleted = _deleteEmptyTick(pool, tierId, tickLower);
            deleted = _deleteEmptyTick(pool, tierId, tickUpper) || deleted;

            // reset tier's next ticks if any ticks deleted
            if (deleted) {
                Tiers.Tier storage tier = pool.tiers[tierId];
                int24 below = TickMaps.nextBelow(pool.tickMaps[tierId], tier.tick + 1);
                int24 above = pool.ticks[tierId][below].nextAbove;
                tier.nextTickBelow = below;
                tier.nextTickAbove = above;
            }
        }
        // -------------------- TOKEN AMOUNTS -----------------------
        // calculate input and output amount for the liquidity change
        if (liquidityDeltaD8 != 0)
            (amount0, amount1) = PoolMath.calcAmtsForLiquidity(
                pool.tiers[tierId].sqrtPrice,
                TickMath.tickToSqrtPrice(tickLower),
                TickMath.tickToSqrtPrice(tickUpper),
                liquidityDeltaD8
            );

        // BE AWARE the pool is locked. Please unlock it after token transfer is done.
    }

    /*===============================================================
     *                    TICKS (UPDATE LIQUIDITY)
     *==============================================================*/

    function _updateTick(
        Pool storage pool,
        uint8 tierId,
        int24 tick,
        int96 liquidityDeltaD8,
        bool isLower
    ) internal returns (bool initialized) {
        mapping(int24 => Ticks.Tick) storage ticks = pool.ticks[tierId];
        Ticks.Tick storage obj = ticks[tick];

        if (obj.liquidityLowerD8 == 0 && obj.liquidityUpperD8 == 0) {
            // initialize tick if adding liquidity to empty tick
            if (liquidityDeltaD8 > 0) {
                TickMaps.TickMap storage tickMap = pool.tickMaps[tierId];
                int24 below = tickMap.nextBelow(tick);
                int24 above = ticks[below].nextAbove;
                obj.nextBelow = below;
                obj.nextAbove = above;
                ticks[below].nextAbove = tick;
                ticks[above].nextBelow = tick;

                tickMap.set(tick);
                initialized = true;
            }

            // assume past fees and reward were generated _below_ the current tick
            Tiers.Tier storage tier = pool.tiers[tierId];
            if (tick <= tier.tick) {
                obj.feeGrowthOutside0 = tier.feeGrowthGlobal0;
                obj.feeGrowthOutside1 = tier.feeGrowthGlobal1;
            }
        }

        // update liquidity
        if (isLower) {
            obj.liquidityLowerD8 = obj.liquidityLowerD8.addInt96(liquidityDeltaD8);
        } else {
            obj.liquidityUpperD8 = obj.liquidityUpperD8.addInt96(liquidityDeltaD8);
        }
    }

    function _deleteEmptyTick(
        Pool storage pool,
        uint8 tierId,
        int24 tick
    ) internal returns (bool deleted) {
        mapping(int24 => Ticks.Tick) storage ticks = pool.ticks[tierId];
        Ticks.Tick storage obj = ticks[tick];

        if (obj.liquidityLowerD8 == 0 && obj.liquidityUpperD8 == 0) {
            assert(tick != TickMath.MIN_TICK && tick != TickMath.MAX_TICK);
            int24 below = obj.nextBelow;
            int24 above = obj.nextAbove;
            ticks[below].nextAbove = above;
            ticks[above].nextBelow = below;
            delete ticks[tick];
            pool.tickMaps[tierId].unset(tick);
            deleted = true;
        }
    }

    /*===============================================================
     *                   POSITION (UPDATE LIQUIDITY)
     *==============================================================*/

    function _getFeeGrowthInside(
        Pool storage pool,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint80 feeGrowthInside0, uint80 feeGrowthInside1) {
        Ticks.Tick storage upper = pool.ticks[tierId][tickUpper];
        Ticks.Tick storage lower = pool.ticks[tierId][tickLower];
        Tiers.Tier storage tier = pool.tiers[tierId];
        int24 tickCurrent = tier.tick;

        unchecked {
            if (tickCurrent < tickLower) {
                // current price below range
                feeGrowthInside0 = lower.feeGrowthOutside0 - upper.feeGrowthOutside0;
                feeGrowthInside1 = lower.feeGrowthOutside1 - upper.feeGrowthOutside1;
            } else if (tickCurrent >= tickUpper) {
                // current price above range
                feeGrowthInside0 = upper.feeGrowthOutside0 - lower.feeGrowthOutside0;
                feeGrowthInside1 = upper.feeGrowthOutside1 - lower.feeGrowthOutside1;
            } else {
                // current price in range
                feeGrowthInside0 = tier.feeGrowthGlobal0 - upper.feeGrowthOutside0 - lower.feeGrowthOutside0;
                feeGrowthInside1 = tier.feeGrowthGlobal1 - upper.feeGrowthOutside1 - lower.feeGrowthOutside1;
            }
        }
    }

    function _updatePosition(
        Pool storage pool,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        int96 liquidityDeltaD8,
        bool collectAllFees
    ) internal returns (uint256 feeAmtOut0, uint256 feeAmtOut1) {
        Positions.Position storage position = Positions.get(
            pool.positions,
            owner,
            positionRefId,
            tierId,
            tickLower,
            tickUpper
        );
        {
            // update position liquidity and accrue fees
            (uint80 feeGrowth0, uint80 feeGrowth1) = _getFeeGrowthInside(pool, tierId, tickLower, tickUpper);
            (feeAmtOut0, feeAmtOut1) = position.update(liquidityDeltaD8, feeGrowth0, feeGrowth1, collectAllFees);
        }

        // update settlement if position is an unsettled limit order
        if (position.limitOrderType != Positions.NOT_LIMIT_ORDER) {
            // passing a zero default tick spacing to here since the settlement state must be already initialized as
            // this position has been a limit order
            uint32 nextSnapshotId = Settlement.update(
                pool.settlements[tierId],
                pool.ticks[tierId],
                tickLower,
                tickUpper,
                position.limitOrderType,
                liquidityDeltaD8,
                0
            );

            // not allowed to update if already settled
            if (position.settlementSnapshotId != nextSnapshotId) revert PositionAlreadySettled();

            // reset position to normal if it is emptied
            if (position.liquidityD8 == 0) {
                position.limitOrderType = Positions.NOT_LIMIT_ORDER;
                position.settlementSnapshotId = 0;
            }
        }
    }

    /*===============================================================
     *                          LIMIT ORDER
     *==============================================================*/

    /// @notice Set (or unset) position to (or from) a limit order
    /// @dev It first unsets position from being a limit order (if it is), then set position to a new limit order type
    function setLimitOrderType(
        Pool storage pool,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint8 limitOrderType
    ) internal {
        require(pool.unlocked);
        require(limitOrderType <= Positions.ONE_FOR_ZERO);
        _checkTickInputs(tickLower, tickUpper);

        Positions.Position storage position = Positions.get(
            pool.positions,
            owner,
            positionRefId,
            tierId,
            tickLower,
            tickUpper
        );
        uint16 defaultTickSpacing = uint16(pool.tickSpacing) * pool.limitOrderTickSpacingMultipliers[tierId];

        // unset position to normal type
        if (position.limitOrderType != Positions.NOT_LIMIT_ORDER) {
            (uint32 nextSnapshotId, ) = Settlement.update(
                pool.settlements[tierId],
                pool.ticks[tierId],
                tickLower,
                tickUpper,
                position.limitOrderType,
                position.liquidityD8,
                false,
                defaultTickSpacing
            );

            // not allowed to update if already settled
            if (position.settlementSnapshotId != nextSnapshotId) revert PositionAlreadySettled();

            // unset to normal
            position.limitOrderType = Positions.NOT_LIMIT_ORDER;
            position.settlementSnapshotId = 0;
        }

        // set position to limit order
        if (limitOrderType != Positions.NOT_LIMIT_ORDER) {
            if (position.liquidityD8 == 0) revert NoLiquidityForLimitOrder();
            (uint32 nextSnapshotId, uint16 tickSpacing) = Settlement.update(
                pool.settlements[tierId],
                pool.ticks[tierId],
                tickLower,
                tickUpper,
                limitOrderType,
                position.liquidityD8,
                true,
                defaultTickSpacing
            );

            // ensure position has a correct tick range for limit order
            if (uint24(tickUpper - tickLower) != tickSpacing) revert InvalidTickRangeForLimitOrder();

            // set to limit order
            position.limitOrderType = limitOrderType;
            position.settlementSnapshotId = nextSnapshotId;
        }
    }

    /// @notice Collect tokens from a settled position. Reset to normal position if all tokens are collected
    /// @dev We only need to update position state. No need to remove any active liquidity from tier or update upper or
    /// lower tick states as these have already been done when settling these positions during a swap
    function collectSettled(
        Pool storage pool,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint96 liquidityD8,
        bool collectAllFees
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmtOut0,
            uint256 feeAmtOut1
        )
    {
        lock(pool);
        _checkTickInputs(tickLower, tickUpper);

        Positions.Position storage position = Positions.get(
            pool.positions,
            owner,
            positionRefId,
            tierId,
            tickLower,
            tickUpper
        );

        {
            // ensure it's a settled limit order, and get data snapshot
            (bool settled, Settlement.Snapshot memory snapshot) = Settlement.getSnapshot(
                pool.settlements[tierId],
                position,
                tickLower,
                tickUpper
            );
            if (!settled) revert PositionNotSettled();

            // update position using snapshotted data
            (feeAmtOut0, feeAmtOut1) = position.update(
                -liquidityD8.toInt96(),
                snapshot.feeGrowthInside0,
                snapshot.feeGrowthInside1,
                collectAllFees
            );
        }

        // calculate output amounts using the price where settlement was done
        uint128 sqrtPriceLower = TickMath.tickToSqrtPrice(tickLower);
        uint128 sqrtPriceUpper = TickMath.tickToSqrtPrice(tickUpper);
        (amount0, amount1) = PoolMath.calcAmtsForLiquidity(
            position.limitOrderType == Positions.ZERO_FOR_ONE ? sqrtPriceUpper : sqrtPriceLower,
            sqrtPriceLower,
            sqrtPriceUpper,
            -liquidityD8.toInt96()
        );

        // reset position to normal if it is emptied
        if (position.liquidityD8 == 0) {
            position.limitOrderType = Positions.NOT_LIMIT_ORDER;
            position.settlementSnapshotId = 0;
        }

        // BE AWARE the pool is locked. Please unlock it after token transfer is done.
    }

    /*===============================================================
     *                        VIEW FUNCTIONS
     *==============================================================*/

    function getPositionFeeGrowthInside(
        Pool storage pool,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint80 feeGrowthInside0, uint80 feeGrowthInside1) {
        if (owner != address(0)) {
            (bool settled, Settlement.Snapshot memory snapshot) = Settlement.getSnapshot(
                pool.settlements[tierId],
                Positions.get(pool.positions, owner, positionRefId, tierId, tickLower, tickUpper),
                tickLower,
                tickUpper
            );
            if (settled) return (snapshot.feeGrowthInside0, snapshot.feeGrowthInside1);
        }
        return _getFeeGrowthInside(pool, tierId, tickLower, tickUpper);
    }

    /// @dev Convert fixed-sized array to dynamic-sized
    function getLimitOrderTickSpacingMultipliers(Pool storage pool) internal view returns (uint8[] memory multipliers) {
        uint8[MAX_TIERS] memory ms = pool.limitOrderTickSpacingMultipliers;
        multipliers = new uint8[](pool.tiers.length);
        unchecked {
            for (uint256 i; i < multipliers.length; i++) multipliers[i] = ms[i];
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/hub/IMuffinHub.sol";
import "./interfaces/IMuffinHubCallbacks.sol";
import "./libraries/utils/SafeTransferLib.sol";
import "./libraries/utils/PathLib.sol";
import "./libraries/math/Math.sol";
import "./libraries/Pools.sol";
import "./MuffinHubBase.sol";

contract MuffinHub is IMuffinHub, MuffinHubBase {
    using Math for uint256;
    using Pools for Pools.Pool;
    using Pools for mapping(bytes32 => Pools.Pool);
    using PathLib for bytes;

    error InvalidTokenOrder();
    error NotAllowedSqrtGamma();
    error InvalidSwapPath();
    error NotEnoughIntermediateOutput();
    error NotEnoughFundToWithdraw();

    /// @dev To reduce bytecode size of this contract, we offload position-related functions, governance functions and
    /// various view functions to a second contract (i.e. MuffinHubPositions.sol) and use delegatecall to call it.
    address internal immutable positionController;

    constructor(address _positionController) {
        positionController = _positionController;
        governance = msg.sender;
    }

    /*===============================================================
     *                           ACCOUNTS
     *==============================================================*/

    /// @inheritdoc IMuffinHubActions
    function deposit(
        address recipient,
        uint256 recipientAccRefId,
        address token,
        uint256 amount,
        bytes calldata data
    ) external {
        uint256 balanceBefore = getBalanceAndLock(token);
        IMuffinHubCallbacks(msg.sender).muffinDepositCallback(token, amount, data);
        checkBalanceAndUnlock(token, balanceBefore + amount);

        accounts[token][getAccHash(recipient, recipientAccRefId)] += amount;
        emit Deposit(recipient, recipientAccRefId, token, amount, msg.sender);
    }

    /// @inheritdoc IMuffinHubActions
    function withdraw(
        address recipient,
        uint256 senderAccRefId,
        address token,
        uint256 amount
    ) external {
        bytes32 accHash = getAccHash(msg.sender, senderAccRefId);
        uint256 balance = accounts[token][accHash];
        if (balance < amount) revert NotEnoughFundToWithdraw();
        unchecked {
            accounts[token][accHash] = balance - amount;
        }
        SafeTransferLib.safeTransfer(token, recipient, amount);
        emit Withdraw(msg.sender, senderAccRefId, token, amount, recipient);
    }

    /*===============================================================
     *                      CREATE POOL / TIER
     *==============================================================*/

    /// @notice Check if the given sqrtGamma is allowed to be used to create a pool or tier
    /// @dev It first checks if the sqrtGamma is in the whitelist, then check if the pool hasn't had that fee tier created.
    function isSqrtGammaAllowed(bytes32 poolId, uint24 sqrtGamma) public view returns (bool) {
        uint24[] storage allowed = poolAllowedSqrtGammas[poolId].length != 0
            ? poolAllowedSqrtGammas[poolId]
            : defaultAllowedSqrtGammas;
        unchecked {
            for (uint256 i; i < allowed.length; i++) {
                if (allowed[i] == sqrtGamma) {
                    Tiers.Tier[] storage tiers = pools[poolId].tiers;
                    for (uint256 j; j < tiers.length; j++) if (tiers[j].sqrtGamma == sqrtGamma) return false;
                    return true;
                }
            }
        }
        return false;
    }

    /// @inheritdoc IMuffinHubActions
    function createPool(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint128 sqrtPrice,
        uint256 senderAccRefId
    ) external returns (bytes32 poolId) {
        if (token0 >= token1 || token0 == address(0)) revert InvalidTokenOrder();

        Pools.Pool storage pool;
        (pool, poolId) = pools.getPoolAndId(token0, token1);
        if (!isSqrtGammaAllowed(poolId, sqrtGamma)) revert NotAllowedSqrtGamma();

        uint8 tickSpacing = poolDefaultTickSpacing[poolId];
        if (tickSpacing == 0) tickSpacing = defaultTickSpacing;
        (uint256 amount0, uint256 amount1) = pool.initialize(sqrtGamma, sqrtPrice, tickSpacing, defaultProtocolFee);
        accounts[token0][getAccHash(msg.sender, senderAccRefId)] -= amount0;
        accounts[token1][getAccHash(msg.sender, senderAccRefId)] -= amount1;

        emit PoolCreated(token0, token1, poolId);
        emit UpdateTier(poolId, 0, sqrtGamma, sqrtPrice, 1);
        pool.unlock();
        underlyings[poolId] = Pair(token0, token1);
    }

    /// @inheritdoc IMuffinHubActions
    function addTier(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint256 senderAccRefId
    ) external returns (uint8 tierId) {
        (Pools.Pool storage pool, bytes32 poolId) = pools.getPoolAndId(token0, token1);
        if (!isSqrtGammaAllowed(poolId, sqrtGamma)) revert NotAllowedSqrtGamma();

        uint256 amount0;
        uint256 amount1;
        (amount0, amount1, tierId) = pool.addTier(sqrtGamma);
        accounts[token0][getAccHash(msg.sender, senderAccRefId)] -= amount0;
        accounts[token1][getAccHash(msg.sender, senderAccRefId)] -= amount1;

        emit UpdateTier(poolId, tierId, sqrtGamma, pool.tiers[tierId].sqrtPrice, 0);
        pool.unlock();
    }

    /*===============================================================
     *                            SWAP
     *==============================================================*/

    /// @inheritdoc IMuffinHubActions
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired,
        address recipient,
        uint256 recipientAccRefId,
        uint256 senderAccRefId,
        bytes calldata data
    ) external returns (uint256 amountIn, uint256 amountOut) {
        Pools.Pool storage pool;
        (pool, , amountIn, amountOut) = _computeSwap(
            tokenIn,
            tokenOut,
            tierChoices,
            amountDesired,
            SwapEventVars(senderAccRefId, recipient, recipientAccRefId)
        );
        _transferSwap(tokenIn, tokenOut, amountIn, amountOut, recipient, recipientAccRefId, senderAccRefId, data);
        pool.unlock();
    }

    /// @inheritdoc IMuffinHubActions
    function swapMultiHop(SwapMultiHopParams calldata p) external returns (uint256 amountIn, uint256 amountOut) {
        bytes memory path = p.path;
        if (path.invalid()) revert InvalidSwapPath();

        bool exactIn = p.amountDesired > 0;
        bytes32[] memory poolIds = new bytes32[](path.hopCount());
        unchecked {
            int256 amtDesired = p.amountDesired;
            SwapEventVars memory evtData = exactIn
                ? SwapEventVars(p.senderAccRefId, msg.sender, p.senderAccRefId)
                : SwapEventVars(p.senderAccRefId, p.recipient, p.recipientAccRefId);

            for (uint256 i; i < poolIds.length; i++) {
                if (exactIn) {
                    if (i == poolIds.length - 1) {
                        evtData.recipient = p.recipient;
                        evtData.recipientAccRefId = p.recipientAccRefId;
                    }
                } else {
                    if (i == 1) {
                        evtData.recipient = msg.sender;
                        evtData.recipientAccRefId = p.senderAccRefId;
                    }
                }

                (address tokenIn, address tokenOut, uint256 tierChoices) = path.decodePool(i, exactIn);

                // For an "exact output" swap, it's possible to not receive the full desired output amount. therefore, in
                // the 2nd (and following) swaps, we request more token output so as to ensure we get enough tokens to pay
                // for the previous swap. The extra token is not refunded and thus results in an extra cost (small in common
                // token pairs).
                uint256 amtIn;
                uint256 amtOut;
                (, poolIds[i], amtIn, amtOut) = _computeSwap(
                    tokenIn,
                    tokenOut,
                    tierChoices,
                    (exactIn || i == 0) ? amtDesired : amtDesired - Pools.SWAP_AMOUNT_TOLERANCE,
                    evtData
                );

                if (exactIn) {
                    if (i == 0) amountIn = amtIn;
                    amtDesired = int256(amtOut);
                } else {
                    if (i == 0) amountOut = amtOut;
                    else if (amtOut < uint256(-amtDesired)) revert NotEnoughIntermediateOutput();
                    amtDesired = -int256(amtIn);
                }
            }
            if (exactIn) {
                amountOut = uint256(amtDesired);
            } else {
                amountIn = uint256(-amtDesired);
            }
        }
        (address _tokenIn, address _tokenOut) = path.tokensInOut(exactIn);
        _transferSwap(_tokenIn, _tokenOut, amountIn, amountOut, p.recipient, p.recipientAccRefId, p.senderAccRefId, p.data);
        unchecked {
            for (uint256 i; i < poolIds.length; i++) pools[poolIds[i]].unlock();
        }
    }

    /// @dev Data to emit in "Swap" event in "_computeSwap" function
    struct SwapEventVars {
        uint256 senderAccRefId;
        address recipient;
        uint256 recipientAccRefId;
    }

    function _computeSwap(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired, // Desired swap amount (positive: exact input, negative: exact output)
        SwapEventVars memory evtData
    )
        internal
        returns (
            Pools.Pool storage pool,
            bytes32 poolId,
            uint256 amountIn,
            uint256 amountOut
        )
    {
        bool isExactIn = tokenIn < tokenOut;
        bool isToken0 = (amountDesired > 0) == isExactIn; // i.e. isToken0In == isExactIn
        (pool, poolId) = isExactIn ? pools.getPoolAndId(tokenIn, tokenOut) : pools.getPoolAndId(tokenOut, tokenIn);
        Pools.SwapResult memory result = pool.swap(isToken0, amountDesired, tierChoices, poolId);

        emit Swap(
            poolId,
            msg.sender,
            evtData.recipient,
            evtData.senderAccRefId,
            evtData.recipientAccRefId,
            result.amount0,
            result.amount1,
            result.amountInDistribution,
            result.amountOutDistribution,
            result.tierData
        );

        unchecked {
            // overflow is acceptable and protocol is expected to collect protocol fee before overflow
            if (result.protocolFeeAmt != 0) tokens[tokenIn].protocolFeeAmt += uint248(result.protocolFeeAmt);
            (amountIn, amountOut) = isExactIn
                ? (uint256(result.amount0), uint256(-result.amount1))
                : (uint256(result.amount1), uint256(-result.amount0));
        }
    }

    function _transferSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address recipient,
        uint256 recipientAccRefId,
        uint256 senderAccRefId,
        bytes calldata data
    ) internal {
        if (tokenIn == tokenOut) {
            (amountIn, amountOut) = amountIn.subUntilZero(amountOut);
        }
        if (recipientAccRefId == 0) {
            SafeTransferLib.safeTransfer(tokenOut, recipient, amountOut);
        } else {
            accounts[tokenOut][getAccHash(recipient, recipientAccRefId)] += amountOut;
        }
        if (senderAccRefId != 0) {
            bytes32 accHash = getAccHash(msg.sender, senderAccRefId);
            (accounts[tokenIn][accHash], amountIn) = accounts[tokenIn][accHash].subUntilZero(amountIn);
        }
        if (amountIn > 0) {
            uint256 balanceBefore = getBalanceAndLock(tokenIn);
            IMuffinHubCallbacks(msg.sender).muffinSwapCallback(tokenIn, tokenOut, amountIn, amountOut, data);
            checkBalanceAndUnlock(tokenIn, balanceBefore + amountIn);
        }
    }

    /*===============================================================
     *                         VIEW FUNCTIONS
     *==============================================================*/

    /// @inheritdoc IMuffinHubView
    function getDefaultParameters() external view returns (uint8 tickSpacing, uint8 protocolFee) {
        return (defaultTickSpacing, defaultProtocolFee);
    }

    /// @inheritdoc IMuffinHubView
    function getPoolParameters(bytes32 poolId) external view returns (uint8 tickSpacing, uint8 protocolFee) {
        Pools.Pool storage pool = pools[poolId];
        return (pool.tickSpacing, pool.protocolFee);
    }

    /// @inheritdoc IMuffinHubView
    function getTier(bytes32 poolId, uint8 tierId) external view returns (Tiers.Tier memory) {
        return pools[poolId].tiers[tierId];
    }

    /// @inheritdoc IMuffinHubView
    function getTiersCount(bytes32 poolId) external view returns (uint256) {
        return pools[poolId].tiers.length;
    }

    /// @inheritdoc IMuffinHubView
    function getTick(
        bytes32 poolId,
        uint8 tierId,
        int24 tick
    ) external view returns (Ticks.Tick memory) {
        return pools[poolId].ticks[tierId][tick];
    }

    /// @inheritdoc IMuffinHubView
    function getPosition(
        bytes32 poolId,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (Positions.Position memory) {
        return Positions.get(pools[poolId].positions, owner, positionRefId, tierId, tickLower, tickUpper);
    }

    /// @inheritdoc IMuffinHubView
    function getStorageAt(bytes32 slot) external view returns (bytes32 word) {
        assembly {
            word := sload(slot)
        }
    }

    /*===============================================================
     *                FALLBACK TO POSITION CONTROLLER
     *==============================================================*/

    /// @dev Adapted from openzepplin v4.4.1 proxy implementation
    fallback() external {
        address _positionController = positionController;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _positionController, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./FullMath.sol";
import "./PoolMath.sol";
import "./UnsafeMath.sol";
import "./Math.sol";
import "../Tiers.sol";

/// @dev Technically maximum number of fee tiers per pool.
/// @dev Declared at file level so other libraries/contracts can use it to define fixed-size array.
uint256 constant MAX_TIERS = 6;

library SwapMath {
    using Math for uint256;
    using Math for int256;

    int256 internal constant REJECTED = type(int256).max; // represents the tier is rejected for the swap
    int256 private constant MAX_UINT_DIV_1E10 = 0x6DF37F675EF6EADF5AB9A2072D44268D97DF837E6748956E5C6C2117;
    uint256 private constant Q72 = 0x1000000000000000000;

    /// @notice Given a set of tiers and the desired input amount, calculate the optimized input amount for each tier
    /// @param tiers        List of tiers
    /// @param isToken0     True if "amount" refers to token0
    /// @param amount       Desired input amount of the swap (must be positive)
    /// @param tierChoices  Bitmap to allow which tiers to swap
    /// @return amts        Optimized input amounts for tiers
    function calcTierAmtsIn(
        Tiers.Tier[] memory tiers,
        bool isToken0,
        int256 amount,
        uint256 tierChoices
    ) internal pure returns (int256[MAX_TIERS] memory amts) {
        assert(amount > 0);
        uint256[MAX_TIERS] memory lsg; // array of liquidity divided by sqrt gamma (UQ128)
        uint256[MAX_TIERS] memory res; // array of token reserve divided by gamma (UQ200)
        uint256 num; //    numerator of sqrt lambda (sum of UQ128)
        uint256 denom; //  denominator of sqrt lambda (sum of UQ200 + amount)

        unchecked {
            for (uint256 i; i < tiers.length; i++) {
                // reject unselected tiers
                if (tierChoices & (1 << i) == 0) {
                    amts[i] = REJECTED;
                    continue;
                }
                // calculate numerator and denominator of sqrt lamdba (lagrange multiplier)
                Tiers.Tier memory t = tiers[i];
                uint256 liquidity = uint256(t.liquidity);
                uint24 sqrtGamma = t.sqrtGamma;
                num += (lsg[i] = UnsafeMath.ceilDiv(liquidity * 1e5, sqrtGamma));
                denom += (res[i] = isToken0
                    ? UnsafeMath.ceilDiv(liquidity * Q72 * 1e10, uint256(t.sqrtPrice) * sqrtGamma * sqrtGamma)
                    : UnsafeMath.ceilDiv(liquidity * t.sqrtPrice, (Q72 * sqrtGamma * sqrtGamma) / 1e10));
            }
        }
        denom += uint256(amount);

        unchecked {
            // calculate input amts, then reject the tiers with negative input amts.
            // repeat until all input amts are non-negative
            uint256 product = denom * num;
            bool wontOverflow = (product / denom == num) && (product <= uint256(type(int256).max));
            for (uint256 i; i < tiers.length; ) {
                if (amts[i] != REJECTED) {
                    if (
                        (amts[i] = (
                            wontOverflow
                                ? int256((denom * lsg[i]) / num)
                                : FullMath.mulDiv(denom, lsg[i], num).toInt256()
                        ).sub(int256(res[i]))) < 0
                    ) {
                        amts[i] = REJECTED;
                        num -= lsg[i];
                        denom -= res[i];
                        i = 0;
                        continue;
                    }
                }
                i++;
            }
        }
    }

    /// @notice Given a set of tiers and the desired output amount, calculate the optimized output amount for each tier
    /// @param tiers        List of tiers
    /// @param isToken0     True if "amount" refers to token0
    /// @param amount       Desired output amount of the swap (must be negative)
    /// @param tierChoices  Bitmap to allow which tiers to swap
    /// @return amts        Optimized output amounts for tiers
    function calcTierAmtsOut(
        Tiers.Tier[] memory tiers,
        bool isToken0,
        int256 amount,
        uint256 tierChoices
    ) internal pure returns (int256[MAX_TIERS] memory amts) {
        assert(amount < 0);
        uint256[MAX_TIERS] memory lsg; // array of liquidity divided by sqrt fee (UQ128)
        uint256[MAX_TIERS] memory res; // array of token reserve (UQ200)
        uint256 num; //   numerator of sqrt lambda (sum of UQ128)
        int256 denom; //  denominator of sqrt lambda (sum of UQ200 - amount)

        unchecked {
            for (uint256 i; i < tiers.length; i++) {
                // reject unselected tiers
                if (tierChoices & (1 << i) == 0) {
                    amts[i] = REJECTED;
                    continue;
                }
                // calculate numerator and denominator of sqrt lamdba (lagrange multiplier)
                Tiers.Tier memory t = tiers[i];
                uint256 liquidity = uint256(t.liquidity);
                num += (lsg[i] = (liquidity * 1e5) / t.sqrtGamma);
                denom += int256(res[i] = isToken0 ? (liquidity << 72) / t.sqrtPrice : (liquidity * t.sqrtPrice) >> 72);
            }
        }
        denom += amount;

        unchecked {
            // calculate output amts, then reject the tiers with positive output amts.
            // repeat until all output amts are non-positive
            for (uint256 i; i < tiers.length; ) {
                if (amts[i] != REJECTED) {
                    if ((amts[i] = _ceilMulDiv(denom, lsg[i], num).sub(int256(res[i]))) > 0) {
                        amts[i] = REJECTED;
                        num -= lsg[i];
                        denom -= int256(res[i]);
                        i = 0;
                        continue;
                    }
                }
                i++;
            }
        }
    }

    function _ceilMulDiv(
        int256 x,
        uint256 y,
        uint256 denom
    ) internal pure returns (int256 z) {
        unchecked {
            z = x < 0
                ? -FullMath.mulDiv(uint256(-x), y, denom).toInt256()
                : FullMath.mulDivRoundingUp(uint256(x), y, denom).toInt256();
        }
    }

    /// @dev Calculate a single swap step. We process the swap as much as possible until the tier's price hits the next tick.
    /// @param isToken0     True if "amount" refers to token0
    /// @param exactIn      True if the swap is specified with an input token amount (instead of an output)
    /// @param amount       The swap amount (positive: token in; negative token out)
    /// @param sqrtP        The sqrt price currently
    /// @param sqrtPTick    The sqrt price of the next crossing tick
    /// @param liquidity    The current liqudity amount
    /// @param sqrtGamma    The sqrt of (1 - percentage swap fee) (precision: 1e5)
    /// @return amtA        The delta of the pool's tokenA balance (tokenA means token0 if `isToken0` is true, vice versa)
    /// @return amtB        The delta of the pool's tokenB balance (tokenB means the opposite token of tokenA)
    /// @return sqrtPNew    The new sqrt price after the swap
    /// @return feeAmt      The fee amount charged for this swap
    function computeStep(
        bool isToken0,
        bool exactIn,
        int256 amount,
        uint128 sqrtP,
        uint128 sqrtPTick,
        uint128 liquidity,
        uint24 sqrtGamma
    )
        internal
        pure
        returns (
            int256 amtA,
            int256 amtB,
            uint128 sqrtPNew,
            uint256 feeAmt
        )
    {
        unchecked {
            amtA = amount;
            int256 amtInExclFee; // i.e. input amt excluding fee

            // calculate amt needed to reach to the tick
            int256 amtTick = isToken0
                ? PoolMath.calcAmt0FromSqrtP(sqrtP, sqrtPTick, liquidity)
                : PoolMath.calcAmt1FromSqrtP(sqrtP, sqrtPTick, liquidity);

            // calculate percentage fee (precision: 1e10)
            uint256 gamma = uint256(sqrtGamma) * sqrtGamma;

            if (exactIn) {
                // amtA: the input amt (positive)
                // amtB: the output amt (negative)

                // calculate input amt excluding fee
                amtInExclFee = amtA < MAX_UINT_DIV_1E10
                    ? int256((uint256(amtA) * gamma) / 1e10)
                    : int256((uint256(amtA) / 1e10) * gamma);

                // check if crossing tick
                if (amtInExclFee < amtTick) {
                    // no cross tick: calculate new sqrt price after swap
                    sqrtPNew = isToken0
                        ? PoolMath.calcSqrtPFromAmt0(sqrtP, liquidity, amtInExclFee)
                        : PoolMath.calcSqrtPFromAmt1(sqrtP, liquidity, amtInExclFee);
                } else {
                    // cross tick: replace new sqrt price and input amt
                    sqrtPNew = sqrtPTick;
                    amtInExclFee = amtTick;

                    // re-calculate input amt _including_ fee
                    amtA = (
                        amtInExclFee < MAX_UINT_DIV_1E10
                            ? UnsafeMath.ceilDiv(uint256(amtInExclFee) * 1e10, gamma)
                            : UnsafeMath.ceilDiv(uint256(amtInExclFee), gamma) * 1e10
                    ).toInt256();
                }

                // calculate output amt
                amtB = isToken0
                    ? PoolMath.calcAmt1FromSqrtP(sqrtP, sqrtPNew, liquidity)
                    : PoolMath.calcAmt0FromSqrtP(sqrtP, sqrtPNew, liquidity);

                // calculate fee amt
                feeAmt = uint256(amtA - amtInExclFee);
            } else {
                // amtA: the output amt (negative)
                // amtB: the input amt (positive)

                // check if crossing tick
                if (amtA > amtTick) {
                    // no cross tick: calculate new sqrt price after swap
                    sqrtPNew = isToken0
                        ? PoolMath.calcSqrtPFromAmt0(sqrtP, liquidity, amtA)
                        : PoolMath.calcSqrtPFromAmt1(sqrtP, liquidity, amtA);
                } else {
                    // cross tick: replace new sqrt price and output amt
                    sqrtPNew = sqrtPTick;
                    amtA = amtTick;
                }

                // calculate input amt excluding fee
                amtInExclFee = isToken0
                    ? PoolMath.calcAmt1FromSqrtP(sqrtP, sqrtPNew, liquidity)
                    : PoolMath.calcAmt0FromSqrtP(sqrtP, sqrtPNew, liquidity);

                // calculate input amt
                amtB = (
                    amtInExclFee < MAX_UINT_DIV_1E10
                        ? UnsafeMath.ceilDiv(uint256(amtInExclFee) * 1e10, gamma)
                        : UnsafeMath.ceilDiv(uint256(amtInExclFee), gamma) * 1e10
                ).toInt256();

                // calculate fee amt
                feeAmt = uint256(amtB - amtInExclFee);
            }

            // reject tier if zero input amt and not crossing tick
            if (amtInExclFee == 0 && sqrtPNew != sqrtPTick) {
                amtA = REJECTED;
                amtB = 0;
                sqrtPNew = sqrtP;
                feeAmt = 0;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IMuffinHubCallbacks {
    /// @notice Called by Muffin hub to request for tokens to finish deposit
    /// @param token    Token that you are depositing
    /// @param amount   Amount that you are depositing
    /// @param data     Arbitrary data initially passed by you
    function muffinDepositCallback(
        address token,
        uint256 amount,
        bytes calldata data
    ) external;

    /// @notice Called by Muffin hub to request for tokens to finish minting liquidity
    /// @param token0   Token0 of the pool
    /// @param token1   Token1 of the pool
    /// @param amount0  Token0 amount you are owing to Muffin
    /// @param amount1  Token1 amount you are owing to Muffin
    /// @param data     Arbitrary data initially passed by you
    function muffinMintCallback(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Called by Muffin hub to request for tokens to finish swapping
    /// @param tokenIn      Input token
    /// @param tokenOut     Output token
    /// @param amountIn     Input token amount you are owing to Muffin
    /// @param amountOut    Output token amount you have just received
    /// @param data         Arbitrary data initially passed by you
    function muffinSwapCallback(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @dev Adapted from Rari's Solmate https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol
/// Edited from using error message to custom error for lower bytecode size.

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    error FailedTransferETH();
    error FailedTransfer();
    error FailedTransferFrom();
    error FailedApprove();

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!callStatus) revert FailedTransferETH();
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        if (!didLastOptionalReturnCallSucceed(callStatus)) revert FailedTransferFrom();
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        if (!didLastOptionalReturnCallSucceed(callStatus)) revert FailedTransfer();
    }

    function safeApprove(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        if (!didLastOptionalReturnCallSucceed(callStatus)) revert FailedApprove();
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returndatasize())

                // Revert with the same message.
                revert(0, returndatasize())
            }

            switch returndatasize()
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returndatasize())

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/hub/IMuffinHubBase.sol";
import "./interfaces/common/IERC20Minimal.sol";
import "./libraries/Pools.sol";

abstract contract MuffinHubBase is IMuffinHubBase {
    error FailedBalanceOf();
    error NotEnoughTokenInput();

    /// @param locked           1 means locked. 0 or 2 means unlocked.
    /// @param protocolFeeAmt   Amount of token accrued as the protocol fee
    struct TokenData {
        uint8 locked;
        uint248 protocolFeeAmt;
    }

    struct Pair {
        address token0;
        address token1;
    }

    /// @inheritdoc IMuffinHubBase
    address public governance;
    /// @dev Default tick spacing of new pool
    uint8 internal defaultTickSpacing = 100;
    /// @dev Default protocl fee of new pool (base 255)
    uint8 internal defaultProtocolFee = 0;
    /// @dev Whitelist of swap fees that LPs can choose to create a pool
    uint24[] internal defaultAllowedSqrtGammas = [99900, 99800, 99700, 99600, 99499]; // 20, 40, 60, 80, 100 bps

    /// @dev Pool-specific default tick spacing
    mapping(bytes32 => uint8) internal poolDefaultTickSpacing;
    /// @dev Pool-specific whitelist of swap fees
    mapping(bytes32 => uint24[]) internal poolAllowedSqrtGammas;

    /// @dev Mapping of poolId to pool state
    mapping(bytes32 => Pools.Pool) internal pools;
    /// @inheritdoc IMuffinHubBase
    mapping(address => mapping(bytes32 => uint256)) public accounts;
    /// @inheritdoc IMuffinHubBase
    mapping(address => TokenData) public tokens;
    /// @inheritdoc IMuffinHubBase
    mapping(bytes32 => Pair) public underlyings;

    /// @dev We blacklist TUSD legacy address on Ethereum to prevent TUSD from getting exploited here.
    /// In general, tokens with multiple addresses are not supported here and will cost losts of fund.
    address internal constant TUSD_LEGACY_ADDRESS = 0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;

    /// @notice Maximum number of tiers each pool can technically have. This number might vary in different networks.
    function maxNumOfTiers() external pure returns (uint256) {
        return MAX_TIERS;
    }

    /// @dev Get token balance of this contract
    function getBalance(address token) private view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this))
        );
        if (!success || data.length != 32) revert FailedBalanceOf();
        return abi.decode(data, (uint256));
    }

    /// @dev "Lock" the token so the token cannot be used as input token again until unlocked
    function getBalanceAndLock(address token) internal returns (uint256) {
        require(token != TUSD_LEGACY_ADDRESS);

        TokenData storage tokenData = tokens[token];
        require(tokenData.locked != 1); // 1 means locked
        tokenData.locked = 1;
        return getBalance(token);
    }

    /// @dev "Unlock" the token after ensuring the contract reaches an expected token balance
    function checkBalanceAndUnlock(address token, uint256 balanceMinimum) internal {
        if (getBalance(token) < balanceMinimum) revert NotEnoughTokenInput();
        tokens[token].locked = 2;
    }

    /// @dev Hash (owner, accRefId) as the key for the internal account
    function getAccHash(address owner, uint256 accRefId) internal pure returns (bytes32) {
        require(accRefId != 0);
        return keccak256(abi.encode(owner, accRefId));
    }

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

interface IERC20Minimal {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
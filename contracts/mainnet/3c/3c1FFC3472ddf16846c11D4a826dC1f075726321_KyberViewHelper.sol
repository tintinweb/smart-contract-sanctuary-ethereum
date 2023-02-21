// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPoolStorage {
  /// @notice Returns the previous and current initialized poolInitializedTicks of a specific tick
  /// @dev If specified tick is uninitialized, the returned values are zero.
  /// @param tick The tick to look up
  function initializedTicks(int24 tick) external view returns (int24 previous, int24 current);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
  /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
  /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
  /// secondsPerLiquidityOutside the seconds spent on the other side of the tick relative to the current tick
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside,
      uint128 secondsPerLiquidityOutside
    );
}

contract KyberViewHelper {
    struct TickData {
        uint256 feeGrowthOutside;
        int128 liquidityNet;
        uint128 secondsPerLiquidityOutside;
        int24 tick;
    }

    function getInitializedTicks(
        IPoolStorage pool
    ) external view returns (TickData[] memory) {
        TickData[200] memory rawResult; // 200 should be enough for all pools.
        (int24 previousInitial, ) = pool.initializedTicks(-887272);
        require(previousInitial == -887272, "Cannot get initial tick");
        int24 previous = previousInitial;
        {
            (, int128 liquidityNet, uint256 feeGrowthOutside, uint128 secondsPerLiquidityOutside) = pool.ticks(previousInitial);
            rawResult[0] = TickData(feeGrowthOutside, liquidityNet, secondsPerLiquidityOutside, previousInitial);
        }
        unchecked {
            uint256 length;
            for (uint256 i = 1; ; i++) {
                if (i >= rawResult.length) {
                    revert("Cannot get all ticks");
                }
                (, int24 current) = pool.initializedTicks(previous);
                if (previous == current) {
                    length = i;
                    break;
                }
                (, int128 liquidityNet, uint256 feeGrowthOutside, uint128 secondsPerLiquidityOutside) = pool.ticks(current);
                rawResult[i] = TickData(feeGrowthOutside, liquidityNet, secondsPerLiquidityOutside, current);
                previous = current;
            }

            TickData[] memory result = new TickData[](length);
            for (uint256 i = 0; i < length; i++) {
                result[i] = rawResult[i];
            }
            return result;
        }
    }
}
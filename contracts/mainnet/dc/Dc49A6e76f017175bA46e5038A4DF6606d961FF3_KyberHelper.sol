// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKyber {
  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
  /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
  /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
  /// secondsPerLiquidityOutside the seconds per unit of liquidity  spent on the other side of the tick relative to the current tick
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside,
      uint128 secondsPerLiquidityOutside
    );

  /// @notice Returns the previous and next initialized ticks of a specific tick
  /// @dev If specified tick is uninitialized, the returned values are zero.
  /// @param tick The tick to look up
  function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

  /// @notice Fetches the pool's prices, ticks and lock status
  /// @return sqrtP sqrt of current price: sqrt(token1/token0)
  /// @return currentTick pool's current tick
  /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
  /// @return locked true if pool is locked, false otherwise
  function getPoolState()
    external
    view
    returns (
      uint160 sqrtP,
      int24 currentTick,
      int24 nearestCurrentTick,
      bool locked
    );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IKyber.sol";

contract KyberHelper {

    function getTicks(IKyber pool, uint maxTickNum) external view returns (bytes[] memory ticks) {
        (,,int24 tick,) = pool.getPoolState();

        int24[] memory initTicks = new int24[](maxTickNum);

        uint counter = 1;
        initTicks[0] = tick;

        (int24 previous, int24 next) = pool.initializedTicks(tick);
        if (previous != tick && previous != 0) {
            initTicks[counter] = previous;
            counter++;
        }
        if (next != tick && next != 0) {
            initTicks[counter] = next;
            counter++;
        }

        while ((next != 0 || previous != 0)) {
            if (previous != 0) {
                (int24 p, ) = pool.initializedTicks(previous);
                if (previous != p && p != 0) {
                    initTicks[counter] = p;
                    previous = p;
                    counter++;
                } else {
                    previous = 0;
                }
            }

            if (counter == maxTickNum) {
                break;
            }

            if (next != 0) {
                (, int24 n) = pool.initializedTicks(next);
                if (next != n && n != 0) {
                    initTicks[counter] = n;
                    next = n;
                    counter++;
                } else {
                    next = 0;
                }
            }

            if (counter == maxTickNum) {
                break;
            }
        }

        ticks = new bytes[](counter);
        for (uint i = 0; i < counter; i++) {
            (
                uint128 liquidityGross,
                int128 liquidityNet,
                ,
            ) = pool.ticks(initTicks[i]);

             ticks[i] = abi.encodePacked(
                 liquidityGross,
                 liquidityNet,
                 initTicks[i]
             );
        }
    }

}
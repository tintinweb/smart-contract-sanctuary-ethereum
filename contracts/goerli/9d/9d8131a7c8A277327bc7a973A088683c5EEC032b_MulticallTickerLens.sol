// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ITickLens.sol";

/// @title MulticallTickerLens - Aggregate results from multiple TickLens function calls
contract MulticallTickerLens {
    ITickLens lens;

    constructor(address _lens) {
        lens = ITickLens(_lens);
    }

    function concat(ITickLens.PopulatedTick[] memory Accounts, ITickLens.PopulatedTick[] memory Accounts2) internal pure returns(ITickLens.PopulatedTick[] memory) {
        ITickLens.PopulatedTick[] memory returnArr = new ITickLens.PopulatedTick[](Accounts.length + Accounts2.length);

        uint i=0;
        for (; i < Accounts.length; i++) {
            returnArr[i] = Accounts[i];
        }

        uint j=0;
        while (j < Accounts.length) {
            returnArr[i++] = Accounts2[j++];
        }

        return returnArr;
    }

    function getPopulatedTicks(
        address pool,
        int16 tickBitmapIndexStart,
        int16 tickBitmapIndexEnd
    ) external view returns (ITickLens.PopulatedTick[] memory populatedTicks) {
        while (tickBitmapIndexStart != tickBitmapIndexEnd) {
            ITickLens.PopulatedTick[] memory ticks = lens.getPopulatedTicksInWord(
                pool,
                tickBitmapIndexStart++);
            populatedTicks = concat(populatedTicks, ticks);
        }
        return populatedTicks;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Tick Lens
/// @notice Provides functions for fetching chunks of tick data for a pool
/// @dev This avoids the waterfall of fetching the tick bitmap, parsing the bitmap to know which ticks to fetch, and
/// then sending additional multicalls to fetch the tick data
interface ITickLens {
    struct PopulatedTick {
        int24 tick;
        int128 liquidityNet;
        uint128 liquidityGross;
    }

    /// @notice Get all the tick data for the populated ticks from a word of the tick bitmap of a pool
    /// @param pool The address of the pool for which to fetch populated tick data
    /// @param tickBitmapIndex The index of the word in the tick bitmap for which to parse the bitmap and
    /// fetch all the populated ticks
    /// @return populatedTicks An array of tick data for the given word in the tick bitmap
    function getPopulatedTicksInWord(address pool, int16 tickBitmapIndex)
        external
        view
        returns (PopulatedTick[] memory populatedTicks);
}
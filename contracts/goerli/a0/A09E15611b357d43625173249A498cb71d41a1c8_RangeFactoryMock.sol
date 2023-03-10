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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import '../interfaces/IRangeFactory.sol';
import './RangePoolMock.sol';

contract RangeFactoryMock is IRangeFactory {
    address mockPool;
    address owner;

    mapping(uint24 => int24) public feeTierTickSpacing;
    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

    constructor(address tokenA, address tokenB) {
        owner = msg.sender;
        require(tokenA < tokenB, 'wrong token order');

        feeTierTickSpacing[500] = 10;
        feeTierTickSpacing[3000] = 60;
        feeTierTickSpacing[10000] = 200;

        mockPool = address(new RangePoolMock(tokenA, tokenB, 500, 10));

        getPool[tokenA][tokenB][500] = mockPool;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import '../interfaces/IRangePool.sol';
import './RangePoolMock.sol';

contract RangePoolMock is IRangePool {
    address internal admin;
    address public token0;
    address public token1;
    int24 public tickSpacing;
    uint256 swapFee;

    uint16 observationCardinality;
    uint16 observationCardinalityNext;

    int56 tickCumulative0;
    int56 tickCumulative1;

    constructor(
        address _token0,
        address _token1,
        uint24 _swapFee,
        int24 _tickSpacing
    ) {
        require(_token0 < _token1, 'wrong token order');
        admin = msg.sender;
        token0 = _token0;
        token1 = _token1;
        swapFee = _swapFee;
        tickSpacing = _tickSpacing;
        observationCardinality = 4;
        observationCardinalityNext = 4;
    }

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 cardinality,
            uint16 cardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        return (1 << 96, 0, 4, observationCardinality, observationCardinalityNext, 100, true);
    }

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        )
    {
        secondsAgos;
        tickCumulatives = new int56[](secondsAgos.length);
        tickCumulatives[0] = int56(tickCumulative0);
        tickCumulatives[1] = int56(tickCumulative1);
        secondsPerLiquidityCumulativeX128s = new uint160[](secondsAgos.length);
        secondsPerLiquidityCumulativeX128s[0] = uint160(949568451203788412348119);
        secondsPerLiquidityCumulativeX128s[1] = uint160(949568438263103965182699);
    }

    function increaseObservationCardinalityNext(uint16 cardinalityNext) external {
        observationCardinalityNext = cardinalityNext;
    }

    function setTickCumulatives(int56 _tickCumulative0, int56 _tickCumulative1) external {
        tickCumulative0 = _tickCumulative0;
        tickCumulative1 = _tickCumulative1;
    }

    function setObservationCardinality(uint16 _observationCardinality) external {
        observationCardinality = _observationCardinality;
    }
}
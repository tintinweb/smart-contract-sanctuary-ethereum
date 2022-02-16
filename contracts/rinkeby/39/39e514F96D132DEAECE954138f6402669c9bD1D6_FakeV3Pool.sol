pragma solidity =0.6.6;

contract FakeV3Pool {
    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }

    Slot0 public slot0;
    address public token0;
    address public token1;

    constructor(
        uint160 _sqrtPriceX96,
        int24 _tick,
        address _token0,
        address _token1
    ) public {
        // Get the real sqrtPriceX96 and tick value from mainnet
        // token0, token1 order should match that in mainnet
        // If the non-stablecoin in mainnet is token0, set token1 to 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF
        // If the non-stablecoin in mainnet is token1, set token0 to 0x0000000000000000000000000000000000000000
        slot0.sqrtPriceX96 = _sqrtPriceX96;
        slot0.tick = _tick;
        token0 = _token0;
        token1 = _token1;
    }

    function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) {
        int24 _tick = slot0.tick;

        uint256 len = secondsAgos.length;
        tickCumulatives = new int56[](len);
        secondsPerLiquidityCumulativeX128s = new uint160[](len);

        for (uint256 i = 0; i < len; i++) {
            tickCumulatives[i] = int56(int256(secondsAgos[i]) * _tick * -1);
            secondsPerLiquidityCumulativeX128s[i] = uint160((i + 1) << 128);
        }
    }

    function set(uint160 _sqrtPriceX96, int24 _tick) external {
        // Get the real sqrtPriceX96 value from mainnet
        slot0.sqrtPriceX96 = _sqrtPriceX96;
        slot0.tick = _tick;
    }
}
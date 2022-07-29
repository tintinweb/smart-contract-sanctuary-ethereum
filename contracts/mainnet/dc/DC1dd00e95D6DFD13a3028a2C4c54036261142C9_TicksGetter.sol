// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IUniswapV3Pool{
    function tickBitmap(int16 wordPosition) external view returns (uint256);
    function tickSpacing() external view returns (int24);
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );
}
// contract TicksGetter{
//     struct Tick
//     {
//         int24 pos;
//         int128 liquidityNet;
//     }
    
//     function get_ticks(address pool_address) external view returns(Tick[] memory populatedTicks) {
//         // Tick[] storage ticks;
//         int24 MIN_TICK = -887272;
//         int24 MAX_TICK = 887272;
//         IUniswapV3Pool pool = IUniswapV3Pool(pool_address);
//         int24 tickSpacing = pool.tickSpacing();
//         int16 maxWord = int16(MAX_TICK / 256 / tickSpacing);
//         int16 minWord = int16(MIN_TICK / 256 / tickSpacing);
//         if(MIN_TICK % (256 * tickSpacing) != 0) minWord -= 1;
                
//         uint256 count = 0;
//         for(int16 currentWord = minWord; currentWord <= maxWord; currentWord++)
//         {
//             uint256 bitmap = pool.tickBitmap(currentWord);
//             int24 bit = 1;
//             while(bitmap != 0)
//             {
//                 if(bitmap & 1 != 0) {
//                     int24 pos = (int24(currentWord) * 256 + bit) * tickSpacing;
//                     (,int128 liquidityNet,,,,,,) = pool.ticks(pos);
//                     populatedTicks[count] = Tick(pos, liquidityNet);
//                     count +=1;
//                 }
//                 bitmap >>= 1;
//                 bit++;
//             }
//         }
//     }
// }


contract TicksGetter{
    struct Tick
    {
        int24 pos;
        int128 liquidityNet;
    }

    function get_ticks(address pool_address) external view returns(Tick[] memory ticks) {
        int24 MIN_TICK = -887272;
        int24 MAX_TICK = 887272;

        IUniswapV3Pool pool = IUniswapV3Pool(pool_address);

        int24 tickSpacing = pool.tickSpacing();
        int16 maxWord = int16(MAX_TICK / 256 / tickSpacing);
        int16 minWord = int16(MIN_TICK / 256 / tickSpacing);
        if(MIN_TICK % (256 * tickSpacing) != 0) minWord -= 1;

        ticks = new Tick[](1000);

        uint256 i = 0;
        for(int16 currentWord = minWord; currentWord <= maxWord; currentWord++)
        {
            uint256 bitmap = pool.tickBitmap(currentWord);
            int24 bit = 0;
            while(bitmap != 0)
            {
                if(bitmap & 1 != 0) {
                    int24 pos = (int24(currentWord) * 256 + bit) * tickSpacing;
                    (,int128 liquidityNet,,,,,,) = pool.ticks(pos);
                    ticks[i++] = Tick(pos, liquidityNet);
                }
                bitmap >>= 1;
                bit++;
            }
        }
    }
}